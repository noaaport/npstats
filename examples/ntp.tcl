#!/usr/local/bin/tclsh8.5

package require udp;
package require time;

set handle [::time::getsntp tropical];
set seconds [::time::unixtime $handle];
set local_seconds [clock seconds];

puts "$seconds $local_seconds";

::time::cleanup $handle;
