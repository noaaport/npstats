#
# $Id$
#
# Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package provide poll 1.0;

package require cmdline;

namespace eval poll {

    variable poll;

    array set poll {};
}

proc ::poll::connect {device poller args} {

    variable poll;

    set usage {::poll::connect <device> <poller> [<poller_options>]}
    
    set F [open "|$poller $args" r+];

    # These are the only internal variables
    set poll($device,F) $F;
}

proc ::poll::disconnect {device} {

    variable poll;

    _verify_connection $device;
    close $poll($device,F);

    unset poll($device,F);
}

proc ::poll::send {device cmd} {

    variable poll;

    _verify_connection $device;

    set status [catch {
	puts $poll($device,F) $cmd;
	flush $poll($device,F);
    } errmsg];

    if {$status != 0} {
	return -code error $errmsg;
    }
}

proc ::poll::send-poll {device} {

    ::poll::send $device "POLL";
}

proc ::poll::send-report {device} {

    ::poll::send $device "REPORT";
}

proc ::poll::pop-line {device line_varname} {
#
# Returns the same code as "gets <fh> line".
#
    upvar $line_varname line; 
    variable poll;
    
    _verify_connection $device;
    set r [gets $poll($device,F) line];

    return $r;
}

proc ::poll::dfconfigure {device args} {
    
    variable poll;

    _verify_connection $device;
    eval fconfigure $poll($device,F) $args;
}

#
# Utility
#
proc ::poll::set_var {device var val} {
    
    variable poll;

    _verify_connection $device;
    set poll($device,user,$var) $val;
}

proc ::poll::get_var {device var} {
    
    variable poll;

    _verify_connection $device;

    if {[info exists poll($device,user.$var)]} {
	return $poll($device,user,$var);
    }

    return -code error "$var not defined";
}

#
# low level
#
proc ::poll::get_filehandle {device} {

    variable poll;

    _verify_connection $device;
    
    return $poll($device,F);
}

#
# private
#
proc ::poll::_verify_connection {device} {

    variable poll;

    if {[info exists poll($device,F)]} {
	return 1;
    }

    return -code error "There is no connection to $device.";
}
