#!%TCLSH%
#
# $Id$
#
# Usage {inbsppoll [-p <port>] [-t <connect_timeout>] <server_ip>};
#
package require cmdline;
set usage {inbsppoll [-p <port>] [-t <connect_timeout>] <server_ip>};
set optlist {{p.arg ""} {t.arg ""}};

# defaults
set inbsp(server_port) 8015;
set inbsp(connect_timeout) 10;

# variables
append inbsp(server_url_tmpl) "http://" \
    {$inbsp(server_ip):$inbsp(server_port)} \
    {/_inbsp/stats?format=csvk};

set inbsp(curl_options_tmpl) \
    [list -s -S --connect-timeout {$inbsp(connect_timeout)}];
#
set inbsp(server_url) "";
set inbsp(curl_options) "";

# These are the output fields according to the devices.def file.
set inbsp(keys) [list \
		     stats_time \
		     frames_received \
		     frames_jumps \
		     frames_data_size \
		     products_transmitted \
		     products_retransmitted \
		     products_missed \
		     queue_processor \
		     queue_filter \
		     queue_server];

# Variables
set inbsp(data,last_time) 0;
set inbsp(data,valid) 0;
foreach k $inbsp(keys) {
    set inbsp(data,$k) "";
}

proc inbsp_get_data {} {

    global inbsp;

    set status [catch {
	set rawdata \
	    [eval exec curl $inbsp(curl_options) $inbsp(server_url)];
    } errmsg];
    if {$status != 0} {
	puts $errmsg;
	# Assume it is a temporary situation.
	return;
    }

    set rawdata_parts [split $rawdata ","];

    # In principle, we should use use the value of a(data_format) to
    # interpret the data if there were various formats or versions.

    foreach kv $rawdata_parts {
	set kv_list [split $kv "="];
	set k [string trim [lindex $kv_list 0]];
	set inbsp(data,$k) [string trim [lindex $kv_list 1]];
    }

    if {[inbsp_verify_data] != 0} {
	# Partial record, maybe from file rotation. Assume it is a
	# temporary situation.
	return;
    }

    set inbsp(data,valid) 1;
    set inbsp(data,last_time) $inbsp(data,stats_time);
}

proc inbsp_report_data {} {

    global inbsp;

    if {$inbsp(data,valid) == 0} {
	puts "WARN:inbsp waiting for data.";
	return;
    }

    set output "OK:";
    set data [list];
    foreach k $inbsp(keys) {
	lappend data $inbsp(data,$k);
    }
    append output [join $data ","];
    puts $output;

    set inbsp(data,valid) 0;
    foreach k $inbsp(keys) {
	set inbsp(data,$k) "";
    }
}

proc inbsp_verify_data {} {

    global inbsp;

    foreach k $inbsp(keys) {
	set v $inbsp(data,$k);
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
set inbsp(server_ip) [lindex $argv 0];

if {$option(p) ne ""} {
    set inbsp(server_port) $option(p);
}

if {$option(t) ne ""} {
    set inbsp(connect_timeout) $option(t);
}

set inbsp(server_url) [subst $inbsp(server_url_tmpl)];
set inbsp(curl_options) [subst $inbsp(curl_options_tmpl)];

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	inbsp_get_data;
    } elseif {$cmd eq "REPORT"} {
	inbsp_report_data;
    } else {
	puts "Unrecognized command $cmd.";
    }
}
