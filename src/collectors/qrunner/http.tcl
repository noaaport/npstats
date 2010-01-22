#
# $Id$
#

#
# tcllib has two md5 packages. We would prefer to use version 2.
# But httpd.init in tclhttpd loads md5 version 1, so we will use that
# here as well. An alternative is to use sha1 (in both tclhttpd
# and here).
#
package require http;
package require md5 1;

#
# http
#
proc qrunner_http_upload {qfilelist} {

    global qrunner;

    if {$qrunner(http,enable) == 0} {
	::npstats::syslog::warn "http not enabled.";
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

	set status [qrunner_http_upload_one $file];

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

proc qrunner_http_upload_one {fpath} {
#
# Returns 0 if there is no error, or 1 otherwise.
#
    global qrunner;

    # Check if the url is https (httpd disabled)
    if {[regexp {^https} $qrunner(http,url)]} {
	::http::register https 443 ::tls::socket;
    }

    set status [catch {
	set query [http_datafile_to_query $fpath $qrunner(http,sitekey)];
	set ht [::http::geturl $qrunner(http,url) -query $query];
    } errmsg];

    if {$status != 0} {
	# Should not call "::http::cleanup $ht" here.
	::npstats::syslog::warn "Could not upload $fpath: $errmsg";
	return 1;
    }

    set status [::http::status $ht];
    if {$status eq "ok"} {
	set ncode [::http::ncode $ht];
	if {$ncode != 200} {
	    set status 1;
	    set errmsg [::http::code $ht];
	} else {
	    set status 0;
	}
    } elseif {$status eq "eof"} {
	set status 1;
	set errmsg "No reply received from server.";
    } else {
	set status 1;
	set errmsg [::http::error $ht];
    }
	
    if {$status == 0} {
	if {$qrunner(verbose) == 1} {
	    ::npstats::syslog::msg "Uploaded $fpath.";
	}
    } else {
	::npstats::syslog::warn $errmsg;
    }

    if {[catch {::http::cleanup $ht} errmsg]} {
	::npstats::syslog::warn $errmsg;
    }

    return $status;
}

proc http_datafile_to_query {fpath sitekey} {

    set deviceid [::npstats::devices::get_deviceid_fromfpath $fpath];
    set data [string trim [::fileutil::cat $fpath]];

    #
    # This is the syntax in md5 version 2
    #
    # set md5 [::md5::hmac -hex -key $sitekey $data];
    #
    # As explained at the top of the file, we use version 1.
    #
    set md5 [::md5::hmac $sitekey $data];

    #
    # The query is
    #
    # deviceid = <deviceid>
    # data = <contents of data file>  (the data file contains a data_pack)
    # md5 = <md5 hmac of data>
    #
    set q [list deviceid $deviceid];
    lappend q data $data;
    lappend q md5 $md5;

    set query [eval ::http::formatQuery $q];

    return $query;
}
