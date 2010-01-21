#
# $Id$
#
package provide devices 1.0;

#
# These functions retrieve the various properties of each device,
# as defined in devices.conf.
#
namespace eval devices {

    variable devices;
}

proc ::devices::get_id {device} {

    set device_id [lindex $device 0];

    return $device_id;
}

proc ::devices::get_type {device} {

    set device_type [lindex $device 1];

    return $device_type;
}

proc ::devices::get_tid {device} {

    set device_tid [lindex $device 2];

    return $device_tid;
}

proc ::devices::get_options {device} {

    set device_options [lindex $device 3];

    return $device_options;
}

proc ::devices::get_tml {device} {

    set device_tml [lindex $device 4];

    return $device_tml;
}

#
# Given a device id (<site>.<name>) and a device list, these functions
# retrieve the properties of the device.
#
proc ::devices::get_device_fromid {devicelist deviceid} {

    foreach d $devicelist {
	if {[get_id $d] == $deviceid} {
	    return $d;
	}
    }

    return [list];
}

proc ::devices::get_type_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_type $device];
}

proc ::devices::get_tid_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_tid $device];
}

proc ::devices::get_options_fromid {devicelist deviceid} {

    set device [get_device_fromid $devicelist $deviceid];
    if {[llength $device] == 0} {
	return "";
    }

    return [get_options $device];
}

proc ::devices::get_tml_fromid {devicelist deviceid} {

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
# <deviceid>|<devicetype>|<devicetid>|<output>

proc ::devices::data_pack {device output} {
#
# <output> should be the csv string of the device output.
# This function returns the string
#
# <deviceid>|<devicetype>|<devicetid>|<output>
#
# which we call a "pdata".

    set pdatalist [lrange $device 0 2]
    lappend pdatalist $output;

    return [join $pdatalist "|"];
}

proc ::devices::data_unpack {pdata} {
#
# Takes as input the result obtained from ::devices::data_pack, and
# returns a list of 4 elements: <deviceid>|<devicetype>|<devicetid>|<output>
# 
#
    return [split $pdata "|"];
}

#
# These functions return each of the four the indivicual elements mentioned
# above. The argument must be the output of ::devices::data_unpack.
#
proc ::devices::data_unpack_deviceid {pdatalist} {

    return [lindex $pdatalist 0];
}

proc ::devices::data_unpack_devicetype {pdatalist} {

    return [lindex $pdatalist 1];
}

proc ::devices::data_unpack_devicetid {pdatalist} {

    return [lindex $pdatalist 2];
}

proc ::devices::data_unpack_output {datalist} {

    return [lindex $datalist 3];
}

#
# Given a <deviceid> = <site>.<devicename> these functions extract the
# two parts: <site> and <devicename> in such a way that the <devicename>
# can contain periods (.e.g., noaaportnet.atom.qdbstats)
#
proc ::devices::get_deviceid_parts {deviceid} {

    if {[regexp {([^\.]+)\.(.+)} $deviceid match site name] == 0} {
	return -code error "Invalid device id $deviceid.";
    }
    
    return [list $site $name];
}

proc ::devices::get_devicesite {deviceid} {

    return [lindex [get_deviceid_parts $deviceid] 0];
}

proc ::devices::get_devicename {deviceid} {

    return [lindex [get_deviceid_parts $deviceid] 1];
}

proc ::devices::get_devicefname_parts {devicefname} {
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

proc ::devices::get_deviceid_fromfname {devicefname} {

    set deviceid [lindex [get_devicefname_parts $devicefname] 0];
    
    return $deviceid;
}

proc ::devices::get_devicesite_fromfname {devicefname} {

    set deviceid [get_deviceid_fromfname $devicefname];
    
    return [get_devicesite $deviceid];
}

proc ::devices::get_deviceid_fromfpath {fpath} {

    set fname [file rootname [file tail $fpath]];
    set deviceid [get_deviceid_fromfname $fname];

    return $deviceid;
}
