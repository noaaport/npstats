#!%TCLSH%
#
# $Id$
#
# This is the "system scheduler", called by the npstatsd daemon.

## The common defaults
source "/usr/local/etc/npstats/collectors.conf";

# The errx library, with syslog enabled
package require npstats::syslog;

## The scheduler library
package require npstats::mscheduler;

#
# Default schedule
#
set scheduler(rc) "scheduler.conf";

# Location (use the last one found)
set scheduler(confdirs) [concat $common(confdir) $common(localconfdirs)];

proc schedule {code args} {

    global g;
    
    set status [catch {
	set match [::npstats::mscheduler::match_timespec $code];
    } errmsg];

    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
    } elseif {$match == 1} {
	lappend g(cmdlist) $args;
    }
}

proc source_rcfile {rcfile} {

    source $rcfile;
}

proc exec_cmd {cmd} {
    # 
    # Each memmber of the cmdlist is a list or the program and options.
    #

    set status [catch {
	eval exec $cmd;
    } errmsg];

    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
    }
}

#
# main
#

set rcfile "";
foreach _d $scheduler(confdirs) {
    set _f [file join ${_d} $scheduler(rc)]; 
    if {[file exists ${_f}]} {
	set rcfile ${_f};
    }
}
if {$rcfile eq ""} {
    ::npstats::syslog::warn "$scheduler(rc) not found.";
    return 1;
}

set g(cmdlist) [list];
source_rcfile $rcfile;

foreach cmd $g(cmdlist) {
    exec_cmd $cmd;
}
