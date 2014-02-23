#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 1;

is( XML::Twig->new( keep_encoding => 1)->parse( q{<d a='"foo'/>})->sprint, q{<d a="&quot;foo"/>}, "quote in att with keep_encoding");

exit;



