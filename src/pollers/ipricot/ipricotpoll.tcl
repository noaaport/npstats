#!%TCLSH%
#
# $Id$
#
# See "ipricotmon.tcl" for the definitions of the ipricot mib variables.
#
# The output here is in the order:
#
# unix_seconds,
# demodulator_lock,
# sn_min, sn_max,
# vber min, vber max,
# uncorrectables_period,
# digital_signal_level_min, digital_signal_level_max,
# packets_period, bytes_period, temp
#
# Options:
#
# -d => device name (or ip)
# -D => debug mode; do not use syslog
# -v => will print the initial "OK:..." message during initialization
#
package require cmdline;
package require fileutil;

set usage {ipricotmon [-d <device_name or ip>] [-D] [-v]};
set optlist {{d.arg "ipricot"} D v};
array set option [::cmdline::getoptions argv $optlist $usage];

# state (global) variables
set ipricotpoll(unix_seconds) 0;
set ipricotpoll(demodulator_lock) 0;
set ipricotpoll(sn_min) 100;
set ipricotpoll(sn_max) 0;
set ipricotpoll(vber_min) 1.0;
set ipricotpoll(vber_max) 0.0e-08;
set ipricotpoll(uncorrectables) 0;
set ipricotpoll(uncorrectables_period) 0;
set ipricotpoll(digital_signal_level_min) 100;
set ipricotpoll(digital_signal_level_max) 0;
set ipricotpoll(packets) 0;
set ipricotpoll(packets_period) 0;
set ipricotpoll(bytes) 0;
set ipricotpoll(bytes_period) 0;
set ipricotpoll(temp) 0;

set ipricotpoll(_key_list) [list unix_seconds \
				demodulator_lock \
				sn_min sn_max \
				vber_min vber_max \
				uncorrectables_period \
				digital_signal_level_min \
				digital_signal_level_max \
				packets_period bytes_period temp];

set ipricotpoll(_device_status) 0;

proc ipricot_warnx {s} {

    global option argv0;

    set progname [file tail $argv0];

    if {$option(D) == 1} {
	puts stderr $s;
    } else {
	logger -t $progname $s;
    }
}

proc ipricot_errx {s} {

    ipricot_warnx $s;
    exit 1;
}

proc ipricot_get_data {} {
    #
    # This function outputs the following data:
    #
    # unix_seconds, demodulator_lock, Eb/No (sn), vber, uncorrectables,
    # digital_signal_level, packets, bytes, temp

    global option;

    set oid(nucast_packets) "IF-MIB::ifInNUcastPkts.3";
    set oid(bytes) "IF-MIB::ifInOctets.3"
    set oid(digital_signal_level) "SNMPv2-SMI::enterprises.6697.1.1.1.1.19.0";
    set oid(demodulator_lock) "SNMPv2-SMI::enterprises.6697.1.1.1.1.21.0";
    set oid(uncorrectables) "SNMPv2-SMI::enterprises.6697.1.1.1.1.22.0";
    #
    set oid(vber) "SNMPv2-SMI::enterprises.6697.1.1.1.1.17.0";
    set oid(sn)   "SNMPv2-SMI::enterprises.6697.1.1.1.1.18.0";
    set oid(temp) "SNMPv2-SMI::enterprises.6697.1.1.1.2.1.0";

    # Put them in the order we want the output
    set oid_list [list demodulator_lock \
		      sn \
		      vber \
		      uncorrectables \
		      digital_signal_level \
		      nucast_packets \
		      bytes \
		      temp];

    set now [clock seconds];
    set data [list $now];

    foreach key $oid_list {
	set output [split [string trim \
		   [exec snmpwalk -v1 -c public $option(d) $oid($key)]]];
	set val [lindex $output end];
	if {$key eq "sn"} {
	    set val [format "%.1f" [expr $val *0.1]];
	} elseif {$key eq "vber"} {
	    set val [string tolower [string trim $val \"]];
	} elseif {$key eq "temp"} {
	    set val [format "%.2f" [expr $val * (0.09/5.0) + 32.0]];
	}
	lappend data $val;
    }

    return [join $data " "];
}

proc ipricot_update_status {data} {

    global ipricotpoll;

    # First extract all the instance values
    set unix_seconds [lindex $data 0];
    set demodulator_lock [lindex $data 1];
    set sn [lindex $data 2];
    set vber [lindex $data 3]
    set uncorrectables [lindex $data 4];
    set digital_signal_level [lindex $data 5];
    set packets [lindex $data 6];
    set bytes [lindex $data 7];
    set temp [lindex $data 8];

    #
    # Update the static values
    #
    set ipricotpoll(unix_seconds) $unix_seconds;
    set ipricotpoll(demodulator_lock) $demodulator_lock;

    if {$sn < $ipricotpoll(sn_min)} {
	set ipricotpoll(sn_min) $sn;
    }
    if {$sn > $ipricotpoll(sn_max)} {
	set ipricotpoll(sn_max) $sn;
    }

    if {[expr $vber < $ipricotpoll(vber_min)]} {
	set ipricotpoll(vber_min) $vber;
    }
    if {[expr $vber > $ipricotpoll(vber_max)]} {
	set ipricotpoll(vber_max) $vber;
    }

    incr ipricotpoll(uncorrectables_period) \
	[expr $uncorrectables - $ipricotpoll(uncorrectables)];
    set ipricotpoll(uncorrectables) $uncorrectables;

    if {$digital_signal_level < $ipricotpoll(digital_signal_level_min)} {
	set ipricotpoll(digital_signal_level_min) $digital_signal_level;
    }
    if {$digital_signal_level > $ipricotpoll(digital_signal_level_max)} {
	set ipricotpoll(digital_signal_level_max) $digital_signal_level;
    }

    incr ipricotpoll(packets_period) \
	[expr $packets - $ipricotpoll(packets)];
    set ipricotpoll(packets) $packets;

    incr ipricotpoll(bytes_period) \
	[expr $bytes - $ipricotpoll(bytes)];
    set ipricotpoll(bytes) $bytes;
    
    set ipricotpoll(temp) $temp;
}

proc ipricot_output_status {} {

    global ipricotpoll;

    if {$ipricotpoll(_device_status) == 1} {
	puts stdout "ERROR:Cannot get device status";
	return;
    }

    # Write the report
    set output [list];
    foreach key $ipricotpoll(_key_list) {
	lappend output $ipricotpoll($key);
    }

    puts -nonewline stdout "OK:";
    puts stdout [join $output ","];

    set ipricotpoll(sn_min) 100;
    set ipricotpoll(sn_max) 0;
    set ipricotpoll(vber_min) 1.0;
    set ipricotpoll(vber_max) 0.0e-08;
    set ipricotpoll(uncorrectables_period) 0;
    set ipricotpoll(digital_signal_level_min) 100;
    set ipricotpoll(digital_signal_level_max) 0;
    set ipricotpoll(packets_period) 0;
    set ipricotpoll(bytes_period) 0;
}

proc ipricot_init_status {} {

    global ipricotpoll;

    # Since the variables reported are not these absolute counters
    # but their increment during a period, they must be initialized
    # to the correct value before the entering the main loop or
    # the first data record will be incorrect.

    set status [catch {
	set data [ipricot_get_data];
    } errmsg];

    if {$status != 0} {
	ipricot_errxx $errmsg;
    }

    set uncorrectables [lindex $data 4];
    set packets [lindex $data 6];
    set bytes [lindex $data 7];

    set ipricotpoll(uncorrectables) $uncorrectables;
    set ipricotpoll(packets) $packets;
    set ipricotpoll(bytes) $bytes;
}

#
# main
#
ipricot_init_status;

if {$option(v)} {
    puts stdout "OK:Device poller ready";
}

while {[gets stdin input_buffer] > 0} {

    set input_buffer [string trim $input_buffer];

    set status [catch {
	set iprdata [ipricot_get_data];
    } errmsg];

    if {$status != 0} {
	set ipricotpoll(_device_status) 1;
	ipricot_warnx $errmsg;
    } else {
	set ipricotpoll(_device_status) 0;
    }

    if {$ipricotpoll(_device_status) == 0} {
	ipricot_update_status $iprdata;
    }

    if {$input_buffer eq "POLL"} {
	continue;
    } elseif {$input_buffer ne "REPORT"} {
	ipricot_errx "Unrecognized command: $input_buffer";
	continue;
    }

    ipricot_output_status;
}
