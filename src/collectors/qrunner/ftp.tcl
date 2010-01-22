#
# $Id$
#

# Packages from tcllib
package require ftp;

#
# Initialize ftp package
#
if {$qrunner(ftp,verbose) == 1} {
    set ::ftp::VERBOSE 1;
}
if {$qrunner(ftp,debug) == 1} {
    set ::ftp::DEBUG 1;
}
#
## Redefine ::ftp::DisplayMsg
#
rename ::ftp::DisplayMsg ::ftp::DisplayMsg.orig;
proc ::ftp::DisplayMsg {handle {msg ""} {state ""}} {

    if {$msg ne ""} {
	::npstats::syslog::warn $msg;
    }
}

#
# ftp upload functions
#
proc qrunner_ftp_upload {qfilelist} {

    global qrunner;

    if {$qrunner(ftp,enable) == 0} {
	::npstats::syslog::warn "ftp not enabled.";
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

    #
    # The open command returns -1 if there is an error. The other ::ftp
    # commands return 0 if there is an error, or 1 if successfull.
    #
    set f [::ftp::Open $qrunner(ftp,server) \
	       $qrunner(ftp,user) $qrunner(ftp,passwd) \
	      -mode $qrunner(ftp,mode) -timeout $qrunner(ftp,timeout)];

    if {$f == -1} {
	::npstats::syslog::warn "Cannot connect to $qrunner(ftp,server).";
	return;
    }

    if {[::ftp::Cd $f $qrunner(ftp,uploaddir)] == 0} {
	::npstats::syslog::warn "Cannot cd to remote dir $qrunner(ftp,uploaddir)";
	catch {::ftp::Close $f};
	return;
    }

    foreach qfile $qfilelist {
	set file [file rootname $qfile];
	append file $qrunner(datafext);

	set status [qrunner_ftp_upload_one $f $file];
	if {$status == 0} {
	    set status [qrunner_ftp_upload_one $f $qfile];
	    if {$status != 0} {
		# Ignore any error here
		::ftp::Delete $f $file;
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
    
    ::ftp::Close $f;
}

proc qrunner_ftp_upload_one {f fpath} {
#
# Returns 0 if there is no error, or 1 otherwise.
#
    global qrunner;

    set status 0;

    set status [catch {
	set file_size [file size $fpath];
    } errmsg];
    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
	return 1;
    }

    #
    # ::ftp::Put returns 1 if there are no errors or 0 if there were errors.
    #
    if {[::ftp::Put $f $fpath] == 0} {
	set status 1;
    }

    if {$status == 0} {
	# Instead of checking only that the file was created, we check
	# its size.
	if {[::ftp::FileSize $f [file tail $fpath]] ne $file_size} {
	    set status 1;
	}
    }

    if {$status == 0} {
	if {$qrunner(verbose) == 1} {
	    ::npstats::syslog::msg "Uploaded $fpath.";
	}
    } else {
	::npstats::syslog::warn "Could not upload $fpath.";
    }

    return $status;
}
