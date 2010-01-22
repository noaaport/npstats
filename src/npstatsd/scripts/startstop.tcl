#!%TCLSH%
#
# $Id$
#
# Usage: startstop <start|stop>
#
set usage {Usage: startstop <start|stop>};

## The common defaults
set defaultsfile "/usr/local/etc/npstats/collectors.conf";
if {[file exists $defaultsfile] == 0} {
    puts "$argv0 disabled: $defaultsfile not found.";
    return 1;
}
source $defaultsfile;

# Local packages - 
## The errx library, with syslog enabled
package require npstats::errx;
::npstats::syslog::usesyslog;

#
# Default schedule
#
set startstop(rc) "startstop.rc";

# Location (use the last one found)
set startstop(confdirs)  [linsert $common(localconfdirs) 0 $common(confdir)];

#
# main
#

set startstop(stage) "";
if {$argc == 1} {
    set startstop(stage) [lindex $argv 0];
}
if {($startstop(stage) ne "start") && ($startstop(stage) ne "stop")} {
    ::npstats::syslog::err $usage;
    return;
}

set conffile "";
foreach _d $startstop(confdirs) {
    set _f [file join ${_d} $startstop(rc)]; 
    if {[file exists ${_f}]} {
	set conffile ${_f};
    }
}
if {$conffile == ""} {
    ::npstats::syslog::err "$startstop(rc) not found.";
    return;
}

set start [list];
set stop [list];
source $conffile;
eval set script_list \$$startstop(stage);

foreach script $script_list {

    # The eval causes the $program string to be split on blanks
    # in case there are options, and any variables to be substituted
    # by their value.

    set status [catch {
        eval $script;
    } errmsg];

    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
    }     
}
