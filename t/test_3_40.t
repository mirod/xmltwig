#!/usr/bin/perl -w
use strict;

use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=76;
print "1..$TMAX\n";


{ my $d="<d><title section='1'>title</title><para>p 1</para> <para>p 2</para></d>";
  is( lf_in_t( XML::Twig->parse( pretty_print => 'indented', discard_spaces => 1, $d)), 1, 'space prevents indentation'); 
  is( lf_in_t( XML::Twig->parse( pretty_print => 'indented', discard_all_spaces => 1, $d)), 5, 'discard_all_spaces restores indentation'); 
}

sub lf_in_t
  { my($t)= @_;
    my @lfs= $t->sprint=~ m{\n}g;
    return scalar @lfs;
  }



{ my $d='<d id="d"><t1 id="t1"/><t2 id="t2"/><t3 att="a|b" id="t3-1" /><t3 att="a" id="t3-2" a2="a|b"/><t3 id="t3-3"><t4 id="t4"/></t3></d>';
  my @tests=
    ( [ 't1|t2',                  HN => 't1t2' ],
      [ 't1|t2|t3[@att="a|b"]',   HN => 't1t2t3-1' ],
      [ 't1|t2|t3[@att!="a|b"]',  HN => 't1t2t3-2t3-3' ],
      [ 't1|level(1)',            H  => 't1t1t2t3-1t3-2t3-3' ],
      [ 't1|level(2)',            H  => 't1t4' ],
      [ 't1|_all_',               H  => 't1t1t2t3-1t3-2t4t3-3d'],
      [ qr/t[12]/ . '|t3/t4',     H  => 't1t2t4' ],
      [ 't3[@a2="a|b"]',          HN => 't3-2' ],
      [ 't3[@a2="a|b"]|t3|t3/t4', H => 't3-1t3-2t3-2t4t3-3' ],
   );
  foreach my $test (@tests)
    { my $nb=0;
      my $ids='';
      my( $trigger, $test_cat, $expected_ids)= @$test;
      my $handlers= $test_cat =~ m{H} ?  { $trigger => sub { $ids.=$_->id; 1; } } : {};
      my $t= XML::Twig->new( twig_handlers => $handlers )->parse( $d);
      is( $ids, $expected_ids, "(H) trigger with alt: '$trigger'"); 

      my $uniq_ids= join '', sort $expected_ids=~m{(t\d(?:-\d)?)}g;

      if( $test_cat =~ m{X})
        { (my $xpath= "//$trigger")=~ s{\|t}{|//t}g;
          is( join( '', map { $_->id } $t->findnodes( $xpath)), $uniq_ids, " (X) path with |: '$trigger'"); 
        }

      if( $test_cat =~ m{N})
        { is( join( '', map { $_->id } $t->root->children( $trigger)), $uniq_ids, "(N)navigation with |: '$trigger'"); }
    }

}

{ my $t1= XML::Twig->parse( '<d id="d1"/>');
  is( XML::Twig->active_twig()->root->id, 'd1', 'active_twig, one twig');
  my $t2= XML::Twig->parse( '<d id="d2"/>');
  is( XML::Twig->active_twig()->root->id, 'd2', 'active_twig, second twig');
}

{ eval { XML::Twig->new(error_context => 1)->parse( $0); };
  matches( $@, "you seem to have used the parse method on a filename", 'parse on a file name');
}

{ my $got;
  XML::Twig->parse( twig_handlers => { 'e[@a]' => sub { $got .= $_->id; } }, '<d><e a="a" id="i1"/><e id="i2"/><e a="0" id="i3"/></d>');
  is( $got, 'i1i3', 'bare attribute in handler condition');
}

{ my $doc= q{<!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)><!ENTITY ext SYSTEM "not_there.txt">]><doc>&ext;</doc>};
  ok( XML::Twig->parse( expand_external_ents => -1, $doc), 'failsafe expand_external_ents');
}
  
{ my $t=XML::Twig->parse( q{<doc><e><e1>e11</e1><e2>e21</e2></e><e><e1>e12</e1></e></doc>});
  is( join( ':',  $t->findvalues( [$t->root->children], "./e1")), 'e11:e12', 'findvalues on array');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  $t->set_encoding( "UTF-8");
  is( $t->sprint, qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc/>}, 'set_encoding without XML declaration');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  $t->set_standalone( 1);
  is( $t->sprint, qq{<?xml version="1.0" standalone="yes"?>\n<doc/>}, 'set_standalone (yes) without XML declaration');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  $t->set_standalone( 0);
  is( $t->sprint, qq{<?xml version="1.0" standalone="no"?>\n<doc/>}, 'set_standalone (no) without XML declaration');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  nok( $t->xml_version, 'xml_version with no XML declaration');
  $t->set_xml_version( 1.1);
  is( $t->sprint, qq{<?xml version="1.1"?>\n<doc/>}, 'set_xml_version without XML declaration');
  is( $t->xml_version, 1.1, 'xml_version after being set');
}

{ my $t= XML::Twig->new;
  is( $t->_dump, "document\n", '_dump on an empty twig');
}

{ my $t=XML::Twig->parse( pretty_print => 'none', '<doc><f a="a">foo</f><f a="b">bar</f></doc>');
  $t->root->field_to_att( 'f[@a="b"]', 'g');
  is( $t->sprint, '<doc g="bar"><f a="a">foo</f></doc>', 'field_to_att on non-simple condition');
  $t->root->att_to_field( g => 'gg');
  is( $t->sprint, '<doc><gg>bar</gg><f a="a">foo</f></doc>', 'att_to_field with att != field');
}

{ my $t=XML::Twig->parse( '<root/>');
  $t->root->wrap_in( 'nroot');
  is( $t->sprint, '<nroot><root/></nroot>', 'wrapping the root');
}

{
my $t=XML::Twig->new;
XML::Twig::_set_weakrefs(0);
my $doc='<doc>\n  <e att="a">text</e><e>text <![CDATA[cdata text]]> more text <e>foo</e>\n more</e></doc>';
$t->parse( $doc);
$doc=~ s{\n  }{}; # just the first one
is( $t->sprint, $doc, 'parse with no weakrefs');
$t->root->insert_new_elt( first_child => x => 'text');
$doc=~ s{<doc>}{<doc><x>text</x>};
is( $t->sprint, $doc, 'insert first child with no weakrefs');
$t->root->insert_new_elt( last_child => x => 'text');
$doc=~ s{</doc>}{<x>text</x></doc>};
is( $t->sprint, $doc, 'insert last child with no weakrefs');
XML::Twig::_set_weakrefs(1);
}

{ my $doc= '<d><e a="a" get1="1" id="e1">foo</e><e a="b" id="e2"><e1 id="e11"/>bar</e><e a="b" id="e3"><e2 id="e21"/>bar</e></d>';
  my( $got1, $got2);
  XML::Twig->new( twig_handlers => { e1 => sub { $_->parent->set_att( get1 => 1); },
                                     e2 => sub { $_->parent->set_att( '#get2' => 1); },
                                     '[@get1]'  => sub { $got1 .= 'a' . $_->id; },
                                     '[@#get2]' => sub { $got2 .= 'a' . $_->id; },
                                     'e[@get1]'  => sub { $got1 .= 'b' . $_->id; },
                                     'e[@#get2]' => sub { $got2 .= 'b' . $_->id; },
                                   },
                )
            ->parse( $doc);
  is( $got1, 'be1ae1', 'handler on bare attribute');
  is( $got2, 'be3ae3', 'handler on private (starting with #) bare attribute');
}

{ my $t=XML::Twig->parse( '<foo><e/>foo<!-- comment --></foo>');
  my $root= $t->root;
  ok( $root->closed, 'closed on completely parsed tree'); 
  ok( $root->_extra_data_before_end_tag, '_extra_data_before_end_tag (success)');
  nok( $root->first_child->_extra_data_before_end_tag, '_extra_data_before_end_tag (no data)');
}

{ my $t= XML::Twig->parse( pi => 'process', '<d><?target?></d>');
  is( $t->first_elt( '#PI')->pi_string, '<?target?>', 'pi_string with empty data');
}

{ my $t= XML::Twig->parse( '<d><e class="a" id="e1"/><e class="b" id="e2"/><f class="a" id="f1"/></d>');
  is( ids( $t->root->children( '.a')), 'e1:f1', 'nav on class');
}

{ my $t=XML::Twig->parse( '<doc><e id="e1">foo</e><e id="e2">bar</e><e id="e3">foobar</e><e id="e4"/><n id="n1">1</n><n id="n2">2</n><n id="n3">3</n></doc>');

  is ( ids( $t->root->children( 'e[string()="foo"]')), 'e1', 'navigation condition using string() =');
  is ( ids( $t->root->children( 'e[string()=~/foo/]')), 'e1:e3', 'navigation condition using string() =~');
  is ( ids( $t->root->children( 'e[string()!~/foo/]')), 'e2:e4', 'navigation condition using string() !~');
  is ( ids( $t->root->children( 'e[string()!="foo"]')), 'e2:e3:e4', 'navigation condition using string() !=');
  is ( ids( $t->root->children( 'e[string()]')), 'e1:e2:e3', 'navigation condition using bare string()');

  is ( ids( $t->root->findnodes( './e[string()="foo"]')), 'e1', 'xpath condition using string() =');
  is ( ids( $t->root->findnodes( './e[string()=~/foo/]')), 'e1:e3', 'xpath condition using string() =~');
  is ( ids( $t->root->findnodes( './e[string()!~/foo/]')), 'e2:e4', 'xpath condition using string() !~');
  is ( ids( $t->root->findnodes( './e[string()!="foo"]')), 'e2:e3:e4', 'xpath condition using string() !=');
  is ( ids( $t->root->findnodes( './e[string()]')), 'e1:e2:e3', 'xpath condition using bare string()');

  is( ids( $t->root->children( 'n[string()=2]')), 'n2', 'navigation string() =');
  is( ids( $t->root->children( 'n[string()!=2]')), 'n1:n3', 'navigation string() !=');
  is( ids( $t->root->children( 'n[string()>2]')), 'n3', 'navigation string() >');
  is( ids( $t->root->children( 'n[string()>=2]')), 'n2:n3', 'navigation string() >=');
  is( ids( $t->root->children( 'n[string()<2]')), 'n1', 'navigation string() <');

  is( ids( $t->root->findnodes( './n[string()=2]')), 'n2', 'xpath string() =');
  is( ids( $t->root->findnodes( './n[string()!=2]')), 'n1:n3', 'xpath string() !=');
  is( ids( $t->root->findnodes( './n[string()>2]')), 'n3', 'xpath string() >');
  is( ids( $t->root->findnodes( './n[string()>=2]')), 'n2:n3', 'xpath string() >=');
  is( ids( $t->root->findnodes( './n[string()<2]')), 'n1', 'xpath string() <');
  is( ids( $t->root->findnodes( './n[string()<=2]')), 'n1:n2', 'xpath string() <=');
}

{ my $got;
  my $t=XML::Twig->parse( twig_handlers => { d => sub { $got .="wrong"; },
                                             'd[@id]' => sub { $got .= "ok"; 0 },
                                           },
                          '<d id="i1"/>'
                        );
  is( $got, 'ok', 'returning 0 prevents the next handler to be called');
} 

{ my $d=q{<html><head><title>foo</title><script><![CDATA[ a> b]]></script></head><body id="b1"><!-- test --><p>foo<b>blank</b></p><hr /><div /></body></html>};
  my $expected=qq{<html>\n  <head>\n    <title>foo</title>\n    <script><![CDATA[ a> b]]></script></head>\n  <body id="b1"><!-- test -->\n    <p>foo<b>blank</b></p>\n    <hr />\n    <div /></body></html>};
  XML::Twig::_indent_xhtml( \$d);
  is( $d, $expected, '_indent_xhtml');
}

{ my $d='<d><e a="a" b="b">c</e></d>';
  my @handlers= ( '/d/e[@a="a" or @b="b"]',
                  '/d/e[@a="a" or @b="c"]|e',
                  '/d/e[@a="a"]',
                  '/d/e[@b="b"]',
                  '/d/e',
                  'd/e[@a="a" and @b="b"]',
                  'd/e[@a="a"]',
                  'd/e[@b="b"]',
                  'd/e',
                  'e[@a="a" or @b="b"]',
                  'e[@b="b" or @a="a"]',
                  'e[@a="a"]|f',
                  'e[@b="b"]',
                  'e',
                  qr/e|f/,
                  qr/e|f|g/,
                  'level(1)',
                );
my $got;
my $i=1;
XML::Twig->parse( twig_handlers => { map { $_ => sub { $got .= $i++; } } @handlers } , $d);
my $expected= join '', (1..@handlers);
  is( $got, $expected, 'handler order');
}

{ my $t=XML::Twig->parse( "<d/>");
  $t->{twig_dtd}="<!ELEMENT d EMPTY>";
  is( $t->doctype(UpdateDTD => 1), "<!ELEMENT d EMPTY>\n", 'doctype with an updated DTD');
}

{ my $t=XML::Twig->parse( '<d><e id="e1"/><e id="e2"><se id="se1"/><se a="1" id="se2"/></e></d>');
  $t->elt_accessors( 'e', 'e');
  $t->elt_accessors( { e2 => 'e[2]', se => 'se', sea => 'se[@a]' });
  my $root= $t->root;
  is( $root->e->id, 'e1', 'accessor, no alias, scalar context');
  my $e2= ($root->e)[-1];
  is( $e2->id, 'e2', 'accessor no alias, list context');
  my $e2= $root->e2;
  is( $e2->id, 'e2', 'accessor alias, list context');
  is( $e2->se->id, 'se1',  'accessor alias, scalar context');
  is( $e2->sea->id, 'se2',  'accessor, with complex step, alias, scalar context');
}
{ my $t=XML::Twig->new( elt_accessors => [ 'e', 'se' ])
                 ->parse( '<d><e id="e1"/><e id="e2"><se id="se1"/><se a="1" id="se2"/></e></d>');
  my $root= $t->root;
  is( $root->e->id, 'e1', 'accessor (created in new), no alias, scalar context');
  my $se= ($root->e)[-1]->se;
  is( $se->id, 'se1', 'accessor (created in new) no alias, scalar context, 2');
}

{ my $t=XML::Twig->new( elt_accessors =>  { e2 => 'e[2]', se => 'se', sea => 'se[@a]' })
                 ->parse( '<d><e id="e1"/><e id="e2"><se id="se1"/><se a="1" id="se2"/></e></d>');
  my $e2= $t->root->e2;
  is( $e2->id, 'e2', 'accessor (created in new) alias, list context');
  is( $e2->se->id, 'se1',  'accessor (created in new) alias, scalar context');
  is( $e2->sea->id, 'se2',  'accessor (created in new), with complex step, alias, scalar context');
}

