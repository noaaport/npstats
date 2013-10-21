#!/usr/bin/tclsh

proc sr1_snmpwalk {device snmpwalk_opts oidlist} {

    set r [list];

    foreach {key oid} $oidlist {
	set output [eval exec snmpwalk [concat $snmpwalk_opts $device $oid]];
	lappend r $key [lindex $output end];
    }

    return $r;
}


set host "ppg.uprrp.edu";
set options {-v 1 -c public -Oq};

    set varlist \
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

#
# puts [join [sr1_snmpwalk $host $options $varlist] " "];
#
foreach {k v} [sr1_snmpwalk $host $options $varlist] {
    puts "${k} = ${v}";
}
