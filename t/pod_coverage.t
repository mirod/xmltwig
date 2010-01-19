#!/usr/bin/perl
use strict;
use warnings;

if( ! $ENV{TEST_AUTHOR} ) { print "1..1\nok 1\n"; warn "Author test. Set \$ENV{TEST_AUTHOR} to a true value to run.\n"; exit; }

eval "use Test::Pod::Coverage 1.00 tests => 1";
if( $@)
  { print "1..1\nok 1\n";
    warn "Test::Pod::Coverage 1.00 required for testing POD coverage";
    exit;
  }

pod_coverage_ok( "XML::Twig", { trustme => [ 'isa' ] });
