#!/usr/bin/perl -w


# test designed to improve coverage of the module

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;

use XML::Twig;

my $perl= $];

my $open;
BEGIN 
  { if( $] < 5.008) 
      { $open= sub { return }; } 
    else 
      { $open= eval( 'sub { open( $_[0], $_[1], $_[2]) }'); }
  }

my $TMAX=663; 

print "1..$TMAX\n";

{
my $t= XML::Twig->new->parse( q{
  <doc>
    <cdata><![CDATA[cdata 01]]></cdata>
    <cdata>foo <![CDATA[cdata <02>]]> bar </cdata>
  </doc>
});

# use CDATA
my $cdata= $t->first_elt( CDATA)->text;
is( $cdata, 'cdata 01', 'first_elt( CDATA)');# test 1
is( $t->first_elt( CDATA)->cdata_string, '<![CDATA[cdata 01]]>', 'cdata_string');# test 2
is( $t->root->cdata_string, '', 'cdata_string for non cdata element');# test 3

my $cdata2= $t->root->first_child( 'cdata[2]')->next_elt( CDATA)->text;
is( $cdata2, 'cdata <02>', 'first_child( cdata[2])');# test 4
}

# test warning for invalid options
my $old_warning_handler= $SIG{__WARN__};

{
my $warning="";
$SIG{__WARN__} = sub { $warning.= join '', @_ };
XML::Twig->new( dummy_opt => 1);
$SIG{__WARN__}= $old_warning_handler;
ok( $warning=~ m{^invalid option DummyOpt}, "expecting 'invalid option DummyOpt...', got '$warning'\n");# test 5

# test no warming if more_options is used
$warning="";
$SIG{__WARN__} = sub { $warning.= join '', @_ };
XML::Twig->new( more_options => 1, dummy_opt => 1);
$SIG{__WARN__}= $old_warning_handler;
nok( $warning, "expecting no warning, got '$warning'\n");# test 6

$warning="";
$SIG{__WARN__} = sub { $warning.= join '', @_ };
XML::Twig::add_options( 'dummy_opt');
XML::Twig->new( dummy_opt => 1);
$SIG{__WARN__}= $old_warning_handler;
nok( $warning, "expecting no warning (2), got '$warning'\n");# test 7
}


{
# test do_not_chain_handlers
my $nb_calls=0;
my $t= XML::Twig->new( twig_handlers => { chain      => sub { $nb_calls++; 1;},
                                         'doc/chain' => sub { $nb_calls++; 1;},
                                        },
                     )->parse( '<doc><chain>chained</chain></doc>');
is( $nb_calls, 2, "chained calls");# test 8

$nb_calls=0;
$t= XML::Twig->new( twig_handlers => { chain      => sub { $nb_calls++; 1 },
                                      'doc/chain' => sub { $nb_calls++; 1 },
                                        },
                     do_not_chain_handlers => 1,
                     )->parse( '<doc><chain>chained</chain></doc>');
is( $nb_calls, 1, "not chained calls");# test 9

$nb_calls=0;
$t= XML::Twig->new( twig_handlers => { chain      => sub { $nb_calls++; 0; },
                                      'doc/chain' => sub { $nb_calls++; 0; },
                                        },
                     )->parse( '<doc><chain>chained</chain></doc>');
is( $nb_calls, 1, "chained handlers returning 0");# test 10
}

# test ignore_elt
{ my $t= XML::Twig->new( ignore_elts => { i1 => 1, i2 => 2})
                  ->parse( '<doc><i1><t/></i1>
                                 <t/><y><t/></y>
                                 <i2><t/><y><t/><i1><t/></i1><t/></y></i2>
                                 <i2><t/><y><t/><i2><t/></i2><t/></y></i2>
                                 <t><t/></t>
                           </doc>');
  my @t= $t->findnodes( '//t');
  my $nb_t= scalar @t;
  is( $nb_t, 4, 'findnodes //t');# test 11
}

# test elt_class
{ 

my $t= XML::Twig->new( elt_class => 'twig_test')->parse( '<doc><elt/></doc>');

package twig_test;
use base 'XML::Twig::Elt';
sub test { return 25 }

package main;
is( $t->root->test, 25, 'elt_class');# test 12
} 

# test char_handler
{ 
my $t= XML::Twig->new( char_handler => sub { my $s= shift; $s=~ s/\w/./g; return $s; })
                 ->parse( '<doc><elt>foo</elt><elt att="bar">baz</elt></doc>');
my $text= $t->root->text;
is( $text, '......', 'silly char_handler');# test 13

my $att= $t->root->last_child( 'elt')->att( 'att');
is( $att, 'bar', 'last_child');# test 14
$att= $t->root->last_child( 'elt')->att( 'att'); # to use the cache
is( $att, 'bar', 'last_child');# test 15
}

# test various methods
{ my $t= XML::Twig->new->parse( '<doc><elt/><elt/></doc>');
  my @new_children= $t->root->children_copy;
  $t->set_id_seed( 'toto_');
  $_->add_id foreach @new_children;
  my $id= $new_children[0]->att( 'id');
  is( $id, 'toto_1', 'copy att');# test 16
  $new_children[1]->change_att_name( id => 'foo');
  my $foo=  $new_children[1]->att( 'foo');
  is( $foo, 'toto_2', 'change_att_name');# test 17

  ok( $t->root->all_children_are( 'elt'), "all_children_are( 'elt')");# test 18
  nok( $t->root->all_children_are( 'none'), "all_children_are( 'none')");# test 19

  my $count= $t->root->children_count( 'elt');
  is( $count, 2, "children_count( 'elt')");# test 20
  $count= $t->root->children_count( 'none');
  is( $count, 0, "children_count( 'none')");# test 21
  $count= $t->root->children_count;
  is( $count, 2, "children_count");# test 22
  ok( $t->root->first_child_matches( 'elt'), "first_child_matches");# test 23

  $t->root->insert_new_elt( 'p');
  nok( $t->root->all_children_are( 'elt'), "all_children_are( 'elt') (with p child)");# test 24

}

# test cdata append_cdata, append_extra_data, append_pcdata
{
my $t=XML::Twig->new->parse( '<doc><elt>text <![CDATA[some cdata]]> more text</elt></doc>');

my $cdata= $t->root->next_elt( CDATA)->cdata;
is( $cdata, 'some cdata', 'created CDATA element');# test 25

$t->root->next_elt( CDATA)->append_cdata( ' appended<>');
$t->root->next_elt( PCDATA)->append_pcdata( 'more ');
$t->root->first_child( 'elt')->append_extra_data( '<!-- comment -->');

is( $t->sprint, '<doc><!-- comment --><elt>text more <![CDATA[some cdata appended<>]]> more text</elt></doc>', "append_extra_data");# test 26
}

# test att_names and att_to_field
{ 
my $t= XML::Twig->new->parse( '<doc><elt att1="foo" att2="bar"/></doc>');
my $elt= $t->root->first_child_matches( 'elt');
ok( $elt, "first_child_matches");# test 27
my $att_names= join ':', sort $elt->att_names;
is( $att_names, 'att1:att2', "att_names");# test 28
$elt->att_to_field( 'att1');
$elt->att_to_field( att2 => "new");
my $elt_string= $elt->sprint;
is( $elt_string, '<elt><new>bar</new><att1>foo</att1></elt>', "att_to_field")# test 29
}

# test child_matches child_text child_trimmed_text children_text
{ 
my $t= XML::Twig->new->parse( '<doc><elt> text </elt><elt2>  text  text</elt2></doc>');
my $root= $t->root;
ok( $root->child_matches( 1, 'elt2'), "child_matches");# test 30

my $text= $root->child_text( 0);
is( $text, ' text ', "child_text");# test 31

$text= $root->child_trimmed_text( -1, 'elt2');
is( $text, 'text text', "child_trimmed_text", 25 );# test 32

$text= join( '-', $root->children_text( qr/elt/));
is( $text, ' text -  text  text', "children_text");# test 33
}

# test _ancestors _children _descendants 
{ my $t= XML::Twig->new->parse( '<doc><elt1/><elt2><elt3/></elt2></doc>');
  is( tags( $t->root->_children), 'elt1:elt2', "_children");# test 34
  is( tags( $t->root->_descendants), 'elt1:elt2:elt3', "_descendants");# test 35
  is( $t->root->last_child_matches( 'elt3') ? "matches" : "no match",# test 36
      "no match", "last_child_matches (no match)");
  my $elt3= $t->root->last_child_matches( 'elt2')->first_child;
  is( $elt3->gi, 'elt3', "last_child_matches (match)");# test 37
  is( tags( $elt3->_ancestors), 'elt2:doc', "_ancestors");# test 38
  is( tags( $elt3->_ancestors(1)), 'elt3:elt2:doc', "_ancestors(1)");# test 39

  is( tags( $t->root->descendants( 'elt1')), 'elt1', 'descendants with gi');# test 40
  is( tags( $t->root->descendants()), 'elt1:elt2:elt3', 'descendants without gi');# test 41
  is( tags( $t->root->descendants( qr/^elt/)), 'elt1:elt2:elt3', 'descendants with qr');# test 42
  is( tags( $t->root->descendants( qr/^elt/)), 'elt1:elt2:elt3', 'descendants with qr (using cache)');# test 43

} 

# test comment methods
{ 
my $t= XML::Twig->new( comments => 'process')
                ->parse( '<doc><elt>text <!-- foo --></elt></doc>');
my $comment= $t->first_elt( '#COMMENT');
is( $comment->comment, ' foo ', "comment");# test 44
is( $comment->comment_string, '<!-- foo -->', "comment");# test 45
}

# test element creation
{
my $t= XML::Twig->new->parse( '<doc/>');
my $root= $t->root;
my $elt= $root->insert_new_elt( first_child => 'elt');
my $elt3= $elt->insert_new_elt( after => elt3 => "elt3 text");
my $elt2= $elt3->insert_new_elt( before => elt2 => { att => "foo" }, "elt2 text");
is( $t->sprint, '<doc><elt/><elt2 att="foo">elt2 text</elt2><elt3>elt3 text</elt3></doc>',# test 46
    "insert_new_elt");

$root->cut_children;
is( $t->sprint, '<doc/>', "cut_children");# test 47
$elt= $root->insert_new_elt( last_child => 'elt' => { '#ASIS' => 1 }, "<p>bar</p>");
is( $elt->is_asis ? 'asis' : 'not asis', 'asis', "is_asis (initial, yes)");# test 48
is( $t->sprint, '<doc><elt><p>bar</p></elt></doc>', "insert_new_elt (ASIS)");# test 49
$elt->set_not_asis;
is( $elt->is_asis ? 'asis' : 'not asis', 'not asis', "is_asis (unset, no)");# test 50
is( $t->sprint, '<doc><elt>&lt;p>bar&lt;/p></elt></doc>', "set_not_asis");# test 51
$elt->set_asis;
is( $elt->is_asis ? 'asis' : 'not asis', 'asis', "is_asis (set, yes)");# test 52
is( $t->sprint, '<doc><elt><p>bar</p></elt></doc>', "set_asis");# test 53

$root->cut_children;
$root->insert_new_elt( first_child => '#CDATA' => "toto");
is( $t->sprint, '<doc><![CDATA[toto]]></doc>', "create CDATA");# test 54
is($root->last_child_matches( '#CDATA') ? "match" : "no match", "match", "last_child_matches (yes)");# test 55
is($root->last_child_matches( "foo") ? "match" : "no match", "no match", "last_child_matches (no)");# test 56
my $cdata= $root->last_child_matches( '#CDATA');
ok( $cdata->is_cdata, "cdata is_cdata");# test 57
nok( $cdata->is_comment, "cdata is_comment");# test 58
nok( $cdata->is_pi, "cdata is_pi");# test 59
nok( $cdata->is_empty, "cdata is_empty");# test 60
nok( $cdata->is_ent, "cdata is_ent");# test 61
ok( $cdata->is_first_child, "cdata is_first_child");# test 62
ok( $cdata->is_last_child, "cdata is_last_child");# test 63

}

# test field last_child_text last_child_trimmed_text
{ my $t= XML::Twig->new->parse( '<doc><field1>val1</field1><field2>val2</field2></doc>');
  my $root= $t->root;
  $root->set_field( field2 => "new  val2 ");
  is( $root->last_child_text( 'field2'), "new  val2 ", "set_field");# test 64
  is( $root->last_child_trimmed_text( 'field2'), "new val2", "set_field (trimmed text)");# test 65
  is( $root->last_child_text( 'field1'), "val1", "last_child_text");# test 66
  $root->set_field( field3 => "val3");
  is( $t->sprint, '<doc><field1>val1</field1><field2>new  val2 </field2><field3>val3</field3></doc>',# test 67
      "set_field (new field)");
}

# test next/prev navigation functions
{ my $t= XML::Twig->new->parse( 
  q{<doc><elt id="elt_1">elt 1</elt>
         <elt id="elt_2">elt 2</elt>
         <sect id="sect_1"><elt id="elt_3">elt 3</elt><elt id="elt_4">elt 4</elt></sect>
         <elt id="elt_5">elt 5 </elt>
    </doc>}
                             );
  my $root= $t->root;
  my $elt1= $t->getElementById( 'elt_1');
  is( $elt1->sprint, '<elt id="elt_1">elt 1</elt>', "getElementById");# test 68
  my $sect= $elt1->getElementById( 'sect_1');
  is( $sect->sprint, '<sect id="sect_1"><elt id="elt_3">elt 3</elt><elt id="elt_4">elt 4</elt></sect>', "getElementById (sect)");# test 69
  ok( $elt1->next_elt_matches( '#PCDATA[text()="elt 1"]'), "next_elt_matches (elt1 => elt)");# test 70
  ok( $elt1->prev_elt_matches( 'doc'), "prev_elt_matches (elt1 => doc)");# test 71
  ok( $sect->next_elt_matches( 'elt[@id="elt_3"]'), "next_elt_matches (sect => elt_3)");# test 72
  ok( $sect->prev_elt_matches( '#PCDATA[text()="elt 2"]'), "prev_elt_matches (sect => elt_2)");# test 73
  is( $sect->next_elt_text( 'elt[@id="elt_5"]'), 'elt 5 ', "next_elt_text");# test 74
  is( $sect->next_elt_trimmed_text( 'elt[@id="elt_5"]'), 'elt 5', "next_elt_trimmed_text");# test 75
  nok( $sect->next_elt( $sect, 'elt[@id="elt_5"]'), "next_elt (outside the subtree)");# test 76
  nok( $sect->next_elt_text( $sect, 'elt[@id="elt_5"]'), "next_elt_text (outside the subtree)");# test 77
  is( $sect->first_child_trimmed_text, "elt 3", "first_child_trimmed_text");# test 78
  is( $sect->first_child_trimmed_text( 'goofy'), "", "first_child_trimmed_text (no child)");# test 79

  # test comparisons $elt1 < $sect < $elt3
  my $elt3= $t->elt_id( 'elt_3');
  ok( $elt1->le( $sect), "\$elt1 le \$sect");# test 80
  ok( $elt1->lt( $sect), "\$elt1 lt \$sect");# test 81
  nok( $elt1->ge( $sect), "\$elt1 ge \$sect");# test 82
  nok( $elt1->gt( $sect), "\$elt1 gt \$sect");# test 83

  nok( $elt3->le( $sect), "\$elt3 le \$sect");# test 84
  nok( $elt3->lt( $sect), "\$elt3 lt \$sect");# test 85
  ok( $elt3->ge( $sect), "\$elt3 ge \$sect");# test 86
  ok( $elt3->gt( $sect), "\$elt3 gt \$sect");# test 87
}

# test keep_attribute_order
{ eval { require Tie::IxHash; };
  if( $@) { skip( 7, "Tie::IxHash not available"); }
  else
    { import Tie::IxHash;
      my $t= XML::Twig->new( keep_atts_order => 1)
                    ->parse( '<doc att_z="foo" att_a="bar"/>');
      is( $t->sprint, '<doc att_z="foo" att_a="bar"/>', "keep_atts_order");# test 88
      ok( $t->keep_atts_order, "keep_atts_order");# test 89
      $t= XML::Twig->new->parse( '<doc att_z="foo" att_a="bar"/>');
      is( $t->sprint, '<doc att_a="bar" att_z="foo"/>', "do not keep_atts_order");# test 90
      nok( $t->keep_atts_order, "keep_atts_order not used");# test 91

      $t->set_keep_atts_order(1);
      my $elt1= $t->root->new( 'elt');
      $elt1->set_att( a1 => 'v1');
      $elt1->set_att( a2 => 'v2');
      is( $elt1->sprint, '<elt a1="v1" a2="v2"/>', 'keep_atts_order with new elt');# test 92
      my $elt2= $t->root->new( 'elt');
      $elt2->set_att( a2 => 'v2');
      $elt2->set_att( a1 => 'v1');
      is( $elt2->sprint, '<elt a2="v2" a1="v1"/>', 'keep_atts_order with new elt (reverse order)');# test 93
      XML::Twig::Elt::set_keep_atts_order(0);
      my $elt3= $t->root->new( 'elt');
      $elt3->set_att( a2 => 'v2');
      $elt3->set_att( a1 => 'v1');
      is( $elt3->sprint, '<elt a1="v1" a2="v2"/>', 'no keep_atts_order with new elt (reverse order)');# test 94
    }
}

# test wrap_children xml_string
{
my $t= XML::Twig->new->parse( '<doc><elt/><elt/><elt2/></doc>');
$t->set_id_seed( 'id_');;
$t->root->wrap_children( '<elt>+', wrap => { foo => "bar"});
is( $t->sprint, '<doc><wrap foo="bar"><elt id="id_1"/><elt id="id_2"/></wrap><elt2 id="id_3"/></doc>', "wrap_children");# test 95
$t->root->strip_att( 'id');
is( $t->sprint, '<doc><wrap foo="bar"><elt/><elt/></wrap><elt2/></doc>', "wrap_children");# test 96
is( $t->root->xml_string, '<wrap foo="bar"><elt/><elt/></wrap><elt2/>', "xml_string");# test 97
}

# test set_output_encoding xml_text
{ 
my $t= XML::Twig->new->parse( '<doc><elt>elt 1</elt><elt> elt 2</elt></doc>');
is( $t->root->xml_text, 'elt 1 elt 2', "xml_text");# test 98
is( $t->root->xml_string, '<elt>elt 1</elt><elt> elt 2</elt>', "xml_text");# test 99
$t->set_output_filter( sub { return '.' x length $_[0] });
is( $t->root->xml_text, '...........', "xml_text (encoded)");# test 100
is( $t->root->xml_string, '.................................', "xml_text (encoded)");# test 101
 
}

# is_first_child is_last_child test contains_a_single contains_only
{
my $t= XML::Twig->new->parse( q{
<doc><elt><elt2>e2_1</elt2></elt>
     <elt><elt2>e2_2</elt2><elt2>e2_3</elt2></elt>
     <elt><elt2>e2_4</elt2><elt2>e2_5</elt2><elt3>e3_1</elt3></elt>
     <elt/>
</doc>});

my $elt1= $t->root->first_child('*');
my $elt2= $t->root->child( 1);
my $elt3= $t->root->first_child( sub { $_[0]->children_count( 'elt3') == 1 });
my $elt4= $t->root->last_child;

nok( $t->root->child( 6), 'child(6)');# test 102
nok( $t->root->child( -6), 'child(-6)');# test 103
nok( $t->root->child( 1, 'foo'), 'child(1, foo)');# test 104
nok( $t->root->child( -1, 'foo'), 'child(-1, foo)');# test 105
nok( $elt4->child( 1), 'child(1) on empty elt on empty elt');# test 106
nok( $elt4->child( 1, 'foo'), 'child(1, foo) on empty elt');# test 107
nok( $elt4->child( -1), 'child(-1) on empty elt');# test 108
nok( $elt4->child( -1, 'foo'), 'child(-1, foo) on empty elt');# test 109

ok( $elt1->is_first_child, "\$elt1->is_first_child");# test 110
nok( $elt2->is_first_child, "\$elt2->is_first_child is false");# test 111
nok( $elt3->is_first_child, "\$elt3->is_first_child is false");# test 112

nok( $elt1->is_last_child, "\$elt1->is_last_child");# test 113
nok( $elt2->is_last_child, "\$elt2->is_last_child");# test 114
ok( $elt4->is_last_child, "\$elt3->is_last_child is false");# test 115

ok( $elt1->contains_a_single( 'elt2'), "\$elt1->contains_a_single( 'elt2')");# test 116
nok( $elt1->contains_a_single( 'elt'), "\$elt1->contains_a_single( 'elt')");# test 117
nok( $elt2->contains_a_single( 'elt2'), "\$elt2->contains_a_single( 'elt2')");# test 118
nok( $elt3->contains_a_single( 'elt2'), "\$elt3->contains_a_single( 'elt2')");# test 119
nok( $elt4->contains_a_single( 'elt2'), "\$elt4->contains_a_single( 'elt2')");# test 120

ok( scalar $elt1->contains_only( 'elt2'), "\$elt1->contains_only( 'elt2')");# test 121
nok( $elt1->contains_only( 'elt'), "\$elt1->contains_only( 'elt') is false");# test 122
ok( scalar $elt2->contains_only( 'elt2'), "\$elt2->contains_only( 'elt2')");# test 123
nok( $elt3->contains_only( 'elt2'), "\$elt3->contains_only( 'elt2') is false");# test 124
ok( $elt4->contains_only( 'elt2'), "elt4->contains_only( 'elt2')");# test 125

is( $elt1->next_sibling_text, $elt2->text, "next_sibling_text");# test 126
is( $elt1->next_sibling_text, $elt2->text, "next_sibling_text using the cache");# test 127
is( $elt1->parent_text, $t->root->text, "parent_text");# test 128
is( $elt1->parent_text('doc'), $t->root->text, "parent_text");# test 129
is( $elt1->first_child->parent_text('doc'), $t->root->text, "parent_text");# test 130
ok( $elt2->parent_matches( 'doc'), "elt->parent_matches( 'doc')");# test 131
nok( $elt2->parent_matches( 'elt'), "elt->parent_matches( 'elt') is false");# test 132

nok( $t->root->parent, 'root parent');# test 133
nok( $t->root->parent_matches( 'doc'), 'root parent( doc)');# test 134
nok( $t->root->parent_matches( 'foo'), 'root parent( foo)');# test 135

is( $elt2->level, 1, "level");# test 136
is( $elt2->level( 'elt'), 0, "level( elt)");# test 137
is( $elt2->level( 'doc'), 1, "level( doc)");# test 138
is( $elt2->level( 'foo'), 0, "level( foo)");# test 139

nok( $elt2->first_child_text( 'foo'), "first_child_text on empty elt( 'foo')");# test 140
nok( $elt2->first_child_trimmed_text( 'foo'), "first_child_trimmed_text on empty elt( 'foo')");# test 141

nok( $elt4->next_sibling, 'next_sibling on last');# test 142
nok( $elt4->first_child, 'first_child on empty');# test 143
nok( $elt4->last_child, 'last_child on empty');# test 144
nok( $elt4->next_sibling_text, 'next_sibling_text on last');# test 145
nok( $elt4->first_child_text, 'first_child_text on empty');# test 146
nok( $elt4->last_child_text, 'last_child_text on empty');# test 147
nok( $elt4->next_sibling_trimmed_text, 'next_sibling_trimmed_text on last');# test 148
nok( $elt4->first_child_trimmed_text, 'first_child_trimmed_text on empty');# test 149
nok( $elt4->last_child_trimmed_text, 'last_child_trimmed_text on empty');# test 150

nok( $elt1->prev_sibling, 'prev_sibling on last');# test 151
nok( $elt1->prev_sibling_text, 'prev_sibling_text on last');# test 152
nok( $elt1->prev_sibling_trimmed_text, 'prev_sibling_trimmed_text on last');# test 153
}
 
# test next_n_elt del_id delete empty_tag_style
{
my $t= XML::Twig->new->parse( '<doc><elt id="id1"/></doc>');
my $elt= $t->root->next_n_elt( 1);
is( $elt->gi, 'elt', "next_n_elt");# test 154
is( $t->elt_id( 'id1')->gi, 'elt', "elt_id");# test 155
$elt->del_id;
is( $t->sprint, '<doc><elt/></doc>', "del_id");# test 156
nok( $t->elt_id( 'id1'), "no elt_id( 'id1')");# test 157
$elt->set_id( 'id2');
is( $t->sprint, '<doc><elt id="id2"/></doc>', "set_id");# test 158
is( $t->elt_id( 'id2')->gi, "elt", "elt_id after set_id");# test 159
$elt->delete;
is( $t->sprint, '<doc></doc>', "delete");# test 160
$t->root->insert_new_elt( first_child => '#COMMENT' => "a comment");
is( $t->sprint, '<doc><!--a comment--></doc>', "add comment");# test 161

$elt= $t->root->insert_new_elt( last_child => elt => { '#EMPTY' => 1 });
is( $t->sprint, '<doc><!--a comment--><elt/></doc>', "empty element");# test 162
ok( $elt->is_empty, "\$elt is empty");# test 163
$elt->set_not_empty;
is( $t->sprint, '<doc><!--a comment--><elt></elt></doc>', "non empty element");# test 164
nok( $elt->is_empty, "\$elt is not empty");# test 165
$elt->set_empty;
ok( $elt->is_empty, "\$elt is empty");# test 166
is( $t->sprint, '<doc><!--a comment--><elt/></doc>', "empty element again");# test 167
$t->set_empty_tag_style( 'html');
is( $t->sprint, '<doc><!--a comment--><elt></elt></doc>', "empty element (html style)");# test 168
XML::Twig::Elt::set_empty_tag_style( 'expand');
is( $t->sprint, '<doc><!--a comment--><elt></elt></doc>', "empty element (expand style)");# test 169
$t->set_empty_tag_style( 'normal');
is( $t->sprint, '<doc><!--a comment--><elt/></doc>', "empty element (normal style)");# test 170

$elt->set_content( "toto");
nok( $elt->is_empty, "\$elt is not empty");# test 171
is( $t->sprint, '<doc><!--a comment--><elt>toto</elt></doc>', "element with content");# test 172

nok( $elt->prev_sibling_matches( '#PI'), "prev_sibling_matches nok");# test 173
my $comment= $elt->prev_sibling_matches( '#COMMENT');
ok( $comment, "prev_sibling_matches ok");# test 174
$comment= $elt->prev_sibling;
is( $comment->gi, '#COMMENT', 'prev_sibling');# test 175
$comment= $elt->prev_sibling;
is( $comment->gi, '#COMMENT', 'prev_sibling using the cached cond');# test 176
$comment= $elt->prev_sibling( '#COMMENT');
is( $comment->gi, '#COMMENT', 'prev_sibling');# test 177
$comment= $elt->prev_sibling( '#COMMENT');
is( $comment->gi, '#COMMENT', 'prev_sibling using the cached cond');# test 178

$comment->set_comment( "another comment");
is( $t->sprint, '<doc><!--another comment--><elt>toto</elt></doc>', "element with content");# test 179

$t->root->field_to_att( 'elt');
is( $t->sprint, '<doc elt="toto"><!--another comment--></doc>', "field_to_att");# test 180

$t->root->del_att( 'elt');
$t->root->first_child( '#COMMENT')->delete;
is( $t->sprint, '<doc></doc>', "back to a very simple doc");# test 181

$t->root->insert( elt => { att => "v2" });
$t->root->first_child->set_content( "val 3");
$t->root->insert_new_elt( first_child => elt => { att => "v1" }, "val 2");
$t->root->insert_new_elt( last_child => elt => { att => "v3" }, "val 1");
is( $t->sprint, '<doc><elt att="v1">val 2</elt><elt att="v2">val 3</elt><elt att="v3">val 1</elt></doc>',# test 182
    "insert 3 elements");
$t->root->sort_children_on_value;
is( $t->sprint, '<doc><elt att="v3">val 1</elt><elt att="v1">val 2</elt><elt att="v2">val 3</elt></doc>',# test 183
    "sort_children_on_value");
$t->root->sort_children_on_att( "att",  order => "reverse" );
is( $t->sprint, '<doc><elt att="v3">val 1</elt><elt att="v2">val 3</elt><elt att="v1">val 2</elt></doc>',# test 184
    "sort_children_on_att (reverse)");

$t->root->set_text( "fini fini");
is( $t->sprint, '<doc>fini fini</doc>', 'set_text on root');# test 185
my $p= $t->root->insert( 'p');
my $new_p= $p->split_at( 4);
is( $t->sprint, '<doc><p>fini</p><p> fini</p></doc>', "split_at");# test 186
my $alt1_p= $p->copy;
my $alt2_p= $p->copy;
$p->split( qr/(i)/, 'b' );
is( $p->sprint, '<p>f<b>i</b>n<b>i</b></p>', "split");# test 187
$alt1_p->first_child->split( qr/(i)/, 'b' );
is( $alt1_p->sprint, '<p>f<b>i</b>n<b>i</b></p>', "split");# test 188
$new_p->split( qr/(i)/, b => { foo => "bar" } );
is( $new_p->sprint, '<p> f<b foo="bar">i</b>n<b foo="bar">i</b></p>', "split (with att)");# test 189
}

# test start_tag_handlers
{ 
my @results;
my $handler;
my $t=XML::Twig->new( start_tag_handlers =>{ elt => \&sth1});

sub sth1 
  { my( $t, $elt)= @_;
    push @results, "handler 1: ". $elt->id;
    $handler= $t->setStartTagHandler( elt => \&sth2);
  }
 
sub sth2 
  { my( $t, $elt)= @_;
    push @results, "handler 2: ". $elt->id;
    $t->setStartTagHandler( elt => $handler);
  }
 
$t->parse( '<doc><elt id="id1"><elt2><elt id="id2"></elt></elt2><elt id="id3"></elt></elt></doc>');

is( shift @results, "handler 1: id1", "handler 1");# test 190
is( shift @results, "handler 2: id2", "handler 2");# test 191
is( shift @results, "handler 1: id3", "handler 1 again");# test 192
}

{
my $t= XML::Twig->new( pi =>'process')->parse( '<doc><?t1 data1?><elt/></doc>');
my $pi= $t->root->first_child( '#PI');
$pi->set_target( 't2');
$pi->set_data( 'data2');
is( $pi->sprint, '<?t2 data2?>', "pi");# test 193
my $elt= $pi->next_sibling;
$elt->set_extra_data( '<!-- comment -->');
is( $elt->sprint, "<!-- comment --><elt/>", "elt with comment");# test 194
}

{
my $t= XML::Twig->new->parse( "<doc><elt>  elt  1 </elt>\n <elt>  elt   2 </elt></doc>");
my $elt1= $t->root->first_child;
my $elt2= $t->root->last_child;
is( $elt2->prev_sibling_text, '  elt  1 ', "prev_sibling_text");# test 195
is( $elt2->prev_sibling_trimmed_text, 'elt 1', "prev_sibling_trimmed_text");# test 196
is( $elt1->next_sibling_trimmed_text, 'elt 2', "next_sibling_trimmed_text");# test 197
ok( $elt1->next_sibling_matches( 'elt'), "next_sibling_matches ok");# test 198
nok( $elt2->next_sibling_matches( 'elt'), "next_sibling_matches nok");# test 199

is( $elt2->prev_elt_text( 'elt'), "  elt  1 ", "prev_elt_text");# test 200
is( $elt2->prev_elt_trimmed_text( 'elt'), "elt 1", "prev_elt_trimmed_text");# test 201

is( $elt2->parent_trimmed_text, "elt 1 elt 2", "parent_trimmed_text");# test 202

is( $elt1->sibling( 1)->trimmed_text, "elt 2", "sibling(1)");# test 203
is( $elt2->sibling( -1)->trimmed_text, "elt 1", "sibling(-1)");# test 204

is( $elt1->sibling_text( 1), "  elt   2 ", "sibling(1)");# test 205
is( $elt2->sibling_text( -1), "  elt  1 ", "sibling(-1)");# test 206

is( scalar $elt1->next_siblings, 1, "next_siblings");# test 207
is( scalar $elt1->next_siblings( 'elt2'), 0, "next_siblings (none)");# test 208

}

{
my $t= XML::Twig->new->parse( '<doc><elt1/><elt2/></doc>');
my $elt1= $t->first_elt( 'elt1');
my $elt2= $t->first_elt( 'elt2');
$elt2->move( before => $elt1);
is( $t->sprint, '<doc><elt2/><elt1/></doc>', "cut");# test 209
$elt2->cut;
is( $t->sprint, '<doc><elt1/></doc>', "cut");# test 210
$elt2->replace( $elt1);
is( $t->sprint, '<doc><elt2/></doc>', "replace");# test 211
$elt2->set_content( "toto");
$elt2->suffix( ":foo");
is( $elt2->xml_string, "toto:foo", "suffix");# test 212
$elt2->first_child( '#TEXT')->suffix( 'bar');
is( $elt2->xml_string, "toto:foobar", "suffix on pcdata elt");# test 213
$elt2->replace_with( $elt1);
is( $t->sprint, '<doc><elt1/></doc>', "replace_with");# test 214
$elt1->set_content( "tto");
my $o= XML::Twig::Elt->new( b => "oo");
$o->paste_within( $elt1, 1);
is( $t->sprint, '<doc><elt1>t<b>oo</b>to</elt1></doc>', "replace_with");# test 215
$o->new( t => {a => 1 }, 'ta')->paste_within( $t->first_elt( 'b')->first_child, 1);
is( $t->sprint, '<doc><elt1>t<b>o<t a="1">ta</t>o</b>to</elt1></doc>', "replace_with");# test 216

}

# test methods inherited from XML::Parser::Expat
{
my $t= XML::Twig->new( twig_handlers => { elt => \&test_inherited })
                ->parse( '<doc><sect><elt>toto</elt></sect></doc>');

sub test_inherited
  { my( $t, $elt)= @_;
    is( $t->depth, 2, "depth");# test 217
    ok( $t->in_element( 'sect'), "in_element");# test 218
    nok( $t->in_element( 'elt'), "in_element (false)");# test 219
    ok( $t->within_element( 'sect'), "within_element");# test 220
    ok( $t->within_element( 'doc'), "within_element");# test 221
    nok( $t->within_element( 'elt'), "within_element (false)");# test 222
    is( join( '/', $t->context), "doc/sect", "context");# test 223
    is( $t->current_line, 1, "current_line");# test 224
    is( $t->current_byte, 20, "current_byte");# test 225
    is( $t->original_string, "</elt>", "original_string");# test 226
    is( $t->recognized_string, "</elt>", "recognized_string");# test 227
    is( $t->current_element, "sect", "current_element");# test 228
    if( $XML::Parser::VERSION>2.27)
      { is( $t->element_index, 3, "element_index"); }# test 229
    else
      { is( $t->element_index, 2, "element_index"); } # alt test 229
    $t->base( "foo");
    is( $t->base, "foo", "base");# test 230
    ok( $t->position_in_context( 1), "position_in_context");# test 231

    my $xml= '<elt>toto</elt>';
    my $expected= '&lt;elt>toto&lt;/elt>';
    my $broken= '&lt;elt>toto</elt>';
    my $xml_escape= $t->xml_escape( $xml);
    if( $xml_escape eq $broken)
      { warn "your version of expat/XML::Parser has a broken xml_escape method\n";
        ok( 1, "xml_escape"); # test# test 232
      }
    else
      { is( $xml_escape, $expected, "xml_escape"); }  # alt test 232
               
    $xml= '<elt>toto</elt>';
    $expected= '&lt;elt>t&#x6F;t&#x6F;&lt;/elt>';
    $broken= '&lt;elt>t&#x6F;t&#x6F;</elt>';
    $xml_escape= $t->xml_escape( $xml, 'o');
    if( $xml_escape eq $expected)
      { ok( 1, "xml_escape"); }# test 233
    elsif( $xml_escape eq $broken)
      { ok( 1, "xml_escape"); } # alt test 233
    else
      { is( $xml_escape, $expected, "xml_escape"); } # alt test 233
  }
}

{
my $t= XML::Twig->new( start_tag_handlers => { i => sub { $_[0]->ignore }, }, 
                       twig_handlers      => { s => sub { $_[0]->finish }, } )
                ->parse( '<doc><elt>foo</elt><i><elt>toto</elt></i><elt2/><s>toto</s><elt>bar</elt></doc>');
is( $t->sprint, "<doc><elt>foo</elt><elt2/><s>toto</s></doc>", "ignore + finish");# test 234
}

# test xml declaration and entity related methods
{
my $t= XML::Twig->new->parse( '<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>
<!DOCTYPE doc SYSTEM "dummy.dtd" [
<!ENTITY ent1 "toto">
<!ENTITY ent2 "<p>tata</p>">
<!ENTITY ent3 SYSTEM "ent3.png" NDATA PNG> ]>
<doc><elt>&ent1;</elt><elt>&ent2;</elt><elt img="ent3"/></doc>');

is( $t->xml_version, "1.0", "xml_version");# test 235
is( $t->encoding, "ISO-8859-1", "encoding");# test 236
nok( $t->standalone, "standalone (no)");# test 237
is( $t->xmldecl, qq{<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>\n}, "xmldecl");# test 238

$t->set_xml_version( "1.1");
is( $t->xml_version, "1.1", "set_xml_version");# test 239
$t->set_encoding( "UTF-8");
is( $t->encoding, "UTF-8", "set_encoding");# test 240
$t->set_standalone( 1);
ok( $t->standalone||'', "set_standalone");# test 241
is( $t->xmldecl, qq{<?xml version="1.1" encoding="UTF-8" standalone="yes"?>\n}, "xmldecl");# test 242

is( join( ':', sort $t->entity_names), "ent1:ent2:ent3", "entity_names");# test 243

my $ent1= $t->entity( 'ent1');
is( $ent1->name, "ent1", "entity name");# test 244
is( $ent1->val, "toto", "entity val");# test 245
nok( $ent1->sysid, "entity sysid (none)");# test 246
nok( $ent1->pubid, "entity pubid (none)");# test 247
nok( $ent1->ndata, "entity ndata (none)");# test 248

my $ent3= $t->entity( 'ent3');
is( $ent3->name, "ent3", "entity name");# test 249
nok( $ent3->val, "entity val (none)");# test 250
is( $ent3->sysid, "ent3.png", "entity sysid");# test 251
nok( $ent3->pubid, "entity pubid (none)");# test 252
is( $ent3->ndata, "PNG", "entity ndata");# test 253

my $doctype= qq{<!DOCTYPE doc SYSTEM "dummy.dtd" [\n<!ENTITY ent1 "toto">\n<!ENTITY ent2 "<p>tata</p>">\n<!ENTITY ent3 SYSTEM "ent3.png" NDATA PNG>\n]>\n};
is( $t->doctype, $doctype, "doctype");# test 254

my $ent4= $t->entity_list->add_new_ent( ent4 =>  "ent 4")->ent( 'ent4');
is( $ent4->text, qq{<!ENTITY ent4 "ent 4">}, "add_new_ent");# test 255

my $ent5= $t->entity_list->add_new_ent( ent5 =>  "", "ent5.png", "", "PNG" )->ent( 'ent5');
is( $ent5->text, qq{<!ENTITY ent5 SYSTEM "ent5.png" NDATA PNG>}, "add_new_ent (ndata)");# test 256

is( join( ':', sort $t->entity_names), "ent1:ent2:ent3:ent4:ent5", "entity_names");# test 257

is( $t->doctype, $doctype, "doctype");# test 258

my $prolog=qq{<?xml version="1.1" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE doc SYSTEM "dummy.dtd"[
<!ENTITY ent1 "toto">
<!ENTITY ent2 "<p>tata</p>">
<!ENTITY ent3 SYSTEM "ent3.png" NDATA PNG>
<!ENTITY ent4 "ent 4">
<!ENTITY ent5 SYSTEM "ent5.png" NDATA PNG>]>
};

is( $t->prolog( UpdateDTD => 1), $prolog, "prolog, updated DTD");# test 259

$t->entity_list->delete( 'ent3');
is( join( ':', sort $t->entity_names), "ent1:ent2:ent4:ent5", "entity_names");# test 260
$t->entity_list->delete( ($t->entity_list->list)[0]);
is( join( ':', sort $t->entity_names), "ent2:ent4:ent5", "entity_names");# test 261
}

{
my $t= XML::Twig->new( comments => 'process', pi =>'process')
                ->parse( '<doc><!--comment--><?target pi?>text<![CDATA[cdata]]></doc>');
is( $t->root->first_child( '#COMMENT')->get_type, "#COMMENT", "get_type #COMMENT");# test 262
is( $t->root->first_child( '#PI')->get_type, "#PI", "get_type #PI");# test 263
is( $t->root->first_child( '#CDATA')->get_type, "#CDATA", "get_type #CDATA");# test 264
is( $t->root->first_child( '#PCDATA')->get_type, "#PCDATA", "get_type #PCDATA");# test 265
is( $t->root->get_type, "#ELT", "get_type #ELT");# test 266
my $cdata= $t->root->first_child( '#CDATA');
$cdata->set_cdata( "new cdata");
is( $cdata->sprint, "<![CDATA[new cdata]]>", "set_cdata");# test 267
my $copy= $t->root->copy;
is( $copy->sprint, $t->root->sprint, 'copy of an element with extra data');# test 268

is( $t->sprint( pretty_print => 'indented'),# test 269
    qq{<doc><!--comment--><?target pi?>text<![CDATA[new cdata]]></doc>\n},
    'indented elt');

}


{ 
my $t= XML::Twig->new->parse( '<!DOCTYPE doc SYSTEM "dummy.dtd"><doc> text &ent; more</doc>');
my $ent= $t->first_elt( '#ENT');
is( $ent->get_type, "#ENT", "get_type");# test 270
is( $ent->ent, '&ent;', "ent");# test 271
is( $ent->ent_name, 'ent', "ent_name");# test 272
$ent->set_ent( '&new_ent;');
is( $ent->ent, '&new_ent;', "new_ent ent");# test 273
is( $ent->ent_name, 'new_ent', "new_ent ent_name");# test 274
}

{ 
my $t= XML::Twig->new->parse( '<doc>text xx more text xx end</doc>');
my $alt_root= $t->root->copy;
$t->root->mark( ' (xx) ', b => { att => "y" });
is( $t->sprint, '<doc>text<b att="y">xx</b>more text<b att="y">xx</b>end</doc>',  'mark');# test 275
$alt_root->first_child->mark( ' (xx) ', b => { att => "y" });
is( $alt_root->sprint, '<doc>text<b att="y">xx</b>more text<b att="y">xx</b>end</doc>', 'mark text');# test 276
}

{
my $t= XML::Twig->new->parse( '<doc att="foo"/>');
is( $t->sprint, '<doc att="foo"/>', "before save_global_state");# test 277
$t->save_global_state;
$t->set_quote( 'single');
is( $t->sprint, "<doc att='foo'/>", "after set_global_state");# test 278
$t->restore_global_state;
is( $t->sprint, '<doc att="foo"/>', "after restore_global_state");# test 279
}

{
my $t= XML::Twig->new->parse( '<doc><elt>text <b>bold text</b> more text and text </elt><elt> even more text</elt></doc>');
$t->subs_text( 'text', 'stuff');
is( $t->sprint, "<doc><elt>stuff <b>bold stuff</b> more stuff and stuff </elt><elt> even more stuff</elt></doc>", "subs_text");# test 280
$t->subs_text( qr{stuf+}, 'text');
is( $t->sprint, "<doc><elt>text <b>bold text</b> more text and text </elt><elt> even more text</elt></doc>", "subs_text");# test 281
my $elt= $t->root->first_child;
my $bold= $elt->first_child( 'b');
$bold->erase;
is( $t->sprint, "<doc><elt>text bold text more text and text </elt><elt> even more text</elt></doc>", "erase");# test 282
$elt->merge( $elt->next_sibling);
is( $elt->first_child_text, "text bold text more text and text  even more text", "merge_text");# test 283
}

# more tests on subs_text
{ 
my $doc='<doc><p>link to http://www.xmltwig.com but do not link to http://bad.com, though link to toto and link to http://www.xml.com</p><p>now http://www.nolink.com and do not link to this and do not link to http://www.bad.com and do not link to http://www.bad2.com and link to http://link.com also</p></doc>';
my $expected='<doc><p>see <a href="http://www.xmltwig.com">www.xmltwig.com</a> but do not link to http://bad.com, though link to toto and see <a href="http://www.xml.com">www.xml.com</a></p><p>now http://www.nolink.com and do not link to this and do not link to http://www.bad.com and do not link to http://www.bad2.com and see <a href="http://link.com">link.com</a> also</p></doc>';
my $t= XML::Twig->new->parse( $doc);
my $got= $t->subs_text( qr{(?<!do not )link to (http://(\S+[\w/]))}, 'see &elt( a =>{ href => $1 }, $2)');
is( $got->sprint, $expected, 'complex substitution with subs_text');# test 284
}

{ 
my $doc='<doc>text <p>and  more text</p></doc>';
(my $expected= $doc)=~ s{ }{&nbsp;}g;
my $t= XML::Twig->new->parse( $doc);
my $got= $t->subs_text( qr{ }, '&ent( "&nbsp;")');
is( $got->sprint, $expected, 'creating entities with subs_text');# test 285
$t= XML::Twig->new->parse( $doc);
my $ent="&nbsp;";
$got= $t->subs_text( qr{ }, "&ent( '$ent')");
is( $got->sprint, $expected, 'creating entities from a variable with subs_text');# test 286
}

{
my $t= XML::Twig->new->parse( 
'<doc>
  <record><key>03</key><val>val 1</val></record>
  <record><key>2</key><val>val 2</val></record>
  <record><key>4</key><val>val 3</val></record>
  <record><key>01</key><val>val 4</val></record>
  <record><key>05</key><val></val></record>
</doc>');

$t->root->sort_children_on_field( 'key', type =>'numeric' );
my $expected=
'
<doc>
 <record><key>01</key><val>val 4</val></record>
 <record><key>2</key><val>val 2</val></record>
 <record><key>03</key><val>val 1</val></record>
 <record><key>4</key><val>val 3</val></record>
 <record><key>05</key><val></val></record>
</doc>
';
$t->set_pretty_print( 'record_c');
$t->set_indent( ' ');
is( $t->sprint, $expected, "sort_children_on_field");# test 287
XML::Twig::Elt::set_indent( '  ');
}

{ 
my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none')->parse( '<doc><elt/></doc>');
is( $t->sprint, "<doc><elt></elt></doc>", "empty_tags expand");# test 288
is( $t->sprint( empty_tags => 'normal'), "<doc><elt/></doc>", "empty_tags normal");# test 289
is( $t->sprint( pretty_print => 'indented', empty_tags => 'normal'), "<doc>\n  <elt/>\n</doc>\n", "empty_tags expand");# test 290
$t->set_pretty_print( 'none');
$t->set_empty_tag_style( 'normal');
}

{ if( $perl < 5.008)  
    { skip( 3, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $out=''; my $out2='';
      $open->( my $fh, ">", \$out);
      $open->( my $fh2, ">", \$out2);
      my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none')->parse( '<doc><elt/></doc>');
      $t->print( $fh);
      is( $out, "<doc><elt></elt></doc>", "empty_tags expand");# test 291
      $t->print( $fh2);
      is( $t->sprint( empty_tags => 'normal'), "<doc><elt/></doc>", "empty_tags normal");# test 292
      $out=''; $t->print( $fh);
      is( $t->sprint( pretty_print => 'indented', empty_tags => 'normal'), "<doc>\n  <elt/>\n</doc>\n", "empty_tags expand");# test 293
      $t->set_pretty_print( 'none');
      $t->set_empty_tag_style( 'normal');
    }
}

{ if( $perl < 5.008)  
    { skip( 3, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $out=''; my $out2='';
      $open->( my $fh, ">", \$out);
      $open->( my $fh2, ">", \$out2);
      my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none');
      $t->parse( '<doc><elt/></doc>')->flush( $fh);
      is( $out, "<doc><elt></elt></doc>", "empty_tags expand");# test 294
      $t->parse( '<doc><elt/></doc>')->flush( $fh2);
      is( $t->sprint( empty_tags => 'normal'), "<doc><elt/></doc>", "empty_tags normal");# test 295
      $out=''; $t->parse( '<doc><elt/></doc>')->flush( $fh);
      is( $t->sprint( pretty_print => 'indented', empty_tags => 'normal'), "<doc>\n  <elt/>\n</doc>\n", "empty_tags expand");# test 296
      $t->set_pretty_print( 'none');
      $t->set_empty_tag_style( 'normal');
    }
}

{
my $t= XML::Twig->new->parse( 
'<doc>
  <record><key>03</key><val>val 1</val></record>
  <record><key>2</key><val>val 2</val></record>
  <record><key>4</key><val>val 3</val></record>
  <record><key>01</key><val>val 4</val></record>
</doc>');

$t->root->sort_children_on_field( 'key', type =>'numeric' );
my $expected=
'
<doc>
 <record><key>01</key><val>val 4</val></record>
 <record><key>2</key><val>val 2</val></record>
 <record><key>03</key><val>val 1</val></record>
 <record><key>4</key><val>val 3</val></record>
</doc>
';
$t->set_pretty_print( 'record_c');
$t->set_indent( ' ');
is( $t->sprint, $expected, "sort_children_on_field");# test 297
$t->set_indent( '  ');
}

{ 
my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none')->parse( '<doc><elt/></doc>');
is( $t->sprint, "<doc><elt></elt></doc>", "empty_tags expand");# test 298
is( $t->sprint( empty_tags => 'normal'), "<doc><elt/></doc>", "empty_tags normal");# test 299
is( $t->sprint( pretty_print => 'indented', empty_tags => 'normal'), "<doc>\n  <elt/>\n</doc>\n", "empty_tags expand");# test 300
$t->set_pretty_print( 'none');
$t->set_empty_tag_style( 'normal');
}



{
my $t= XML::Twig->new->parse( '<doc xmlns="uri_def" xmlns:ns1="uri1"><elt/><ns1:elt/></doc>');
my $elt1= $t->root->first_child( 'elt');
my $elt2= $t->root->first_child( 'ns1:elt');
is( $elt1->namespace, "uri_def", "default namespace");# test 301
is( $elt2->namespace, "uri1", "namespace");# test 302
is( $elt1->namespace, "uri_def", "namespace default");# test 303
is( $elt1->namespace( 'ns1'), "uri1", "namespace not default");# test 304
is( join( ' - ', $elt1->current_ns_prefixes), '', "current_ns_prefixes");# test 305
is( join( ' - ', $elt2->current_ns_prefixes), ' - ns1', "current_ns_prefixes");# test 306
}

{
my $t=XML::Twig->new( ignore_elts => { i => 1 });
$t->parse( '<doc><elt1/><i><elt2/></i><elt3><i/><elt4/></elt3></doc>');
is( $t->sprint, '<doc><elt1/><elt3><elt4/></elt3></doc>', "setIgnoreEltsHandler");# test 307
}
{
my $t=XML::Twig->new;
$t->setIgnoreEltsHandler( i => 'discard');
$t->parse( '<doc><elt1/><i><elt2/></i><elt3><i/><elt4/></elt3></doc>');
is( $t->sprint, '<doc><elt1/><elt3><elt4/></elt3></doc>', "setIgnoreEltsHandler");# test 308
}

# test setEndTagHandler
{ my $called="";
  my $t= XML::Twig->new( twig_roots => { title => 1 });
  my $doc=q{<doc><sect id="sect1"><title id="title1">title 1</title><p id="p1"/></sect>
                 <sect id="sect2"><title id="title2">title 2</title><p id="p2"/></sect>
            </doc>};
  $t->parse( $doc);
  is( $called, "", "no end_tag_handler");# test 309
  $called= '';
  $t->setEndTagHandler( sect => sub { $called.= ":" if( $called); $called .= $_[1]});
  $t->parse( $doc);
  is( $called, "sect:sect", "end_tag_handler");# test 310
  $called= '';
  $t->setEndTagHandler( sect => sub { return });
  $t->parse( $doc);
  is( $called, "", "empty end_tag_handler");# test 311
}

# test replace_prefix
{ my $called='';
  my $not_called='';
  my $t= XML::Twig->new( namespaces => 1,
                         map_xmlns => { "uri1" => "foo", "uri2" => "whatever" },
                         twig_handlers => { "foo:bar" => sub  { $called.= ":" if( $called); 
                                                                $called .= $_->id
                                                               },
                                            "toto:bar" => sub  { $not_called.= ":" if( $not_called); 
                                                                 $not_called .= $_->id
                                                               },
                                          },
                       );
  $t->parse( q{<doc xmlns:toto="uri1" xmlns:foo="uri2" xmlns:no="uri3"><toto:bar id="ok1"/><foo:bar id="nok1" />
                 <toto:bar id="ok2"/><foo:bar id="nok2" /><no:bar id="no1" /> <bar id="no2"/></doc>});
  is( $called, "ok1:ok2", "map_xmlns");# test 312
  is( $not_called, "", "map_xmlns (no hit)");# test 313
}

# test parser
{ my $t= XML::Twig->new( twig_handlers => 
    { doc => sub 
		    { is( ref( $_[0]->parser), 'XML::Parser::Expat', "parser"); } },# test 314
                       )
                  ->parse( "<doc />");
  is( ref( $t->parser), '', "parser (empty, after the parse)");# test 315
  $t->set_doctype( doc => "doc.dtd");
  is( $t->sprint, qq{<!DOCTYPE doc SYSTEM "doc.dtd">\n<doc/>}, "set_doctype");# test 316
  $t->set_doctype( doc => "doc.dtd", "-//public id/");
  is( $t->sprint, qq{<!DOCTYPE doc PUBLIC "-//public id/" "doc.dtd">\n<doc/>}, "set_doctype");# test 317
  $t->set_doctype( doc => "doc.dtd", '', qq{[<!ENTITY toto "foo">]});
  is( $t->sprint, qq{<!DOCTYPE doc SYSTEM "doc.dtd" [\n<!ENTITY toto "foo">\n]>\n<doc/>}, "set_doctype");# test 318
#set_doctype ($name, $system, $public, $internal)
}

{ if( $perl < 5.008)  
    { skip( 3, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $out='';
      $open->( my $fh, ">", \$out);
      my $doc= q{<doc><sect><p>p1</p><p>p2</p><flush/></sect></doc>};
      my $t= XML::Twig->new( twig_handlers => { flush => sub { $_->flush( $fh) } } );
      $t->{twig_autoflush}=0;
      $t->parse( $doc);
      is( $out, q{<doc><sect><p>p1</p><p>p2</p><flush/>}, "flush");# test 319
      close $fh;

      $out="";
      $open->( $fh, ">", \$out);
      $t= XML::Twig->new( twig_handlers => { flush => sub { $_[0]->flush_up_to( $_->prev_sibling, $fh) } } );
      $t->{twig_autoflush}=0;
      $t->parse( $doc);
      is( $out, q{<doc><sect><p>p1</p><p>p2</p>}, "flush_up_to");# test 320

      $t= XML::Twig->new( twig_handlers => { purge => sub { $_[0]->purge_up_to( $_->prev_sibling->prev_sibling, $fh) } } )
                      ->parse( q{<doc><sect2/><sect><p>p1</p><p><sp>sp 1</sp></p><purge/></sect></doc>});
      is( $t->sprint, q{<doc><sect><p><sp>sp 1</sp></p><purge/></sect></doc>}, "purge_up_to");# test 321
    }
}
      
# test next_n_elt for a twig
{ my $t= XML::Twig->new->parse( q{<doc><e1><e2>e 2</e2><e3>e 3</e3></e1></doc>});
  is_undef( $t->next_n_elt( 1), "next_n_elt(1)");# test 322
  is( $t->next_n_elt( 3)->gi, "e2", "next_n_elt(3)");# test 323
  is( $t->next_n_elt( 1, "e3")->gi, "e3", "next_n_elt(1, e3)");# test 324
  nok( $t->next_n_elt( 2, "e3"), "next_n_elt(2, e3)");# test 325
  is( join(':', map { $_->gi } $t->_children), 'doc', "\$t->_children");# test 326
}

# test dtd_print
{ if( $perl < 5.008)  
    { skip( 2, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { 
      { my $out='';
        $open->( my $fh, ">", \$out);
        my $t= XML::Twig->new()->parse( q{<!DOCTYPE doc [<!ELEMENT doc (#PCDATA)*>]><doc>toto</doc>});
        $t->dtd_print( $fh);
        is( $out, "<!DOCTYPE doc [\n<!ELEMENT doc (#PCDATA)*>\n\n]>\n", "dtd_print");# test 327
        close $fh;
      }
      { my $out="";
        $open->( my $fh, ">", \$out);
        my $t= XML::Twig->new( twig_handlers => { stop => sub { print $fh "[X]"; $_->set_text( '[Y]'); $_[0]->flush( $fh); $_[0]->finish_print( $fh); } });
        $t->{twig_autoflush}=0;
        $t->parse( q{<doc>before<stop/>finish</doc>});
        select STDOUT;
        is( $out, q{[X]<doc>before<stop>[Y]</stop>finish</doc>}, "finish_print");# test 328
      }
    }
}

# test set_input_filter
{ my $t=XML::Twig->new( input_filter => \&rot13)
                 ->parse( q{<doc att="foo">text</doc>});
  is( $t->sprint, q{<qbp ngg="sbb">grkg</qbp>}, "input filter");# test 329
  $t=XML::Twig->new;
  $t->parse( q{<doc att="foo">text</doc>});
  is( $t->sprint, q{<doc att="foo">text</doc>}, "input filter (none)");# test 330
  $t->set_input_filter( \&rot13);
  $t->parse( q{<qbp ngg="sbb">grkg</qbp>});
  is( $t->sprint, q{<doc att="foo">text</doc>}, "set_input_filter");# test 331
  $t->parse( '<doc><?target data?><elt/><!-- silly hey? --><elt/></doc>');
  is( $t->sprint, '<qbp><?gnetrg qngn?><ryg/><!-- fvyyl url? --><ryg/></qbp>',# test 332
      "set_input_filter on comments and cdata");  
 


}

sub rot13 { $_[0]=~ tr/a-z/n-za-m/; $_[0]; }

# test global_state methods
{ my $doc= q{<doc att="foo"><p>p 1</p><p>p 2</p></doc>};
  my $t=XML::Twig->new->parse( $doc);
  is( $t->sprint, $doc, "initial state");# test 333
  my $state= $t->global_state;
  $t->set_pretty_print( 'indented');
  $t->set_indent( 8);
  nok( $t->sprint eq $doc, "changed state");# test 334
  $t->set_global_state( $state);
  is( $t->sprint, $doc, "re-set initial state");# test 335
  $t->save_global_state;
  $t->set_pretty_print( 'nice');
  $t->set_quote( 'single');
  nok( $t->sprint eq $doc, "changed state");# test 336
  $t->restore_global_state( $state);
  is( $t->sprint, $doc, "restored initial state");# test 337
}

# test encoding functions
{  if( $perl < 5.008)  
    { skip( 21, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { require Encode; import Encode;
      my $text= "\x{E9}t\x{E9}";
      my $text_latin1 = encode( latin1 => $text);
      my $text_utf8   = encode( utf8   => $text);
      my $text_html="&eacute;t&eacute;";
      my $text_safe= "&#233;t&#233;";
      my $text_safe_hex= "&#xe9;t&#xe9;";
      my $doc_latin1=qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n<doc>$text_latin1</doc>};
      my $doc_utf8=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text_utf8</doc>};
      my $doc_html=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text_html</doc>};
      my $doc_safe=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text_safe</doc>};
      my $doc_safe_hex=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text_safe_hex</doc>};
      my $doc_escaped= xml_escape( $doc_html);

      my $t= XML::Twig->new( output_encoding => "ISO-8859-1")->parse( $doc_utf8);
      $t->save_global_state;
      is( $t->output_encoding, 'ISO-8859-1', "output_encoding (ISO-8859-1)");# test 338
      is( $t->sprint, $doc_latin1, "output_encoding ISO-8859-1");# test 339
      $t->set_output_encoding( "UTF-8");
      is( $t->output_encoding, 'UTF-8', "output_encoding (UTF-8)");# test 340
      is( $t->sprint, $doc_utf8, "output_encoding UTF-8");# test 341
      $t->set_output_text_filter( 'safe');
      is( $t->sprint, $doc_safe, 'safe');# test 342
      $t->set_output_text_filter( 'safe_hex');
      is( $t->sprint, $doc_safe_hex, 'safe_hex');# test 343
      if( $perl == 5.008)
        { skip( 2 => "cannot use latin1_output_text_filter with perl $perl"); }
      else
        { 
          $t->set_output_text_filter( $t->latin1 );
          $t->set_output_encoding( "ISO-8859-1");
          is( normalize_xml( $t->sprint( pretty_print => 'indented')), normalize_xml( $doc_latin1), 'latin1');# test 344

          $t->set_output_filter( 'latin1' );
          $t->set_output_encoding( "ISO-8859-1");
          is( $t->sprint, $doc_latin1, 'latin1 (just the string)');# test 345

        }
      $t->set_output_text_filter( );
      $t->set_output_encoding( "UTF-8");
      $t->restore_global_state;

      eval "require HTML::Entities";
      if( $@) 
        { skip( 4, "need HTML::Entities for those tests"); }
      elsif( $perl == 5.008)
        { skip( 4, "HTML::Entities don't seem to work well with perl 5.8.0 (the e acute becomes &#233; instead of &eacute;)"); }
      else
        { 
          import HTML::Entities;
          $t->save_global_state;
          $t->set_output_encoding( "UTF-8");

          my $original_output_text_filter= $t->output_text_filter;
          $t->set_output_text_filter( "html");
          my $html_output_text_filter= $t->output_text_filter;
          is( $t->sprint, $doc_html, "output_text_filter html");# test 346
          $t->set_output_text_filter( $original_output_text_filter);
          is( $t->sprint, $doc_utf8, "no output_text_filter ");# test 347

          my $original_output_filter= $t->output_filter;
          $t->set_output_filter( "html");
          is( $t->sprint, $doc_escaped, "output_filter html");# test 348

          $t->restore_global_state;
          $t->set_output_encoding( "UTF-8");
          is( $t->sprint, $doc_utf8, "no output_text_filter ");# test 349
        }

      $t->restore_global_state;
      $t->set_output_encoding();

      eval "require Text::Iconv";
      if( $@) 
        { skip( 3, "need Text::Iconv for those tests"); }
      else
        { my $encoding= 'ISO-8859-1';
          if( eval( '$t->iconv_convert( "$encoding");'))
            { $t->set_output_filter( $t->iconv_convert( $encoding) );
              $t->set_encoding( $encoding);
              is( $t->encoding, $encoding, "set_encoding");# test 350
              is( $t->sprint, $doc_latin1, "output_filter ISO-8859-1 (using Text::Iconv)");# test 351
              $t->restore_global_state;
              $t->set_output_encoding( "UTF-8");
              is( $t->sprint, $doc_utf8, "no output_filter ");# test 352
            }
          else
            { if( $@=~ m{^Unsupported encoding: $encoding})
                { skip( 3, "your version of iconv does not support $encoding"); }
              else
                { skip( 3, "odd error creating filter with iconv: $@"); }
            }
        }

      $t->restore_global_state;
      $t->set_output_encoding();

      eval( 'require Unicode::Map8 && require Unicode::String;');
      if( $@) 
        { skip( 3, "need Unicode::Map8 and Unicode::String for those tests" ); }
      else
        { $t->set_output_filter( $t->unicode_convert( 'latin1') );
          $t->set_encoding( "ISO-8859-1");
          is( $t->encoding, "ISO-8859-1", "set_encoding");# test 353
          is( $t->sprint, $doc_latin1, "output_filter latin-1 (using Unicode::*)");# test 354
          $t->restore_global_state;
          $t->set_output_encoding( "UTF-8");
          is( $t->sprint, $doc_utf8, "no output_filter ");# test 355
          $t->restore_global_state;
          $t->set_output_encoding();
        }

      $t->set_output_filter( $t->regexp2latin1 );
      $t->set_encoding( "ISO-8859-1");
      is( $t->encoding, "ISO-8859-1", "set_encoding");# test 356
      is( $t->sprint, $doc_latin1, "output_filter latin-1 (using regexp2latin1)");# test 357
      $t->restore_global_state;
      $t->set_output_encoding( "UTF-8");
      is( $t->sprint, $doc_utf8, "no output_filter ");# test 358
      $t->restore_global_state;
      $t->set_output_encoding();

    }
}

# test SAX1 export
{ eval "require XML::Handler::YAWriter";
  if( $@)
    { skip(3, "require XML::Handler::YAWriter"); }
  else
    { import XML::Handler::YAWriter;
      my $xmldecl= qq{<?xml version="1.0" encoding="UTF-8"?>};
      my $body= qq{<doc><p att="p1">text</p></doc>};
      my $doc= $xmldecl.$body;
      my $t= XML::Twig->new->parse( $doc);
      $t->root->set_att( '#priv' => 'private');
      $t->root->insert_new_elt( last_child => '#private');
      my $writer = XML::Handler::YAWriter->new( AsString => 1);
      is( normalize_xml( $t->toSAX1( $writer)), $doc, 'toSAX1');# test 359
      $writer->start_document;
      $t->root->toSAX1( $writer);
      is( normalize_xml( $writer->end_document), $doc, 'root toSAX1');# test 360

      my $doc_flush="<doc><p>p 1</p><add/><p/><p>text<flush/> more text</p></doc>";
      my $doc_flushed=qq{<?xml version="1.0" encoding="UTF-8"?><doc><p>p 1</p><add/><g>a</g><p/><p>text<flush/> more text</p></doc>};
      $writer = XML::Handler::YAWriter->new( AsString => 1, Pretty => { CatchEmptyElement => 1 });
      $writer->start_document;

      $SIG{__WARN__} = sub {  };
      $t= XML::Twig->new( twig_handlers => 
              { add =>   sub { $_[0]->flush_toSAX1( $writer);
                               $_->new( g => "a")->toSAX1( $writer);
                             },
                flush => sub { $_[0]->flush_toSAX1( $writer); },
              }
                        )
                      ->parse( $doc_flush);
      my $output=  $t->flush_toSAX1( $writer) || '';
      $SIG{__WARN__}= $old_warning_handler;
      is( normalize_xml( $output), $doc_flushed, 'root toSAX1');# test 361

    }
}

# test SAX2 export
{ eval "require XML::SAX::Writer;"; 
  if( $@)
    { skip(5, "XML::SAX::Writer not available"); }
  elsif( $XML::SAX::Writer::VERSION < 0.39)
    { skip( 5, "XML::SAX::Writer version 0.39 and above required to use SAX2 export"); }
  else
    { eval "require XML::Filter::BufferText;";
      if( $@)
        { skip(5, "XML::Filter::BufferText not available"); }
      else
        { import XML::SAX::Writer;
          import XML::Filter::BufferText;
          my $output='';
          my $writer = XML::SAX::Writer->new( Output => \$output);
          my $xmldecl= qq{<?xml version="1.0" encoding="UTF-8"?>};
          my $body= qq{<doc><!-- comment --><p att="p1">text</p><?target pi ?><ns xmlns:foo="uri2"><foo:e foo:att="bar">foo:e text</foo:e></ns><ns xmlns="uri2"><e att="tata">t</e></ns><p><![CDATA[ some cdata]]></p>[</doc>};
          my $doc= $xmldecl.$body;
          my $xfbtv= $XML::Filter::BufferText::VERSION;  
          if( $xfbtv < 1.01)
            { skip( 2, "XML::Filter::BufferText version $xfbtv has a bug in CDATA processing"); }
          else
            {
              my $t= XML::Twig->new( comments =>'process', pi => 'process')->parse( $doc);
              # add private data
              $t->root->set_att( '#priv' => 'private');
              $t->root->insert_new_elt( last_child => '#private');
              $t->toSAX2( $writer);
              is( normalize_xml( $output), $doc, 'toSAX2');# test 362
              $output='';
              $t->root->toSAX2( $writer);
              is( normalize_xml( $output), $body, 'flush_toSAX2');# test 363
            }

          my $doc_flush="<doc><p>p 1</p><add/><p/><p>text<flush/> more text</p></doc>";
          my $doc_flushed=qq{<doc><p>p 1</p><add/><g>a</g><p/><p>text<flush/> more text</p></doc>};
          $output='';

          my $t= XML::Twig->new( twig_handlers => 
                  { add =>   sub { $_[0]->flush_toSAX2( $writer);
                                   $_->new( g => "a")->toSAX2( $writer);
                                 },
                    flush => sub { $_[0]->flush_toSAX2( $writer); },
                  }
                               )
                          ->parse( $doc_flush);
          $t->flush_toSAX2( $writer);
          is( normalize_xml( $output), $doc_flushed, 'flush_toSAX2');# test 364

          $doc= qq{<!DOCTYPE doc [ <!ENTITY toto "foo">]><doc>toto = &toto;</doc>};
          $t= XML::Twig->new()->parse( $doc);
          $output='';
          $writer = XML::SAX::Writer->new( Output => \$output);
          $t->toSAX2( $writer);
          $output=~ s{<!DOCTYPE.*?>}{}s; # shows that in fact we have a problem with outputing the DTD
          is( normalize_xml( $output), '<doc>toto = foo</doc>', 'toSAX2 with an entity');# test 365

          $doc= qq{<!DOCTYPE doc SYSTEM "not_there" ><doc>toto = &toto;</doc>};
          $t= XML::Twig->new()->parse( $doc);
          $output='';
          $writer = XML::SAX::Writer->new( Output => \$output);
          $t->toSAX2( $writer);
          is( normalize_xml( $output), normalize_xml( $doc), 'toSAX2 with a non expanded entity');# test 366
        }
 
    }
}

# test flushed an twig_current status (not a very good test, but the methods are not used in practice)
{ my $t= XML::Twig->new->parse( '<doc />');
  nok( $t->root->_flushed, "root is not flushed");# test 367
  $t->root->_set_flushed;
  ok( $t->root->_flushed, "root is flushed");# test 368
  $t->root->_del_flushed;
  nok( $t->root->_flushed, "root is not flushed");# test 369

  nok( $t->root->{twig_current}, "root is not twig current");# test 370
  $t->root->set_twig_current;
  ok( $t->root->{twig_current}, "root is twig current");# test 371
  $t->root->del_twig_current;
  nok( $t->root->{twig_current}, "root is not twig current");# test 372

  ok( $t->root->closed, "root is closed");# test 373

}


# test ignore
{ my $t= XML::Twig->new( start_tag_handlers => { ignore         => sub { $_[0]->ignore },
                                                 ignore_parent  => sub { $_->parent->ignore },
                                               },
                       )
                  ->parse( '<doc><p>yes 1</p><ignore><p>no 1</p></ignore><p>yes 2</p><ignore/>
                            <p><p>no 2</p><ignore_parent/></p></doc>');
  is( $t->sprint, '<doc><p>yes 1</p><p>yes 2</p></doc>', "ignore");# test 374
}

# test subs_text with replacement
{ my $doc= '<doc>text rep <p>text rep</p> text rep</doc>';
  (my $rep1= $doc)=~ s/rep/newr/g;
  (my $rep2= $doc)=~ s{rep}{<b>new</b>}g;
  (my $rep3= $rep2)=~ s{ }{&nbsp;}g;
  my $t= XML::Twig->new->parse( $doc);
  $t->root->subs_text( qr/(r)ep/,  'new$1');
  is( $t->sprint, $rep1, "subs_text");# test 375
  $t->root->subs_text( qr/(new)r/,  '&elt( b => $1)');
  is( $t->sprint, $rep2, "subs_text (with elt)");# test 376
  $t->root->subs_text( qr/ /,  '&ent( "&nbsp;")');
  is( $t->sprint, $rep3, "subs_text (with ent)");# test 377
  
}

# test handlers that are not activated in 5.8

package test_handlers;
sub new { bless { } }
sub recognized_string { return 'recognized_string'; }
sub original_string { return 'original_string'; }

package main;

{ if( $perl < 5.008)  
    { skip( 4, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { 
      my $out='';
      $open->( my $fh, ">", \$out);
      my $stdout= select $fh;
      XML::Twig::_twig_print_original_default( test_handlers->new);
      select $stdout;
      close $fh;
      is( $out, 'original_string', 'twig_print_original_default');# test 378

      $out='';
      $open->( $fh, ">", \$out);
      select $fh;
      XML::Twig::_twig_print( test_handlers->new);
      select $stdout;
      close $fh;
      is( $out, 'recognized_string', 'twig_print');# test 379

      $out='';
      $open->( $fh, ">", \$out);
      select $fh;
      XML::Twig::_twig_print_end_original( test_handlers->new);
      select $stdout;
      close $fh;
      is( $out, 'original_string', 'twig_print_end_original');# test 380

      $out='';
      $open->( $fh, ">", \$out);
      select $fh;
      XML::Twig::_twig_print( test_handlers->new);
      select $stdout;
      close $fh;
      is( $out, 'recognized_string', 'twig_print');# test 381
    }
  XML::Twig::_twig_print_entity; # does nothing!

}
      
{ 
  my %ents= ( foo => '"toto"', pile => 'SYSTEM "file.bar" NDATA bar');
  my %ent_text = hash_ent_text( %ents);
  my $ent_text = string_ent_text( %ents); 

  my $doc= "<!DOCTYPE doc [$ent_text]><doc/>";

  my $t= XML::Twig->new->parse( $doc);
  is( normalize_xml( $t->entity_list->text), $ent_text, 'entity_list');# test 382
  my @entities= $t->entity_list->list;
  is( scalar @entities, scalar keys %ents, 'entity_list');# test 383

  if( $perl < 5.008)  
    { skip( (scalar( keys %ents) + 1), "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { 
      foreach my $ent (@entities)
        { my $out='';
          $open->( my $fh, ">", \$out);
          my $stdout= select $fh;
          $ent->print;
          close $fh;
          select $stdout;
          is( normalize_xml( $out), $ent_text{$ent->name}, "print $ent->{name}"); # 2 tests 384 - 385
        }
      my $out='';
      $open->( my $fh, ">", \$out);
      my $stdout= select $fh;
      $t->entity_list->print;
      close $fh;
      select $stdout;
      is( normalize_xml( $out), $ent_text, 'print entity_list');# test 386

    }
           
  delete $ents{pile}; 
  %ent_text = hash_ent_text( %ents);
  $ent_text = string_ent_text( %ents);
  $t->entity_list->delete( 'pile');
  @entities= $t->entity_list->list;
  is( scalar @entities, scalar keys %ents, '1 entity deleted');# test 387
  is( $t->entity_list->text, $ent_text, 'entity_list (one entity deleted)');# test 388

}

{
  if( $perl < 5.008)  
    { skip( 3, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $out1=''; $open->( my $fh1, ">", \$out1);
      my $out2=''; $open->( my $fh2, ">", \$out2);
      my $out3=''; $open->( my $fh3, ">", \$out3);

      my $stdout= select $fh3; 
      my $t= XML::Twig->new( twig_handlers => { e => sub { $_->print( $fh2); 
                                                           print $fh1 "X"; 
                                                           $_[0]->finish_print( $fh1);
                                                         },
                                              },
                           )
                      ->parse( '<doc>text<e>e <p>text</p></e>more text <p>foo</p></doc>');
      print 'should be in $out3';
      select $stdout;
      is( $out1, 'Xmore text <p>foo</p></doc>', 'finish_print');# test 389
      is( $out2, '<e>e <p>text</p></e>', 'print to fh');# test 390
      is( $out3, 'should be in $out3', 'restoring initial fh');# test 391
   
    }
}

# test prefix mappings

package test_sax_prefix_mapping;

sub new                  { return bless { out => 'start ' }; }
sub start_element        { my( $h, $element)= @_; $h->{out}.= "- start $element->{Name} "; }
sub end_element          { my( $h, $element)= @_; $h->{out}.= "- end $element->{Name} "; }
sub start_prefix_mapping { my( $h, $map)= @_; $h->{out}.= "- map $map->{Prefix} to $map->{NamespaceURI} "; }
sub end_prefix_mapping   { my( $h, $map)= @_; $h->{out}.= "- end map $map->{Prefix} "; }
sub end_document         { my( $h, $document)= @_; return $h->{out}; }

package main;

{ my $h= test_sax_prefix_mapping->new;
  my $t= XML::Twig->new->parse( q{<doc xmlns="uri1"><p xmlns:p1="uri2"><p1:e>text</p1:e></p>
                                  <p xmlns:p1="uri3"><p1:e>text</p1:e></p></doc>});
  my $out= $t->toSAX2( $h);
  is( $out, 'start - map  to uri1 - start doc - map p1 to uri2 - start p - start p1:e - end p1:e - end p - end map p1 - map p1 to uri3 - start p - start p1:e - end p1:e - end p - end map p1 - end doc - end map  ', 'prefix mapping');# test 392
}

# test parsing with keep_encoding (to check no spurious warnings are produced)
{ my $warnings='';
  $SIG{__WARN__}= sub { $warnings .= shift; };
  my $doc= '<doc><p att1="v1" att2="v2">text</p><p>more text &gt; &#xe9; </p></doc>';
  my $t= XML::Twig->new( keep_encoding => 1)->parse( $doc);
  $SIG{__WARN__}= $old_warning_handler;
  is( $warnings, '', 'keep_encoding with elements with no attributes');# test 393
  is( $t->sprint, $doc, 'twig output');# test 394
}

# test end_tag_handlers with ignore
{
my $out='';
my $t= XML::Twig->new( twig_roots         => { p => 1 },
                       start_tag_handlers => { x => sub { $out .= "s" } },
                       twig_handlers      => { n => sub { $out .="n";},
                                               x => sub { $out .="e"; }
                                             },
                     )
                ->parse( '<doc><p>text <x>text <n/> </x> more <x/> text</p><n/></doc>');
is( $out, 'snese', 'end_tag_handlers without ignore');# test 395

$out='';
$t= XML::Twig->new( twig_roots         => { p => 1 },
                       start_tag_handlers => { x => sub { $out .= "s"; $_->ignore } },
                       end_tag_handlers   => { x => sub { $out .="e"; },            },
                       twig_handlers      => { n => sub { $out .="n"; },            },
                     )
                ->parse( '<doc><p>text <x>text <n/> </x> more <x/> text</p><n/></doc>');
is( $out, 'sese', 'end_tag_handlers with ignore');# test 396

eval ' XML::Twig->new( start_tag_handlers => { x => sub { $out .= "s"; $_->ignore } },
                       end_tag_handlers   => { x => sub { $out .="e"; },            },
                       twig_handlers      => { n => sub { $out .="n"; },            },
                     );
     ';
matches( $@, '^you should not use EndTagHandlers without', "error using end_tag_handlers");# test 397


$out='';
$t= XML::Twig->new(    force_end_tag_handlers_usage => 1,
                       start_tag_handlers => { x => sub { $out .= "s"; $_->ignore } },
                       end_tag_handlers   => { x => sub { $out .="e"; },            },
                       twig_handlers      => { n => sub { $out .="n"; },            },
                     )
                ->parse( '<doc><p>text <x>text <n/> </x> more <x/> text</p><n/></doc>');
is( $out, 'sesen', 'end_tag_handlers with ignore and force_end_tag_handlers_usage');# test 398

}

{ my @doc=( "<root><l1><lignore><l2/></lignore><foo/></l1><foo/></root>",
            "<root><l1><l2><lignore><l3/></lignore><foo/></l2></l1><foo/></root>",
            "<root><l1><l2><lignore><l3/></lignore></l2></l1><foo/></root>",
            "<root><l1><l2><lignore><l3/></lignore></l2><foo/></l1><foo/></root>",
          );

my( @r1, @r2, @r3, @r4);
my $t1= XML::Twig->new( ignore_elts   => { lignore => 1 },
                        twig_handlers => { root    => sub { push @r1, $_->tag; },
	                                       l1      => sub { push @r1, $_->tag; },
	                                     }
                     );
my $t2= XML::Twig->new( twig_handlers => { root    => sub { push @r2, $_->tag; },
                                           lignore => sub { $_->parent( 'l1')->ignore; },
	                                     },
                     );
my $t3= XML::Twig->new( 
                        twig_handlers => { root    => sub { push @r3, $_->tag; },
                                           lignore => sub { $_->parent( 'l1')->ignore; },
	                                     },
	                    end_tag_handlers => { l1   => sub { push @r3, $_[1]; }, },
                        force_end_tag_handlers_usage => 1
                     );
my $t4= XML::Twig->new( twig_roots => { l1    => sub { push @r4, 'l1 from roots handler'; },
                                        lignore => sub { $_->parent( 'l1')->ignore; },
	                                  },
	                    end_tag_handlers => { 'root/l1'   => sub { push @r4, 'l1 from end_tag_handler'; }, },
                     );
my $i=0;
foreach my $doc (@doc)
  { @r1=(); @r2=(); @r3=(); @r4=();
    $i++;
    $t1->parse( $doc);
    is( join( ':', @r1), "l1:root", "ignore_elt with twig_handlers $i (checking that stack is properly resized)");
    $t2->parse( $doc);
    is( join( ':', @r2), "root", "ignore_elt on ancestor with twig_handlers $i (checking that stack is properly resized)");
    $t3->parse( $doc);
    is( join( ':', @r3), "l1:root", "ignore_elt on ancestor with twig_handlers and end_tag_handlers $i (checking that stack is properly resized)");
    $t4->parse( $doc);
    is( join( ':', @r4), "l1 from end_tag_handler", "ignore_elt on ancestor with twig_roots and end_tag_handlers $i (checking that stack is properly resized)");
  }
}


{
my $warning="";
$SIG{__WARN__} = sub { $warning .= join '', @_ };
my $t= XML::Twig->new( dummy_opt2 => 1);
$SIG{__WARN__}= $old_warning_handler; 
matches( $warning, '^invalid option', "warning for extra option");# test 399

}


# test various handlers
{ my %got;
  my $doc= '<doc id="doc1"><e id="e1"/><no id="no1"/>
                           <a id="a1" a1="v11" a2="v12"/><a id="a2" a1="v21" a2="v22"/>
                           <b id="b1" a1="v11" a2="v12"/><b id="b2" a1="v21" a2="v22"/>
                           <t id="t1">foobar</t><t id="t2">foo</t><t id="t3">no</t>
            </doc>';
  my @handler_exp= ( 'e', 'doc/e', '/doc/e', 'a[@a1]', 'a[@a2]', 'a[@a1="v11"]',
                     'a[@a1="v21"]', '*[@a1]', '*[@a1="v11"]', '*[@a1="v21"]', '*[@a1=~/^v21$/]',
                     't[string()="foobar"]', 't[string()=~ /^foo/]', 't[string()=~ /bar$/]',
                     '_default_',
                   );
  my %handlers;
  foreach my $exp (@handler_exp)
    { my $code= "\$got{\$_->id}||=[]; push \@{\$got{\$_->id}}, '$exp'; 1";
      my $sub= eval "sub { $code }";
      die "oops, error in test, code is '$code'" if( $@);
      $handlers{$exp}= $sub;
    }
  my $t= XML::Twig->new( twig_handlers => \%handlers)->parse( $doc);
  my %expected= ( e1   => [ '/doc/e', 'doc/e', 'e' ],
                  no1  => [ '_default_'],
                  a1   => [ '*[@a1]', '*[@a1="v11"]', 'a[@a1]', 'a[@a2]', 'a[@a1="v11"]' ],
                  a2   => [ '*[@a1]', '*[@a1="v21"]', 'a[@a1]', 'a[@a2]', 'a[@a1="v21"]', '*[@a1=~/^v21$/]' ],
                  b1   => [ '*[@a1]', '*[@a1="v11"]' ],
                  b2   => [ '*[@a1="v21"]', '*[@a1]', '*[@a1=~/^v21$/]'],
                  t1   => [ 't[string()="foobar"]', 't[string()=~ /^foo/]', 't[string()=~ /bar$/]' ],
                  t2   => [ 't[string()=~ /^foo/]' ],
                  t3   => [ '_default_'],
                  doc1 => [ '_default_'],
                );
  foreach my $elt (sort keys %expected)
    { my $expected= join( ' - ', sort @{$expected{$elt}});
      my $got= $got{$elt} ? join( ' - ', sort @{$got{$elt}}) : '';
      is( $got, $expected, "handlers on $elt"); # 10 tests 400 - 409
    }

  my %handlers2;
  my %got2;
  foreach my $exp (@handler_exp)
    { my $code= "\$got2{\$_->id}||=[]; push \@{\$got2{\$_->id}}, '$exp:2'; 1";
      my $sub= eval "sub { $code }";
      die "oops, error in test, code is '$code'" if( $@);
      $t->setTwigHandler( $exp, $sub);
    }
  $t->parse( $doc);
  foreach my $elt (sort keys %expected)
    { my $expected= join( ' - ', map { "$_:2" } sort @{$expected{$elt}});
      my $got= $got2{$elt} ? join( ' - ', sort @{$got2{$elt}}) : '';
      is( $got, $expected, "handlers on $elt (2)"); # 10 tests 410 - 419
    }
  
}

{ my $t= XML::Twig->new->parse( '<doc><elt1/><elt2/><elt3/></doc>');
  $t->change_gi( elt1 => 'elt2');
  $t->change_gi( elt3 => 'elt4');
  is( $t->sprint, '<doc><elt2/><elt2/><elt4/></doc>', 'change_gi');# test 420
}

# these do not pass (yet?)
{ my $doc= '<doc><p>text</p><i>&lt;ignored&gt;</i><p>more text</p></doc>';
  my $t= XML::Twig->new( start_tag_handlers => { i => sub { $_->ignore( 'string') }})
                  ->parse( $doc);
  is( $t->sprint, '<doc><p>text</p><p>more text</p></doc>', 'ignore');# test 421
  $t->set_keep_encoding( 1);
  $t->parse( $doc);
  is( $t->sprint, '<doc><p>text</p><p>more text</p></doc>', 'ignore');# test 422
  XML::Twig::Elt::set_keep_encoding( 0);
}

{ my $t= XML::Twig->new->parse( '<doc xmlns:ns1="uri2"><p xmlns="uri" ns1:att="foo"/></doc>');
  my $p= $t->first_elt( '*[@ns1:att=~/^f/]');
  is( $p->namespace, 'uri', 'namespace on elt');# test 423
  is( $p->namespace( 'ns1'), 'uri2', 'namespace with arg');# test 424
  is( $p->namespace( 'xmlns'), 'http://www.w3.org/2000/xmlns/', 'namespace for xmlns');# test 425
  is( $t->root->namespace(), '', 'default namespace');# test 426
  is( $t->root->namespace( ''), '', 'namespace with arg default');# test 427
  is( $t->root->namespace( 'xml'), 'http://www.w3.org/XML/1998/namespace', 'namespace for xml');# test 428
}

{ my $t= XML::Twig->new->parse( '<doc><e id="e1"/><f id="f1" att="foo"/><e id="e2" att="foo"/><e id="e3"/><t id="t1">text</t></doc>');
  is( $t->root->first_child( 'e[@att="foo"]')->id, 'e2', 'cond on att value');# test 429
  is( $t->root->first_child( '*[@att="foo"]')->id, 'f1', 'cond on att value (with wc)');# test 430
  is( $t->root->first_child( '*[@att="foo" and @id="e2"]')->id, 'e2', 'and cond on att value');# test 431
  is( $t->root->first_child( '*[@att="foo" or @id="e2"]')->id, 'f1', 'and cond on att value');# test 432
  is(  $t->root->first_child( 't[string()="text"]')->id, 't1', 'string cond');# test 433
  is(  $t->root->first_child( '*[string()="text"]')->id, 't1', 'string cond wc');# test 434
  is(  $t->root->first_child( 't[string()=~/^t/]')->id, 't1', 'regexp cond');# test 435
  is(  $t->root->first_child( '*[string()=~/^t/]')->id, 't1', 'regexp cond wc');# test 436
  is(  $t->root->first_child( qr/^t/)->id, 't1', 'regexp cond wc');# test 437

  my $sprint= $t->root->first_child( 't')->sprint;
  $t->root->first_child( 't')->change_att_name( 'foo');

  is( $t->root->first_child( 't')->sprint, $sprint, 'change_att_name on non existent att');# test 438
  my $ids= join ':', sort keys %{$t->{twig_id_list}};
  my $elt= XML::Twig::Elt->new( 'e');
  is( $elt->sprint, '<e/>', 'new elt');# test 439
  $elt->del_id;
  is( $elt->sprint, '<e/>', 'del_id, no id');# test 440
  $elt->set_id( 'new_e');
  is( $elt->sprint, '<e id="new_e"/>', 'set_id');# test 441
  my( $new_ids)= join ':', sort keys %{$t->{twig_id_list}};
  is( $new_ids, $ids, 'set_id on elt not in the tree');# test 442
  $elt->del_id;
  is( $elt->sprint, '<e/>', 'del_id, id removed');# test 443

  nok( $t->first_elt( 'e')->next_elt(  $t->first_elt( 'e')), 'next_elt on empty subtree');# test 444
  nok( $t->first_elt( 'e')->next_elt($t->first_elt( 'e'), 'e'), 'next_elt on empty subtree');# test 445

  is( $t->root->get_xpath( './e[1]', 0)->id, 'e1', 'get_xpath with ./');# test 446
  is( $t->root->first_child->get_xpath( '/doc/e[1]', 0)->id, 'e1', 'get_xpath with /');# test 447
  is( $t->root->first_child->get_xpath( '/doc/e[-1]', 0)->id, 'e3', 'get_xpath with /');# test 448
  is( $t->root->first_child->get_xpath( './../e[2]', 0)->id, 'e2', 'get_xpath with ..');# test 449
  is( $t->root->first_child->get_xpath( './../*[2]', 0)->id, 'f1', 'get_xpath with ../*[2]');# test 450
  is( $t->root->first_child->get_xpath( './../*', 0)->id, 'e1', 'get_xpath with ../*');# test 451

}

{ my $t= XML::Twig->new->parse( '<doc><e/><e/></doc>');
  is( $t->root->cmp( $t->root), 0, 'cmp root with itself');# test 452
  my $ne= $t->root->new( 'ne');
  is( $ne->cmp( $ne), 0, 'cmp with itself');# test 453
  is_undef( $t->root->cmp( $ne), 'cmp elt in different trees');# test 454
  my $t_sprint= $t->sprint;
  $t->root->field_to_att( 'foo');
  is( $t->sprint, $t_sprint, 'field_to_att on wrong field');# test 455
  my $ne_sprint= $ne->sprint;
  $ne->field_to_att( 'foo');
  is( $ne->sprint, $ne->sprint, 'field_to_att on wrong field (no child)');# test 456

  $ne->prefix( '<p1>p 1</p1>pr', 'asis');
  is(  $ne->sprint, '<ne><p1>p 1</p1>pr</ne>', 'prefix asis');# test 457
  $ne->prefix( '<p2>p 2</p2>', 'asis');
  is(  $ne->sprint, '<ne><p2>p 2</p2><p1>p 1</p1>pr</ne>', 'prefix asis');# test 458
  $ne->suffix( '<s1>s 1</s1>su', 'asis');
  is(  $ne->sprint, '<ne><p2>p 2</p2><p1>p 1</p1>pr<s1>s 1</s1>su</ne>', 'prefix asis');# test 459
  $ne->suffix( '<s2>s 2</s2>', 'asis');
  is(  $ne->sprint, '<ne><p2>p 2</p2><p1>p 1</p1>pr<s1>s 1</s1>su<s2>s 2</s2></ne>', 'prefix asis');# test 460
}

{ my $t=  XML::Twig->new( twig_handlers => { w => sub { $_->wrap_in( 'ww'); } })
                   ->parse( '<doc><p/><w>text <i/></w><p/></doc>');
  is( $t->sprint, '<doc><p/><ww><w>text <i/></w></ww><p/></doc>', 'wrap current elt');# test 461
  $t->root->wrap_in( 'd');
  is( $t->sprint, '<d><doc><p/><ww><w>text <i/></w></ww><p/></doc></d>', 'wrap root');# test 462
}

{ my $t=  XML::Twig->new( twig_handlers => { w => sub { $_->parent->wrap_in( 'ww'); } })
                   ->parse( '<doc><p><w>text</w></p></doc>');
  is( $t->sprint, '<doc><ww><p><w>text</w></p></ww></doc>', 'wrap real current elt');# test 463
}
{ my $t=  XML::Twig->new( twig_handlers => { w => sub { $_->parent->wrap_in( 'ww'); } })
                   ->parse( '<doc><p><w>text</w><x/></p></doc>');
  is( $t->sprint, '<doc><ww><p><w>text</w></p><x/></ww></doc>', 'wrap current elt');# test 464
}



my $doc=q{<?xml version="1.0"?><!DOCTYPE doc [<!ENTITY eqn1 SYSTEM "eqn1.jpg" NDATA JPG>]><doc/>};
my $t= XML::Twig->new->parse( $doc);
(my $out= $t->sprint)=~ s{\n}{}g; 
is( $out, $doc, 'doc with entities but no DTD');# test 465


# test is_first(last)_child
{ my $t= XML::Twig->new->parse( q{<doc><elt1/><elt2/><elt3/></doc>});
  my $root= $t->root;
  $root->reset_cond_cache;
  nok( $root->is_first_child(), 'root as first child');# test 466

  nok( $root->is_last_child(), 'root as last child');# test 467

  my $elt1= $root->first_child( 'elt1');
  ok( $elt1->is_first_child(), 'first_child, no argument');# test 468

  ok( $elt1->is_first_child( 'elt1'), 'first_child( elt1)');# test 469

  nok( $elt1->is_first_child( 'elt2'), 'first_child( elt2)');# test 470

  nok( $elt1->is_first_child( 'dummy'), 'first_child( dummy)');# test 471

  nok( $elt1->is_last_child( ), 'last_child');# test 472

  ok( $elt1->is_last_child(  'elt1'), 'last_child( elt1)');# test 473

  nok( $elt1->is_last_child( 'elt2'), 'last_child( elt2)');# test 474

  nok( $elt1->is_last_child( 'dummy'), 'last_child( dummy)');# test 475

}

# testing alternate start tag parser
{ my $t=XML::Twig->new( keep_encoding => 1, parse_start_tag => sub { return ( toto => att => 1)})
                 ->parse( '<doc/>');
  is( $t->sprint, '<toto att="1"/>', 'parse_start_tag');# test 476

}
{ my $t=XML::Twig->new( parse_start_tag => sub { return ( toto => att => 1)})
                 ->parse( '<doc/>');
  is( $t->sprint, '<toto att="1"/>', 'parse_start_tag');# test 477

}

# testing output_filter option
{ my $t= XML::Twig->new( output_filter => sub { return 'a' })->parse( '<doc><elt/></doc>');
  is( $t->sprint, 'a', 'output_filter option');# test 478

}

# testing output_text_filter option
{ my $t= XML::Twig->new( output_text_filter => sub { return 'a' })->parse( '<doc><elt/></doc>');
  is( $t->sprint, '<a><a/></a>', 'output_text_filter option');# test 479

}
 
# testing id option
{ my $t= XML::Twig->new( id => "foo")
                  ->parse( '<doc foo="f1" id= "f2"><elt foo="f2" id= "f1">bar</elt></doc>');
  is( $t->elt_id( "f2")->sprint, '<elt foo="f2" id="f1">bar</elt>', 'id option');# test 480

}

# testing no_prolog option
{ my $t= XML::Twig->new( no_prolog => 1)
                  ->parse( '<?xml version="1.0"?><doc/>');
  is( $t->sprint, '<doc/>', 'no_prolog option');# test 481

}

# testing no_prolog option
{ my $t= XML::Twig->new( no_prolog => 1, keep_encoding => 1)
                  ->parse( '<?xml version="1.0"?><doc/>');
  is( $t->sprint, '<doc/>', 'no_prolog option');# test 482

}

# testing _all_ handler
{ my $nb_calls= 0;
  my $t= XML::Twig->new( twig_handlers => { _all_ => sub { $nb_calls++ } })
                  ->parse( '<doc><elt att="foo">text</elt><elt2/></doc>');
  is( $nb_calls, 3, '_all_ handler');# test 483

}
{ my $nb_calls= 0;
  my $t= XML::Twig->new( start_tag_handlers => { _all_ => sub { $nb_calls++ } })
                  ->parse( '<doc><elt att="foo">text</elt><elt2/></doc>');
  is( $nb_calls, 3, '_all_ handler (on starttag)');# test 484

}

# test changing handlers
# expressions in @exp must match the elements
{ my @exp= ( 'elt', 'doc/elt', '/doc/elt', 'elt[@att]', 'elt[@att="att1"]', 
             '*[@att]', '*[@att="att1"]', '*[@att=~/att/]',
             'elt[@att=~/^att/]', '_default_', 
             'elt[string()="toto"]', 'elt[string()=~/to/]',
             'elt[string(sub)="toto"]', 'elt[string(sub)=~/to/]',
           );

  my $doc= q{<doc><elt att="att1"><sub>toto</sub></elt><elt att="att1"><sub>toto</sub></elt>
                  <change/>
                  <elt att="att1"><sub>toto</sub></elt><elt att="att1"><sub>toto</sub></elt>
             </doc>
           };
  foreach my $exp (@exp)
    { my $res='';
      my $t= XML::Twig->new( twig_handlers => { $exp   => sub { $res .= "O"; },
                                                change => sub { $res .= "C"; 
                                                                $_[0]->setTwigHandler( $exp => sub { $res .= "N"; });
                                                                nok( $_->closed, 'closed (on open element)');# 14 tests 485 - 498
                                                              },
                                                doc    => sub { }, # so _default_ doesnt find it
                                                sub    => sub { },
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'OOCNN', "changing handlers on $exp");# 14 tests 499 - 512

    }
}

{ my $res='';
  my $doc= q{<doc><elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="3"/>
                  <change/>
                  <elt att="1"><sub>toto</sub></elt><elt att="1"><sub>toto</sub></elt><elt att="3"/>
                  <change2/>
                  <elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="1"/>
             </doc>
           };
      my %handlers= map { build_handler_on_att( 'O', $_) } (1..3);
      my $t= XML::Twig->new( twig_handlers => { %handlers,
                                                change => sub { foreach( 1..3)
                                                                  { $_[0]->setTwigHandler( build_handler_on_att( 'N', $_)) }
                                                              },
                                                change2 => sub { $_[0]->setTwigHandler( 'elt[@att="1"]', undef); 
                                                                 $_[0]->setTwigHandler( build_handler_on_att( 'D', 2));
                                                               }
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'O1O2O3N1N1N3D2', "changing handlers on atts");# test 513


  sub build_handler_on_att
    { my( $prefix, $nb)= @_;
      return( qq{elt[\@att="$nb"]} => sub { $res.= $prefix . $nb });
    }
}
{ my $res='';
  my $doc= q{<doc><elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="3"/>
                  <change/>
                  <elt att="1"><sub>toto</sub></elt><elt att="1"><sub>toto</sub></elt><elt att="3"/>
                  <change2/>
                  <elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="1"/>
             </doc>
           };
      my %handlers= map { build_att_regexp_handler( 'O', $_) } (1..3);
      my $t= XML::Twig->new( twig_handlers => { %handlers,
                                                change => sub { foreach( 1..3)
                                                                  { $_[0]->setTwigHandler( build_att_regexp_handler( 'N', $_)) }
                                                              },
                                                change2 => sub { $_[0]->setTwigHandler( 'elt[@att=~ /1/]', undef); 
                                                                 $_[0]->setTwigHandler( build_att_regexp_handler( 'D', 2));
                                                               }
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'O1O2O3N1N1N3D2', "changing handlers on regexps on atts");# test 514


  sub build_att_regexp_handler
    { my( $prefix, $nb)= @_;
      return( qq{elt[\@att=~ /$nb/]} => sub { $res.= $prefix . $nb });
    }
}

{ my $res='';
  my $doc= q{<doc><elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="3"/>
                  <change/>
                  <elt att="1"><sub>toto</sub></elt><elt att="1"><sub>toto</sub></elt><elt att="3"/>
                  <change2/>
                  <elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="1"/>
             </doc>
           };
      my %handlers= map { build_handler_on_star_att( 'O', $_) } (1..3);
      my $t= XML::Twig->new( twig_handlers => { %handlers,
                                                change => sub { foreach( 1..3)
                                                                  { $_[0]->setTwigHandler( build_handler_on_star_att( 'N', $_)) }
                                                              },
                                                change2 => sub { $_[0]->setTwigHandler( '*[@att="1"]', undef); 
                                                                 $_[0]->setTwigHandler( build_handler_on_star_att( 'D', 2));
                                                               }
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'O1O2O3N1N1N3D2', "changing handlers on star atts");# test 515


  sub build_handler_on_star_att
    { my( $prefix, $nb)= @_;
      return( qq{*[\@att="$nb"]} => sub { $res.= $prefix . $nb });
    }
}
{ my $res='';
  my $doc= q{<doc><elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="3"/>
                  <change/>
                  <elt att="1"><sub>toto</sub></elt><elt att="1"><sub>toto</sub></elt><elt att="3"/>
                  <change2/>
                  <elt att="1"><sub>toto</sub></elt><elt att="2"><sub>toto</sub></elt><elt att="1"/>
             </doc>
           };
      my %handlers= map { build_star_att_regexp_handler( 'O', $_) } (1..3);
      my $t= XML::Twig->new( twig_handlers => { %handlers,
                                                change => sub { foreach( 1..3)
                                                                  { $_[0]->setTwigHandler( build_star_att_regexp_handler( 'N', $_)) }
                                                              },
                                                change2 => sub { $_[0]->setTwigHandler( '*[@att=~ /1/]', undef); 
                                                                 $_[0]->setTwigHandler( build_star_att_regexp_handler( 'D', 2));
                                                               }
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'O1O2O3N1N1N3D2', "changing handlers on regexps on star atts");# test 516


  sub build_star_att_regexp_handler
    { my( $prefix, $nb)= @_;
      return( qq{*[\@att=~ /$nb/]} => sub { $res.= $prefix . $nb });
    }
}
{ my $res='';
  my $doc= q{<doc><elt>1</elt><elt>2</elt><elt>3</elt>
                  <change/>
                  <elt>1</elt><elt>1</elt><elt>3</elt>
                  <change2/>
                  <elt>1</elt><elt>2</elt><elt>1</elt>
             </doc>
           };
      my %handlers= map { build_string_handler( 'O', $_) } (1..3);
      my $t= XML::Twig->new( twig_handlers => { %handlers,
                                                change => sub { foreach( 1..3)
                                                                  { $_[0]->setTwigHandler( build_string_handler( 'N', $_)) }
                                                              },
                                                change2 => sub { $_[0]->setTwigHandler( 'elt[string()= "1"]', undef); 
                                                                 $_[0]->setTwigHandler( build_string_handler( 'D', 2));
                                                               }
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'O1O2O3N1N1N3D2', "changing handlers on elt[string()]");# test 517


  sub build_string_handler
    { my( $prefix, $nb)= @_;
      return( qq{elt[string()= "$nb"]} => sub { $res.= $prefix . $nb });
    }
}

{ my $res='';
  my $doc= q{<doc><elt>1</elt><elt>2</elt><elt>3</elt>
                  <change/>
                  <elt>1</elt><elt>1</elt><elt>3</elt>
                  <change2/>
                  <elt>1</elt><elt>2</elt><elt>1</elt>
             </doc>
           };
      my %handlers= map { build_regexp_handler( 'O', $_) } (1..3);
      my $t= XML::Twig->new( twig_handlers => { %handlers,
                                                change => sub { foreach( 1..3)
                                                                  { $_[0]->setTwigHandler( build_regexp_handler( 'N', $_)) }
                                                              },
                                                change2 => sub { $_[0]->setTwigHandler( 'elt[string()=~ /1/]', undef); 
                                                                 $_[0]->setTwigHandler( build_regexp_handler( 'D', 2));
                                                               }
                                              },
                           )
                      ->parse( $doc);
      is( $res, 'O1O2O3N1N1N3D2', "changing handlers on elt[string()]");# test 518


  sub build_regexp_handler
    { my( $prefix, $nb)= @_;
      return( qq{elt[string()=~ /$nb/]} => sub { $res.= $prefix . $nb });
    }
}


# test PI and comment drops
{ my $doc= q{<?xml version="1.0"?><!-- comment 1 --><?pi data?><doc><?pi2 data2?>text<?pi3 data3?><!--comment--> more text</doc>};
  (my $doc_without_pi      = $doc)=~ s{<\?pi.*?\?>}{}g;
  (my $doc_without_comment = $doc)=~ s{<!--.*?-->}{}g;
  (my $doc_without_all     = $doc)=~ s{<(\?pi|!--).*?(\?|--)>}{}g;
  my $t= XML::Twig->new( pi => 'drop',    comments => 'process')->parse( $doc);
  is( normalize_xml( $t->sprint), $doc_without_pi, 'drop pis');# test 519

  $t= XML::Twig->new( pi => 'process', comments => 'drop')->parse( $doc);
  is( normalize_xml( $t->sprint), $doc_without_comment, 'drop comments');# test 520

  $t= XML::Twig->new( pi => 'drop'   , comments => 'drop')->parse( $doc);
  is( normalize_xml( $t->sprint), $doc_without_all, 'drop comments and pis');# test 521

  my $doc6=q{<doc><elt/><?pi2 data2?>text more text</doc>};
  $t= XML::Twig->new( pi => 'keep')->parse( $doc6);
  is( _hash( normalize_xml( $t->sprint)), _hash( $doc6), 'keep pi');# test 522

  my $doc5=q{<doc><elt/><?pi2 data2?>text more text</doc>};
  $t= XML::Twig->new( pi => 'process')->parse( $doc5);
  is( normalize_xml( $t->sprint), $doc5, 'process pi');# test 523

  my $doc4=q{<?xml version="1.0"?><!-- comment 1 --><?pi data?><doc><elt/><?pi2 data2?>text more text</doc>};
  $t= XML::Twig->new->parse( $doc4);
  is( _hash( normalize_xml( $t->sprint)), _hash( $doc4), 'comment before PI (2 PIs, no comments)');# test 524

  my $doc3=q{<?xml version="1.0"?><!-- comment 1 --><?pi data?><doc><?pi2 data2?>text more text</doc>};
  $t= XML::Twig->new->parse( $doc3);
  is( _hash( normalize_xml( $t->sprint)), _hash( $doc3), 'comment before PI (2 PIs, no comments)');# test 525

  my $doc1=q{<?xml version="1.0"?><!-- comment 1 --><?pi data?><doc>t<?pi2 data2?>text<!--comment--> more text</doc>};
  $t= XML::Twig->new->parse( $doc1);
  is( _hash( normalize_xml( $t->sprint)), _hash( $doc1), 'comment before PI (2 PIs, pcdata before pi)');# test 526

  my $doc2=q{<?xml version="1.0"?><!-- comment 1 --><?pi data?><doc> <?pi2 data2?>text<!--comment--> more text</doc>};
  $t= XML::Twig->new->parse( $doc2);
  is( _hash( normalize_xml( $t->sprint)), _hash( $doc2), 'comment before PI (2 PIs)');# test 527


  $t= XML::Twig->new->parse( $doc);
  is( _hash( normalize_xml( $t->sprint)), _hash( $doc), 'comment before PI (3 PIs)');# test 528
}

# returns a string that has all the chars in the input, ordered, to allow
# comparison of texts without taking the order into consideration
sub _hash
  { return sort split //, $_[0]; }

{ my $doc=q{<doc><elt1/><elt2 att="a"/><elt7 att="b"/><elt3><elt4/></elt3><elt5 att="c"/><elt6 att="d"/><root/></doc>};
  my $res='';
  my $t= XML::Twig->new( twig_roots => { root => 1 },
                         start_tag_handlers =>
                           { 'elt1'            => sub { $res.=  'E1'; },
                             'elt2[@att="a"]'  => sub { $res .= 'E2'; },
                             'elt7[@att=~/b/]' => sub { $res .= 'E3'; },
                             '/doc/elt3'       => sub { $res .= 'E4'; },
                             'elt3/elt4'       => sub { $res .= 'E5'; },
                             '*[@att="c"]'     => sub { $res .= 'E6'; },
                             '*[@att=~/d/]'    => sub { $res .= 'E7'; },
                             _default_         => sub { $res .= 'E0'; }
                           },
                       )->parse( $doc);
  is( $res => 'E0E1E2E3E4E5E6E7E0', 'all types of handlers on start_tags');# test 529

}                  

{ my $doc= q{<doc>  <![CDATA[cdata]]></doc>};
  my $t= XML::Twig->new( keep_spaces => 1)->parse( $doc);
  is( $t->sprint, $doc, 'spaces before cdata');# test 530

}

{ my $doc= q{<doc>  <![CDATA[cdata]]>  <elt/>  <![CDATA[more cdata]]></doc>};
  my $t= XML::Twig->new( keep_spaces => 1)->parse( $doc);
  is( $t->sprint, $doc, '2 cdata sections');# test 531

}

{ my $doc= q{<doc>  <![CDATA[cdata]]>  <elt/>  <!-- comment --> <![CDATA[more cdata]]></doc>};
  my $t= XML::Twig->new( keep_spaces => 1, comments => 'process')->parse( $doc);
  is( $t->sprint, $doc, 'spaces and extra data before cdata');# test 532

}

{ # fun with suffix and asis
  my $t=XML::Twig->new->parse( '<doc>to</doc>');
  $t->root->suffix( 'to');
  is( $t->sprint, '<doc>toto</doc>', 'regular suffix');# test 533

  $t=XML::Twig->new->parse( '<doc><b>to</b></doc>');
  $t->root->suffix( 'to');
  is( $t->sprint, '<doc><b>to</b>to</doc>', 'regular suffix needs new elt');# test 534

  $t=XML::Twig->new->parse( '<doc><b>to</b></doc>');
  $t->root->suffix( '<to/>', 'asis');
  is( $t->sprint, '<doc><b>to</b><to/></doc>', 'asis suffix needs new elt');# test 535

  $t=XML::Twig->new->parse( '<doc>to</doc>');
  $t->root->suffix( '<to/>', 'asis');
  is( $t->sprint, '<doc>to<to/></doc>', 'asis suffix');# test 536

  $t=XML::Twig->new->parse( '<doc>&lt;to/&gt;</doc>');
  $t->root->set_asis( 1);
  $t->root->suffix( '<to/>', 'asis');
  is( $t->sprint, '<doc><to/><to/></doc>', 'asis suffix (on asis elt)');# test 537

  $t=XML::Twig->new->parse( '<doc>&lt;to/&gt;</doc>');
  $t->root->set_asis( 1);
  $t->root->suffix( '<to/>');
  is( $t->sprint, '<doc><to/>&lt;to/></doc>', 'regular suffix (on asis elt)');# test 538

}
{ # fun with prefix and asis
  my $t=XML::Twig->new->parse( '<doc>to</doc>');
  $t->root->prefix( 'to');
  is( $t->sprint, '<doc>toto</doc>', 'regular prefix');# test 539

  $t=XML::Twig->new->parse( '<doc><b>to</b></doc>');
  $t->root->prefix( '<to/>', 'asis');
  is( $t->sprint, '<doc><to/><b>to</b></doc>', 'regular prefix needs new elt');# test 540

  $t=XML::Twig->new->parse( '<doc><b>to</b></doc>');
  $t->root->prefix( 'to');
  is( $t->sprint, '<doc>to<b>to</b></doc>', 'asis prefix needs new elt');# test 541

  $t=XML::Twig->new->parse( '<doc>to</doc>');
  $t->root->prefix( '<to/>', 'asis');
  is( $t->sprint, '<doc><to/>to</doc>', 'asis prefix');# test 542

  $t=XML::Twig->new->parse( '<doc>&lt;to/&gt;</doc>');
  $t->root->set_asis( 1);
  $t->root->prefix( '<to/>', 'asis');
  is( $t->sprint, '<doc><to/><to/></doc>', 'asis prefix (on asis elt)');# test 543

  $t=XML::Twig->new->parse( '<doc>&lt;to/&gt;</doc>');
  $t->root->set_asis( 1);
  $t->root->prefix( '<to/>');
  is( $t->sprint, '<doc>&lt;to/><to/></doc>', 'regular suffix (on asis elt)');# test 544

}

{ # wrap_in on the current
  my $t= XML::Twig->new( twig_handlers => { wrapped => sub { $_->wrap_in( wrapper => { foo => 'bar'} )} })
                  ->parse( '<doc>toto<wrapped>tata</wrapped><elt/></doc>');
  is( $t->sprint,  '<doc>toto<wrapper foo="bar"><wrapped>tata</wrapped></wrapper><elt/></doc>', 'wrap_in');# test 545

}

{ my $t= XML::Twig->new->parse( q{<doc><elt1/><elt2 att1="a1"/><elt3 att1="a2" att2="a3"/></doc>});
  ok ( $t->first_elt( 'elt1')->has_no_atts, 'has_no_atts true');# test 546

  nok( $t->first_elt( 'elt2')->has_no_atts, 'has_no_atts false');# test 547

  nok( $t->first_elt( 'elt3')->has_no_atts, 'has_no_atts false');# test 548

  nok ( $t->first_elt( 'elt1')->has_atts, 'has_atts false');# test 549

  ok( $t->first_elt( 'elt2')->has_atts, 'has_atts true');# test 550

  ok( $t->first_elt( 'elt3')->has_atts, 'has_atts true');# test 551

  is( $t->first_elt( 'elt1')->att_nb, 0, 'att_nb, 0');# test 552

  is( $t->first_elt( 'elt2')->att_nb, 1, 'att_nb, 1');# test 553

  is( $t->first_elt( 'elt3')->att_nb, 2, 'att_nb, 2');# test 554

}

{ my $t= XML::Twig->new->parse( '<doc><p>titi</p></doc>');
  $t->root->split( qr/(i)/);
  is( $t->sprint, '<doc><p>t<p>i</p>t<p>i</p></p></doc>', "split with no tag");# test 555
}

{ my $t= XML::Twig->new->parse( '<doc><p>titi toto</p></doc>');
  $t->root->split( 'b');
  is( $t->sprint, '<doc><p>titi toto</p></doc>', "split with no regexp");# test 556
}

{ my $t= XML::Twig->new->parse( '<doc><p>titi toto</p></doc>');
  $t->root->split( qr/foo/, 'ta');
  is( $t->sprint, '<doc><p>titi toto</p></doc>', 'split, no match');# test 557
}

{ my $doc= '<?xml version="a.0"?><!DOCTYPE doc SYSTEM "no_dtd" []> <doc att="val"><p att="val">toto &ent; <![CDATA[ toto]]></p></doc>';
  my $t= XML::Twig->new->parse( $doc);
  my $alt_root= $t->root->copy;
  is( $alt_root->sprint, $t->root->sprint, 'copy with entity');# test 558

}

{ my $doc= '<doc>toto</doc>';
  my $t= XML::Twig->new->parse( $doc);
  my $pcdata= $t->first_elt( '#TEXT');
  my $start_tag= $pcdata->start_tag;
  nok( $start_tag, 'start_tag for a text element');# test 559
  $t->root->set_att( '#priv_att' => 1);
  is( $t->sprint, $doc, 'private attributes');# test 560
  my $priv_elt= $t->root->insert( '#priv_elt');
  is( $t->sprint, $doc, 'private element');# test 561
  $priv_elt->set_gi( 'foo');
  is( $t->sprint, '<doc><foo>toto</foo></doc>', 'private element');# test 562
  $priv_elt->set_gi( '#priv');
  is( $t->sprint, $doc, 'private element');# test 563
  $priv_elt->set_att( att => "val");
  is( $t->sprint, $doc, 'private element');# test 564
  $priv_elt->set_gi( 'foo');
  is( $t->sprint, '<doc><foo att="val">toto</foo></doc>', 'private element');# test 565
}

{ my $doc= qq{<doc><record><!-- field 1 --><f1>val1</f1><f2>val2</f2></record></doc>};
  my $out= qq{\n<doc>\n  <record>\n    <!-- field 1 -->\n    <f1>val1</f1>\n    <f2>val2</f2>\n  </record>\n</doc>\n};
  my $t=XML::Twig->new( pretty_print => 'record')->parse( $doc);
  is( $t->sprint, $out, 'record with empty record');# test 566
  $t->set_pretty_print( 'none');
}

{ my $e= XML::Twig::Elt->new( 'toto');
  nok( scalar $e->_is_private, 'private elt (not)');# test 567
  $e->set_tag( '#toto');
  ok( scalar $e->_is_private, 'private elt (yes)');# test 568
  ok( scalar XML::Twig::Elt::_is_private_name( '#toto'), '_is_private_name (yes)');# test 569
  nok( scalar XML::Twig::Elt::_is_private_name( 'toto'), '_is_private_name (no)');# test 570
}

{ my $t= XML::Twig->new->parse( '<doc><![CDATA[toto]]></doc>');
  my $text_elt= $t->first_elt( '#TEXT');
  is( $text_elt->xml_string, '<![CDATA[toto]]>', 'xml_string for cdata');# test 571
  $text_elt->set_text( '<>');
  is( normalize_xml( $t->sprint), '<doc><![CDATA[<>]]></doc>', 'set_text on CDATA');# test 572
  $text_elt->set_text( '<>', force_pcdata => 1);
  is( normalize_xml( $t->sprint), '<doc>&lt;></doc>', 'set_text on CDATA (with force_pcdata)');# test 573
  $t->root->set_content( { att => "val" }, 'toto ', 'tata');
  is( $t->root->sprint, '<doc att="val">toto tata</doc>', 'set_content with attributes');# test 574
  $text_elt= $t->first_elt( '#TEXT');
  $text_elt->set_content( 'titi');
  is( $t->root->sprint, '<doc att="val">titi</doc>', 'set_content on text elt');# test 575
}

{ my $t=XML::Twig->new->parse( '<doc><elt>text 1</elt><elt>text 2</elt><elt>text 3</elt></doc>');
  my $elt1= $t->root->first_child( 'elt[1]');
  my $elt2= $t->root->first_child( 'elt[2]');
  my $elt3= $t->root->first_child( 'elt[3]');
  my $new1= XML::Twig::Elt->new( new => "new 1");
  my $new2= XML::Twig::Elt->new( new => "new 2");
  my $new3= XML::Twig::Elt->new( new => "new 3");
  $new1->replace( $elt1);
  $new2->replace( $elt2);
  $new3->replace( $elt3);
  is( $t->sprint, '<doc><new>new 1</new><new>new 2</new><new>new 3</new></doc>', 'replace');# test 576
  $new1->replace_with( $elt2, $elt1, $elt3);
  is( $t->sprint, '<doc><elt>text 2</elt><elt>text 1</elt><elt>text 3</elt><new>new 2</new><new>new 3</new></doc>', 'replace');# test 577
}
  
{ 
  if( $perl < 5.008)  
    { skip( 1, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $doc= '<doc><![CDATA[toto]]>tata<!-- comment -->t<?pi data?> more</doc>';
      my $out=''; $open->( my $fh, ">", \$out);
      my $t= XML::Twig->new( comments => 'process', pi => 'process')->parse( $doc);
      $t->flush( $fh);
      is( $out, $doc, 'flush with cdata');# test 578
    }
}

{ my $doc=<<END;
<doc>
  <elt>text</elt><indent>this</indent>
  <pre>text to 
keep spaces
  in like
    this
</pre>
</doc>
END
  my $t= XML::Twig->new( pretty_print => 'indented', keep_spaces_in => [ qw(pre) ])->parse( $doc);
  (my $indented= $doc)=~ s{<indent>}{\n  <indent>};
  is( $t->sprint, $indented, 'indented with keep_spaces_in');# test 579
  $t->set_pretty_print( 'indented');
}

{ my $doc='<doc><elt att="1">text</elt></doc>';
  my $nsgmls= qq{<doc\n><elt\natt="1"\n>text</elt></doc>\n};
  my $t= XML::Twig->new( pretty_print => 'nsgmls')->parse( $doc);
  is( $t->sprint, $nsgmls, 'nsgmls style');# test 580
  $t->set_pretty_print( 'indented');
}

{ my $t= XML::Twig->new->parse( '<doc><new_root>text</new_root></doc>');
  $t->root->erase;
  is( $t->root->sprint, "<new_root>text</new_root>\n", 'erase root');# test 581
}


{ my $t= XML::Twig->new->parse( '<doc><elt1 att="val"/><elt2/><elt3/></doc>');
  my $elt2= $t->first_elt( 'elt2');
  ok( $elt2->sibling(   0, 'elt2'), 'sibling 0 (ok)');# test 582
  nok( $elt2->sibling(  0, 'elt1'), 'sibling 0 (nok)');# test 583
  nok( $elt2->sibling(  1, 'elt1'), 'sibling 1 (nok)');# test 584
  nok( $elt2->sibling( -1, 'elt3'), 'sibling -1 (nok)');# test 585
  ok( $elt2->in( 'doc'), 'in with condition');# test 586
  ok( $elt2->in( $t->root), 'in with elt');# test 587
  nok( $elt2->in( 'elt1'), 'in with condition (false)');# test 588
  nok( $elt2->in( $t->root->last_child), 'in with elt (false)');# test 589
  is( $elt2->prev_sibling( 'elt1[@att="val"]')->gi, 'elt1', '@att="val" condition');# test 590
  nok( $elt2->prev_sibling( 'elt1[@att="val2"]'), '@att="val" condition (not found)');# test 591
  is( $elt2->prev_sibling( 'elt1[@att=~ /val/]')->gi, 'elt1', '@att=~ /val/ condition');# test 592
  nok( $elt2->prev_sibling( 'elt1[@att=~/val2/]'), '@att=~/val2/ condition (not found)');# test 593
}

{
  if( $perl < 5.008)  
    { skip( 2, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $out=''; 
      $open->( my $fh, ">", \$out);
      my $doc='<doc><elt>text</elt><elt1/><elt2/><elt3>text</elt3></doc>';
      $t= XML::Twig->new( twig_roots=> { elt2 => 1 },
                          start_tag_handlers => { elt  => sub { print $fh '<e1/>'; } },  
                          end_tag_handlers   => { elt3 => sub { print $fh '<e2/>'; } },  
                          twig_print_outside_roots => $fh,
                          keep_encoding => 1
                        )
                   ->parse( $doc);
      is( $out, '<doc><e1/><elt>text</elt><elt1/><elt3>text<e2/></elt3></doc>',# test 594
          'twig_print_outside_roots, start/end_tag_handlers, keep_encoding');
      close $fh;
      $out='';
      $open->( $fh, ">", \$out);
      $t= XML::Twig->new( twig_roots=> { elt2 => 1 },
                          start_tag_handlers => { elt  => sub { print $fh '<e1/>'; } },  
                          end_tag_handlers   => { elt3 => sub { print $fh '<e2/>'; } },  
                          twig_print_outside_roots => $fh,
                        )
                   ->parse( $doc);
      is( $out, '<doc><e1/><elt>text</elt><elt1/><elt3>text<e2/></elt3></doc>',# test 595
         'twig_print_outside_roots and start_tag_handlers');
    }
}

{ my $t= XML::Twig->new->parse( '<doc><elt id= "elt-1" att="a1"><elt2 id="elt2-1"/><elt2 id="elt2-2" att2="a2">text 1</elt2></elt>
                                      <elt id= "elt-2" att="a1"><elt2 id="elt2-3"/><elt2 id="elt2-4" att2="a2">text 2</elt2></elt>
                                      <elt id= "elt-3" att="a2"><elt2 id="elt2-5"/><elt2 id="elt2-6" att2="a2">text 3</elt2></elt>
                                 </doc>');
  my @a1= $t->get_xpath( '/doc/elt[@att="a1"]');
  is( ids( @a1), 'elt-1:elt-2', 'xpath /doc/elt[@att="a1"]');# test 596
  @a1= $t->get_xpath( '/doc/*[@att="a1"]');
  is( ids( @a1), 'elt-1:elt-2', 'xpath /doc/*[@att="a1"]');# test 597
  @a1= $t->get_xpath( '/doc//*[@att="a1"]');
  is( ids( @a1), 'elt-1:elt-2', 'xpath /doc//*[@att="a1"]');# test 598
  @a1= $t->get_xpath( '//*[@att="a1"]');
  is( ids( @a1), 'elt-1:elt-2', 'xpath //*[@att="a1"]');# test 599
  @a1= $t->get_xpath( '//elt[@att="a1"]');
  is( ids( @a1), 'elt-1:elt-2', 'xpath //elt[@att="a1"]');# test 600
  my @a2= $t->get_xpath( '//elt2[@id="elt2-4" and @att2="a2"]');
  is( ids( @a2), 'elt2-4', 'xpath //elt2[@id="elt2-4" and @att2="a2"]');# test 601
  @a2= $t->get_xpath( '//elt2[@id="toto" or @att2="a2"]');
  is( ids( @a2), 'elt2-2:elt2-4:elt2-6', 'xpath //elt2[@id="toto" or @att2="a2"]');# test 602
  my $a2= $t->get_xpath( '//elt2[@id="toto" or @att2="a2"]', 1);
  is( $a2->att( 'id'), 'elt2-4', 'xpath //elt2[@id="toto" or @att2="a2"], offset 1');# test 603
  @a2= $t->get_xpath( \@a1, './elt2[@id="toto" or @att2="a2"]');
  is( ids( @a2), 'elt2-2:elt2-4', 'xpath //elt2[@id="toto" or @att2="a2"] on @a1');# test 604
  $a2= $t->findvalue( \@a1, './elt2[@id="toto" or @att2="a2"]');
  is( $a2, 'text 1text 2', 'findvalue //elt2[@id="toto" or @att2="a2"] on @a1');# test 605
}

{ my $doc= qq{<!DOCTYPE doc SYSTEM "where_is_it?" [\n<!ENTITY ent "foo">\n]>\n<doc>toto &ent;</doc>\n};
  my $t= XML::Twig->new( keep_encoding => 1)->parse( $doc);
  is( $t->sprint, $doc, 'keep_encoding with entity');# test 606
}

# testing DTD parsing
{ my $doc= qq{<?xml version="1.0"?>\n<!DOCTYPE doc [\n<!ELEMENT doc (#PCDATA)>\n]>\n<doc/>};
  my $t= XML::Twig->new->parse( $doc);
  is( $t->sprint, $doc, 'simple DTD');# test 607
}
{ my $doc= qq{<?xml version="1.0"?>\n<!DOCTYPE doc [\n<!ELEMENT doc (#PCDATA)>\n<!ATTLIST doc att CDATA #IMPLIED>\n]>\n<doc/>};
  my $t= XML::Twig->new->parse( $doc);
  is( $t->sprint, $doc, 'DTD 1 element and simple attlist');# test 608
}

{ my $doc=<<DTD;
<?xml version="1.0"?>
<!DOCTYPE doc [
<!ELEMENT doc (elt+)>
<!ATTLIST doc att CDATA #IMPLIED
              att2 (toto|tata) 'toto'
>
<!ELEMENT elt (#PCDATA)>
<!ATTLIST elt att ID #REQUIRED>
<!ELEMENT elt2 (#PCDATA)>
<!ATTLIST elt2 att CDATA #FIXED 'fixed'>
]>
<doc att2="toto">
  <elt>text</elt>
</doc>
DTD

  my $t= XML::Twig->new( ErrorContext => 1)->parse( $doc);
  is( $t->sprint, $doc, 'complex DTD');# test 609
  is( join( ':', $t->model), 'doc:elt:elt2', 'model with no elt (all element in the dtd)');# test 610
}

# testing do_not_output_DTD option
{ my $t= XML::Twig->new( no_prolog => 1)
                  ->parse( '<?xml version="1.0"?><!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)>]><doc/>');
  is( $t->sprint, '<doc/>', 'no_prolog');# test 611
}

# testing do_not_output_DTD option
{ my $t= XML::Twig->new( do_not_output_DTD => 1)
                  ->parse( '<!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)>]><doc/>');
  is( $t->sprint, '<doc/>', 'do_not_output_DTD option');# test 612
  $t->purge;
}

# handlers on PIs
{ my $t= XML::Twig->new( pretty_print => 'none', twig_handlers => { '?t1' => sub { return "<?t2 $_[2]?>"; } })
                  ->parse( '<doc><!--comment--><?t1 data ?><elt>toto</elt></doc>');
  is( $t->sprint, '<doc><!--comment--><?t2 data ?><elt>toto</elt></doc>', 'handler on pi t1, with comment');# test 613
}
# handlers on PIs
{ my $t= XML::Twig->new( pretty_print => 'none', twig_handlers => { '?' => sub { return "<?t2 $_[2]?>"; } })
                  ->parse( '<doc><!--comment--><?t1 data ?><elt>toto</elt></doc>');
  is( $t->sprint, '<doc><!--comment--><?t2 data ?><elt>toto</elt></doc>', 'handler on all pi, with comment');# test 614
}

# creating an output encoding
{
  if( $perl < 5.008)  
    { skip( 1, "need perl 5.8 or above to perform these tests (you have $perl)"); }
  else
    { my $t= XML::Twig->new->parse( '<doc/>');
      $t->set_output_encoding( 'ISO-8859-1');
      is( $t->sprint, qq{<?xml version="1.0" encoding="ISO-8859-1"?><doc/>}, 'creating an output encoding');# test 615
    }
}

# some calls that return false
{ my $root= XML::Twig->new->parse( '<doc/>')->root;
  nok( $root->last_child_matches( 'toto'), 'last_child_matches (not)');# test 616
  nok( $root->first_child_matches( 'toto'), 'first_child_matches(not)');# test 617
  nok( $root->child_text( 1, 'toto'), 'child_text(not)');# test 618
  nok( $root->child_trimmed_text( 1, 'toto'), 'child_trimmed_text(not)');# test 619
  nok( $root->child_matches( 1, 'toto'), 'child_matches(not)');# test 620
  nok( $root->prev_sibling_matches( 'toto'), 'prev_sibling_matches(not)');# test 621
  nok( $root->prev_elt_text( 'toto'), 'prev_elt_text(not)');# test 622
  nok( $root->sibling_text( 1, 'toto'), 'prev_elt_text(not)');# test 623
  nok( $root->prev_elt_trimmed_text( 'toto'), 'prev_elt_trimmed_text(not)');# test 624
  nok( $root->prev_elt_matches( 'toto'), 'prev_elt_matches(not)');# test 625
  nok( $root->next_elt_trimmed_text( 'toto'), 'next_elt_trimmed_text(not)');# test 626
  nok( $root->next_elt_matches( 'toto'), 'next_elt_matches(not)');# test 627
  nok( $root->parent_text( 'toto'), 'parent_text(not)');# test 628
  nok( $root->parent_trimmed_text( 'toto'), 'parent_trimmed_text(not)');# test 629
  nok( $root->pcdata_xml_string, 'pcdata_xml_string of a non pcdata elt');# test 630
  nok( $root->att_xml_string( 'foo'), 'att_xml_string of a non existing att');# test 631
}

{ my $doc=<<END;
<doc>
  <elt xml:space="preserve">
    <sub id="s1">
      <sub>text 1</sub>
      <sub>text 2</sub>
    </sub>
  </elt>
  <elt>
    <sub id="s2">
      <sub>text 1</sub>
      <sub>text 2</sub>
    </sub>
  </elt>
</doc>
END
my $expected_doc=q{<doc><elt xml:space="preserve">
    <sub id="s1">
      <sub>text 1</sub>
      <sub>text 2</sub>
    </sub>
  </elt><elt><sub id="s2"><sub>text 1</sub><sub>text 2</sub></sub></elt></doc>};

my $expected_s1= q{<sub id="s1">
      <sub>text 1</sub>
      <sub>text 2</sub>
    </sub>};

my $expected_s2= q{<sub id="s2"><sub>text 1</sub><sub>text 2</sub></sub>};

  my $t=XML::Twig->new(pretty_print => 'none')->parse( $doc);
  is( $t->sprint, $expected_doc, 'doc with xml:space="preserve"');# test 632
  is( $t->get_xpath( '//*[@id="s1"]', 0)->sprint, $expected_s1, 'sub element of an xml:space="preserve" element');# test 633
  is( $t->get_xpath( '//*[@id="s2"]', 0)->sprint, $expected_s2, 'regular sub element');# test 634
}

{ my $e= XML::Twig::Elt->parse( '<elt/>');
  is( $e->xml_text, '', 'xml_text of an empty elt');# test 635
  $e= XML::Twig::Elt->parse( '<elt>toto</elt>')->first_child;
  is( $e->xml_text, 'toto', 'xml_text of a pcdata');# test 636
  $e->set_content();
  is( $e->xml_text, 'toto', 'empty set_content');# test 637
  $e= XML::Twig::Elt->parse( '<elt><![CDATA[toto]]></elt>')->first_child;
  is( $e->xml_text, '<![CDATA[toto]]>', 'xml_text of a cdata');# test 638
}

{ my $doc=   q{<doc xmlns:ns1="uri1" xmlns:ns2="uri2"><ns1:elt>toto</ns1:elt>}
           . q{<ns2:elt>tata</ns2:elt></doc>};
  my $expected_keep= $doc;
  $expected_keep=~ s{toto}{foo};
  $expected_keep=~ s{tata}{bar};
  my $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         keep_original_prefix => 1,
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  is( $t->sprint, $expected_keep, "map_xmlns and keep_original_prefix");# test 639
  $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  (my $expected_remap= $expected_keep)=~ s{ns(?=\d)}{ns_}g;
  is( $t->sprint, $expected_remap, "map_xmlns");# test 640
}

{ my $doc=   q{<doc xmlns:ns1="uri1" xmlns:ns2="uri2"><ns1:elt ns2:att="titi">toto</ns1:elt>}
           . q{<ns2:elt>tata</ns2:elt></doc>};
  my $expected_keep= $doc;
  $expected_keep=~ s{toto}{foo};
  $expected_keep=~ s{tata}{bar};
  my $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         keep_original_prefix => 1,
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  is( $t->sprint, $expected_keep, "map_xmlns and keep_original_prefix");# test 641
  $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  (my $expected_remap= $expected_keep)=~ s{ns(?=\d)}{ns_}g;
  is( $t->sprint, $expected_remap, "map_xmlns");# test 642
}

{ my $doc=   q{<doc xmlns="uri1" xmlns:ns2="uri2"><elt att="tutu" ns2:att="titi">toto</elt>}
           . q{<ns2:elt>tata</ns2:elt></doc>};
  my $expected_keep= $doc;
  $expected_keep=~ s{toto}{foo};
  $expected_keep=~ s{tata}{bar};
  my $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         keep_original_prefix => 1,
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  is( $t->sprint, $expected_keep, "map_xmlns and keep_original_prefix with default ns");# test 643
  $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  (my $expected_remap= $expected_keep)=~ s{ns(?=\d)}{ns_}g;
  $expected_remap=~ s{(?<!:)(elt|att|doc)}{ns_1:$1}g;
  $expected_remap=~ s{xmlns=}{xmlns:ns_1=};
  is( $t->sprint, $expected_remap, "map_xmlns  with default ns");# test 644
}

{ my $doc=   q{<doc xmlns="uri1" xmlns:ns2="uri2" xmlns:ns_3="uri3"><elt att="tutu" ns2:att="titi">toto</elt>}
           . q{<ns2:elt>tata</ns2:elt><ns_3:elt ns_3:att="bang">kaboom</ns_3:elt></doc>};
  my $expected_keep= $doc;
  $expected_keep=~ s{toto}{foo};
  $expected_keep=~ s{tata}{bar};
  my $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         keep_original_prefix => 1,
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  is( $t->sprint, $expected_keep, "map_xmlns and keep_original_prefix with default ns");# test 645
  $t= XML::Twig->new( map_xmlns => { uri1 => "ns_1", uri2 => "ns_2" },
                         twig_handlers => { 'ns_1:elt' => sub { $_->set_text( 'foo'); },
                                            'ns_2:elt' => sub { $_->set_text( 'bar'); },
                                          }
                       )
                  ->parse( $doc);
  (my $expected_remap= $expected_keep)=~ s{ns(?=\d)}{ns_}g;
  $expected_remap=~ s{(?<!:)(elt|att|doc)}{ns_1:$1}g;
  $expected_remap=~ s{xmlns=}{xmlns:ns_1=};
  is( $t->sprint, $expected_remap, "map_xmlns  with default ns");# test 646
}

{ my $t= XML::Twig->new->parse( '<doc/>'); 
  my $elt= $t->root->insert( elt => { att => undef});
  $elt->insert( '#PCDATA');
  is( $t->sprint => '<doc><elt att=""></elt></doc>', "undef text and att");# test 647
} 

exit 0;
