#!%TCLSH%
#
# $Id$
#
# Usage: npstatsdbplot [-b] [-d outputdir]
#                      [-f fmt] [-F] [-g fmtoptions] [-n 24hperiods]
#                      [-o outputfile] [-s size] [-t deviceid]
#                      <devicetable> <devicetid> [<template>]
#
# If the template is not specified, the data is written to stdout.
#
# Examples:
#           npstatsdbplot novra_s75 1001 novra_s75_vber.g
#           npstatsdbplot -t "wxpronet.novra9020" \
#               -o "wxpronet.novra9020.vber.png" \
#               novra_s75 1004 novra_s75_vber.g
#           npstatsdbplot novra_s75 1001 (outputs the data)
#
# -b => use syslog
# -d => directory for output file
# -f => format  (default "png")
# -F => the template is used as is (instead of looking in std dirs)
# -g => options (default: small background "#d0d0d0")
# -n => 24 hour periods back (default 0 => last 24 hours)
# -o => outputfile name (default "<devicetable>.<devicetid>.<fmt>)
# -s => size (default "0.6,0.6")
# -t => device id (default "<devicetable>.<devicetid>")
#
package require cmdline;

set usage {npstatsdbplot [-b] [-d outputdir]
    [-f fmt] [-F] [-g fmtoptions] [-n 24hperiods]
    [-o outputfile] [-s size] [-t deviceid]
    <devicetable> <devicetid> [<template>]};

set optlist {b {d.arg ""} {f.arg "png"} F {g.arg {small d0d0d0}}
    {n.arg 0} {o.arg ""} {s.arg "0.6,0.6"} {t.arg ""}}; 

#
# Functions
#
proc npstatsdbplot_get_data_mysql {devicetable devicetid} {

    global option;
    global npstatsdbplot;

    set nperiods $option(n);

    set mysqlscript {
	use $npstatsdbplot(mysql,dbname);
	select * from $devicetable where device_id = $devicetid and \
	    sample_time >= $last24_start_secs;
	quit
    }

    set now [clock seconds];
    # set last24_start_secs [expr $now - 24*3600*$nperiods - (23*60 + 59)*60];
    set last24_start_secs [expr $now - 24*3600*($nperiods + 1)]

    set status [catch {
	set f [open "|mysql $npstatsdbplot(mysql,options)" r+];
	puts $f [subst -nobackslashes $mysqlscript];
	flush $f;
	regsub -all {\t} [string trim [read $f]] "," data;
    } errmsg];
    catch {close $f};

    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
	return "";
    }

    return $data;
}

proc npstatsdbplot_find_template {templatename} {

    global npstatsdbplot;

    # Look for it in the main directory, then in the localconfdirs
    # and use the last one found.
    set _tmpl "";
    set subdir $npstatsdbplot(gnuplot_templates_subdir);
    foreach d [concat $npstatsdbplot(confdir) $npstatsdbplot(localconfdirs)] {
        if {[file exists [file join $d $subdir $templatename]]} {
            set _tmpl [file join $d $subdir $templatename];
        }
    }

    return ${_tmpl};
}

proc npstatsdbplot_gnuplot {} {

    global gplot;
    
    set status [catch {
	set f [open "|gnuplot > /dev/null" w];
	puts $f [subst -nobackslashes -nocommands $gplot(script)];
    } errmsg];

    if {$status != 0} {
	::npstats::syslog::warn $errmsg;
    }

    if {[info exists f]} {
	set status [catch {close $f} errmsg];
    }

    # gnuplot sometimes throws a warning. We try to catch it and _not_
    # flag it as an error.
    if {($status != 0) && ([regexp -nocase {warning} $errmsg] == 0)} {
	::npstats::syslog::warn $errmsg;
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
set npstatsdbplot(conf) [file join $common(confdir) "npstatsdbplot.conf"];
set npstatsdbplot(confdir) $common(confdir);
set npstatsdbplot(localconfdirs) $common(localconfdirs);
set npstatsdbplot(gnuplot_templates_subdir) $common(gnuplot_templates_subdir);
#
set npstatsdbplot(mysql,dbname) "npstats";
set npstatsdbplot(mysql,options) "-b --skip-column-names";

if {[file exists $npstatsdbplot(conf)]} {
    source $npstatsdbplot(conf);
}

#
# main
#
array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];

if {$option(b) == 1} {
    ::npstats::syslog::usesyslog;
}

if {($argc < 2) || ($argc > 3)} {
    ::npstats::syslog::warn "Invalid number of arguments";
    ::npstats::syslog::warn $usage;
    return 1;
}

set option(devicetable) [lindex $argv 0];	# mysql table name
set option(devicetid) [lindex $argv 1]
set option(template) "";

if {$argc == 3} {
    set option(template) [lindex $argv 2];
}

if {$option(n) < 0} {    
    ::npstats::syslog::warn "-n argument cannot be negative.";
    return 1;
}

# Get the data first. If no template was specified, output the data and return.
set gplot(data) [npstatsdbplot_get_data_mysql \
		     $option(devicetable) $option(devicetid)];

if {$option(template) eq ""} {
    puts $gplot(data);
    return 0;
}

# If a template was specified and there is no data return an error.
if {$gplot(data) eq ""} {
    ::npstats::syslog::warn "No data.";
    return 1;
}

# The device name (id)
if {$option(t) ne ""} {
    set gplot(deviceid) $option(t);
} else {
    set gplot(deviceid) $option(devicetable).$option(devicetid);
}

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
    set gnuplottemplate [npstatsdbplot_find_template $option(template)];
}
if {($gnuplottemplate eq "") || ([file exists $gnuplottemplate] == 0)} {
    ::npstats::syslog::warn "$option(template) not found.";
    return 1;
}
source $gnuplottemplate;

npstatsdbplot_gnuplot;
