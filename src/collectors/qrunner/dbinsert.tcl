#
# $Id$
#
package require npstats::db;	# local package

# Initialize the db package
::npstats::db::init $qrunner(dbinsert,cmd) $qrunner(dbinsert,cmdoptions);

#
# upload functions
#
proc qrunner_dbinsert_upload {qfilelist} {

    global qrunner;

    if {$qrunner(dbinsert,enable) == 0} {
	::npstats::syslog::warn "dbinsert method not enabled.";
	return;
    }

    if {[llength $qfilelist] == 0} {
	if {$qrunner(verbose) == 1} {
	    ::npstats::syslog::warn "Nothing to transfer.";
	}
	return;
    }

    set status [catch {
	::npstats::db::connect;
    } errmsg];
    if {$status != 0} {
	::npstats::syslog::warn "Cannot connect to db: $errmsg";
	return;
    }

    if {$qrunner(verbose) == 1} {
	qrunner_log_qfilelist $qfilelist;
    }

    foreach qfile $qfilelist {
	set file [file rootname $qfile];
	append file $qrunner(datafext);

	set dbinsert_status [qrunner_dbinsert_upload_one $file];
	if {$dbinsert_status != 0} {
	    break;
	}
    }

    if {[catch {::npstats::db::disconnect} errmsg]} {
	::npstats::syslog::warn $errmsg;
	set dbinsert_status 1;
    }

    # Clean up
    foreach qfile $qfilelist {
	set file [file rootname $qfile];
	append file $qrunner(datafext);

	if {$dbinsert_status != 0} {
	    ::npstats::syslog::warn \
		"Rescheduling $file and $qfile for uploading.";
	    continue;
	}
	
	if {$qrunner(savesent) == 0} {
	    file delete $qfile;
	    file delete $file;
	} else {
	    if {[catch {
		file rename -force $file $qfile $qrunner(sentdir);
	    } errmsg] != 0} {
		::npstats::syslog::warn $errmsg;
	    }
	}
    }
}

proc qrunner_dbinsert_upload_one {fpath} {
#
# Returns 0 if there is no error, or 1 otherwise.
#
    global qrunner;

    set status [catch {
	foreach {id pnames pvalues} [dbinsert_datafile_to_values $fpath] {
	    break;
	}
	set dbtable [qrunner_get_dbtable_fromid $id];
	::npstats::db::send_insert $dbtable $pnames $pvalues;
    } errmsg];

    if {$status == 0} {
	if {$qrunner(verbose) == 1} {
	    ::npstats::syslog::msg "Uploading $fpath.";
	}
    } else {
	::npstats::syslog::warn "Could not upload $fpath: $errmsg";
    }

    return $status;
}

proc dbinsert_datafile_to_values {fpath} {
#
# Returns three elements as a list: the deviceid (<site>.<name>)
# pnames and pvalues. The latter two contain the comma-separated
# parameter names and values.
#
    global qrunner;

    set deviceid [::npstats::devices::get_deviceid_fromfpath $fpath];
    set devicenumber [qrunner_get_number_fromid $deviceid];
    if {$devicenumber eq ""} {
	return -code error "Device unconfigured: $deviceid";
    }

    #
    # From devices.def, the first column in the table is the "devicenumber".
    #
    set pnames [join [qrunner_get_dbcols_fromid $deviceid] ","];
    set pvalues $devicenumber;

    # The contents of the file is a "pdata" (from devices.tcl)
    set pdata [string trim [::fileutil::cat $fpath]];
    set pdatalist [::npstats::devices::data_unpack $pdata];
    set output [::npstats::devices::data_unpack_output $pdatalist];

    append pvalues "," $output;

    return [list $deviceid $pnames $pvalues];
}
