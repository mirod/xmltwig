#!/usr/bin/perl -w
use strict;


use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

#$|=1;
my $DEBUG=0;

use XML::Twig;

my $TMAX=17;
print "1..$TMAX\n";

{ # test bug outputing end tag with pretty_print => nsgmls on
  my $out= XML::Twig->new( pretty_print => 'nsgmls')->parse( "<doc><elt>text</elt></doc>")->sprint;
  ok( XML::Twig->new( error_context => 1)->safe_parse( $out), "end tag with nsgmls option" . ($@ || '') );
}
  

{ # test bug RT #8830: simplify dies on mixed content
  ok( XML::Twig->new->parse( "<doc>text1<elt/></doc>")->root->simplify, "simplify mixed content");
}


{ # testing to see if bug RT #7523 is still around
  my $t= XML::Twig->new->parse( '<doc/>');
  if( eval( '$t->iconv_convert( "utf8");'))
    { $t->set_output_encoding( 'utf8');
      eval { $t->sprint;};
      ok( !$@, 'checking bug RT 7523');
    }
  else
    { if( $@=~ m{^Can't locate Text/Iconv.pm} || $@=~ m{^Text::Iconv not available} )
        { skip( 1, "Text::Iconv not available"); }
      elsif( $@=~ m{^Unsupported (encoding|conversion): utf8})
        { skip( 1, "your version of iconv does not support utf8"); }
      else
        { skip( 1, "odd error creating filter with iconv: $@"); }
    }
}


{ # bug on comments
  my $doc= "<doc>\n  <!-- comment -->\n  <elt>foo</elt>\n</doc>\n";

  my $t= XML::Twig->new( comments => 'keep', pretty_print => 'indented')
                  ->parse( $doc);
  is( $t->sprint => $doc, "comment with comments => 'keep'");
}

{ # bug with disapearing entities in attributes
  my $text= '<doc att="M&uuml;nchen"><elt att="&ent2;"/><elt att="A&amp;E">&ent3;</elt></doc>';
  my $doc= qq{<!DOCTYPE doc SYSTEM "test_ent_in_att.dtd"[<!ENTITY foo "toto">]>$text};

  XML::Twig::Elt::init_global_state();
  my $regular=XML::Twig->new( pretty_print => 'none')->parse( $doc)->root->sprint;
  (my $expected= $text)=~ s{&(uuml|ent2);}{}g;  # yes, entities in attributes just vanish!
  is( $regular => $expected, "entities in atts, no option");

  XML::Twig::Elt::init_global_state();
  my $with_keep=XML::Twig->new(keep_encoding => 1)->parse( $doc)->root->sprint;
  is( $with_keep => $text, "entities in atts with keep_encoding");

  XML::Twig::Elt::init_global_state();
  my $with_dneaia=XML::Twig->new(do_not_escape_amp_in_atts => 1)->parse( $doc)->root->sprint;
  if( $with_dneaia eq '<doc att="Mnchen"><elt att=""/><elt att="A&amp;E">&ent3;</elt></doc>')
    { skip( 1, "option do_not_escape_amp_in_atts not available, no worries"); }
  else
    { is( $with_dneaia => $text, "entities in atts with do_not_escape_amp_in_atts"); }
    

  # checking that all goes back to normal
  XML::Twig::Elt::init_global_state();
  $regular=XML::Twig->new()->parse( $doc)->root->sprint;
  is( $regular => $expected, "entities in atts, no option");

}

# bug on xmlns in path expression trigger
{ my $matched=0;
  my $twig = XML::Twig->new( map_xmlns => { uri1  => 'aaa', },
                             twig_handlers => { '/aaa:doc/aaa:elt' => sub { $matched=1; } }
                           )
                      ->parse( q{<xxx:doc xmlns:xxx="uri1"><xxx:elt/></xxx:doc>});
  ok( $matched, "using name spaces in path expression trigger");
  $matched=0;
  $twig = XML::Twig->new( map_xmlns => { uri1  => 'aaa', },
                          twig_handlers => { 'aaa:doc/aaa:elt' => sub { $matched=1; } }
                        )
                      ->parse( q{<xxx:doc xmlns:xxx="uri1"><xxx:elt/></xxx:doc>});
  ok( $matched, "using name spaces in partial path expression trigger");
}

# bug where the leading spaces are discarded in an element like <p>  <b>foo</b>bar</p>
{ # check that leading spaces after a \n are discarded
  my $doc= "<p>\n  <b>foo</b>\n</p>";
  my $expected= "<p><b>foo</b></p>";
  my $result=  XML::Twig->new->parse( $doc)->sprint;
  is( $result => $expected, 'leading spaces kept when not after a \n');
}
{
  # check that leading spaces NOT after a \n are kept around
  my $doc= "<p>  <b>foo</b>bar</p>";
  my $result=  XML::Twig->new->parse( $doc)->sprint;
  is( $result => $doc, 'leading spaces kept when not after a \n');
}

{
my $t= XML::Twig->new->parse( "<doc><elt>  elt  1 </elt> <elt>  elt   2 </elt></doc>");
is( scalar $t->descendants( '#PCDATA'), 3, 'properly parsed pcdata');
}

{
my $t= XML::Twig->new->parse( "<doc>\n  <elt>  elt  1 </elt>\n  <elt>  elt   2 </elt>\n</doc>");
is( scalar $t->descendants( '#PCDATA'), 2, 'properly parsed pcdata');
}

{ # bug RT 8137
  my $doc= q{<doc  att="val"/>};
  (my $expected= $doc)=~ s{  }{ };
  is( XML::Twig->new( keep_encoding => 1)->parse( $doc)->sprint, $expected, 
      'keep_encoding and 2 spaces between gi and attribute'
    );
}

{ # copy of an element with extra_data_before_end_tag
  my $doc= '<doc>data<?pi here?>more</doc>';
  my $expected= '<doc>data<?pi here?>more</doc>'; # pi's are not being moved around anymore
  my $elt= XML::Twig->new( pi => 'keep')->parse( $doc)->root->copy;
  is( $elt->sprint, $expected, 'copy of an element with extra_data_before_end_tag');
}

{ # copy of an element with extra_data_before_end_tag
  my $doc= '<doc><?pi here?></doc>';
  my $elt= XML::Twig->new( pi => 'keep')->parse( $doc)->root->copy;
  is( $elt->sprint, $doc, 'copy of an element with extra_data_before_end_tag');
}
