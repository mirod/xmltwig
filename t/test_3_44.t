#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 1;


{ my $e= XML::Twig::Elt->new( 'foo');
  $e->set_content( { bar => 'baz', toto => 'titi' });
  is( $e->sprint, '<foo bar="baz" toto="titi"/>', 'set_content with just attributes');
}
