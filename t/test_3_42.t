#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 3;


{ my $t= XML::Twig->new( twig_handlers => { e => sub { XML::Twig::Elt->parse( '<new/>')->paste( before => $_); } })
                  ->parse('<d><e/></d>');
  is( $t->sprint, '<d><new/><e/></d>', 'elements created with parse are still available once parsing is done');
}

import myElt;

{ my $doc='<d><f><e2>foo</e2><e>e1</e></f><f><e>e2</e><e2>foo</e2></f></d>';
  my $t= XML::Twig->new( elt_class => 'myElt',
                         field_accessors => { e => 'e' },
                         elt_accessors   => { ee => 'e', ef => 'f', },
                       )
                  ->parse( $doc);

  is( join( ':', map { $_->e } $t->root->ef), 'e1:e2', 'elt_accessors with elt_class');
  is( join( ':', map { $_->ee->text } $t->root->children( 'f')), 'e1:e2', 'field_accessors with elt_class');
}

package myElt;
use base 'XML::Twig::Elt';
1;
 
