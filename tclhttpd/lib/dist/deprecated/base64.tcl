# base64.tcl
# Encode/Decode base64 for a string
# Stephen Uhler / Brent Welch (c) 1997 Sun Microsystems
# The decoder was done for exmh by Chris Garrigues
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# SCCS: @(#) base64.tcl 1.4 98/02/24 16:00:03

package provide base64 1.0

set i 0
foreach char {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
	      a b c d e f g h i j k l m n o p q r s t u v w x y z \
	      0 1 2 3 4 5 6 7 8 9 + /} {
    set base64($char) $i
    set base64_en($i) $char
    incr i
}

proc Base64_Encode {string} {
    global base64_en
    set result {}
    set state 0
    set length 0
    foreach {c} [split $string {}] {
	scan $c %c x
	switch [incr state] {
	    1 {	append result $base64_en([expr {($x >>2) & 0x3F}]) }
	    2 { append result \
		$base64_en([expr {(($old << 4) & 0x30) | (($x >> 4) & 0xF)}]) }
	    3 { append result \
		$base64_en([expr {(($old << 2) & 0x3C) | (($x >> 6) & 0x3)}])
		append result $base64_en([expr {($x & 0x3F)}])
		set state 0}
	}
	set old $x
	incr length
	if {$length >= 72} {
	    append result \n
	    set length 0
	}
    }
    set x 0
    switch $state {
	0 { # OK }
	1 { append result $base64_en([expr {(($old << 4) & 0x30)}])== }
	2 { append result $base64_en([expr {(($old << 2) & 0x3C)}])=  }
    }
    return $result
}
proc Base64_Decode {string} {
    global base64

    set output {}
    set group 0
    set j 18
    foreach char [split $string {}] {
	if {[string compare $char \n] == 0} {
	    continue
	}
	if [string compare $char "="] {
	    set bits $base64($char)
	    set group [expr {$group | ($bits << $j)}]
	} else {
	    break
	}

	if {[incr j -6] < 0} {
	    scan [format %06x $group] %2x%2x%2x a b c
	    append output [format %c%c%c $a $b $c]
	    set group 0
	    set j 18
	}
    }
    switch $j {
	-6 { # Even multiple of 4 6-bit chars }
	0 { # One traiing = means one extra byte we don't want
	    scan [format %06x $group] %2x%2x%2x a b c
	    append output [format %c%c $a $b]
	}
	6 { # Two tailing == means two extra bytes we don't want
	    scan [format %06x $group] %2x%2x%2x a b c
	    append output [format %c $a] 
	}
	12 { # Shouldn't happen, go through loop at least twice }
    }
    return $output
}


