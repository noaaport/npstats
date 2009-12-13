#!%TCLSH%
#
# $Id$
#
# Usage: npstatshttpsend <url> <fpath> <sitekey>
#
# Example:
#	 ./npstatshttpsend.tcl "http://caribe:8025/npstats/collect"
#                               noaaportnet.linda.1247150513.df
#                               kakameni
#
package require http;
package require devices;

#
# tcllib has two md5 packages. We would prefer to use version 2.
# But httpd.init in tclhttpd loads md5 version 1, so we will use that
# here as well.
#
package require md5 1;

set usage {npstatshttpsend <url> <fpath> <sitekey>};

proc http_datafile_to_query {fpath sitekey} {

    set deviceid [::devices::get_deviceid_fromfpath $fpath];
    set data  [string trim [exec cat $fpath]];

    #set md5 [::md5::hmac -hex -key $sitekey $data]; # version 2
    set md5 [::md5::hmac $sitekey $data];

    #
    # The query is
    #
    # deviceid = <deviceid>
    # data = <contents of data file>
    # md5 = <md5 hmac of data>
    #
    set q [list deviceid $deviceid];
    lappend q data $data;
    lappend q md5 $md5;

    set query [eval ::http::formatQuery $q];

    return $query;
}

proc http_upload_one {url fpath sitekey} {

    # Check if the url is https
    if {[regexp {^https} $url]} {
        ::http::register https 443 ::tls::socket;
    }
    
    set query [http_datafile_to_query $fpath $sitekey];
    set ht [::http::geturl $url -query $query];

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
        
    if {$status != 0} {
	return -code error $errmsg;
    }

    catch {::http::cleanup $ht};
}

#
# main
#
if {$argc != 3} {
    puts $usage;
    exit 1;
}
set url [lindex $argv 0];
set fpath [lindex $argv 1];
set sitekey [lindex $argv 2];

set status [catch {
    http_upload_one $url $fpath $sitekey;
} errmsg];

if {$status == 0} {
    puts "Uploaded $fpath";
} else {
    puts $errmsg;
}
