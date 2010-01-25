#!%TCLSH%
#
# $Id$
#
package require "novramon";

proc novrapoll_get_data {} {

    global g;

    set status [catch {
	::novramon::poll;
    } errmsg];

    set g(poll_status) $status;
    set g(poll_errmsg) $errmsg;
}

proc novrapoll_report_data {} {

    global g;

    if {$g(poll_status) == 0} {
	set status [catch {
	    ::novramon::report data;
	} errmsg];
    } else {
	set status $g(poll_status);
	set errmsg $g(poll_errmsg);
    }

    if {$status == 0} {
	set output "OK:";
	append output $data;
    } else {
	set output "ERROR:";
	append output $errmsg;
    }

    puts $output;
}

#
# state variables
#
set g(poll_status) 0;
set g(poll_errmsg) "";

#
# main
#
::novramon::open;

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
        novrapoll_get_data;
    } elseif {$cmd eq "REPORT"} {
        novrapoll_report_data;
    } else {
        puts "ERROR:Unrecognized command $cmd.";
    }
}

::novramon::close;
