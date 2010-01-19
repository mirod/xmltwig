#!/usr/bin/perl -w
use strict;


use strict;
use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;

use XML::Twig;

my $TMAX=25;
print "1..$TMAX\n";

{ # testing creation of elements in the proper class
  
  package foo; use base 'XML::Twig::Elt'; package main;
  
  my $t= XML::Twig->new( elt_class => "foo")->parse( '<doc><elt/></doc>');
  my $elt= $t->first_elt( 'elt');
  $elt->set_text( 'bar');
  is( $elt->first_child->text, 'bar', "content of element created with set_text");
  is( ref( $elt->first_child), 'foo', "class of element created with set_text");
  $elt->set_content( 'baz');
  is( $elt->first_child->text, 'baz', "content of element created with set_content");
  is( ref( $elt->first_child), 'foo', "class of element created with set_content");
  $elt->insert( 'toto');
  is( $elt->first_child->tag, 'toto', "tag of element created with set_content");
  is( ref( $elt->first_child), 'foo', "class of element created with insert");
  $elt->insert_new_elt( first_child => 'tata');
  is( $elt->first_child->tag, 'tata', "tag of element created with insert_new_elt");
  is( ref( $elt->first_child), 'foo', "class of element created with insert");
  $elt->wrap_in( 'tutu');
  is( $t->root->first_child->tag, 'tutu', "tag of element created with wrap_in");
  is( ref( $t->root->first_child), 'foo', "class of element created with wrap_in");
  $elt->prefix( 'titi');
  is( $elt->first_child->text, 'titi', "content of element created with prefix");
  is( ref( $elt->first_child), 'foo', "class of element created with prefix");
  $elt->suffix( 'foobar');
  is( $elt->last_child->text, 'foobar', "content of element created with suffix");
  is( ref( $elt->last_child), 'foo', "class of element created with suffix");
  $elt->last_child->split_at( 3);
  is( $elt->last_child->text, 'bar', "content of element created with split_at");
  is( ref( $elt->last_child), 'foo', "class of element created with split_at");
  is( ref( $elt->copy), 'foo', "class of element created with copy");

  $t= XML::Twig->new( elt_class => "foo")->parse( '<doc>toto</doc>');
  $t->root->subs_text( qr{(to)} => '&elt( p => $1)');
  is( $t->sprint,  '<doc><p>to</p><p>to</p></doc>', "subs_text result");
  my $result= join( '-', map { join( ":", ref($_), $_->tag) } $t->root->descendants);
  is( $result, "foo:p-foo:#PCDATA-foo:p-foo:#PCDATA", "subs_text classes and tags");
  
}


{ # wrap children with > in attribute
  my $doc=q{<d><e a="1" b="w"/><e a=">2" b="w"/><e b="w" a=">>" c=">"/></d>};
  my $result   =XML::Twig->new->parse( $doc)->root->wrap_children( '<e b="w">+', "w")->strip_att( 'id')->sprint; 
  my $expected = q{<d><w><e a="1" b="w"/><e a=">2" b="w"/><e a=">>" b="w" c=">"/></w></d>};
  is( $result => $expected, "wrap_children with > in attributes");
  $result   =XML::Twig->new->parse( $doc)->root->wrap_children( '<e a="&gt;&gt;">+', "w")->strip_att( 'id')->sprint; 
  $expected = q{<d><e a="1" b="w"/><e a=">2" b="w"/><w><e a=">>" b="w" c=">"/></w></d>};
  is( $result => $expected, "wrap_children with > in attributes, &gt; in condition");
  $result   =XML::Twig->new->parse( $doc)->root->wrap_children( '<e a=">>">+', "w")->strip_att( 'id')->sprint; 
  $expected = q{<d><e a="1" b="w"/><e a=">2" b="w"/><e a=">>" b="w" c=">"/></d>};
  is( $result => $expected, "wrap_children with > in attributes un-escaped > in condition");
  $result   =XML::Twig->new->parse( $doc)->root->wrap_children( '<e b="w" a="1">+', "w")->strip_att( 'id')->sprint; 
  $expected = q{<d><w><e a="1" b="w"/></w><e a=">2" b="w"/><e a=">>" b="w" c=">"/></d>};
  is( $result => $expected, "wrap_children with > in attributes, 2 atts in condition");
  $result   =XML::Twig->new->parse( $doc)->root->wrap_children( '<e b="N" a="1">+', "w")->strip_att( 'id')->sprint; 
  $expected = q{<d><e a="1" b="w"/><e a=">2" b="w"/><e a=">>" b="w" c=">"/></d>};
  is( $result => $expected, "wrap_children with > in attributes, 2 atts in condition (no child matches)");
}

{ # test improvements to wrap_children
  my $doc= q{<doc><elt att="&amp;">ok</elt><elt att="no">NOK</elt></doc>};
  my $expected= q{<doc><w a="&amp;"><elt att="&amp;">ok</elt></w><elt att="no">NOK</elt></doc>};
  my $t= XML::Twig->new->parse( $doc);
  $t->root->wrap_children( '<elt att="&amp;">+', w => { a => "&" });
  $t->root->strip_att( 'id');
  is( $t->sprint, $expected, "wrap_children with &amp;");
}

