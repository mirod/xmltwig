#!/usr/bin/perl
use strict;
use warnings;

if( ! $ENV{TEST_AUTHOR} ) { print "1..1\nok 1\n"; warn "Author test. Set \$ENV{TEST_AUTHOR} to a true value to run.\n"; exit; }

eval { require Test::More; Test::More->import(); };
if( $@) { print "1..1\nok 1\n"; warn "need test::More installed for this test\n"; exit; }

eval { require Test::Kwalitee; Test::Kwalitee->import() };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;


