#!%TCLSH%
#
# $Id$
#
package require cmdline;
package require fileutil;

set usage {sr1mon [-b] [-l <logfile>] [-n <count>] [-p <period>] [device]};
set optlist {b {l.arg ""} {n.arg ""} {p.arg "10"}};

namespace eval sr1 {

    variable sr1;

    set sr1(device) "sr1";
    set sr1(snmpwalk_opts) {-v 1 -c public -Oq};
    set sr1(data.last) [list];
    set sr1(data.now) [list];
    set sr1(output) [list];
    set sr1(oidlist) \
	[list frequency1 iso.3.6.1.4.1.27928.101.1.1.1.1.1.0 \
	     symbol_rate1 iso.3.6.1.4.1.27928.101.1.1.1.2.2.0 \
	     tuner_status1 iso.3.6.1.4.1.27928.101.1.1.4.1.0 \
	     demodulator_status1 iso.3.6.1.4.1.27928.101.1.1.4.11.0 \
	     transport_status1 iso.3.6.1.4.1.27928.101.1.1.4.13.0 \
	     frequency_offset1 iso.3.6.1.4.1.27928.101.1.1.4.2.0 \
	     power_level1 iso.3.6.1.4.1.27928.101.1.1.4.3.0 \
	     esno1 iso.3.6.1.4.1.27928.101.1.1.4.4.0 \
	     ber1 iso.3.6.1.4.1.27928.101.1.1.4.5.0 \
	     crc_errors1 iso.3.6.1.4.1.27928.101.1.1.4.12.0 \
	     bad_frame_count1 iso.3.6.1.4.1.27928.101.1.1.4.15.0 \
	     bad_packet_count1 iso.3.6.1.4.1.27928.101.1.1.4.16.0 \
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
}

proc sr1::warnx {s} {

    global option argv0;

    set progname [file tail $argv0];

    if {$option(b) == 0} {
	puts stderr $s;
    } else {
	exec logger -t $progname $s;
    }
}

proc sr1::errx {s} {

    warnx $s;

    exit 1;
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
	lappend r $key [lindex $output end];
    }

    set sr1(data.now) $r;
}

proc sr1::snmpwalk {} {

    variable sr1;

    set r [list];
    sr1::snmpwalk1;

    set counters {^(counter|crc_errors|bad_frame_count|bad_packet_count)};

    foreach {k1 v1} $sr1(data.last) {k1 v2} $sr1(data.now) {
	set v $v2;
	if {([regexp $counters $k1]) && ($v2 > $v1)} {
	    set v [expr $v2 - $v1];
	}
	lappend r $k1 $v;
    }
    set sr1(data.last) $sr1(data.now);
    set sr1(output) $r;
}

proc sr1::snmpprint {} {

    variable sr1;

    foreach {k v} $sr1(output) {
	puts "${k} = ${v}";
    }
}

proc sr1::snmplog {logfile} {

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

# puts "Initializing ...";

set count 0;
while {1} {
    incr count;
    if {($option(n) ne "") && ($count > $option(n))} {
	break;
    }
    after [expr $option(p) * 1000];

    set status [catch {
	::sr1::snmpwalk;
	::sr1::snmplog $option(l);
    } errmsg];

    if {$status != 0} {
	sr1::errx $errmsg;
    }
}
