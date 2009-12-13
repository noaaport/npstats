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

# Common packages from tcllib
# (ftp, http, ..., are loaded in the individual modules)
package require fileutil;

# Local packages

## The errx library, with syslog enabled
package require errx;
::syslog::usesyslog;

# the devices library
package require devices;

# Initialization
set qrunner(conf) [file join $common(confdir) "qrunner.conf"];
set qrunner(localconfdirs) $common(localconfdirs);
set qrunner(lockfile) [file join $common(lockdir) "qrunner.lock"];
#
set qrunner(verbose) 0;
set qrunner(savesent) 0;
#
set qrunner(configured) "dbinsert";	# ftp, sftp, http, dbinsert

#
### ftp configuration
#
set qrunner(ftp,user) "";
set qrunner(ftp,passwd) "";
set qrunner(ftp,server) "stats.noaaport.net";
set qrunner(ftp,uploaddir) "upload";
# ftp options
set qrunner(ftp,enable) 1;
set qrunner(ftp,mode) "active";
set qrunner(ftp,timeout) 30;
set qrunner(ftp,verbose) 0;
set qrunner(ftp,debug) 0;

#
### sftp configuration
#
set qrunner(sftp,user) "";
set qrunner(sftp,host) "stats.noaaport.net/upload";
# sftp options
set qrunner(sftp,enable) 1;
set qrunner(sftp,timeout) 30;
set qrunner(sftp,verbose) 0;
set qrunner(sftp,debug) 0;

#
### http configuration
#
set qrunner(http,sitekey) "";
set qrunner(http,url) "http://stats.noaaport.net:8025/npstats/collect";
# http options
set qrunner(http,enable) 1;
set qrunner(http,timeout) 30;
set qrunner(http,verbose) 0;
set qrunner(http,debug) 0;

#
## direct insertion to a db (e.g., mysql)
#
set qrunner(dbinsert,enable) 1;
set qrunner(dbinsert,cmd) "mysql";
set qrunner(dbinsert,cmdoptions) {
    -B -h <dbhost> -p<dbpassword> -u <dbuser> <dbname>
};

#
# variables
#
set qrunner(spooldir) $common(spooldir);
set qrunner(sentdir) $common(sentdir);
set qrunner(workdir)  $common(datadir);
set qrunner(datafext) $common(datafext);
set qrunner(queuefext) $common(queuefext);
set qrunner(uploadersdir) $common(uploadersdir);
#
set qrunner(LOCK) "";
#
set qrunner(devicesconf)  $common(devicesconf);
set qrunner(devicesdef)  $common(devicesdef);
set qrunner(dev,devicelist) [list];

#
# Read the optional configuration file.
#
if {[file exists $qrunner(conf)] == 1} {
    source $qrunner(conf);
}

# Check the upload method
if {[regexp {^(ftp|sftp|http|dbinsert)$} $qrunner(configured)] == 0} {
    ::syslog::err "qrunner.conf unconfigured.";
    return 1;
}

# Load the uploader that is configured
set _uploader [file join $qrunner(uploadersdir) $qrunner(configured).tcl];
if {[file exists ${_uploader}] == 0} {
    ::syslog::err "${_uploader} not found.";
    return 1;
}
source ${_uploader};
unset _uploader;

#
# The devices definitions, configuration and lib files are required
#
foreach _f [list $qrunner(devicesdef) $qrunner(devicesconf)] {
    if {[file exists ${_f}] == 0} {
	::syslog::err "${_f} is required.";
	return 1;
    }
    source ${_f};
}

# Copy all the devices(..) entries for easy reference in the functions
foreach key [array names devices *] {
    set qrunner(dev,$key) $devices($key);
}

if {[llength $qrunner(dev,devicelist)] == 0} {
    ::syslog::err "No devices configured.";
    return 1;
}

#
# Functions common to all methods
#
proc qrunner_log_qfilelist {qfilelist} {

    set namelist [list];

    foreach qfile $qfilelist {
	set name [file tail [file rootname $qfile]];
	lappend namelist $name;
    }
    
    ::syslog::msg "Starting to upload [join $namelist " "]";
}

proc qrunner_lock {} {

    global qrunner;

    set status [catch {
	set qrunner(LOCK) [open $qrunner(lockfile) {CREAT EXCL RDWR}];
    } errmsg];

    if {$status != 0} {
	::syslog::warn $errmsg;
    }

    return $status;
}

proc qrunner_unlock {} {

    global qrunner;

    set status [catch {
	close $qrunner(LOCK);
	file delete $qrunner(lockfile);
    } errmsg];	
    set qrunner(LOCK) "";

    if {$status != 0} {
	::syslog::warn $errmsg;
    }
}

#
# Given a deviceid (<site>.<name>), these functions retrieve the various
# properties of each device as specified in the devices table
#
proc qrunner_get_type_fromid {deviceid} {

    global qrunner;

    return [::devices::get_type_fromid $qrunner(dev,devicelist) $deviceid];
}

proc qrunner_get_tid_fromid {deviceid} {

    global qrunner;

    return [::devices::get_tid_fromid $qrunner(dev,devicelist) $deviceid];
}

proc qrunner_get_options_fromid {deviceid} {

    global qrunner;

    return [::devices::get_options_fromid $qrunner(dev,devicelist) $deviceid];
}

proc qrunner_get_dbtable_fromid {deviceid} {

    global qrunner;

    set device_type [qrunner_get_type_fromid $deviceid];
    if {$device_type eq ""} {
	return "";
    }

    return $qrunner(dev,dbtable,$device_type);
}

proc qrunner_get_dbcols_fromid {deviceid} {

    global qrunner;

    set device_type [qrunner_get_type_fromid $deviceid];
    if {$device_type eq ""} {
	return "";
    }

    return $qrunner(dev,dbcols,$device_type);
}

#
# main
#

#
# after [expr 1000 + int(rand() * 15000)];
#

if {[qrunner_lock] == 1} {
    ::syslog::warn "Queue may be locked by another qrunner.";
    return;
}
::syslog::msg "Started qrunner.";

set status [catch {
    cd $qrunner(workdir);
    set qfilelist [glob -dir $qrunner(spooldir) -nocomplain \
		       "*$qrunner(queuefext)"];
    if {$qrunner(configured) eq "ftp"} {
	qrunner_ftp_upload $qfilelist;
    } elseif {$qrunner(configured) eq "sftp"} {
	qrunner_sftp_upload $qfilelist;
    } elseif {$qrunner(configured) eq "http"} {
	qrunner_http_upload $qfilelist;
    } elseif {$qrunner(configured) eq "dbinsert"} {
	qrunner_dbinsert_upload $qfilelist;
    } else {
	return -code error "Unsupported upload method: $qrunner(configured)";
    }
} errmsg];

qrunner_unlock;

if {$status != 0} {
    ::syslog::warn $errmsg;
}

::syslog::msg "Finished qrunner.";
