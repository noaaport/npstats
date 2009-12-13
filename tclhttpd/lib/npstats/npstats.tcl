#
# $Id$
#
Direct_Url /npstats npstats

package require html

proc npstats {} {

    global Config;

    set result [npstats/status/display_main_device];

    return $result
}

proc npstats/printconf {} {
#
# Print current npstatsd configuration.
#
    set result "<h1>Configuration parameters</h1>\n";

    append result [display_config];

    return $result;
}
