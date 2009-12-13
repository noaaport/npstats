#!%TCLSH%
#
#  $Id$
#
package require cmdline;
package require textutil::trim;

set usage {nbspqstatspoll [-t <qdb|mdb|qstate>]};
set optlist {{t.arg "qstate"}};

#
# Get the location of the queue statistics files
#
set _nbspdinit "/usr/local/libexec/nbsp/nbspd.init";
if {[file exists ${_nbspdinit}] == 0} {
    puts stderr "${_nbspdinit} not found.";
    exit 1;
}
source ${_nbspdinit};
unset _nbspdinit;

set nbspqstatspoll(logfile,qdb) $nbspd(qdbstatslogfile);
set nbspqstatspoll(logfile,mdb) $nbspd(mspoolbdb_dbstats_logfile);
set nbspqstatspoll(logfile,qstate) $nbspd(qstatelogfile)

set nbspqstatspoll(data,last_time,qdb) 0;
set nbspqstatspoll(data,last_time,mdb) 0;
set nbspqstatspoll(data,last_time,qstate) 0;
#
set nbspqstatspoll(data,valid,qdb) 0;
set nbspqstatspoll(data,valid,mdb) 0;
set nbspqstatspoll(data,valid,qstate) 0;
#
set nbspqstatspoll(data,values,qdb) [list];
set nbspqstatspoll(data,values,mdb) [list];
set nbspqstatspoll(data,values,qstate) [list];

proc nbspqstatspoll_get_data {type} {

    global nbspqstatspoll;

    if {$type eq "qdb"} {
	set values \
	    [nbspqstatspoll_qdbstats_values $nbspqstatspoll(logfile,$type)];
    } elseif {$type eq "mdb"} {
	set values \
	    [nbspqstatspoll_mdbstats_values $nbspqstatspoll(logfile,$type)];
    } elseif {$type eq "qstate"} {
	set values \
	    [nbspqstatspoll_qstate_values $nbspqstatspoll(logfile,$type)];
    } else {
	return -error code "Invalid type $type.";
    }

    set data_time [lindex [split $values] 0];
    if {$data_time == $nbspqstatspoll(data,last_time,$type)} {
	return;
    }

    # If there is unreported data, report it or we will loose it
    if {$nbspqstatspoll(data,valid,$type) == 1} {
	nbspqstatspoll_report_data $type;
    }

    set nbspqstatspoll(data,values,$type) $values;
    set nbspqstatspoll(data,valid,$type) 1;
    set nbspqstatspoll(data,last_time,$type) $data_time;
}

proc nbspqstatspoll_report_data {type} {

    global nbspqstatspoll;

    if {$nbspqstatspoll(data,valid,$type) == 0} {
	puts "WARN:nbspqstatspoll waiting for data.";
	return;
    }

    set output "OK:";
    append output [join $nbspqstatspoll(data,values,$type) ","];
    puts $output;

    set nbspqstatspoll(data,valid,$type) 0;
    set nbspqstatspoll(data,values,$type) [list];
}

proc nbspqstatspoll_qdbstats_values {inputfile} {
#
# The values are emitted in the following order:
#
# time
# qdb.panic_flag "Panic value";
# qdb.cache.pages.found "Requested pages found";
# qdb.cache.pages.foundfr (percentage wise)
# qdb.cache.pages.notfound "Requested pages not found";
# qdb.cache.pages.created "Pages created";
# qdb.cache.pages.readin "Pages read";
# qdb.cache.pages.writtenout "Pages written";
#
    set phrases(0) "Local time";
    set phrases(1) "Panic value";
    set phrases(2) "Requested pages found";
    # set phrases(3) - obtained from the same line as 2.
    set phrases(4) "Requested pages not found";
    set phrases(5) "Pages created";
    set phrases(6) "Pages read";
    set phrases(7) "Pages written";

    foreach line [split [exec cat $inputfile] "\n"] {
	if {[regexp {^Pool File:} $line]} {
	    break;
	}

	foreach varname [array names phrases] {
	    if {[regexp $phrases($varname) $line]} {
		set val($varname) [lindex [split $line] 0];

		# Convert the date to seconds
		if {$varname == 0} {
		    set val(0) [clock scan [lindex [split $line "\t"] 0]];
		}

		# Extract the value of pages found percentage-wise
		if {$varname == 2} {		    
		    set val(3) [string trimright [string trimleft \
				[lindex [split $line] end] "("] ")"];
		}
	    }
	}
    }

    set values [list];
    foreach name [lsort [array names val]] {
	lappend values $val($name);
    }

    return $values;
}

proc nbspqstatspoll_mdbstats_values {inputfile} {
#
# The values are emitted in the following order:
#
# time
# mdb.panic_flag "Panic value";
# mdb.cache.pages.found "Requested pages found";
# mdb.cache.pages.foundfr (percentage wise)
# mdb.cache.pages.notfound "Requested pages not found";
# mdb.cache.pages.created "Pages created";
#
    set phrases(0) "Local time";
    set phrases(1) "Panic value";
    set phrases(2) "Requested pages found";
    # set phrases(3) - obtained from the same line as 2.
    set phrases(4) "Requested pages not found";
    set phrases(5) "Pages created";

    foreach line [split [exec cat $inputfile] "\n"] {
	if {[regexp {^Pool File:} $line]} {
	    break;
	}

	foreach varname [array names phrases] {
	    if {[regexp $phrases($varname) $line]} {
		set val($varname) [lindex [split $line] 0];

		# Convert the date to seconds
		if {$varname == 0} {
		    set val(0) [clock scan [lindex [split $line "\t"] 0]];
		}

		# Extract the value of pages found percentage-wise
		if {$varname == 2} {		    
		    set val(3) [string trimright [string trimleft \
				[lindex [split $line] end] "("] ")"];
		}
	    }
	}
    }

    set values [list];
    foreach name [lsort [array names val]] {
	lappend values $val($name);
    }

    return $values;
}

proc nbspqstatspoll_qstate_values {inputfile} {
#
# The file nbspd.qstate has the data in this order:
#
# <time> <processor queue> <filter queue> <server queue>
#
    set data [exec tail -n 1 $inputfile];

    return [join $data ","];
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];

if {[regexp {^(qdb|mdb|qstate)$} $option(t)] == 0} {
    puts $usage;
    return 1;
}

while {[gets stdin cmd] > 0} {
    if {$cmd eq "POLL"} {
	nbspqstatspoll_get_data $option(t);
    } elseif {$cmd eq "REPORT"} {
	nbspqstatspoll_report_data $option(t);
    } else {
	puts "Unrecognized command $cmd.";
    }
}
