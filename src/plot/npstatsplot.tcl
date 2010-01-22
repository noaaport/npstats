#!%TCLSH%
#
# $Id$
#
# Usage: npstatsplot [-b] [-d outputdir] [-D datafile]
#                    [-f fmt] [-F] [-g fmtoptions]
#                    [-n days_back | -y yyyymmdd]
#                    [-o outputfile] [-s size]
#                    <deviceid> [<template>]
#
# If the <template> is not given, then the data is output to stdout.
#
# Examples:
#           npstatsplot linda.noaaportnet novra_s75_vber.g
#           npstatsplot -o "wxpronet.novra9020.vber.png" \
#                       novra9020.wxpronet novra_s75_vber.g
#           npstatsplot linda.noaaportnet (output the data to stdout)
#
# -b => use syslog
# -d => directory for output file
# -D => use the given datafile instead of the archive
# -f => format  (default "png")
# -F => the template is used as is (instead of looking in std dirs)
# -g => options (default "small xd0d0d0")
# -n => default n = 0 (today); n = 1 is yesterday, etc.
# -o => outputfile name (default "<devtype>_<devid>.<fmt>)
# -s => size (default "0.6,0.6")
# -y => the day yyyymmdd (conflicts with -n)
#
package require cmdline;

set usage {npstatsplot [-b] [-d outputdir] [-D datafile]
    [-f fmt] [-F] [-g fmtoptions] [-n days_back | -y yyyymmdd]
    [-o outputfile] [-s size] [-y yyyymmdd]
    <deviceid> [<template>]};

set optlist {b {d.arg ""} {D.arg ""} {f.arg "png"} F {g.arg "small xd0d0d0"}
    {n.arg 0} {o.arg ""} {s.arg "0.6,0.6"} {y.arg ""}}; 

#
# Functions
#
proc npstatsplot_verify_option_conflicts {} {

    global option;

    set conflict_ny 0;

    if {$option(n) ne ""} {
	incr conflict_ny;
    }

    if {$option(y) ne ""} {
	incr conflict_ny;
    }

    if {$conflict_ny > 1} {
	::npstats::syslog::warn "Options -n,-y conflict.";
	return 1;
    }

    if {$option(n) < 0} {    
	::npstats::syslog::warn "-n argument must be positive.";
	return 1;
    }

    return 0;
}

proc npstatsplot_get_archive_datafile {} {

    global option;
    global npstatsplot;

    if {$option(y) ne ""} {
	if {[regsub {(\d{4})(\d{2})(\d{2})} $option(y) \
		 match yyyy mm dd] == 0} {
	    ::npstats::syslog::warn "Invalid yyyymmdd.";
	    return "";
	}
    } else {
	set now [clock seconds];
	if {$option(n) != 0} {
	    set time [expr $now - 24*3600*$option(n)];
	} else {
	    set time $now;
	}
	set yyyy [clock format $time -format "%Y" -gmt 1];
	set mm [clock format $time -format "%m" -gmt 1];
	set dd [clock format $time -format "%d" -gmt 1];
	set yyyymmdd ${yyyy}${mm}${dd};
    }

    set datafile [file join $npstatsplot(csvarchivedir) $option(deviceid) \
		      $yyyy $mm $option(deviceid).${yyyymmdd}];
    append datafile $npstatsplot(csvfext);

    return $datafile;
}

proc npstatsplot_get_data_csv {} {

    global option;
    global npstatsplot;

    if {$option(D) ne ""} {
	set datafile $option(D);
    } else {
	set datafile [npstatsplot_get_archive_datafile];
    }

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

proc npstatsplot_find_template {templatename} {

    global npstatsplot;

    # Look for it in the main directory, then in the localconfdirs
    # and use the last one found.
    set _tmpl "";
    set subdir $npstatsplot(gnuplot_templates_subdir);
    foreach d [concat $npstatsplot(confdir) $npstatsplot(localconfdirs)] {
        if {[file exists [file join $d $subdir $templatename]]} {
            set _tmpl [file join $d $subdir $templatename];
        }
    }

    return ${_tmpl};
}

proc npstatsplot_gnuplot {} {

    global gplot;
    
    set status [catch {
	set f [open "|gnuplot > /dev/null" w];
	puts $f [subst -nobackslashes -nocommands $gplot(script)];
    } errmsg];

    if {$status != 0} {
	puts $errmsg;
    }

    if {[info exists f]} {
	set status [catch {close $f} errmsg];
    }

    # gnuplot sometimes throws a warning. We try to catch it and _not_
    # flag it as an error.
    if {($status != 0) && ([regexp -nocase {warning} $errmsg] == 0)} {
	puts $errmsg;
	return 1;
    }
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
set npstatsplot(confdir) $common(confdir);
set npstatsplot(localconfdirs) $common(localconfdirs);
set npstatsplot(gnuplot_templates_subdir) $common(gnuplot_templates_subdir);
set npstatsplot(csvarchivedir) $common(csvarchivedir);
set npstatsplot(csvfext) $common(csvfext);
# Optional configuration file
set npstatsplot(conf) [file join $common(confdir) "npstatsplot.conf"];

if {[file exists $npstatsplot(conf)]} {
    source $npstatsplot(conf);
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];
if {[npstatsplot_verify_option_conflicts] != 0} {
    return 1;
}

if {$option(b) == 1} {
    ::npstats::syslog::usesyslog;
}

if {($argc == 0) || ($argc > 2)} {
    ::npstats::syslog::warn "Invalid number of arguments.";
    ::npstats::syslog::warn $usage;
    return 1;
}
set option(deviceid) [lindex $argv 0];
set option(template) "";
if {$argc == 2} {
    set option(template) [lindex $argv 1];
}

# Get the data first. If no template was specified, output the data and return.
set gplot(data) [npstatsplot_get_data_csv];

if {$option(template) eq ""} {
    puts $gplot(data);
    return 0;
}

# If a template was specified and there is no data return an error.
if {$gplot(data) eq ""} {
    ::npstats::syslog::warn "No data.";
    return 1;
}

# The device name
set gplot(deviceid) $option(deviceid);

# Default output file and data file
set gplot(output) $gplot(deviceid).$option(f);
if {$option(o) ne ""} {
    set gplot(output) $option(o);
}
if {$option(d) ne ""} {
    set gplot(output) [file join $option(d) $gplot(output)];
}

set gplot(fmt) $option(f);
set gplot(fmtoptions) $option(g);
set gplot(size) $option(s);

if {$option(F) == 1} {
    set gnuplottemplate $option(template);
} else {
    set gnuplottemplate [npstatsplot_find_template $option(template)];
}
if {($gnuplottemplate eq "") || ([file exists $gnuplottemplate] == 0)} {
    ::npstats::syslog::warn "$option(template) not found.";
    return 1;
}
source $gnuplottemplate;

npstatsplot_gnuplot;
