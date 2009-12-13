#
# $Id$
#

proc proc_fmtrow {n} {

    set fmt "<tr>"
    set i 1
    while {$i <= $n} {
	append fmt "<td>%s</td>"
	incr i
    }
    append fmt "</tr>\n"
    
    return $fmt
}

proc display_config {} {

    set fmt [proc_fmtrow 2];

    append result "<table border>\n";

    append result [format $fmt "Package version" [exec npstatsversion]];
    foreach line [split [exec npstatsd -C 2> /dev/null] "\n"] {
	set parts [split $line];
        set p [lindex $parts 0];
        set v [join [lreplace $parts 0 0] " "];
        append result [format $fmt $p $v];
    }

    append result "</table>\n";
}
