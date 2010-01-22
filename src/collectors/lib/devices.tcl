#
# $Id$
#
package provide npstats::devices 1.0;
package require textutil::split;

#
# These functions retrieve the various properties of each device,
# as defined in devices.conf.
#
namespace eval npstats::devices {

    variable devices;
}

proc ::npstats::devices::get_id {device} {

    set i [lsearch -exact $device "deviceid"];
    incr i;
    set deviceid [lindex $device $i];

    return $deviceid;
}

proc ::npstats::devices::get_number {device} {

    set i [lsearch -exact $device "devicenumber"];
    incr i;
    set devicenumber [lindex $device $i];

    return $devicenumber;
}

proc ::npstats::devices::get_type {device} {

    set i [lsearch -exact $device "devicetype"];
    incr i;
    set devicetype [lindex $device $i];

    return $devicetype;
}

proc ::npstats::devices::get_options {device} {

    set i [lsearch -exact $device "export"];
    incr i;
    set v1 [lindex $device $i];

    set i [lsearch -exact $device "csvarchive"];
    incr i;
    set v2 [lindex $device $i];

    set i [lsearch -exact $device "displaystatus"];
    incr i;
    set v3 [lindex $device $i];

    return [list export $v1 csvarchive $v2 displaystatus $v3];
}

proc ::npstats::devices::get_tml {device} {

    set i [lsearch -exact $device "displaytemplate"];
    incr i;
    set displaytemplate [lindex $device $i];

    return $displaytemplate;
}

#
# Given a device id (<site>.<name>) and a device list, these functions
# retrieve the properties of the device.
#
proc ::npstats::devices::get_device_fromid {devicelist deviceid} {

    foreach d $devicelist {
	if {[get_id $d] eq $deviceid} {
	    return $d;
	}
    }

    return [list];
}

proc ::npstats::devices::get_type_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_type $device];
}

proc ::npstats::devices::get_number_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_number $device];
}

proc ::npstats::devices::get_options_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_options $device];
}

proc ::npstats::devices::get_tml_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_tml $device];
}

# These functions are used to uniformize the exchange of data among
# the various programs. The rationale is this. The data enters into
# the system via the manager, which sends the data to the spooler
# and the monitor, which can in turn propagate it further via the qrunner.
# The convention is that the data from each poller (called <output>)
# is a csv string. The manager adds the metadata (using the data_pack
# function here) and that is the string that is exchanged from program
# to program. So, every program receives a <pdata> string:
#
# <deviceid>|<devicenumber>|<devicetype>|<output>

proc ::npstats::devices::data_pack {device output} {
#
# <output> should be the csv string of the device output.
# This function returns the string
#
# <deviceid>|<devicenumber>|<devicetype>|<output>
#
# which we call a "pdata".

    lappend pdatalist [get_id $device] \
	[get_number $device] \
	[get_type $device] \
	$output;

    return [join $pdatalist "|"];
}

proc ::npstats::devices::data_unpack {pdata} {
#
# Takes as input the result obtained from ::npstats::devices::data_pack, and returns
# a list of 4 elements: <deviceid>|<devicenumber>|<devicetype>|<output>
#
    return [split $pdata "|"];
}

#
# These functions return each of the four the indivicual elements mentioned
# above. The argument must be the output of ::npstats::devices::data_unpack.
#
proc ::npstats::devices::data_unpack_deviceid {pdatalist} {

    return [lindex $pdatalist 0];
}

proc ::npstats::devices::data_unpack_devicenumber {pdatalist} {

    return [lindex $pdatalist 1];
}

proc ::npstats::devices::data_unpack_devicetype {pdatalist} {

    return [lindex $pdatalist 2];
}

proc ::npstats::devices::data_unpack_output {datalist} {

    return [lindex $datalist 3];
}

#
# Given a <deviceid> = <site>.<devicename> these functions extract the
# two parts: <site> and <devicename> in such a way that the <devicename>
# can contain periods (.e.g., noaaportnet.atom.qdbstats)
#
proc ::npstats::devices::get_deviceid_parts {deviceid} {

    if {[regexp {([^\.]+)\.(.+)} $deviceid match site name] == 0} {
	return -code error "Invalid device id $deviceid.";
    }
    
    return [list $site $name];
}

proc ::npstats::devices::get_devicesite {deviceid} {

    return [lindex [get_deviceid_parts $deviceid] 0];
}

proc ::npstats::devices::get_devicename {deviceid} {

    return [lindex [get_deviceid_parts $deviceid] 1];
}

proc ::npstats::devices::get_devicefname_parts {devicefname} {
#
# By <devicefname> we understand the rootname of a device data file
# such as
#
#         noaaportnet.atom.var_noaaport_data.20090813.csv
# or
#         noaaportnet.atom.var_noaaport_data.1250127090.df
#
# The <devicefname> is the portion of the form
#
# <deviceid>.<time> = <site>.<devicename>.<time>
#
# where <time> is a date or a unix time. This function
# returns the two pieces <deviceid> and <time> as a tcl list.

    set deviceid [file rootname $devicefname];
    set time [string trimleft [file extension $devicefname] "."];

    return [list $deviceid $time];
}

proc ::npstats::devices::get_deviceid_fromfname {devicefname} {

    set deviceid [lindex [get_devicefname_parts $devicefname] 0];
    
    return $deviceid;
}

proc ::npstats::devices::get_devicesite_fromfname {devicefname} {

    set deviceid [get_deviceid_fromfname $devicefname];
    
    return [get_devicesite $deviceid];
}

proc ::npstats::devices::get_deviceid_fromfpath {fpath} {

    set fname [file rootname [file tail $fpath]];
    set deviceid [get_deviceid_fromfname $fname];

    return $deviceid;
}

#
# Each time a script sources devices.conf, this function should be called
# to verify that the devices(devicelist) is properly constructed oin case
# the list is constructed by hand rather than being loaded from the text
# dbfile.
#
proc ::npstats::devices::verify_devicelist {devicelist} {

    set paramnames [list deviceid devicenumber devicetype \
			export csvarchive displaystatus \
			displaytemplate];

    foreach device $devicelist {
	# Each device must contain the {key val} pair for each of the above
	# keywords.
	if {[llength $device] != 14} {
	    return -code error "Invalid device list: $device";
	}
	foreach key $paramnames {
	    if {[lsearch -exact $device $key] == -1} {
		return -code error "Invalid device list: $device";
	    }
	}
    }
}

#
# This function loads a devices "flat dbfile" and constructs
# the devices(devicelist) in the format of devices.conf.
#
proc ::npstats::devices::load_devices_dbfile {dbfile devices_array} {

    upvar $devices_array devices;

    # Make the default options array
    array set defaultoptions $devices(defaultoptions);

    # The parameters, in the order in which they must appear in the
    # (flat) dbfile. Only the first three are mandatory. The others are
    # optional, and get set to the default values if they are not given
    # or are empty.

    set paramnames [list deviceid devicenumber devicetype \
			export csvarchive displaystatus \
			displaytemplate];

    set body [split [string trim [exec cat $dbfile]] "\n"];

    foreach line $body {
	if {[regexp {^\#|^\s*$} $line]} {
	    continue;
	}
	# puts $line;

	set paramlist [textutil::split::splitx [string trim $line] {\s*,\s*}];

	set status [catch {
	    _verify_device_paramlist $paramlist;
	} errmsg];
	if {$status != 0} {
	    return -code error "Error processing line: $line: $errmsg";
	}

	if {[lindex $paramlist 3] eq ""} {
	    lset paramlist 3 $defaultoptions(export);
	}

	if {[lindex $paramlist 4] eq ""} {
	    lset paramlist 4 $defaultoptions(csvarchive);
	}

	if {[lindex $paramlist 5] eq ""} {
	    lset paramlist 5 $defaultoptions(displaystatus);
	}

	if {[lindex $paramlist 6] eq ""} {
	    set devicetype [lindex $paramlist 2];
	    lset paramlist 6 $devices(defaulttemplate,$devicetype);
	}

	# Now construct the list of key value pairs and lappend it to
	# devices(devicelist).
	set _device [list];
	set i 0;
	foreach name $paramnames {
	    lappend _device $name [lindex $paramlist $i];
	    incr i;
	}
	lappend devices(devicelist) ${_device};
    }
}

#
# This is a helper function for ::npstats::devices::load_devices_dbfile.
#
proc ::npstats::devices::_verify_device_paramlist {paramlist} {

    set r "";
    if {[llength $paramlist] < 3} {
	set r "Invalid number of parameters.";
    }

    set id [lindex $paramlist 0];
    if {$id eq ""} {
	set r "Invalid deviceid";
    }

    set number [lindex $paramlist 1];
    if {$number eq ""} {
	set r "Invalid devicenumber";
    }

    set type [lindex $paramlist 2];
    if {$type eq ""} {
	set r "Invalid devicetype";
    }

    if {$r ne ""} {
	return -code error $r;
    }
}
