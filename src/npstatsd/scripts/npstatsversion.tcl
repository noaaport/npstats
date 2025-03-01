#!%TCLSH%
#
# $Id$

set pkgname "npstats";

if {[file executable "/usr/sbin/pkg"]} {
    set output [exec pkg info ${pkgname} | grep Version];
    set version [string trim [lindex [split $output] end]];
} elseif {[file executable "/usr/bin/dpkg"]} {
    set output [exec dpkg -s ${pkgname} | grep -m 1 "Version"];
    set version [string trim [lindex [split $output] 1]];
} elseif {[file executable "/bin/rpm"]} {
    set output [exec rpm -qa | grep "${pkgname}-"];
    regexp ${pkgname}-(.+) $output match version;
} else {
    set version "unknown";
}

puts $version;
