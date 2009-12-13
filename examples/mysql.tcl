#!/usr/local/bin/tclsh8.5

set now [expr [clock seconds] -4*3600];

set script {
    use npstats;
    select * from dev_novra_s75 \
	where device_id = 1001 and sample_time > $now;
    quit
}

set f [open "|mysql -b --skip-column-names -h stats.noaaport.net" r+];
puts $f [subst $script];
flush $f;
regsub -all {\t} [string trim [read $f]] "," data;
close $f;
puts $data;
