#
# $Id$
#

#
#  Not longer used after switching to templates (Tue Oct 16 11:23:46 AST 2012)
#
## Direct_Url /npstats/status npstats/status;
#

#
# The (local) spooler and monitor packages
#
package require npstats::devices;	# the devices properties

proc npstats/status/display_device_list {} {

    global Config;

    if {[llength $Config(devicelist)] == 0} {
	return "No devices configured.";
    }

    set result "<h3>Configured devices</h3>\n";
    array set result_by_type {};
    foreach device $Config(devicelist) {
	array set option [::npstats::devices::get_options $device];
	if {([info exists option(displaystatus)] == 0) || \
		($option(displaystatus) == 0)} {
	    continue;
	}
	set deviceid [::npstats::devices::get_id $device];
	set devicetype [::npstats::devices::get_type $device];
	set template [::npstats::devices::get_tml $device];
	set q "deviceid=$deviceid&template=$template";
	set url "/npstats/status/display_device_status.tml";
	append url "?" $q;
	append result_by_type($devicetype) \
	    "<li><a href=\"$url\" target=\"newwindow\">$deviceid</a></li>\n";
    }
    foreach devicetype [array names result_by_type] {
	append result "<h4>$devicetype</h4>\n";
	append result "<ul>\n" $result_by_type($devicetype) "</ul>\n";
    }

    return $result;
}

proc npstats/status/display_device_status {deviceid template} {

    global Config;

    Httpd_Refresh [Httpd_CurrentSocket] 60;

    set status [catch {
	set r [exec npstatspage -b \
		   -h $Config(docRoot) -d $Config(npstatsplothtdir) \
		   $deviceid $template];
    } errmsg];
	
    if {$status != 0} {
	Stderr $errmsg;
	return "Internal server error";
    }

    return $r;
}

proc npstats/status/display_main_device {} {

    global Config;

    set r "No devices configured.";

    if {[llength $Config(devicelist)] == 0} {
	return $r
    }

    foreach device $Config(devicelist) {
	array set option [::npstats::devices::get_options $device];
	if {([info exists option(displaystatus)] == 0) || \
		($option(displaystatus) == 0)} {
	    continue;
	}
	set deviceid [::npstats::devices::get_id $device];
	set template [::npstats::devices::get_tml $device];
	set r [npstats/status/display_device_status $deviceid $template];

	break;
    }

    return $r;
}
