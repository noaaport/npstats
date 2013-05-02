#!#!%TCLSH%
#
# $Id$
#
package require cmdline;
package require fileutil;

# -D => debug mode; do not use syslog
# -v => will print the initial "OK:..." message during initialization

set usage {sr1mon [-D] [-v] [device]};
set optlist {D v};

namespace eval sr1 {

    variable sr1;

    set sr1(device) "sr1";
    set sr1(snmpwalk_opts) {-v 1 -c public -Oq};
    set sr1(data.last) [list];
    set sr1(data.now) [list];
    set sr1(output) [list];
    set sr1(oidlist) \
	[list tuner_status1 iso.3.6.1.4.1.27928.101.1.1.4.1.0 \
	     demodulator_status1 iso.3.6.1.4.1.27928.101.1.1.4.11.0 \
	     power_level1 iso.3.6.1.4.1.27928.101.1.1.4.3.0 \
	     esno1 iso.3.6.1.4.1.27928.101.1.1.4.4.0 \
	     ber1 iso.3.6.1.4.1.27928.101.1.1.4.5.0 \
	     crc_errors1 iso.3.6.1.4.1.27928.101.1.1.4.12.0 \
	     counter_crc_errors11 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.6.1 \
	     counter_crc_errors12 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.6.2 \
	     counter_crc_errors13 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.6.3 \
	     counter_crc_errors14 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.6.4 \
	     counter_crc_errors31 iso.3.6.1.4.1.27928.101.1.2.1.4.3.1.6.1 \
	     counter_pid_passed11 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.4.1 \
	     counter_pid_passed12 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.4.2 \
	     counter_pid_passed13 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.4.3 \
	     counter_pid_passed14 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.4.4 \
	     counter_pid_passed31 iso.3.6.1.4.1.27928.101.1.2.1.4.3.1.4.1 \
	     counter_mpe_sections11 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.5.1 \
	     counter_mpe_sections12 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.5.2 \
	     counter_mpe_sections13 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.5.3 \
	     counter_mpe_sections14 iso.3.6.1.4.1.27928.101.1.1.1.4.3.1.5.4 \
	     counter_mpe_sections31 iso.3.6.1.4.1.27928.101.1.2.1.4.3.1.5.1];

    # list variables in the order the will be output
    set sr1(poll.varlist) [list \
			      unixseconds \
			      tuner_status1 \
			      demodulator_status1 \
			      power_level1_min power_level1_max  \
			      esno1_min esno1_max \
			      ber1_min ber1_max \
			      crc_errors1 \
			      counter_crc_errors11 \
			      counter_crc_errors12 \
			      counter_crc_errors13 \
			      counter_crc_errors14 \
			      counter_crc_errors31 \
			      counter_pid_passed11 \
			      counter_pid_passed12 \
			      counter_pid_passed13 \
			      counter_pid_passed14 \
			      counter_pid_passed31 \
			      counter_mpe_sections11 \
			      counter_mpe_sections12 \
			      counter_mpe_sections13 \
			      counter_mpe_sections14 \
			      counter_mpe_sections31];

    # Initialize state variables
    foreach var $sr1(poll.varlist) {
	set sr1(poll.${var}) 0;
    }
    set sr1(poll.power_level1_min) -10;
    set sr1(poll.power_level1_max) -1000;
    set sr1(poll.esno1_min) 1000;
    set sr1(poll.esno1_max) 0;
    set sr1(poll.ber1_min) 1000000;
    set sr1(poll.ber1_max) 0;

    # Internal variables
    set sr1(_device_status) 0;
}

proc sr1::warnx {s} {

    global option argv0;

    set progname [file tail $argv0];

    if {$option(D) == 1} {
	puts stderr $s;
    } else {
	exec logger -t $progname $s;
    }
}

proc sr1::errx {s} {

    warnx $s;

    exit 1;
}

proc sr1::oidlist {} {
#
# Return the list of variable names in the oidlist
#
    variable sr1;

    set r [list];
    foreach {k v} $sr1(oidlist) {
	lappend r $k;
    }

    return $r;
}

proc sr1::init {device} {

    variable sr1;

    if {$device ne ""} {
	set sr1(device) $device;
    }

    snmpwalk1;
    set sr1(data.last) $sr1(data.now);
}

proc sr1::snmpwalk1 {} {

    variable sr1;

    set device $sr1(device);
    set oidlist $sr1(oidlist);
    set snmpwalk_opts $sr1(snmpwalk_opts);

    set r [list "unixseconds" [clock seconds]];
    foreach {key oid} $oidlist {
	set output [eval exec snmpwalk [concat $snmpwalk_opts $device $oid]];
	set val [lindex $output end];
	lappend r $key $val;
    }

    set sr1(data.now) $r;
}

proc sr1::snmpwalk {} {

    variable sr1;

    set r [list];
    sr1::snmpwalk1;
    if {[llength $sr1(data.last)]} {
	foreach {k1 v1} $sr1(data.last) {k1 v2} $sr1(data.now) {
	    set v $v2;
	    if {([regexp {^counter} $k1]) && ($v2 > $v1)} {
		set v [expr $v2 - $v1];
	    }
	    lappend r $k1 $v;
	}
    }
    set sr1(data.last) $sr1(data.now);
    set sr1(output) $r;
}

proc sr1::update {} {
#
# Update the status variables after reading snmpwalk
#
    variable sr1;

    # Read from the device
    snmpwalk;

    # First update the poll variables that are directly read
    foreach var $sr1(poll.varlist) {
	set index [lsearch $sr1(output) $var];
	if {$index != -1} {
	    incr index;
	    set sr1(poll.${var}) [lindex $sr1(output) $index];
	}
    }

    # Update the min/max
    foreach var [list power_level1 esno1 ber1] {
	set index [lsearch $sr1(output) $var];
	incr index;

	set current_val [lindex $sr1(output) $index];

	if {$current_val > $sr1(poll.${var}_max)} {
	    set sr1(poll.${var}_max) $current_val;
	}

	if {$current_val < $sr1(poll.${var}_min)} {
	    set sr1(poll.${var}_min) $current_val;
	}
    }
}

proc sr1::print {} {

    variable sr1;

    foreach {k v} $sr1(output) {
	puts "${k} = ${v}";
    }
}

proc sr1::log {logfile} {

    variable sr1;

    set r [list];
    foreach {k v} $sr1(output) {
	lappend r $v;
    }

    set data [join $r " "];
    if {$logfile eq ""} {
	puts stdout $data;
    } else {
	append data "\n";
	::fileutil::appendToFile $logfile $data;
    }
}

proc sr1::output {} {

    variable sr1;

    if {$sr1(_device_status) != 0} {
	puts stdout "ERROR:Cannot get device status";
	return;
    }

    set r [list];
    foreach key $sr1(poll.varlist) {
	set val $sr1(poll.${key});
	if {[regexp {(power_level|esno)} $key]} {
	    set val [format "%.1f" [expr $val *0.1]];
	} elseif {[regexp {(ber)} $key]} {
	    #set val [format "%.1e" [expr $val * 1.0e-7]];
	    set val "${val}e-7";
	}

	lappend r $val;
    }

    puts -nonewline stdout "OK:";
    puts stdout [join $r ","];

    # Reinitialize the variables
    set sr1(poll.power_level1_min) -10;
    set sr1(poll.power_level1_max) -1000;
    set sr1(poll.esno1_min) 1000;
    set sr1(poll.esno1_max) 0;
    set sr1(poll.ber1_min) 1000000;
    set sr1(poll.ber1_max) 0;
}

proc sr1::set_device_status {status} {

    variable sr1;

    set sr1(_device_status) $status;
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];

set device "";
if {$argc == 1} {
    set device [lindex $argv 0];
} elseif {$argc > 1} {
    ::sr1::errx $usage;
}

set status [catch {
    ::sr1::init $device;
} errmsg];

if {$status != 0} {
    ::sr1::errx $errmsg;
}

if {$option(v)} {
    puts stdout "OK:Device poller ready";
}

while {[gets stdin input_buffer] > 0} {

    set input_buffer [string trim $input_buffer];

    set status [catch {
	# This calls snmpwalk and then updates the state variables
	::sr1::update;
    } errmsg];

    if {$status != 0} {
	::sr1::set_device_status 1;
	::sr1::warnx $errmsg;
    } else {
	::sr1::set_device_status 0;
    }

    if {$input_buffer eq "POLL"} {
	continue;
    } elseif {$input_buffer ne "REPORT"} {
	::sr1::errx "Unrecognized command: $input_buffer";
	continue;
    }

    ::sr1::output;
}
