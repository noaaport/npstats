#!/usr/local/bin/tclsh8.6

set database "novra";
set tablename "novra_s75";

set pnames "id";
set pvals "'noaaportnet.linda'";

set data [split [string trim [exec cat noaaportnet.linda.1247150513.df]] ","];
foreach i $data {
    if {[regexp {(.+)\.([^.=]+)=(.+)} $i match device p v] == 0} {
	puts "Error";
	return 1;
    }
    append pnames "," $p;
    append pvals "," $v;
}

puts $pnames;
puts $pvals;
exit
set insert_script {
    insert into ${tablename}($pnames) values($pvals);
}

set f [open "|sqlite3 $database" "w"];
puts $f [subst -nocommands -nobackslashes $insert_script];
close $f;

#id,time,data_lock,signal_lock,signal_strength,vber_min,vber_max,errors
#insert into novra_s75 values(1247150513,1,1,67,7.10e-06,1.57e-05,0);
