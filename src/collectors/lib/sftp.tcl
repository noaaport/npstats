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

package provide npstats::sftp 1.0;

namespace eval npstats::sftp {

    variable sftp;

    array set sftp {};
}

proc ::npstats::sftp::init {user host} {

    variable sftp;

    set usage {::npstats::sftp::init <user> <host>};

    # These are the only internal variables
    set sftp(user_host) "${user}@${host}";
    set sftp(output) "";
}

proc ::npstats::sftp::send {cmd file} {

    set script {
	$cmd $file
	quit
    };

    set r [::npstats::sftp::_batch $script];

    return $r;
}

proc ::npstats::sftp::put {file} {

    set r [::npstats::sftp::send "put" $file];

    return $r;
}

proc ::npstats::sftp::rm {file} {

    set r [::npstats::sftp::send "rm" $file];

    return $r;
}

#
# Utility
#
proc ::npstats::sftp::get_output {} {

    variable sftp;

    return $sftp(output);
}

#
# private
#
proc ::npstats::sftp::_verify_init {} {

    variable sftp;

    if {[info exists sftp(user_host)]} {
	return 1;
    }

    return -code error "No user@host defined.";
}

proc ::npstats::sftp::_batch {script} {

    variable sftp;

    set sftp_options "-b -";

    ::npstats::sftp::_verify_init;

    set f [open "|sftp $sftp_options $sftp(user_host)" r+];

    set status [catch {
	puts $f $script;
	flush $f;
	set output [read $f];
    } errmsg];

    set status_close [catch {
	close $f;
    } errmsg_close];

    if {$status_close != 0} {
	set status $status_close;
	if {$errmsg eq ""} {
	    set errmsg $errmsg_close;
	} else {
	    append errmsg "\n" $errmsg_close;
	}
    }

    if {$status != 0} {
	return -code error $errmsg;
    }

    set sftp(output) $output;

    return 0;
}
