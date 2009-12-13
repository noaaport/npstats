#
# $Id$
#
#
# Functions to send the data to the monitor program (used by the manager,
# http, and any other collector).
#
package provide monitor 1.0;

namespace eval monitor {

    variable monitor;

    array set monitor {};

    # monitor(F);
    set monitor(program) "";
}

proc ::monitor::init {program} {
    
    variable monitor;

    set monitor(program) $program;
}

proc ::monitor::connect {} {

    variable monitor;

    set status [catch {
	set F [open "|$monitor(program)" "w"];
    } errmsg];

    if {$status != 0} {
	return $errmsg;
    }

    set monitor(F) $F;

    return "";
}

proc ::monitor::disconnect {} {

    variable monitor;

    if {[info exists monitor(F)] == 0} {
	return "";
    }

    set status [catch {
	close $monitor(F);
    } errmsg];

    unset monitor(F);

    if {$status != 0} {
	return $errmsg;
    }

    return "";
}

proc ::monitor::send_output {pdata} {

    variable monitor;

    set status [catch {
	puts $monitor(F) $pdata;
	flush $monitor(F);
    } errmsg];

    if {$status != 0} {
	::monitor::disconnect;
	::monitor::connect;
	return $errmsg;
    }

    return "";
}
