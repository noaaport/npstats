#
# $Id$
#

package require npstats::sftp;

# Initialize the sftp package
::npstats::sftp::init $qrunner(sftp,user) $qrunner(sftp,host);

#
# sftp upload functions
#
proc qrunner_sftp_upload {qfilelist} {

    global qrunner;

    if {$qrunner(sftp,enable) == 0} {
	::npstats::syslog::warn "sftp not enabled.";
	return;
    }

    if {[llength $qfilelist] == 0} {
	if {$qrunner(verbose) == 1} {
	    ::npstats::syslog::warn "Nothing to transfer.";
	}
	return;
    }

    if {$qrunner(verbose) == 1} {
	qrunner_log_qfilelist $qfilelist;
    }

    foreach qfile $qfilelist {
	set file [file rootname $qfile];
	append file $qrunner(datafext);

	set status [qrunner_sftp_upload_one $file];
	if {$status == 0} {
	    set status [qrunner_sftp_upload_one $qfile];
	    if {$status != 0} {
		# Ignore any error here
		catch {::npstats::sftp:rm $file};
	    }
	}

	if {$status != 0} {
	    ::npstats::syslog::warn "$file and $qfile scheduled for retransmission.";
	    break;
	}
	
	if {$qrunner(savesent) == 0} {
	    file delete $qfile;
	    file delete $file;
	} else {
	    set status [catch {
		file rename -force $file $qfile $qrunner(sentdir);
	    } errmsg];
	    if {$status != 0} {
		::npstats::syslog::warn $errmsg;
	    }
	}
    }
}

proc qrunner_sftp_upload_one {fpath} {
#
# Returns 0 if there is no error, or 1 otherwise.
#
    global qrunner;

    set status [catch {
	::npstats::sftp::put $fpath;
    } errmsg];
    
    if {$status == 0} {
	if {$qrunner(verbose) == 1} {
	    ::npstats::syslog::msg "Uploaded $fpath.";
	}
    } else {
	::npstats::syslog::warn "Could not upload $fpath: $errmsg";
    }

    return $status;
}
