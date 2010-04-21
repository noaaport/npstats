#!%TCLSH%
#
# $Id$
#
# usage: npstatsctl <start|stop>
#
# This script calls the installed init script
#
set usage {Usage: npstats <start|stop>};

## The common defaults
source "/usr/local/etc/npstats/collectors.conf";

## The errx library (log to stderr)
package require npstats::errx;
# ::npstats::syslog::usesyslog;

# configuration
set npstatsctl(rcfpath) "%RCFPATH%";

#
# init
#

if {$argc != 1} {
    ::npstats::syslog::err $usage;
}
set stage [lindex $argv 0];

#
# main
#

set status [catch {
    exec $npstatsctl(rcfpath) $stage;
} errmsg];

if {$status != 0} {
    ::npstats::syslog::err $errmsg;
}

return $status;
