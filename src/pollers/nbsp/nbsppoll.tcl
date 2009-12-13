#!%TCLSH%
#
# $Id$
#

# Get the location of the nbspd status file
set _nbspdinit "/usr/local/libexec/nbsp/nbspd.init";
if {[file exists ${_nbspdinit}] == 0} {
    puts stderr "${_nbspdinit} not found.";
    exit 1;
}
source ${_nbspdinit};
unset _nbspdinit;
set nbsppoll(datafile) $nbspd(statusfile);

# This is the order of the fields in nbspd.status (according to nbsp/stats.c)
set nbsppoll(numfields) 17;
set nbsppoll(index,time) 0;
set nbsppoll(index,frames_received) 1;
set nbsppoll(index,frames_processed) 2;
set nbsppoll(index,frames_jumps) 3;
set nbsppoll(index,frames_bad) 4;
set nbsppoll(index,frames_data_size) 5;
set nbsppoll(index,products_transmitted) 6;
set nbsppoll(index,products_completed) 7;
set nbsppoll(index,products_missed) 8;
set nbsppoll(index,products_retransmitted) 9;
set nbsppoll(index,products_retransmitted_c) 10;
set nbsppoll(index,products_retransmitted_p) 11;
set nbsppoll(index,products_retransmitted_i) 12;
set nbsppoll(index,products_retransmitted_r) 13;
set nbsppoll(index,products_rejected) 14;
set nbsppoll(index,products_aborted) 15;
set nbsppoll(index,products_bad) 16;

# These are the output fields according to the devices.def file.
set nbsppoll(fields) [list time \
			  frames_received \
			  frames_data_size \
			  products_transmitted \
			  products_completed \
			  products_missed \
			  products_retransmitted];

# Variables
set nbsppoll(data,last_time) 0;
set nbsppoll(data,valid) 0;
foreach field $nbsppoll(fields) {
    set nbsppoll(data,$field) 0;
}

proc nbsppoll_get_data {} {

    global nbsppoll;

    set data [split [string trimright [exec tail -n 1 $nbsppoll(datafile)]]];

    if {[nbsppoll_verify_data $data] != 0} {
	# Partial record, maybe from file rotation. Assume it is a
	# temporary situation.
	return;
    }

    set data_time [lindex $data $nbsppoll(index,time)];
    if {$data_time == $nbsppoll(data,last_time)} {
	return;
    }

    # If there is unreported data, report it or we will loose it
    if {$nbsppoll(data,valid) == 1} {
	nbsppoll_report_data;
    }

    # Fill the array with the current values
    foreach field $nbsppoll(fields) {
	set nbsppoll(data,$field) [lindex $data $nbsppoll(index,$field)];
    }
    set nbsppoll(data,valid) 1;
    set nbsppoll(data,last_time) $nbsppoll(data,time);
}

proc nbsppoll_report_data {} {

    global nbsppoll;

    if {$nbsppoll(data,valid) == 0} {
	puts "WARN:nbsppoll waiting for data.";
	return;
    }

    set output "OK:";
    set data [list];
    foreach field $nbsppoll(fields) {
	lappend data $nbsppoll(data,$field);
    }
    append output [join $data ","];
    puts $output;

    set nbsppoll(data,valid) 0;
    foreach field $nbsppoll(fields) {
	set nbsppoll(data,$field) 0;
    }
}

proc nbsppoll_verify_data {data} {

    global nbsppoll;

    if {[llength $data] != $nbsppoll(numfields)} {
	return 1;
    }

    foreach field $nbsppoll(fields) {
	set v [lindex $data $nbsppoll(index,$field)];
	if {[regexp {^\d+$} $v] == 0} {
	    return 1;
	}
    }

    return 0;
}

#
# main
#
while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	nbsppoll_get_data;
    } elseif {$cmd eq "REPORT"} {
	nbsppoll_report_data;
    } else {
	puts "Unrecognized command $cmd.";
    }
}
