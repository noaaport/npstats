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

package provide npstats::db 1.0;

namespace eval npstats::db {

    variable db;

    array set db {};
}

proc ::npstats::db::init {cmd options} {

    variable db;

    set usage {::npstats::db::init <cmd> <options>};

    # These are the only internal variables
    set db(cmd) [concat $cmd $options];
    set db(output) "";
    ## unset db(F);
}

proc ::npstats::db::connect {} {

    variable db;

    set db(F) [open "|$db(cmd)" "r+"];
}

proc ::npstats::db::disconnect {} {

    variable db;

    _verify_connection;

    close $db(F);
    unset db(F);
}

proc ::npstats::db::send {sqlscript} {

    variable db;

    _verify_connection;

    puts $db(F) $sqlscript;
    flush $db(F);
}

proc ::npstats::db::send_insert {table pnames pvalues} {

    variable db;

    _verify_connection;

    set script {
	insert into ${table}($pnames) values($pvalues);
    }

    puts $db(F) [subst -nocommands -nobackslashes $script];
    flush $db(F);
}

#
# Utility
#
proc ::npstats::db::get_output {} {

    variable db;

    _verify_connection;

    return [read $db(F)];
}

proc ::npstats::db::read_output_xml {} {
#
# In mysql, the appropriate command line options to use this fuction are
# "-B -n -X"
#
    variable db;

    _verify_connection;

    set done 0;
    set r [list];
    while {$done == 0} {
	set n [gets $db(F) line]; 
	if {$n == -1} {
	    set done 1;
	} elseif {$n == 0} {
	    continue;
	} else {
	    lappend r $line;
	    if {[regexp {</resultset>} $line]} {
		set done 1;
	    }
	}
    }
    return [join $r "\n"];
}

#
# private
#
proc ::npstats::db::_verify_connection {} {

    variable db;

    if {[info exists db(F)]} {
	return 1;
    }

    return -code error "db not opened.";
}
