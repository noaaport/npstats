#!%TCLSH%
#
# $Id$
#
# Usage {inpemwinpoll <server_poll_id>};
#
set inpemwin(pool_domain_url) {pool.iemwin.net:8016/_iemwin/stats};

# This is the order of the fields in nbspd.status (according to nbsp/stats.c)
set inpemwin(numfields) 17;
set inpemwin(index,time) 0;
set inpemwin(index,frames_received) 1;
set inpemwin(index,frames_processed) 2;
set inpemwin(index,frames_jumps) 3;
set inpemwin(index,frames_bad) 4;
set inpemwin(index,frames_data_size) 5;
set inpemwin(index,products_transmitted) 6;
set inpemwin(index,products_completed) 7;
set inpemwin(index,products_missed) 8;
set inpemwin(index,products_retransmitted) 9;
set inpemwin(index,products_retransmitted_c) 10;
set inpemwin(index,products_retransmitted_p) 11;
set inpemwin(index,products_retransmitted_i) 12;
set inpemwin(index,products_retransmitted_r) 13;
set inpemwin(index,products_rejected) 14;
set inpemwin(index,products_aborted) 15;
set inpemwin(index,products_bad) 16;

# These are the output fields according to the devices.def file.
set inpemwin(fields) [list time \
			  frames_received \
			  frames_data_size \
			  products_transmitted \
			  products_completed \
			  products_missed \
			  products_retransmitted];

# Variables
set inpemwin(data,last_time) 0;
set inpemwin(data,valid) 0;
foreach field $inpemwin(fields) {
    set inpemwin(data,$field) 0;
}

proc inpemwin_get_data {} {

    global inpemwin;

    set data [split [string trimright [exec tail -n 1 $inpemwin(datafile)]]];

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
	if {[regexp {^\d+$} $v] == 0} {
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
set inpemwin(pool_url) $inpemwin(pool_server_id).$inpemwin(pool_domain_url);

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	inpemwin_get_data;
    } elseif {$cmd eq "REPORT"} {
	inpemwin_report_data;
    } else {
	puts "Unrecognized command $cmd.";
    }
}
