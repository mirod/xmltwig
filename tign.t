#!/usr/bin/perl -w
use strict;
 
use XML::Twig;
use Test::More;

{ 
  # testing ignore on a non-current element
  my $calls='';
  my $t2= XML::Twig->new( 
                          start_tag_handlers => { d     => sub { $_[1]->parent->ignore } }
                       )
                   ->parse( q{<a><f><b><c/><d/><e/></b></f><f><b><c/><d/><e/></b></f></a>})
                  ;
  is( $t2->sprint, '<a><f/><f/></a>', 'tree build with ignore on the parent of an element');
  
}

done_testing();


