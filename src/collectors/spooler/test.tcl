#!/usr/local/bin/tclsh8.6

set pdata \
    "noaaportnet.linda|1001|novra_s75|1248924150,1,1,67,4.42e-03,4.98e-03,6"

set f [open "|/usr/local/libexec/npstats/spooler" w];
set i 0;
while {$i <= 5} {
    puts $f $pdata;
    incr i;
}

close $f;
