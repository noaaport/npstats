#
# $Id$
#
#
# Functions to send the data to the spooler program (used by the manager,
# http, and any other collector).
#
package provide spooler 1.0;

namespace eval spooler {

    variable spooler;

    array set spooler {};

    # spooler(F);
    set spooler(program) "";
}

proc ::spooler::init {program} {
    
    variable spooler;

    set spooler(program) $program;
}

proc ::spooler::connect {} {

    variable spooler;

    set status [catch {
	set F [open "|$spooler(program)" "w"];
    } errmsg];

    if {$status != 0} {
	return $errmsg;
    }

    set spooler(F) $F;

    return "";
}

proc ::spooler::disconnect {} {

    variable spooler;

    if {[info exists spooler(F)] == 0} {
	return "";
    }

    set status [catch {
	close $spooler(F);
    } errmsg];

    unset spooler(F);

    if {$status != 0} {
	return $errmsg;
    }

    return "";
}

proc ::spooler::send_output {pdata} {

    variable spooler;

    set status [catch {
	puts $spooler(F) $pdata;
	flush $spooler(F);
    } errmsg];

    if {$status != 0} {
	::spooler::disconnect;
	::spooler::connect;
	return $errmsg;
    }

    return "";
}
