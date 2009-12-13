#!/usr/local/bin/tclsh8.5

set now [expr [clock seconds] - 2*3600];

set host "stats.noaaport.net";

set options [list -B --skip-column-names -h $host wxpro_npstats];

set script {
    select * from dev_novra_s75 \
	where device_id = 1001 and sample_time > $now;
    quit
}

# select device_id from device where device_name='linda' \
# and site_id = (select site_id from site where site_name = 'noaaportnet');

set _type {select device_type from device where \
    device_name='linda' \
    and site_id = (select site_id from site where site_name = 'noaaportnet')}

set _id {select device_id from device where device_name='atom' \
    and site_id = (select site_id from site where site_name = 'noaaportnet')}

set script1 {
    use wxpro_npstats;
    select * from dev_nbsp where device_id = (${_id});
    quit
}

set script2 {
    use wxpro_npstats;
    ${_type};
    quit
}


set cmd [concat mysql $options];

set f [open "|$cmd" r+];
puts $f [subst $script1];
flush $f;
set data [string trim [read $f]];
close $f;

if {$data ne ""} {
    regsub -all {\t} $data "," data;
    puts $data;
} else {
    puts "No data";
}
