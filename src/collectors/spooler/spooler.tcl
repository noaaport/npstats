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

# Local packages - 
## The errx library, with syslog enabled
package require errx;
::syslog::usesyslog;

## The devices library
package require devices;

# Initialization
set spooler(conf) [file join $common(confdir) "spooler.conf"];
set spooler(localconfdirs) $common(localconfdirs);
set spooler(verbose) 0;
set spooler(export_enable) 0;
set spooler(csvarchive_enable) 1;

# variables
set spooler(spooldir) $common(spooldir);
set spooler(datafext) $common(datafext);
set spooler(queuefext) $common(queuefext);
set spooler(csvarchivedir) $common(csvarchivedir);
set spooler(csvfext) $common(csvfext);
set spooler(devicesconf)  $common(devicesconf);
set spooler(devicesdef)  $common(devicesdef);
#
set spooler(dev,devicelist) [list];
set spooler(f_quit) 0;

#
# Read the optional configuration file.
#
if {[file exists $spooler(conf)] == 1} {
    source $spooler(conf);
}

#
# The devices definitions, configuration files are required
#
foreach _f [list $spooler(devicesdef) $spooler(devicesconf)] {
    if {[file exists ${_f}] == 0} {
	::syslog::err "${_f} is required.";
	return 1;
    }
    source ${_f};
}

# Verify the device list (in case it was manually constructed rather
# than loading it from a tdb file.
set status [catch {
    ::devices::verify_devicelist $devices(devicelist);
} errmsg];
if {$status != 0} {
    ::syslog::err $errmsg;
    return 1;
}

# Copy all the devices(..) entries for easy reference in the functions
foreach key [array names devices *] {
    set spooler(dev,$key) $devices($key);
}

if {[llength $spooler(dev,devicelist)] == 0} {
    ::syslog::err "No devices configured.";
    return 1;
}

proc main {argv} {

    global spooler;

    fileevent stdin readable [list spooler_fileevent_handler_stdin];
    vwait spooler(f_quit);
}

proc spooler_fileevent_handler_stdin {} {

    global spooler;
    global errorInfo;

    set r [gets stdin pdata];

    if {$r == -1} {
	set spooler(f_quit) 1;
	return;
    } elseif {$pdata eq ""} {
	::syslog::msg "Received request to quit.";
	set spooler(f_quit) 1;
	return;
    }

    set status [catch {spooler_process $pdata} errmsg];
    if {$status == 1} {
	::syslog::warn "Error processing $pdata";
	::syslog::warn $errmsg;
	::syslog::warn $errorInfo;
    }
}

proc spooler_process {pdata} {
#
# <pdata> is a string of the form
#
# <deviceid>|<devicenumber>|<devicetype>|<output>
#
# where <output> is the csv separated string of values as emitted by the
# pollers.
#
    global spooler;

    set pdataparts [::devices::data_unpack $pdata];
    set deviceid [::devices::data_unpack_deviceid $pdataparts];
    set devicenumber [::devices::data_unpack_devicenumber $pdataparts];
    set devicetype [::devices::data_unpack_devicetype $pdataparts];
    set output [::devices::data_unpack_output $pdataparts];

    array set option [spooler_get_device_options_fromid $deviceid];

    if {($spooler(export_enable) == 1) && ($option(export) == 1)} {
	spooler_spool_device_report $deviceid $output $pdata;
    }

    if {($spooler(csvarchive_enable) == 1) && ($option(csvarchive) == 1)} {
	spooler_csvarchive_device_data $deviceid $devicetid $output;
    }
}

proc spooler_spool_device_report {deviceid output pdata} {

    global spooler;

    set paramlist [spooler_get_device_param_fromid $deviceid];
    set vlist [split $output ","];
    
    if {[llength $vlist] != [llength $paramlist]} {
	::syslog::warn "Number of data items and parameters do not match.";
	::syslog::warn "$deviceid: $output.";
	return;
    }

    # The convention is that the first element of the data from any
    # device is a time stamp (unix seconds).
    set time [lindex $vlist 0];

    set dfpath [file join $spooler(spooldir) ${deviceid}.${time}];
    set qfpath $dfpath;
    append dfpath $spooler(datafext);
    append qfpath $spooler(queuefext);

    # set report "";
    # append report [join $paramlist ","] "=" $output;
    set status [catch {
        # ::fileutil::writeFile $dfpath $report;
	::fileutil::writeFile $dfpath $pdata;
	::fileutil::touch $qfpath;
    } errmsg]; 

    if {$status != 0} {
	::syslog::warn $errmsg;
	file delete $dfpath;
	file delete $qfpath;
    }
}

proc spooler_csvarchive_device_data {deviceid devicetid output} {

    global spooler;

    # The convention is that the first element of the data from any
    # device is a time stamp (unix seconds). So, instead of
    #
    # set time [clock seconds];
    #
    set time [lindex [split $output ","] 0];

    set ymdhms [clock format $time -format "%Y%m%d%H%M%S" -gmt 1];
    set yyyy [clock format $time -format "%Y" -gmt 1];
    set month [clock format $time -format "%m" -gmt 1];
    set day [clock format $time -format "%d" -gmt 1];
    set yyyymmdd ${yyyy}${month}${day};

    set csvarchivedir [file join $spooler(csvarchivedir) \
			   $deviceid $yyyy $month];

    set csvfpath [file join $csvarchivedir ${deviceid}.${yyyymmdd}];
    append csvfpath $spooler(csvfext);

    # The <data> will be the
    #
    # <devicetid>,<output>
    #
    # We add the <devicetid> because it would be easier later to
    # transfer the csv files to/from a db.

    set data $devicetid;
    append data "," $output "\n";
    set status [catch {
	::fileutil::appendToFile $csvfpath $data;
    } errmsg]; 

    if {$status != 0} {
	::syslog::warn $errmsg;
    }
}

#
# These functions retrieve the various properties of each device.
#
proc spooler_get_device_options_fromid {deviceid} {

    global spooler;

    set device_options [::devices::get_options_fromid \
			    $spooler(dev,devicelist) $deviceid];

    return $device_options;
}

proc spooler_get_device_param_fromid {deviceid} {

    global spooler;

    set device_type [::devices::get_type_fromid \
			 $spooler(dev,devicelist) $deviceid];

    return $spooler(dev,param,$device_type);
}

#
# main
#
main $argv;
