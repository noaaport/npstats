#!%TCLSH%
#
# $Id$
#
# Usage:
#       inpemwinpoll [-p <port>] [-t <connect_timeout>] <pool_id> | -h <host>
#
package require cmdline;

set usage {inpemwinpoll [-p <port>] [-t <connect_timeout>]
    <pool_id> | -h <host>};
set optlist {h {p.arg ""} {t.arg ""}};

# defaults
set inpemwin(pool_server_port) 8016;
set inpemwin(connect_timeout) 10;

# variables
append inpemwin(pool_url_tmpl) "http://" \
    {$inpemwin(pool_server_id).pool.iemwin.net:$inpemwin(pool_server_port)} \
    "/_iemwin/stats";

append inpemwin(host_url_tmpl) "http://" \
    {$inpemwin(pool_server_id):$inpemwin(pool_server_port)} \
    "/_iemwin/stats";

set inpemwin(curl_options_tmpl) \
    [list -s -S --connect-timeout {$inpemwin(connect_timeout)}];
#
set inpemwin(pool_url) "";
set inpemwin(curl_options) "";

# This is the order of the fields
set inpemwin(numfields) 20;
set inpemwin(index,time) 0;
set inpemwin(index,npemwind_start_time) 1;
set inpemwin(index,num_clients) 2;
set inpemwin(index,client_table) 3;
#
set inpemwin(index,es_ip) 4;
set inpemwin(index,es_port) 5;
set inpemwin(index,es_stats_connect) 6;
set inpemwin(index,es_stats_disconnect) 7;
set inpemwin(index,es_stats_consecutive_packets) 8;
set inpemwin(index,es_stats_max_packets) 9;
set inpemwin(index,es_stats_total_packets) 10;
set inpemwin(index,es_stats_bad_packet_count) 11; 
set inpemwin(index,es_stats_connections) 12;
set inpemwin(index,es_stats_error) 13;
set inpemwin(index,es_stats_serverread_errors) 14;
set inpemwin(index,es_stats_serverclosed_errors) 15;
set inpemwin(index,es_stats_header_errors) 16;
set inpemwin(index,es_stats_checksum_errors) 17;
set inpemwin(index,es_stats_filename_errors) 18;
set inpemwin(index,es_stats_unknown_errors) 19;
#
# These will be included, and inpemwin(numfields) will be updated,
# if the npemwin output includes the frames data.
#
set inpemwin(index,frames_time) 20;
set inpemwin(index,frames_received) 21;
set inpemwin(index,frames_processed) 22;
set inpemwin(index,frames_bad) 23;
set inpemwin(index,frames_data_size) 24;

# These are the output fields according to the devices.def file.
set inpemwin(fields) [list time \
			  npemwind_start_time \
			  num_clients \
			  es_ip \
			  es_port \
			  es_stats_connect \
			  es_stats_consecutive_packets \
			  client_table];

# Variables
set inpemwin(data,last_time) 0;
set inpemwin(data,valid) 0;
foreach field $inpemwin(fields) {
    set inpemwin(data,$field) 0;
}

proc inpemwin_get_data {} {

    global inpemwin;

    set status [catch {
	set rawdata \
	    [eval exec curl $inpemwin(curl_options) $inpemwin(pool_url)];
    } errmsg];
    if {$status != 0} {
	puts $errmsg;
	# Assume it is a temporary situation.
	return;
    }

    set rawdata_parts [split $rawdata ";"];

    foreach part $rawdata_parts {
	set part_list [split [string trim $part] "="];
	set key [lindex $part_list 0];
	set a($key) [lindex $part_list 1];
    }
    #
    # We will transform the data in two ways. First the clients in the
    # client table will be separated by a '+' rather than a space.
    # Secondly, we will enclose the string valued elements within single
    # quotes (as a concesion to the sql insert methods later).
    #
    set client_table [join [split $a(client_table) "\n"] "|"];
    set a(client_table) "'${client_table}'";
    set es_ip "'[lindex $a(upstream_master) 0]'";
    set a(upstream_master) [lreplace $a(upstream_master) 0 0 $es_ip];

    # The raw data contains
    #
    # data_format
    # npemwind_start_time
    # upstream_master
    # npemwin_status
    # num_clients
    # client_table
    #
    # where (from npemwin/src/servers.c)
    #
    # upstream_master = es->ip, es->port,
    #		  (intmax_t)es->stats.connect, 
    #		  (intmax_t)es->stats.disconnect, 
    #		  es->stats.consecutive_packets, 
    #		  es->stats.max_packets,
    #		  es->stats.total_packets, 
    #		  es->stats.bad_packet_count, 
    #		  es->stats.connections, 
    #		  es->stats.error,
    #		  es->stats.serverread_errors,
    #		  es->stats.serverclosed_errors,
    #		  es->stats.header_errors,
    #		  es->stats.checksum_errors,
    #		  es->stats.filename_errors,
    #		  es->stats.unknown_errors
    #
    # and (from npemwin/src/stats.c)
    #
    # npemwin_status = (unsigned int)g.nbspstats.time,
    #	  g.nbspstats.frames_received,
    #     g.nbspstats.frames_processed,
    #     g.nbspstats.frames_bad,
    #     g.nbspstats.frames_data_size
    #

    # Handle first the original (up to npemwin-2.4.5r output (version 1)
    set data [concat [list [clock seconds] $a(start_time) \
			  $a(num_clients) $a(client_table)] \
		  [split $a(upstream_master)]];

    # Handle the revised (as of npemwin-2.4.6r) output (version 2) which
    # includes the frames data.
    if {$a(data_format) == 2} {
	set data [concat $data [split $a(npemwin_status)]];
	incr inpemwin(numfields) 5;
    }

    if {[inpemwin_verify_data $data] != 0} {
	# Partial record, maybe from file rotation. Assume it is a
	# temporary situation.
	return;
    }

    # Fill the array with the current values
    foreach field $inpemwin(fields) {
	set inpemwin(data,$field) [lindex $data $inpemwin(index,$field)];
    }
    set inpemwin(data,valid) 1;
    set inpemwin(data,last_time) $inpemwin(data,time);
}

proc inpemwin_report_data {} {

    global inpemwin;

    if {$inpemwin(data,valid) == 0} {
	puts "WARN:inpemwin waiting for data.";
	return;
    }

    set output "OK:";
    set data [list];
    foreach field $inpemwin(fields) {
	lappend data $inpemwin(data,$field);
    }
    append output [join $data ","];
    puts $output;

    set inpemwin(data,valid) 0;
    foreach field $inpemwin(fields) {
	set inpemwin(data,$field) 0;
    }
}

proc inpemwin_verify_data {data} {

    global inpemwin;

    if {[llength $data] != $inpemwin(numfields)} {
	puts [llength $data];
	return 1;
    }

    foreach field $inpemwin(fields) {
	set v [lindex $data $inpemwin(index,$field)];
	if {[regexp {^\s*$} $v]} {
	    return 1;
	}
    }

    return 0;
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];
if {$argc != 1} {
    puts $usage;
    exit 1;
}
set inpemwin(pool_server_id) [lindex $argv 0];

if {$option(p) ne ""} {
    set inpemwin(pool_server_port) $option(p);
}

if {$option(t) ne ""} {
    set inpemwin(connect_timeout) $option(t);
}

set inpemwin(curl_options) [subst $inpemwin(curl_options_tmpl)];
if {$option(h) == 0} {
    set inpemwin(pool_url) [subst $inpemwin(pool_url_tmpl)];
} else {
    set inpemwin(pool_url) [subst $inpemwin(host_url_tmpl)];
}

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	inpemwin_get_data;
    } elseif {$cmd eq "REPORT"} {
	inpemwin_report_data;
    } else {
	puts "Unrecognized command $cmd.";
    }
}
