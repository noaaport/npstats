#!%TCLSH%
#
# $Id$
#
# Usage {inpemwinpoll <server_poll_id>};
#
set inpemwin(pool_url_tmpl) \
    {http://$inpemwin(pool_server_id).pool.iemwin.net:8016/_iemwin/stats};
set inpemwin(pool_url) "";   # defined in main
#
set inpemwin(connect_timeout) 10;
set inpemwin(curl_options) [list -s -S \
				--connect-timeout $inpemwin(connect_timeout)];

# This is the order of the fields
set inpemwin(numfields) 19;
set inpemwin(index,time) 0;
set inpemwin(index,npemwind_start_time) 1;
set inpemwin(index,num_clients) 2;
#
set inpemwin(index,es_ip) 3;
set inpemwin(index,es_port) 4;
set inpemwin(index,es_stats_connect) 5;
set inpemwin(index,es_stats_disconnect) 6;
set inpemwin(index,es_stats_consecutive_packets) 7;
set inpemwin(index,es_stats_max_packets) 8;
set inpemwin(index,es_stats_total_packets) 9;
set inpemwin(index,es_stats_bad_packet_count) 10; 
set inpemwin(index,es_stats_connections) 11;
set inpemwin(index,es_stats_error) 12;
set inpemwin(index,es_stats_serverread_errors) 13;
set inpemwin(index,es_stats_serverclosed_errors) 14;
set inpemwin(index,es_stats_header_errors) 15;
set inpemwin(index,es_stats_checksum_errors) 16;
set inpemwin(index,es_stats_filename_errors) 17;
set inpemwin(index,es_stats_unknown_errors) 18;

# These are the output fields according to the devices.def file.
set inpemwin(fields) [list time \
	npemwind_start_time \
	num_clients \
	es_ip \
	es_port \
	es_stats_connect \
	es_stats_consecutive_packets];

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

    # The raw data contains
    #
    # data_format
    # npemwind_start_time
    # upstream_master_data
    # num_clients
    # client_table
    #
    # where (from npemwin/src/servers.c)
    #
    # upstream_master_data = es->ip, es->port,
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
    # In principle, we should use use the value of a(data_format) to
    # interpret the data if there were various formats or versions.
    # Whatever we do later, this is how we will normalize the data:

    set data [concat [list [clock seconds] $a(start_time) $a(num_clients)] \
		  [split $a(upstream_master)]];

    if {[inpemwin_verify_data $data] != 0} {
	# Partial record, maybe from file rotation. Assume it is a
	# temporary situation.
	return;
    }

    set data_time [lindex $data $inpemwin(index,time)];
    if {$data_time == $inpemwin(data,last_time)} {
	return;
    }

    # If there is unreported data, report it or we will loose it
    if {$inpemwin(data,valid) == 1} {
	inpemwin_report_data;
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
if {$argc != 1} {
    puts $usage;
    exit 1;
}
set inpemwin(pool_server_id) [lindex $argv 0];
set inpemwin(pool_url) [subst $inpemwin(pool_url_tmpl)];

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	inpemwin_get_data;
    } elseif {$cmd eq "REPORT"} {
	inpemwin_report_data;
    } else {
	puts "Unrecognized command $cmd.";
    }
}
