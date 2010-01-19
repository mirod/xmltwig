#!/usr/bin/perl
use strict;
use warnings;

if( ! $ENV{TEST_AUTHOR} ) { print "1..1\nok 1\n"; warn "Author test. Set \$ENV{TEST_AUTHOR} to a true value to run.\n"; exit; }

eval "use Test::Pod 1.00";
if( $@) { print "1..1\nok 1\n"; warn "skipping, Test::Pod required\n"; }
else    { all_pod_files_ok( ); }


exit 0;

