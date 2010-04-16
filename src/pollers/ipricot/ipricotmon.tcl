#!%TCLSH%
#
# $Id$
#
# Packets, bytes
#
# IF-MIB::ifInNUcastPkts.3 = Counter32: 947389833
# IF-MIB::ifInOctets.3 = Counter32: 2147613181
#
# vber, sn (Eb/No), Digital Level percentage, demodulator lock, uncorrectables
#
# SNMPv2-SMI::enterprises.6697.1.1.1.1.17.0 = STRING: "0.0E-08"
# SNMPv2-SMI::enterprises.6697.1.1.1.1.18.0 = INTEGER: 83
# SNMPv2-SMI::enterprises.6697.1.1.1.1.19.0 = INTEGER: 64
# SNMPv2-SMI::enterprises.6697.1.1.1.1.21.0 = INTEGER: 1
# SNMPv2-SMI::enterprises.6697.1.1.1.1.22.0 = INTEGER: 15936
#
# inside temperature
#
# SNMPv2-SMI::enterprises.6697.1.1.1.2.1.0 = INTEGER: 3140
#
# For reference, this is the command we will use
# snmpwalk -v1 -c public ipricot OID
#
# The output is in the order:
#
# unix_seconds, demodulator_lock, Eb/No (sn), vber, uncorrectables,
# digital_signal_level, packets, bytes, temp

package require cmdline;
package require fileutil;

set usage {ipricotmon [-b] [-d <device_name>] [-l <logfile>] [-n <count>]};
set optlist {b {d.arg "ipricot"} {l.arg ""} {n.arg ""}};
array set option [::cmdline::getoptions argv $optlist $usage];

proc ipricot_warnx {s} {

    global option argv0;

    set progname [file tail $argv0];

    if {$option(b) == 0} {
	puts stderr $s;
    } else {
	logger -t $progname $s;
    }
}

proc ipricot_errx {s} {

    ipricot_warnx $s;
    exit 1;
}

proc ipricot_output {data} {

    global option;

    if {$option(l) eq ""} {
	puts stdout $data;
    } else {
	append data "\n";
	::fileutil::appendToFile $option(l) $data;
    }
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

#
# main
#
set count 0;
while {1} {
    incr count;
    if {($option(n) ne "") && ($count > $option(n))} {
	break;
    }

    set status [catch {
	set iprdata [ipricot_get_data];
	ipricot_output [join $iprdata " "];
    } errmsg];

    if {$status != 0} {
	ipricot_errx $errmsg;
    }
}
