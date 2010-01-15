#!/usr/bin/perl -w
use strict;

# $Id: /xmltwig/trunk/t/test_3_30.t 27 2007-08-30T08:07:25.079327Z mrodrigu  $

use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=57;
print "1..$TMAX\n";

# escape_gt option
{
my $doc='<doc a="&gt;>">&gt;></doc>';
my $doc_normal= '<doc a=">>">>></doc>';
my $doc_esc= '<doc a="&gt;&gt;">&gt;&gt;</doc>';
is( XML::Twig->parse( $doc)->sprint, $doc_normal, '> in data');
is( XML::Twig->parse( escape_gt => 1, $doc)->sprint, $doc_esc, '> in data with escape_gt');
XML::Twig::Elt::init_global_state();
is( XML::Twig->parse( $doc)->sprint, $doc_normal, '> in data');
}

{
my $doc= qq{<doc><elt foo="foo" abc="bar"/></doc>};
if( _use( 'Tie::IxHash'))
  {
     { 
        my $doc= '<doc><elt a2="foo" a1="bar"/></doc>';
        my $t = XML::Twig->new( keep_atts_order => 1)->parse( $doc);
        $t->root->first_child( 'elt')->set_att( a2 => "foo");
        is( $t->sprint, $doc, 'keep_atts_order when setting an attribute');
      }

      {
        my $doc= qq{<doc><elt foo="foo" abc="bar"/></doc>};
        my $t = XML::Twig->new( keep_atts_order => 1, twig_roots => { elt => 1 })->parsestring( $doc);
        is( $t->sprint, $doc, 'keep_atts_order with twig_roots');
      }
      {
        my $doc= qq{<doc xmlns:a="foo"><elt foo="nok" abc="bar"/><a:elt foo="ok" abc="bar"/><a:elt a:foo="nok" a:abc="bar"/></doc>};
        my $t = XML::Twig->new( keep_atts_order => 1, map_xmlns => { 'foo' => 'b' }, twig_roots => { 'b:elt' => 1 })->parse( $doc);
        is( $t->first_elt( 'b:elt')->att( 'foo'), 'ok', 'test on element with twig_roots, xmlns and keep_atts_order');
      }
      {
        my $doc= qq{<doc xmlns:a="foo"><elt foo="nok" abc="bar"/><a:elt foo="nok" abc="bar"/><a:elt a:foo="ok" a:abc="bar"/></doc>};
        my $t = XML::Twig->new( keep_atts_order => 1, map_xmlns => { 'foo' => 'b' }, twig_roots => { 'b:elt[@b:foo]' => 1 })->parsestring( $doc);
        is( $t->first_elt( 'b:elt')->att( 'b:foo'), 'ok', 'test on element with twig_roots, xmlns (handler triggerd on attribute) and keep_atts_order');
      }
  }
else
  { skip( 4, 'Tie::IxHash not available'); }

}


{
my $doc= qq{<doc xmlns:a="foo"><elt foo="nok" abc="bar"/><a:elt foo="ok" abc="bar"/><a:elt a:foo="nok" a:abc="bar"/></doc>};
my $t = XML::Twig->new( map_xmlns => { 'foo' => 'b' }, twig_roots => { 'b:elt' => 1 })->parse( $doc);
is( $t->first_elt( 'b:elt')->att( 'foo'), 'ok', 'test on element with twig_roots and xmlns');
}
{
my $doc= qq{<doc xmlns:a="foo"><elt foo="nok" abc="bar"/><a:elt foo="nok" abc="bar"/><a:elt a:foo="ok" a:abc="bar"/></doc>};
my $t = XML::Twig->new( map_xmlns => { 'foo' => 'b' }, twig_roots => { 'b:elt[@b:foo]' => 1 })->parsestring( $doc);
is( $t->first_elt( 'b:elt')->att( 'b:foo'), 'ok', 'test on element with twig_roots and xmlns (handler triggerd on attribute)');
}


{ my $t= XML::Twig->parse( '<doc/>');
  eval { $t->root->set_att( { a => 1 }); };
  matches( $@, qr{^improper call to set_att}, 'hashref passed to set_att');
}

{
my $tok = XML::Twig::Elt->new(foo => {} => 'XML::Twig::Elt');
ok (defined $tok and $tok->isa('XML::Twig::Elt'), 'created an token with classname in text element');
}

{
my $t= XML::Twig->parse( '<d a1="1" a2="0" a3="" a4="0.0"/>');
ok( $t->root->att_exists( 'a1'), 'att_exists, true att');
ok( $t->root->att_exists( 'a2'), 'att_exists, false (0) att');
ok( $t->root->att_exists( 'a3'), 'att_exists, false (empty string) att');
ok( $t->root->att_exists( 'a4'), 'att_exists, flase (0.0) att');
ok( !$t->root->att_exists( 'a5'), 'att_exists, non existent att');
}

{ my @styles= qw( none nsgmls nice indented indented_close_tag indented_c wrapped record_c record cvs indented_a );
  is( join( ':', XML::Twig::_pretty_print_styles), join( ':', @styles), '_pretty_print_styles');
}

{ my $doc='<d>></d>';
  my $t= XML::Twig->parse( $doc);
  is( $t->sprint, $doc, 'gt not escaped');
  $t->escape_gt;
  is( $t->sprint, '<d>&gt;</d>', 'gt not escaped');
  $t->do_not_escape_gt;
  is( $t->sprint, $doc, 'gt not escaped');
}

{
  my $d1='<d1 xmlns:pfoo="foo.com"><pfoo:e/></d1>';
  my $d2='<d2/>';
    { my $t1= XML::Twig->parse( $d1);
      my $t2= XML::Twig->parse( $d2);
      my $e= $t1->first_elt( 'pfoo:e');
      $e->move( first_child => $t2->root);
      is( $t2->sprint, '<d2><pfoo:e/></d2>', 'moving a namespaced element to a different doc');
    }
    { my $t1= XML::Twig->parse( $d1);
      my $t2= XML::Twig->parse( $d2);
      my $e= $t1->first_elt( 'pfoo:e');
      $e->cut;
      $e->declare_missing_ns;
      $e->paste( first_child => $t2->root);
      is( $t2->sprint, '<d2><pfoo:e xmlns:pfoo="foo.com"/></d2>', 'declare_missing_ns');
    }
}

{ my $d='<D ATTa="1" aTTB="2" Attc="3"/>';
  (my $expected= $d)=~ s{(\w+=)}{\L$1}g;
  is( XML::Twig->parse( $d)->root->lc_attnames->sprint, $expected, 'lc_attnames');
}


{ my $d='<d/>';
  is( XML::Twig->parse( $d)->root->set_ns_decl( 'http://example.com', 'ns')->sprint, '<d xmlns:ns="http://example.com"/>', 'set_ns_decl with prefix');
  is( XML::Twig->parse( $d)->root->set_ns_decl( 'http://example.com')->sprint, '<d xmlns="http://example.com"/>', 'set_ns_decl with no prefix');
  $d='<d att="val"/>';
  is( XML::Twig->parse( $d)->root->set_ns_decl( 'http://example.com', 'ns')->sprint, '<d att="val" xmlns:ns="http://example.com"/>', 'set_ns_decl with prefix');
  is( XML::Twig->parse( $d)->root->set_ns_decl( 'http://example.com')->sprint, '<d att="val" xmlns="http://example.com"/>', 'set_ns_decl with no prefix');
}

{ my $d='<d><df:e1 xmlns:df="http://df.com/"><e2><df:e3>foo</df:e3><e4>bar</e4></e2></df:e1></d>';
  is( XML::Twig->parse( $d)->root->set_ns_as_default( 'http://df.com/')->sprint,
     '<d xmlns="http://df.com/"><e1><e2><e3>foo</e3><e4>bar</e4></e2></e1></d>',
     'set_ns_as_default'
     );
}

{ my $d='<d><e1>ve1</e1><e2>ve2</e2><e3>ve3</e3><e4>ve4</e4></d>';
  is( join( ':', XML::Twig->parse( $d)->root->fields( qw( e3 e1 e4))), 've3:ve1:ve4', 'fields');
}


{ my $d='<d>foo<!--bar--></d>';
  my $t= XML::Twig->parse( $d);
  is( $t->root->sprint, $d, 'before _del_extra_data_before_end_tag');
  $t->root->_del_extra_data_before_end_tag;
  is( $t->root->sprint, '<d>foo</d>', '_del_extra_data_before_end_tag');
}


{ my $d="<d><e/></d>";
    { my $t= XML::Twig->parse( $d);
      is( $t->first_elt( 'e')->cut->twig, undef, 'twig of a cut element');
    }
    { my $t= XML::Twig->parse( $d);
      is( $t->first_elt( 'e')->cut->_twig_through_cut, $t, '_twig_through_cut of a cut element');
    }
}


{ my $d='<d><e1/></d>';
  my $t= XML::Twig->parse( $d);
  my $e2= XML::Twig::Elt->new( 'e2');
  $e2->set_parent( $t->root);
  my $e1= $t->first_elt( 'e1');
  $e1->set_next_sibling( $e2);
  $e2->set_prev_sibling( $e1);
  is( $t->sprint, '<d><e1/><e2/></d>', 'set_*');
}

{ my $d="<d>2>1'</d>";
  my $t= XML::Twig->parse( $d);
  is( $t->sprint, $d, 'basic replaced ents');
  $t->root->set_replaced_ents( "<&>'");
  is( $t->sprint, $d='<d>2&gt;1&apos;</d>', 'changed replaced ents');
}


{ my $d='<d><e1/><e2/><e3/><e4/></d>';
  is( XML::Twig->parse( ignore_elts => [ qw/e2 e4/ ], $d)->sprint, '<d><e1/><e3/></d>', 'ignore_elts with an arrayref');
}

{ if( _use( 'HTML::TreeBuilder') && _use( 'LWP::Simple') && _use( 'Cwd') )
    { my $html_file= make_tmp_file( '<html><body>foo<p>bar<p>baz</body></html>');
      my $t= XML::Twig->parse( 'file://' . Cwd::abs_path($html_file));
      is( $t->first_elt( 'p')->text, 'bar', 'parse an HTML file (not well-formed)');
      my $t2= XML::Twig->parse( 'file://' . Cwd::abs_path($html_file));
      is( $t2->first_elt( 'p')->text, 'bar', 'parse an HTML file (not well-formed), second time, to re-use the parser');
      unlink $html_file;
    }
  else
    { skip( 2, 'HTML::TreeBuilder, LWP::Simple needed for this test'); }
}

{ 
  nok( XML::Twig::_use( 'XML::Twig', $XML::Twig::VERSION + 1), '_use, check on version number (on higher version)'); 
  ok(  XML::Twig::_use( 'XML::Twig', $XML::Twig::VERSION    ), '_use, check on version number (on exact version)'); 
  ok(  XML::Twig::_use( 'XML::Twig', $XML::Twig::VERSION - 1), '_use, check on version number (on lower version)');  
}


{ my $d= '<d><e>text <!-- with --> extra <!-- data --> embedded <?in text?></e><e></e></d>';
  my $t= XML::Twig->parse( $d);
  is( $t->sprint, $d, 'embedded extra data');
  my $dump= $t->root->_dump( { extra => 1, short_text => 1 });
  my $nb_cpi;
  $nb_cpi++ while $dump=~ m{\bcpi\b}g;
  is( $nb_cpi, 3, '_dump of element with embedded comments and pi');
}

{ if( _use( 'Tie::IxHash'))
    { my $t=XML::Twig->new('keep_encoding' => 1, 'keep_spaces' => 1 , 'keep_atts_order' => 1);
      my $doc = q{<foo c="1" b="2" a="3">power<bar></bar></foo>};
      is( $t->parse( $doc)->root->copy->sprint, $doc, "keep empty status for copied elements");
    }
  else
    { skip( 1 => "need Tie::IxHash"); }
}

{ my $doc=qq{<doc>\n  <e>\n    <se>foo</se>\n    <se>bar</se>\n    </e>\n  <e>baz</e>\n  </doc>\n};
  is( XML::Twig->parse( pretty_print => 'indented_close_tag', $doc)->sprint, $doc, 'indent-close-tag');
}


{ my $doc=q{<doc><foo><e c="t">a</e><e>b</e><f c="t">c</f></foo><bar><e>XXX</e></bar><foo>XX<e c="f">d</e><g>e</g></foo></doc>};
  my $result;
  XML::Twig->parse( twig_handlers => { 'foo/*' => sub { $result .= $_->text; } }, $doc);
  is( $result, 'abcde', 'foo/* condition');
  $result='';
  XML::Twig->parse( twig_handlers => { 'foo/*[@c]' => sub { $result .= $_->text; } }, $doc);
  is( $result, 'acd', 'foo/*[@c] condition');
  $result='';
  XML::Twig->parse( twig_handlers => { 'foo/*[@c="t"]' => sub { $result .= $_->text; } }, $doc);
  is( $result, 'ac', 'foo/*[@c="t"] condition');
}

{ my $ok= eval { XML::Twig->new->setTwigHandler( 'foo[2]' => sub {}); };
  matches( $@, 'position selector \[2\] not supported on twig_handlers', 'position selector in handler trigger');
}

{ is( XML::Twig->parse( q{<e foo='"'></e>})->sprint, qq{<e foo="&quot;"></e>\n}, "quote in attribute");
  is( XML::Twig->parse( quote => 'single', q{<e foo='"'></e>})->sprint, qq{<e foo='"'></e>\n}, "single quote");
  is( XML::Twig->parse( quote => 'single', q{<e foo="'"></e>})->sprint, qq{<e foo='&apos;'></e>\n}, "quote in attribute (single quote)");
}

{ is( XML::Twig->parse( "<d><e>nope</e><e>foo or bar</e></d>")->first_elt( "e[text()=~/oo or b/]")->text, "foo or bar", "or in a regexp"); }

{ is( XML::Twig->parse( '<d><e.a>foo</e.a></d>')->root->field( 'e.a'), 'foo', 'condition on a field with .'); }

{ my $empty_file= "empty.xml";
  open( EMPTY, ">$empty_file") or die "cannot create empty file '$empty_file': $!";
  print EMPTY '';
  close EMPTY;
  my $t= XML::Twig->new->safe_parsefile( $empty_file);
  is( $t, undef, 'safe_parsefile of an empty file, return value');
  matches( $@, qr{^empty file}, 'parsefile of an empty file error message');
  unlink $empty_file;
}

1;

sub make_tmp_file
  { my $tmp_file= 'tmp_file';
    open( TMP, ">$tmp_file") or die "cannot create temp file $tmp_file: $!"; 
    print TMP @_;
    close TMP;
    return $tmp_file;
  }
