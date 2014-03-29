#!/usr/bin/perl

use Test::More;
eval 'use Test::CPAN::Changes';
plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.' if ! $ENV{TEST_AUTHOR};
changes_ok(); 
