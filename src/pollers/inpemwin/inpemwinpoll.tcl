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

# These are the output fields according to the devices.def file.
set inpemwin(keys) [list \
			stats_time \
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
foreach key $inpemwin(keys) {
    set inpemwin(data,$key) "";
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

    # format 1 is separated by ";\n" while in format it is just "\n"
    set rawdata_lines [split $rawdata "\n"];

    foreach line $rawdata_lines {
	set line [string trimright $line ";"]
	set kv_list [split $line "="];
	set key [string trim [lindex $kv_list 0]];
	set inpemwin(data,$key) [string trim [lindex $kv_list 1]];
    }

    # Handle format 1
    if {$inpemwin(data,data_format) == 1} {
	#
	# Split on the ";" so that we get the client table
	# in one list element
	#
	set rawdata_lines [split $rawdata ";"];
	foreach line $rawdata_lines {
	    set kv_list [split $line "="];
	    set key [string trim [lindex $kv_list 0]];
	    set inpemwin(data,$key) [string trim [lindex $kv_list 1]];
	}

	#
	# Split the upstream data and extract what we need. We use the fact
	# that the fields are ordered like this
	# (from npemwin/src/servers.c)
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
	set _es [split $inpemwin(data,upstream_master)];	
	set inpemwin(data,es_ip) [lindex ${_es} 0];
	set inpemwin(data,es_port) [lindex ${_es} 1];
	set inpemwin(data,es_stats_connect) [lindex ${_es} 2];
	set inpemwin(data,es_stats_consecutive_packets) [lindex ${_es} 4];

	# The stats time is not output in version 1 of the iemwin query
	set inpemwin(data,stats_time) [clock seconds];

	# The start_time key was renamed in version 2
	set inpemwin(data,npemwind_start_time) $inpemwin(data,start_time);

	# Transform the client_table as output by iemwin in version 1;
	# each client entry is delimited by a "|" instead of a "\n".
	set inpemwin(data,client_table) \
	    [join [split $inpemwin(data,client_table) "\n"] "|"];
    }

    #
    # We will enclose the string valued elements within single
    # quotes (as a concesion to the sql insert methods later).
    #
    set inpemwin(data,client_table) "'$inpemwin(data,client_table)'";
    set inpemwin(data,es_ip) "'$inpemwin(data,es_ip)'";

    if {[inpemwin_verify_data] != 0} {
	# Partial record, maybe from file rotation. Assume it is a
	# temporary situation.
	return;
    }

    set inpemwin(data,valid) 1;
    set inpemwin(data,last_time) $inpemwin(data,stats_time);
}

proc inpemwin_report_data {} {

    global inpemwin;

    if {$inpemwin(data,valid) == 0} {
	puts "WARN:inpemwin waiting for data.";
	return;
    }

    set output "OK:";
    set data [list];
    foreach k $inpemwin(keys) {
	lappend data $inpemwin(data,$k);
    }
    append output [join $data ","];
    puts $output;

    set inpemwin(data,valid) 0;
    foreach k $inpemwin(keys) {
	set inpemwin(data,$k) "";
    }
}

proc inpemwin_verify_data {} {

    global inpemwin;

    foreach k $inpemwin(keys) {
	set v $inpemwin(data,$k)];
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
