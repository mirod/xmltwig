eval "use Test::Pod 1.00";
if( $@) { print "1..1\nok 1\n"; warn "skipping, Test::Pod required\n"; }
else    { all_pod_files_ok( ); }


exit 0;

