#!%TCLSH%
#
# $Id$
#

## The common defaults
source "/usr/local/etc/npstats/collectors.conf";

# Packages from tcllib
package require fileutil;
package require textutil;

# Local packages - 
## The errx library, with syslog enabled
package require npstats::syslog;

## The pollers library
package require npstats::poll;

## The devices library
package require npstats::devices;

## The interface to the spooler and monitor
package require npstats::spooler;
package require npstats::monitor;

# Initialization
set manager(conf) [file join $common(confdir) "manager.conf"];
set manager(localconfdirs) $common(localconfdirs);
set manager(verbose) 0;
set manager(spooler_enable) 1;
set manager(monitor_enable) 1;

# variables
set manager(spooldir) $common(spooldir);
set manager(datafext) $common(datafext);
set manager(queuefext) $common(queuefext);
set manager(csvarchivedir) $common(csvarchivedir);
set manager(csvfext) $common(csvfext);
set manager(devicesconf)  $common(devicesconf);
set manager(devicesdef)  $common(devicesdef);
set manager(spooler) $common(spooler);
set manager(monitor) $common(monitor);
#
set manager(dev,devicelist) [list];
set manager(dev,alertlist) [list];
set manager(f_quit) 0;

#
# Read the optional configuration file.
#
if {[file exists $manager(conf)] == 1} {
    source $manager(conf);
}

#
# The devices definitions, configuration files are required
#
foreach _f [list $manager(devicesdef) $manager(devicesconf)] {
    if {[file exists ${_f}] == 0} {
	::npstats::syslog::err "${_f} is required.";
	return 1;
    }
    source ${_f};
}

# Verify the device list (in case it was manually constructed rather
# than loading it from a tdb file.
set status [catch {
    ::npstats::devices::verify_devicelist $devices(devicelist);
} errmsg];
if {$status != 0} {
    ::npstats::syslog::err $errmsg;
    return 1;
}

# Copy all the devices(..) entries for easy reference in the functions
foreach key [array names devices *] {
    set manager(dev,$key) $devices($key);
}

if {[llength $manager(dev,devicelist)] == 0} {
    ::npstats::syslog::err "No devices configured.";
    return 1;
}

proc main {argv} {

    global manager;

    manager_open_devices;
    manager_open_spooler;
    manager_open_monitor;

    fileevent stdin readable [list manager_fileevent_handler_stdin];
    vwait manager(f_quit);

    manager_close_monitor;
    manager_close_spooler;
    manager_close_devices;
}

proc manager_fileevent_handler_stdin {} {

    global manager;
    global errorInfo;

    set r [gets stdin cmd];

    if {$r == -1} {
	set manager(f_quit) 1;
	return;
    } elseif {$cmd eq ""} {
	::npstats::syslog::msg "Received request to quit.";
	set manager(f_quit) 1;
	return;
    }

    set status [catch {manager_process $cmd} errmsg];
    if {$status == 1} {
	::npstats::syslog::warn "Error processing $cmd";
	::npstats::syslog::warn $errmsg;
	::npstats::syslog::warn $errorInfo;
    }
}

proc manager_process {cmd} {

    global manager;

    if {$manager(verbose) > 0} {
	::npstats::syslog::msg "Sending $cmd to pollers.";
    }

    if {$cmd eq "POLL"} {
	manager_poll_devices;
    } elseif {$cmd eq "REPORT"} {
	manager_report_devices;
    } else {
	::npstats::syslog::warn "Unrecognized comand: $cmd";
    }
}

#
# Functions that operate on the device list
#
proc manager_open_devices {} {

    global manager;

    foreach device $manager(dev,devicelist) {
	manager_open_one_device $device;
    }
}

proc manager_close_devices {} {

    global manager;

    foreach device $manager(dev,devicelist) {
	manager_close_one_device $device;
    }
}

proc manager_poll_devices {} {

    global manager;

    foreach device $manager(dev,devicelist) {
	manager_send_one_device $device "POLL";
    }
}

proc manager_report_devices {} {

    global manager;

    foreach device $manager(dev,devicelist) {
	manager_send_one_device $device "REPORT";
    }
}

#
# These functions operate on one device
# 
proc manager_open_one_device {device} {

    global manager;

    set device_id [manager_get_device_id $device];
    set device_poller [manager_get_device_poller $device];
	
    set status [catch {
	::npstats::poll::connect $device_id $device_poller;
    } errmsg];
    
    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
	return;
    }

    fileevent [::npstats::poll::get_filehandle $device_id] readable \
	[list manager_fileevent_handler_device $device];
}

proc manager_close_one_device {device} {

    global manager;

    set device_id [manager_get_device_id $device];
    catch {::npstats::poll::disconnect $device_id};
}

proc manager_send_one_device {device cmd} {

    global manager;

    set device_id [manager_get_device_id $device];

    set status [catch {
	::npstats::poll::send $device_id $cmd;
    } errmsg];
    
    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
    }

    # If there is an error, close the device and try to reopen it.
    if {$status != 0} {
	::npstats::syslog::msg "Trying again.";
	manager_close_one_device $device;
	manager_open_one_device $device;
	set status [catch {
	    ::npstats::poll::send $device_id $cmd;
	} errmsg];
	if {$status == 0} {
	    ::npstats::syslog::msg "OK";
	}
    }

    return $status;
}

proc manager_fileevent_handler_device {device} {

    global manager;

    set device_id [manager_get_device_id $device];

    set codeoutput "";
    set status [catch {
	set r [::npstats::poll::pop_line $device_id codeoutput];
    } errmsg];
    
    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
	manager_close_one_device $device;
	manager_open_one_device $device;
	return;
    }
    
    if {$r == -1} {
	::npstats::syslog::warn "Device $device_id closed.";
	manager_close_one_device $device;
	manager_open_one_device $device;
	set status 1;
    } elseif {$r == 0} {
	::npstats::syslog::warn "No output from device $device_id.";
	set status 1;
    } else {
	if {[regexp {([^:]+):(.+)} $codeoutput match code output] == 0} {
	    ::npstats::syslog::warn \
		"Device $device_id: Invalid output $output";
	    set status 1;
	} else {
	    if {$code ne "OK"} {
		::npstats::syslog::warn "Device $device_id: $codeoutput";
		set status 1;
	    }
	}
    }

    if {$status != 0} {
	return;
    }

    manager_send_spooler $device $output;
    manager_send_monitor $device $output;
}

#
# These functions retrieve the various properties of each device.
#
proc manager_get_device_id {device} {

    set device_id [::npstats::devices::get_id $device];

    return $device_id;
}

proc manager_get_device_type {device} {

    set device_type [::npstats::devices::get_type $device];

    return $device_type;
}

proc manager_get_device_number {device} {

    set device_number [::npstats::devices::get_number $device];

    return $device_number;
}

proc manager_get_device_options {device} {

    set device_options [::npstats::devices::get_options $device];

    return $device_options;
}

proc manager_get_device_poller {device} {

    global manager;

    # First look by id, othewise get the default for its type.

    set device_id [manager_get_device_id $device];
    if {[info exists manager(dev,poller,$device_id)]} {
	return $manager(dev,poller,$device_id);
    }

    set device_type [manager_get_device_type $device];

    return $manager(dev,poller,$device_type);
}

proc manager_get_device_param {device} {

    global manager;

    set device_type [manager_get_device_type $device];

    return $manager(dev,param,$device_type);
}

#
# Functions to send the data to the monitor
#
proc manager_send_monitor {device output} {

    global manager;

    if {$manager(monitor_enable) == 0} {
	return;
    }

    set pdata [::npstats::devices::data_pack $device $output];

    set r [::npstats::monitor::send_output $pdata];
    if {$r ne ""} {
	::npstats::syslog::warn $r;
    }
}

proc manager_open_monitor {} {
#
# The monitor is enabled only if the alertlist is set in the
# devices.conf file.
#
    global manager;

    if {$manager(monitor_enable) == 0} {
	return;
    }

    if {([info exists manager(dev,alertlist)] == 0) || \
	    ([llength $manager(dev,alertlist)] == 0)} {

	# disable it
	::npstats::syslog::warn "No alerts defined. Disabling the monitor.";
	set manager(monitor_enable) 0;

	return;
    }

    ::npstats::monitor::init $manager(monitor);
    set r [::npstats::monitor::connect];
    if {$r ne ""} {
	::npstats::syslog::warn $r;
    }
}

proc manager_close_monitor {} {

    global manager;

    if {$manager(monitor_enable) == 0} {
	return;
    }

    set r [::npstats::monitor::disconnect];
    if {$r ne ""} {
	::npstats::syslog::warn $r;
    }
}

#
# Spooler functions
#
proc manager_send_spooler {device output} {

    global manager;

    if {$manager(spooler_enable) == 0} {
	return;
    }

    set pdata [::npstats::devices::data_pack $device $output];

    set r [::npstats::spooler::send_output $pdata];
    if {$r ne ""} {
	::npstats::syslog::warn $r;
    }
}

proc manager_open_spooler {} {

    global manager;

    if {$manager(spooler_enable) == 0} {
	return;
    }

    ::npstats::spooler::init $manager(spooler);
    set r [::npstats::spooler::connect];
    if {$r ne ""} {
	::npstats::syslog::warn $r;
    }
}

proc manager_close_spooler {} {

    global manager;

    if {$manager(spooler_enable) == 0} {
	return;
    }

    set r [::npstats::spooler::disconnect];
    if {$r ne ""} {
	::npstats::syslog::warn $r;
    }
}

#
# main
#
main $argv;
