#
# $Id$
#
package provide npstats::errx 1.0;
package require fileutil;

namespace eval npstats::errx {}
namespace eval npstats::filelog {}
namespace eval npstats::syslog {

    variable syslog;

    set syslog(usesyslog) 0;
}

proc npstats::errx::warn s {

    global argv0;

    set name [file tail $argv0];
    puts stderr "$name: $s";
}

proc npstats::errx::errc s {

    warn $s;
}

proc npstats::errx::err s {

    warn $s;
    exit 1;
}

#
# syslog
#
proc npstats::syslog::usesyslog {{flag 1}} {

    variable syslog;

    set syslog(usesyslog) $flag;
}

proc npstats::syslog::_log_msg s {

    global argv0;

    set name [file tail $argv0];
    exec logger -t $name -- $s;
}

proc npstats::syslog::msg s {

    variable syslog;

    if {$syslog(usesyslog) == 1} {
	_log_msg $s;
    } else {
	puts $s;
    }
}

proc npstats::syslog::warn s {

    variable syslog;

    if {$syslog(usesyslog) == 1} {
	_log_msg "Warning: $s";
    } else {
	::npstats::errx::warn $s;
    }
}

proc npstats::syslog::errc s {

    variable syslog;

    if {$syslog(usesyslog) == 1} {
	_log_msg "Error: $s";
    } else {
	::npstats::errx::errc $s;
    }
}

proc npstats::syslog::err s {

    variable syslog;

    if {$syslog(usesyslog) == 1} {
	_log_msg "Error: $s";
	exit 1;
    } else {
	::npstats::errx::err $s;
    }
}

#
# Log to a file
#
proc npstats::filelog::msg {logfile s} {

    global argv0;

    set name [file tail $argv0];
    append msg $name ": " [clock format [clock seconds]] ": " $s "\n"; 

    set status [catch {
	::fileutil::appendToFile $logfile $msg;
    } errmsg];

    if {$status != 0} {
	puts stderr $errmsg;
    }
}
