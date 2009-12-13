#!%TCLSH%
#
# $Id$
#

## The common defaults
set defaultsfile "/usr/local/etc/npstats/collectors.conf";
if {[file exists $defaultsfile] == 0} {
    puts "$argv0: $defaultsfile not found.";
    return 1;
}
source $defaultsfile;
unset defaultsfile;

# Packages from tcllib
package require fileutil;
package require textutil;
package require mime;
package require smtp;

# Local packages - 
## The errx library, with syslog enabled
package require errx;
::syslog::usesyslog;
## devices
package require devices;

# Initialization
set monitor(conf) [file join $common(confdir) "monitor.conf"];
set monitor(localconfdirs) $common(localconfdirs);
set monitor(rc) [file join $common(confdir) "monitor.rc"];
set monitor(rcdir)  [file join $common(rcdir) "monitor"];
#
set monitor(verbose) 0;
#
set monitor(alert,smtp,originator) "npstats@localhost";
set monitor(alert,smtp,servers)    "localhost";

# Variables
set monitor(rcfiles) [list];
set monitor(devicesconf)  $common(devicesconf);
set monitor(devicesdef)  $common(devicesdef);
set monitor(dev,alertlist) [list];
set monitor(condition) [list];
set monitor(alert) [list];
set monitor(f_quit) 0;

#
# Read the optional configuration file.
#
if {[file exists $monitor(conf)] == 1} {
    source $monitor(conf);
}

# The main rc file is required. The rc file is read at the end
# after the rcfile list is constructed (which uses a function defined below).
if {[file exists $monitor(rc)] == 0} {
    ::syslog::err "monitor disabled: $monitor(rc) not found.";
    return 1;
}

#
# The devices configuration and definitions file are required
#
foreach _f [list $monitor(devicesconf) $monitor(devicesdef)] {
    if {[file exists ${_f}] == 0} {
	::syslog::err "${_f} is required.";
	return 1;
    }
    source ${_f};
}

# Copy all the devices(..) entries for easy reference in the functions
foreach key [array names devices *] {
    set monitor(dev,$key) $devices($key);
}

#
# Functions
#
proc monitor_uwildmat {uwildregex str} {
#
# This function is a copy of filterlib_uwildmat in the nbsp filter lib.
# Behaves similarly to inn's uwildmat(), but uses re's rather than
# glob style patters. Using only a pair of expressions, the second
# one of which is negated, is equivalent to use an accept and then reject
# pattern as described in nbspd.conf. This mechanism generalizes that.
#
    if {$uwildregex eq ""} {
        return 0;
    }

    set pattlist [split $uwildregex ","];
    set status 0;

    foreach p $pattlist {
        set v 1;
        set reg [string trim $p];
        if {[string range $reg 0 0] eq "!"} {
            set v 0;
            set reg [string range $reg 1 end];
        }
        if {[regexp -- $reg $str]} {
            set status $v;
        }
    }

    return $status;
}

proc monitor_get_rcfiles {rcfname confdirs rcdir} {

# Build the list of rules rc files. First
# the one in the site directory or default directory if the
# site version does not exist (i.e., look in confdirs and retain only the
# last one found) then any rc file in the $rcdir directory.

    set _rcfiles [list];
    set _rc $rcfname;
    set _localrc "";
    foreach _d $confdirs {
	if {[file exists ${_d}/${_rc}]} {
	    set _localrc ${_d}/${_rc};
	}
    }
    if {${_localrc} ne ""} {
        lappend _rcfiles ${_localrc};
    }
    unset _d;
    unset _rc;
    unset _localrc;

    if {[file isdirectory $rcdir]} {
	set _rcfiles [concat ${_rcfiles} [glob -nocomplain \
		-directory $rcdir *.rc]];
    }

    return $_rcfiles;
}

#
# Functions to manage the alerts
#
proc monitor_signal_raise {deviceid level rclist} {

    global monitor;

    set count 1;
    if {[info exists monitor(dev,status,$deviceid)]} {
	set prev_level [lindex $monitor(dev,status,$deviceid) 0];
	if {$level == $prev_level} {
	    set count [lindex $monitor(dev,status,$deviceid) 1];
	    incr count;
	}
    }

    set monitor(dev,status,$deviceid) [list $level $count];
    monitor_signal_alert $deviceid $rclist;
}

proc monitor_signal_alert {deviceid rclist} {

    global monitor;

    set level [lindex $monitor(dev,status,$deviceid) 0];
    set count [lindex $monitor(dev,status,$deviceid) 1];

    foreach alert $monitor(dev,alertlist) {
	set deviceid_re [lindex $alert 0];
	set level_re [lindex $alert 1];
	set skip [lindex $alert 2];
	if {[monitor_uwildmat $deviceid_re $deviceid] && \
		[monitor_uwildmat $level_re $level] && \
		(($count == 1) || ([_skip_test $count $skip] == 0))} {
	    set methods [lindex $alert 3];
	    #
	    # methods is a tcl list of <transport>://<recipients>
	    #
	    foreach m $methods {
		set mparts [::textutil::splitx $m {://}];
		set transport [lindex $mparts 0];
		set recipients [lindex $mparts 1];
		if {$transport eq "proc"} {
		    # <recipients> is the proc name
		    $recipients $deviceid $level $count $rclist;
		} elseif {$transport eq "smtp"} {
		    monitor_smtp_proc \
			$recipients $deviceid $level $count $rclist;
		}
	    }
	}
    }
}

proc monitor_smtp_proc {recipients deviceid level count rclist} {

    append subject ${deviceid} ":" ${level} ":" ${count};
    append body $subject "\n\n";
    foreach {key val} $rclist {
	append body $key " = " $val "\n";
    }
    monitor_smtp_send $recipients $subject $body;
}

proc _skip_test {count skip} {

    if {($skip >= 0) && ([expr $count % ($skip + 1)] == 0)} {
	return 0;
    }

    return 1;
}

proc monitor_smtp_send {recipients subject body} {
#
# <recipients> is a comma-separated string of email addresses.
#
    global monitor;

    set token [mime::initialize -canonical text/plain -string $body];

    set result [smtp::sendmessage $token \
                    -originator $monitor(alert,smtp,originator) \
                    -servers $monitor(alert,smtp,servers) \
                    -recipients $recipients \
                    -header [list Subject $subject]];

    mime::finalize $token;

    if {[llength $result] == 0} {
        set status 0;
    } else {
        set status 1;
        foreach r $result {
	    ::syslog::warn [join $r ":"];
        }
    }

    return $status;
}

proc main {argv} {

    global monitor;

    fileevent stdin readable [list monitor_fileevent_handler_stdin];
    vwait monitor(f_quit);
}

proc monitor_fileevent_handler_stdin {} {

    global monitor
    global errorInfo;

    set r [gets stdin pdata];

    if {$r == -1} {
	set monitor(f_quit) 1;
	return;
    } elseif {$pdata eq ""} {
	::syslog::msg "Received request to quit.";
	set monitor(f_quit) 1;
	return;
    }

    set status [catch {monitor_process $pdata} errmsg];
    if {$status == 1} {
	::syslog::warn "Error processing $pdata";
	::syslog::warn $errmsg;
	::syslog::warn $errorInfo;
    }
}

proc monitor_process {pdata} {
#
# <pdata> is a string of the form
#
# <deviceid>|<devivetype>|<devicetid>|<output>
#
# where <output> is the csv separated string of values as emitted by the
# pollers.
#
# This function assigns the <deviceid>, <devicetype> and the values to
# the rc() variables.
#
    global monitor;

    # Initialization
    array set rc [list];
    set rc(deviceid) "";
    set rc(devicetype) "";
    set rc(devicetid) "";
    set rc(devicedata) "";

    set pdataparts [::devices::data_unpack $pdata];
    set rc(deviceid) [::devices::data_unpack_deviceid $pdataparts];
    set rc(devicetype) [::devices::data_unpack_devicetype $pdataparts];
    set rc(devicetid) [::devices::data_unpack_devicetid $pdataparts];
    set rc(devicedata) [::devices::data_unpack_output $pdataparts];

    set datalist [split $rc(devicedata) ","];
    set i 0;
    foreach p $monitor(dev,param,$rc(devicetype)) {
	set rc($p) [lindex $datalist $i];
	incr i;
    }

    # This list is passed to the alert function
    set rclist [array get rc];

    set rc_status 1;
    # Evaluate the condition/alert pairs, from all sets.
    set i 0;		# counts the sets
    foreach clist $monitor(condition) {
        set alist [lindex $monitor(alert) $i];
	set j 0;	# counts the rules with each set
	foreach c $clist {
	    set a [lindex $alist $j];
            if {[expr $c]} {
                monitor_signal_raise $rc(deviceid) $a $rclist;
            }
	    incr j;
        }
        incr i;
    }
}
    
#
# main
#

# Build the list of rc files
set monitor(rcfiles) [monitor_get_rcfiles [file tail $monitor(rc)] \
					       $monitor(localconfdirs) \
					       $monitor(rcdir)];
source $monitor(rc);
main $argv;
