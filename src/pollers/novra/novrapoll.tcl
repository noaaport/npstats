#!%TCLSH%
#
# $Id$
#
package require "novramon";

proc novrapoll_get_data {} {

    set status [catch {
	::novramon::poll;
    } errmsg];
}

proc novrapoll_report_data {} {

    set status [catch {
	::novramon::report data;
    } errmsg];
    
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
