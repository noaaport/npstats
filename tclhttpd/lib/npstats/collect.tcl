#
# $Id$
#
Direct_Url /npstats/collect npstats/collect

# This module requires md5 from tcllib. But httpd.init already loads
# version 1, so we will use that not just here, but also in the client
# qrunner.

package require html;
package require fileutil;
package require textutil::split;

#
# The (local) spooler and monitor packages
#
package require spooler;
package require monitor;
package require devices;	# get_devicesite function
#
if {$Config(collect,spooler_enable) != 0} {
    ::spooler::init $Config(collect,spooler);
    Httpd_RegisterShutdown ::spooler::disconnect;

    set r [::spooler::connect];
    if {$r ne ""} {
        Stderr $r;
    }
}

if {$Config(collect,monitor_enable) != 0} {
    ::monitor::init $Config(collect,monitor);
    Httpd_RegisterShutdown ::monitor::disconnect;

    set r [::monitor::connect];
    if {$r ne ""} {
	Stderr $r;
    }
}

# This is a global array variable, used only by the functions in this file
#
#   npstats_collect(sitekeys,<site>)
#
if {[file exists $Config(collect,sitekeys_file)]} {
    foreach line [split [::fileutil::cat $Config(collect,sitekeys_file)] \
		      "\n"] {

	if {[regexp {^#|^\s+$} $line]} {
	    continue;
	}
	     
	foreach {site key} [::textutil::split::splitx $line] {
	    set npstats_collect(sitekeys,$site) $key;
	}
    }
}

proc npstats/collect {args} {

    global Config;
    global npstats_collect;

    if {[llength args] == 0} {
	Httpd_Error [Httpd_CurrentSocket] 500 "Empty data.";
    }

    # From the qrunner/http.tcl file, what we get here is:
    #
    # deviceid = <deviceid>  (<site>.<name>)
    # data = <contents of data file>
    # md5 = <md5 hmac of data>

    set deviceid "";
    set data ""
    set md5 "";
    foreach {name value} $args {
	if {$name eq "deviceid"} {
	    set deviceid $value;       # deviceid here is <site>.<device_name>
	} elseif {$name eq "data"} {
	    set data $value;
	} elseif {$name eq "md5"} {
	    set md5 $value;
	}
    }
    if {($deviceid eq "") || ($data eq "") || ($md5 eq "")} {
	Httpd_Error [Httpd_CurrentSocket] 500 "Invalid data.";
    }

    #
    # Do authentication based on site and sitekey.
    # 
    set site [::devices::get_devicesite $deviceid];
    if {[info exists npstats_collect(sitekeys,$site)] == 0} {
	Httpd_Error [Httpd_CurrentSocket] 401 "Unauthorized";
    }
    set sitekey $npstats_collect(sitekeys,$site);

    #
    # With md5 version 2, the syntax is
    #
    # set md5check [::md5::hmac -hex $sitekey $data];
    #
    # But httpd.init loads md5 version 1, and so we are using that
    # in the client qrunner and therefore we use it here as well.
    #
    set md5check [::md5::hmac $sitekey $data];

    if {$md5 ne $md5check} {
	Httpd_Error [Httpd_CurrentSocket] 401 "Unauthorized";
    }

    # The <data> is a data_pack (from devices.tcl), which is precisely
    # what the spooler and monitor expect.

    if {$Config(collect,spooler_enable) != 0} {
	set errmsg [_npstats_collect_send_spooler $data];
	if {$errmsg ne ""} {
	    Httpd_Error [Httpd_CurrentSocket] 500 "Server returned: $errmsg";
	}
    }

    if {$Config(collect,monitor_enable) != 0} {
	set errmsg [_npstats_collect_send_monitor $data];
	if {$errmsg ne ""} {
	    Httpd_Error [Httpd_CurrentSocket] 500 "Server returned: $errmsg";
	}
    }

    return "";
}

proc _npstats_collect_send_spooler {pdata} {

    set r [::spooler::send_output $pdata];
    if {$r ne ""} {
        Stderr $r;
    }

    return $r;
}

proc _npstats_collect_send_monitor {pdata} {

    set r [::monitor::send_output $pdata];

    if {$r ne ""} {
        Stderr $r;
    }

    return $r;
}
