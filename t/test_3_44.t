#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 38;


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
  $e->set_content( '');
  is( $e->sprint, '<d></d>', 'set_content with empty content');
  $e->set_content( '#EMPTY');
  is( $e->sprint, '<d/>', 'set_content with empty content and #EMPTY');
  $e->set_content( 'x', 'y');
  is( $e->sprint, '<d>xy</d>', 'set_content with 2 strings');
  $e->set_content( '', 'y');
  is( $e->sprint, '<d>y</d>', 'set_content with 2 strings, first one empty');

}

{ my $t= XML::Twig->parse( '<d><s a="1"><e/></s></d>');
  my $s= $t->first_elt( 's');

  $s->att_to_field( 'a');
  is( $s->sprint, '<s><a>1</a><e/></s>', 'att_to_field with default name');
  $s->field_to_att( 'a');
  is( $s->sprint, '<s a="1"><e/></s>', 'field_to_att with default name');

  $s->att_to_field( a => 'b');
  is( $s->sprint, '<s><b>1</b><e/></s>', 'att_to_field with non default name');
  $s->field_to_att( b => 'c');
  is( $s->sprint, '<s c="1"><e/></s>', 'field_to_att with non default name');
}

{ my $t= XML::Twig->parse( '<d>f</d>');
  my $r= $t->root;
  $r->suffix( '&1', 'opt' );
  is( $t->sprint, '<d>f&amp;1</d>', 'suffix, non asis option');
  $r->suffix( '&2', 'asis');
  is( $t->sprint, '<d>f&amp;1&2</d>', 'suffix, asis option');
  $r->suffix( '&3');
  is( $t->sprint, '<d>f&amp;1&2&amp;3</d>', 'suffix, after a suffix with an asis option');
}
{ my $t= XML::Twig->parse( '<d>f</d>');
  $t->root->last_child->suffix( '&1', 'opt' );
  is( $t->sprint, '<d>f&amp;1</d>', 'pcdata suffix, non asis option');
  $t->root->last_child->suffix( '&2', 'asis');
  is( $t->sprint, '<d>f&amp;1&2</d>', 'pcdata suffix, asis option');
  $t->root->last_child->suffix( '&3', 'asis');
  is( $t->sprint, '<d>f&amp;1&2&3</d>', 'pcdata suffix, asis option, after an asis element');
  $t->root->last_child->suffix( '&4');
  is( $t->sprint, '<d>f&amp;1&2&3&amp;4</d>', 'pcdata suffix, after a suffix with an asis option');
}

{ my $t= XML::Twig->parse( '<d>f</d>');
  my $r= $t->root;
  $r->prefix( '&1', 'opt' );
  is( $t->sprint, '<d>&amp;1f</d>', 'prefix, non asis option');
  $r->prefix( '&2', 'asis');
  is( $t->sprint, '<d>&2&amp;1f</d>', 'prefix, asis option');
  $r->prefix( '&3');
  is( $t->sprint, '<d>&amp;3&2&amp;1f</d>', 'prefix, after a prefix with an asis option');
}
{ my $t= XML::Twig->parse( '<d>f</d>');
  $t->root->first_child->prefix( '&1', 'opt' );
  is( $t->sprint, '<d>&amp;1f</d>', 'pcdata prefix, non asis option');
  $t->root->first_child->prefix( '&2', 'asis');
  is( $t->sprint, '<d>&2&amp;1f</d>', 'pcdata prefix, asis option');
  $t->root->first_child->prefix( '&3', 'asis');
  is( $t->sprint, '<d>&3&2&amp;1f</d>', 'pcdata prefix, asis option, before an asis element');
  $t->root->first_child->prefix( '&4');
  is( $t->sprint, '<d>&amp;4&3&2&amp;1f</d>', 'pcdata prefix, after a prefix with an asis option');
}

{ my $weakrefs= XML::Twig::_weakrefs();
  XML::Twig::_set_weakrefs(0);

  my $t= XML::Twig->parse( '<d><e>f</e></d>');
  my $e= $t->first_elt( 'e');
  XML::Twig::Elt->new( x => 'g')->replace( $e);
  is( $t->sprint, '<d><x>g</x></d>', 'replace non root element without weakrefs');
  XML::Twig::Elt->new( y => 'h')->replace( $t->root);
  is( $t->sprint, '<y>h</y>', 'replace root element without weakrefs');

  XML::Twig::_set_weakrefs( $weakrefs);
}

{ my $t= XML::Twig->parse( '<d><p>foo<!--c1--></p><!--c2--><p>bar<!--c3-->baz<!--c4--></p></d>');
  my $r= $t->root;
  is( $r->children_count, 2, '2 p');
  $t->root->first_child->merge( $t->root->last_child);
  is( $r->children_count, 1, 'merged p');
  is( $t->sprint, '<d><p>foo<!--c1--><!--c2-->bar<!--c3-->baz<!--c4--></p></d>', 'merged p with extra data');
}

{ my $t= XML::Twig->parse( '<d><p>foo</p><p>baz<b>bar</b></p></d>');
  my $r= $t->root;
  is( $r->children_count, 2, '2 p, one with mixed content');
  $t->root->first_child->merge( $t->root->last_child);
  is( $r->children_count, 1, 'merged p, one with mixed content');
  is( $t->sprint, '<d><p>foobaz<b>bar</b></p></d>', 'merged p with extra children in the second element');
}

{ my $t= XML::Twig->parse( '<d/>');
  my $r= $t->root;
  $r->insert_new_elt( first_child => '#PCDATA') foreach 0..1;
  is( $r->children_count, 2, '2 empty texts');
  $r->first_child->merge(  $r->last_child);
  is( $r->children_count, 1, 'merged empty texts, number of children');
  is( $t->sprint, '<d></d>', 'merged empty texts');
} 
