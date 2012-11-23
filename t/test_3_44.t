#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 5;


{ my $e= XML::Twig::Elt->new( 'foo');
  $e->set_content( { bar => 'baz', toto => 'titi' });
  is( $e->sprint, '<foo bar="baz" toto="titi"/>', 'set_content with just attributes');
}

{ my $e= XML::Twig::Elt->parse( '<d>t</d>');
  $e->set_content( 'x');
  is( $e->sprint, '<d>x</d>', 'set_content on element that contains just text');
  $e->first_child( '#PCDATA')->set_content( 'y');
  is( $e->sprint, '<d>y</d>', 'set_content on text element');
  $e->set_content( XML::Twig::Elt->new( 'e'));
  is( $e->sprint, '<d><e/></d>', 'set_content element on element that contains just text');
  $e->set_content( 'z', XML::Twig::Elt->new( 'e'));
  is( $e->sprint, '<d>z<e/></d>', 'set_content with 2 elements on element that contains just text');
}
