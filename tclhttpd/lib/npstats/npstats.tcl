#
# $Id$
#

#
# Not used with the template system
# Direct_Url /npstats npstats
#

package require html

proc npstats/main {} {

    global Config;

    set result [npstats/status/display_main_device];

    return $result
}

proc npstats/printconf {} {
#
# Print current npstatsd configuration.
#
    set result "<h3>Configuration parameters</h3>\n";

    append result [display_config];

    return $result;
}
