#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 1;

use utf8;

{
XML::Twig::_disallow_use( 'Tie::IxHash');
my $t;
eval { $t= XML::Twig->new( keep_atts_order => 0); };
ok( $t, 'keep_atts_order => 0');
}


exit;



