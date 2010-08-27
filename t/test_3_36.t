#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=26;
print "1..$TMAX\n";

{ my $doc=q{<d><s id="s1"><t>title 1</t><s id="s2"><t>title 2</t></s><s id="s3"></s></s><s id="s4"></s></d>};
  my $ids;
  XML::Twig->parse( twig_handlers => { 's[t]' => sub { $ids .= $_->id; } }, $doc);
  is( $ids, 's2s1', 's[t]');
}

{
    my $string = q{<foo>power<baz/><bar></bar></foo>};
    my $t=XML::Twig->parse( $string);
    my $root = $t->root();
    my $copy = $root->copy();
    is( $copy->sprint, $root->sprint, 'empty elements in a copy') 

}

{ my $doc=q{<d><e>e1</e><e>e2</e><e>e3</e><f>f1</f></d>};
  my $t=XML::Twig->parse( $doc);
  my $e1=  $t->first_elt( 'e');
  is( all_text( $e1->siblings),       'e2:e3:f1', 'siblings, all');
  is( all_text( $e1->siblings( 'e')), 'e2:e3',    'siblings(e)');
  is( all_text( $e1->siblings('f')),  'f1',       'siblings(f)');
  my $e2=  $e1->next_sibling( 'e');
  is( all_text( $e2->siblings),       'e1:e3:f1', 'siblings (2cd elt), all');
  is( all_text( $e2->siblings( 'e')), 'e1:e3',    'siblings(e) (2cd elt)');
  is( all_text( $e2->siblings('f')),  'f1',       'siblings(f) (2cd elt)');
  my $f=  $e1->next_sibling( 'f');
  is( all_text( $f->siblings),        'e1:e2:e3', 'siblings (f elt), all');
  is( all_text( $f->siblings( 'e')),  'e1:e2:e3', 'siblings(e) (f elt)');
  is( all_text( $f->siblings('f')),   '',         'siblings(f) (f elt)');

}

{ my $doc= q{<d><e a="foo">bar</e><f a="foo2" a2="toto">bar2</f><f1>ff1</f1></d>};
  my $t= XML::Twig->new( att_accessors => [ 'b', 'a' ], elt_accessors => [ 'x', 'e', 'f' ], field_accessors => [ 'f3', 'f1' ])
                  ->parse( $doc);
  my $d= $t->root;
  is( $d->e->a, 'foo', 'accessors (elt + att)');
  is( $d->f->a, 'foo2', 'accessors (elt + att), on f');
  is( $d->f1, 'ff1', 'field accessor');

  eval { $t->elt_accessors( 'tag'); };
  matches( $@, q{^attempt to redefine existing method tag using elt_accessors }, 'duplicate elt accessor');
  eval { $t->field_accessors( 'tag'); };
  matches( $@, q{^attempt to redefine existing method tag using field_accessors }, 'duplicate elt accessor');

  $t->att_accessors( 'a2');
  is(  $d->f->a2, 'toto', 'accessors created after the parse');
  $t->elt_accessors( 'f');
  $t->att_accessors( 'a2');
  is(  $d->f->a2, 'toto', 'accessors created twice after the parse');
  $t->field_accessors( 'f1');
  is( $d->f1, 'ff1', 'field accessor (created twice)');
}

{ my $doc=q{<d><e id="i1">foo</e><e id="i2">bar</e><e id="i3">vaz<e>toto</e></e></d>};
  my $t= XML::Twig->parse( $doc);
  $t->elt_id( 'i1')->set_outer_xml( '<f id="e1">boh</f>');
  $t->elt_id( 'i3')->set_outer_xml( '<f id="e2"><g att="a">duh</g></f>');
  is( $t->sprint, '<d><f id="e1">boh</f><e id="i2">bar</e><f id="e2"><g att="a">duh</g></f></d>', 'set_outer_xml');
}

{ my $doc= q{<d><e><f/><g/></e></d>};
  my $t= XML::Twig->parse( $doc);
  $t->first_elt( 'e')->cut_children( 'g');
  is( $t->sprint, q{<d><e><f/></e></d>}, "cut_children leaves some children");
}

{ if( $] >= 5.006)
    { my $t= XML::Twig->parse( q{<d><e/></d>});
      $t->first_elt( 'e')->att( 'a')= 'b';
      is( $t->sprint, q{<d><e a="b"/></d>}, 'lvalued attribute (no attributes)');
      $t->first_elt( 'e')->att( 'c')= 'd';
      is( $t->sprint, q{<d><e a="b" c="d"/></d>}, 'lvalued attribute (attributes)');
      $t->first_elt( 'e')->att( 'c')= '';
      is( $t->sprint, q{<d><e a="b" c=""/></d>}, 'lvalued attribute (modifying existing attributes)');
      $t->root->class= 'foo';
      is( $t->sprint, q{<d class="foo"><e a="b" c=""/></d>}, 'lvalued class (new class)');
      $t->root->class=~ s{fo}{tot};
      is( $t->sprint, q{<d class="toto"><e a="b" c=""/></d>}, 'lvalued class (modify class)');
    }
  else
    { skip( 5 => "cannot use lvalued attributes with perl $]"); }
}
  

sub all_text
  { return join ':' => map { $_->text } @_; }

1;
