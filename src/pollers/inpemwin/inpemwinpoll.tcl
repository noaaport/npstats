#!%TCLSH%
#
# $Id$
#
# device_type = inpemwin
# device_name = iemwinnet.1pool
# 
set usage {iemwin-poll <server_poll_id>};

set url_domain {pool.iemwin.net:8016/_iemwin/stats};

if {$argc != 1} {
    puts $usage;
    exit 1;
}
set server_poll_id [lindex $argv 0];

set data [exec wget -q -O - http://${server_poll_id}.${url_domain}];
set data_parts [split $data ";"];

foreach part $data_parts {
    set part_list [split [string trim $part] "="];
    set key [lindex $part_list 0];
    set a($key) [lindex $part_list 1];
}

# current_time,
# npemwind_start_time, num_clients,
# upstream_data
#
# where
#
# upstream_data = ip, port,
#		  (intmax_t)es->stats.connect, 
#		  (intmax_t)es->stats.disconnect, 
#		  es->stats.consecutive_packets, 
#		  es->stats.max_packets,
#		  es->stats.total_packets, 
#		  es->stats.bad_packet_count, 
#		  es->stats.connections, 
#		  es->stats.error,
#		  es->stats.serverread_errors,
#		  es->stats.serverclosed_errors,
#		  es->stats.header_errors,
#		  es->stats.checksum_errors,
#		  es->stats.filename_errors,
#		  es->stats.unknown_errors
#
set result [list];
#set result [concat [list [clock seconds] $a(start_time) $a(num_clients)] \
#		[split $a(upstream_master)]];
set result [concat [list [clock seconds] $a(start_time) $a(num_clients)] \
		[split [lrange $a(upstream_master) 0 4]]];

puts [join $result ","];
