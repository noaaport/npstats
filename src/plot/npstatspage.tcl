#!%TCLSH%
#
# $Id$
#
# npstatspage [-b] [-d outputdir] [-h docroot] <deviceid> <template> [yyyymmdd]
#
# -h => gives the (physical) path of the document root of the web server
# -d => gives the output directory relative to docroot. It will then become
#       the url prefix in the web server (see the templates).
# [yyyymmdd] use the given yyyymmdd file instead of the current date
#
# This script grabs the last two lines of the csv file for the device.
# Using the last line it defines the variables
#
# tml(1) ... tml(n)
#
# that contain the current values of the data parameters of the device
# (it excludes the first two fields, i.e. the device numeric id and the time).
#
# In addition it defines the variables
#
# tml(starttime)  - from the last line
# tml(stoptime)   - from the next to last line
# tml(deviceid)   - from the cmd line argument
#
# The template is free to use the tml() variables at will.
#
package require cmdline;

set usage {npstatspage [-b] [-d outputdir] [-h docroot]
    <deviceid> <template> [yyyymmdd]};
set optlist {b {d.arg ""} {h.arg ""}};

#
# Functions
#
proc npstatsplot_get_archive_datafile {} {

    global option;
    global npstatsplot;

    set yyyymmdd $option(date);

    if {$yyyymmdd eq ""} {
	set now [clock seconds];
	set time $now;
	set yyyy [clock format $time -format "%Y" -gmt 1];
	set mm [clock format $time -format "%m" -gmt 1];
	set dd [clock format $time -format "%d" -gmt 1];
	set yyyymmdd ${yyyy}${mm}${dd};
    } else {
	if {[regexp {(\d{4})(\d{2})(\d{2})} $yyyymmdd match yyyy mm dd] \
		== 0} {
	    ::npstats::syslog::err "Invalid date argument $yyyymmdd.";
	    return "";
	}
    }

    set datafile [file join $npstatsplot(csvarchivedir) $option(deviceid) \
		      $yyyy $mm $option(deviceid).${yyyymmdd}];
    append datafile $npstatsplot(csvfext);

    return $datafile;
}

proc npstatsplot_get_archive_data_csv {} {

    global option;
    global npstatsplot;

    set datafile [npstatsplot_get_archive_datafile];

    if {[file exists $datafile] == 0} {
	::npstats::syslog::warn "$datafile not found.";
	return "";
    }

    set status [catch {
	set data [exec cat $datafile];
    } errmsg];

    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
	return "";
    }

    return $data;
}

proc npstatsplot_find_tml_template {templatename} {

    global npstatsplot;

    # Look for it in the main directory, then in the localconfdirs
    # and use the last one found.
    set _tmpl "";
    set subdir $npstatsplot(tml_templates_subdir);
    foreach d [concat $npstatsplot(confdir) $npstatsplot(localconfdirs)] {
        if {[file exists [file join $d $subdir $templatename]]} {
            set _tmpl [file join $d $subdir $templatename];
        }
    }

    return ${_tmpl};
}

## Initialization
# The common defaults
set defaultsfile "/usr/local/etc/npstats/collectors.conf";
if {[file exists $defaultsfile] == 0} {
    puts "$argv0: $defaultsfile not found.";
    return 1;
}
source $defaultsfile;
unset defaultsfile;

# Packages from tcllib
## package require fileutil;
## package require textutil::split;

# Local packages - 
## The errx library. syslog enabled below if -b is given.
package require npstats::errx;

# Configuration
set npstatsplot(conf) [file join $common(confdir) "npstatsplot.conf"];
set npstatsplot(confdir) $common(confdir);
set npstatsplot(localconfdirs) $common(localconfdirs);
set npstatsplot(tml_templates_subdir) $common(tml_templates_subdir);
set npstatsplot(csvarchivedir) $common(csvarchivedir);
set npstatsplot(csvfext) $common(csvfext);

if {[file exists $npstatsplot(conf)]} {
    source $npstatsplot(conf);
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];
if {$argc < 2} {
    puts "device name and template are required.";
    puts $usage;
    return 1;
} elseif {$argc > 3} {
    puts "Too many arguments.";
    puts $usage;
    return 1;
}

if {$option(b) == 1} {
    ::npstats::syslog::usesyslog;
}
set option(deviceid) [lindex $argv 0];
set option(template) [lindex $argv 1];
set option(date) "";
if {$argc == 3} {
    set option(date) [lindex $argv 2];
}

# Variables
set tml(deviceid) $option(deviceid);
set tml(outputdir) $option(d);
set tml(docroot) $option(h);

set data [npstatsplot_get_archive_data_csv];
if {$data eq ""} {
    return 1;
}
set data [split $data "\n"];

if {[llength $data] < 2} {
    return 1;
}
set data0 [lindex $data end];
set data1 [lindex $data end-1];

# The format of the csv archive is <devicetid>,<v1>,<v2>,...,
# and <v1> is the time.
set data0 [lreplace [split $data0 ","] 0 0];
set data1 [lreplace [split $data1 ","] 0 0];

set tml(endtime) [clock format [lindex $data0 0] -gmt 1];
set tml(starttime) [clock format [lindex $data1 0] -gmt 1];

set i 1;
set n [llength $data0];
while {$i <= $n} {
    set tml($i) [lindex $data0 $i];
    incr i;
}

set template [npstatsplot_find_tml_template $option(template)];
if {($template eq "") || ([file exists $template] == 0)} {
    ::npstats::syslog::warn "$option(template) not found.";
    return 1;
}
source $template;

puts [string trim [subst $tml(page)]];
