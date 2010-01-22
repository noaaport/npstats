#!/usr/local/bin/tclsh8.6

source "devices.tcl";

set source_devices_def_defined 1;
set source_devices_conf_defined 1;
source "devices.def";
source "devices.conf";

::devices::verify_devicelist $devices(devicelist);

::devices::load_devices_dbfile "devices.tdb" devices;

foreach d $devices(devicelist) {
    puts $d;
}
