#!%TCLSH%
#
# $Id$
#
package require cmdline;
package require textutil::split;

set usage {syspoll [-t fs|load|mem_freebsd|mem_linux] [<file_system>]};
set optlist {{t.arg "load"}};
 
# These are the output fields according to the devices.def file.
#
#  fs: time device size used free
#  load: time load1 load5 load15
#  mem: ...

# The top and vmstat parameters
set syspoll(top_params,mem_freebsd) {{exec top -d 1} 3 4};
set syspoll(top_params,mem_linux) {{exec top -b -n 1} 3 4};
set syspoll(vmstat_params,mem_freebsd) {{exec vmstat} 2 7 8};
set syspoll(vmstat_params,mem_linux) {{exec vmstat} 2 6 7};

# Variables
set syspoll(data,last_time,fs) 0;
set syspoll(data,last_time,load) 0;
set syspoll(data,last_time,mem_freebsd) 0;
set syspoll(data,last_time,mem_linux) 0;
set syspoll(data,valid,fs) 0;
set syspoll(data,valid,load) 0;
set syspoll(data,valid,mem_freebsd) 0;
set syspoll(data,valid,mem_linux) 0;
#
set syspoll(data,values,fs) [list];
set syspoll(data,values,load) [list];
set syspoll(data,values,mem_freebsd) [list];
set syspoll(data,values,mem_linux) [list];

proc syspoll_get_data {type args} {

    if {$type eq "fs"} {
	syspoll_get_data_fs $args;
    } elseif {$type eq "load"} {
	syspoll_get_data_load;
    } elseif {($type eq "mem_freebsd") || ($type eq "mem_linux")} {
	syspoll_get_data_mem $type;
    } else {
	puts $usage;
    }
}

proc syspoll_get_data_fs {args} {

    global syspoll;

    set name [lindex $args 0];

    set df [::textutil::split::splitx \
		[lindex [split [exec df $name] "\n"] 1]];

    set device [lindex $df 0];
    set size [lindex $df 1];
    set used [lindex $df 2];
    set free [lindex $df 3];
    set capacity [string trimright [lindex $df 4] "%"];   # used%
    
    set data [list $device $size $used $free $capacity]

    set time [clock seconds];

    # If there is unreported data, report it or we will loose it
    # if {$syspoll(data,valid,fs) == 1} {
    #	syspoll_report_data "fs";
    # }

    set syspoll(data,values,fs) [concat [list $time] $data];
    set syspoll(data,valid,fs) 1;
    set syspoll(data,last_time,fs) $time;
}

proc syspoll_get_data_load {} {
#
# We use ``uptime'', but an alternative could be ``sysctl vm.loadavg''
#
    global syspoll;

    regsub -all "," [exec uptime] " " uptime;
    set data [lrange [::textutil::split::splitx $uptime] end-2 end];
    set time [clock seconds];

    # If there is unreported data, report it or we will loose it
    # if {$syspoll(data,valid,load) == 1} {
    #	syspoll_report_data "load";
    # }

    set syspoll(data,values,load) [concat [list $time] $data];
    set syspoll(data,valid,load) 1;
    set syspoll(data,last_time,load) $time;
}

proc syspoll_get_data_mem {type} {

    syspoll_get_data_mem_top $type;
    syspoll_get_data_mem_vmstat $type;
}

proc syspoll_get_data_mem_top {type} {
#
# <type> is either "mem_freebsd" or "mem_linux". In FreeBSD, top does not
# report "Swap: Used" if the value is zero; e.g., sometimes
#
# Mem: 138M Active, 1304M Inact, 200M Wired, 88K Cache, 112M Buf, 357M Free
# Swap: 4096M Total, 4096M Free
#
# and sometimes
# 
# Swap: 5120M Total, 68K Used, 5120M Free
#
# and similarly with Mem:Cache (and probably the others as well).
#
# Until we find a good way to deal with all this, we treat these special
# cases separately.
#
    global syspoll;

    set cmd [lindex $syspoll(top_params,$type) 0];
    set start [lindex $syspoll(top_params,$type) 1];
    set end [lindex $syspoll(top_params,$type) 2];

    set topdata [lrange [split [eval $cmd] "\n"] $start $end];

    set key_list [list];
    set val_list [list];
    set time [clock seconds];

    foreach line $topdata {
	set parts [split $line ":"];
	set name [lindex $parts 0];	# Mem or Swap
	set data [split [lindex $parts 1] ","]; 

	foreach i $data {
	    if {[regexp {\s*([^\s]+)\s*([^\s]+)} $i match val key] == 0} {
		return -code error "Invalid data $data";
	    }

	    lappend key_list [string tolower "${name}.${key}"];
	    lappend val_list $val;
	}
    }

    if {$type eq "mem_freebsd"} {
	if {[lsearch -exact $key_list "mem.cache"] == -1} {
	    # Add it with a value 0
	    set key_list [linsert $key_list 3 "mem.cache"];
	    set val_list [linsert $val_list 3 0];
	}

	if {[lsearch -exact $key_list "swap.used"] == -1} {
	    # Add it with a value 0
	    set key_list [linsert $key_list end-1 "swap.used"];
	    set val_list [linsert $val_list end-1 0];
	}
    }

    set syspoll(data,values,$type) [concat [list $time] $val_list];
    set syspoll(data,valid,$type) 1;
    set syspoll(data,last_time,$type) $time;
}

proc syspoll_get_data_mem_vmstat {type} {

    global syspoll;

    set cmd [lindex $syspoll(vmstat_params,$type) 0];
    set lineindex [lindex $syspoll(vmstat_params,$type) 1];
    set paramstart [lindex $syspoll(vmstat_params,$type) 2];
    set paramend [lindex $syspoll(vmstat_params,$type) 3];

    set vmdata [string trim [lindex [split [eval $cmd] "\n"] $lineindex]];
    set val_list [lrange [::textutil::split::splitx $vmdata] \
		      $paramstart $paramend];
    set syspoll(data,values,$type) [concat $syspoll(data,values,$type) \
					$val_list];
}

proc syspoll_report_data {type} {

    global syspoll;

    if {$syspoll(data,valid,$type) == 0} {
	puts "WARN:syspoll waiting for $type data.";
	return;
    }

    set output "OK:";
    append output [join $syspoll(data,values,$type) ","];
    puts $output;

    set syspoll(data,valid,$type) 0;
    set syspoll(data,values,$type) [list];
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];
set fs "";

if {$option(t) eq "fs"} {
    if {$argc != 1} {
	puts $usage;
	return 1;
    }
    set fs [lindex $argv 0];
}

if {[regexp {^(fs|load|mem_freebsd|mem_linux)$} $option(t)] == 0} {
    puts $usage;
    return 1;
}

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	syspoll_get_data $option(t) $fs;
    } elseif {$cmd eq "REPORT"} {
	syspoll_report_data $option(t);
    } else {
	puts "Unrecognized command $cmd.";
    }
}
