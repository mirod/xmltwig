#!/usr/bin/perl -w 

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;

use XML::Twig;

my $TMAX=158;
print "1..$TMAX\n";

{
#bug with long CDATA

# get an accented char in iso-8859-1
my $char_file=File::Spec->catfile('t', "latin1_accented_char.iso-8859-1");
open( CHARFH, "<$char_file") or die "cannot open $char_file: $!";
my $latin1_char=<CHARFH>;
chomp $latin1_char;
close CHARFH;

my %cdata=( "01- 1023 chars" => 'x' x 1022 . 'a',
            "02- 1024 chars" => 'x' x 1023 . 'a',
            "03- 1025 chars" => 'x' x 1024 . 'a',
            "04- 1026 chars" => 'x' x 1025 . 'a',
            "05- 2049 chars" => 'x' x 2048 . 'a',
            "06- 1023 chars spaces" => 'x' x 1020 . '  a',
            "07- 1024 chars spaces" => 'x' x 1021 . '  a',
            "08- 1025 chars spaces" => 'x' x 1022 . '  a',
            "09- 1026 chars spaces" => 'x' x 1023 . '  a',
            "10- 2049 chars spaces" => 'x' x 2048 . '  a',
            "11- 1023 accented chars" => $latin1_char x 1022 . 'a',
            "12- 1024 accented chars" => $latin1_char x 1023 . 'a',
            "13- 1025 accented chars" => $latin1_char x 1024 . 'a',
            "14- 1026 accented chars" => $latin1_char x 1025 . 'a',
            "15- 2049 accented chars" => $latin1_char x 2048 . 'a',
            "16- 1023 accented chars spaces" => $latin1_char x 1020 . '  a',
            "17- 1024 accented chars spaces" => $latin1_char x 1021 . '  a',
            "18- 1025 accented chars spaces" => $latin1_char x 1022 . '  a',
            "19- 1026 accented chars spaces" => $latin1_char x 1023 . '  a',
            "20- 2049 accented chars spaces" => $latin1_char x 2048 . '  a', 
            "21- 511 accented chars" => $latin1_char x 511 . 'a',
            "22- 512 accented chars" => $latin1_char x 512 . 'a',
            "23- 513 accented chars" => $latin1_char x 513 . 'a',
            #"00- lotsa chars" => 'x' x 2000000 . 'a', # do not try this at home
                                                       # but if you do with a higher number, let me know!
            );

if( ($] == 5.008) || ($] < 5.006) || ($XML::Parser::VERSION <= 2.27) )
  { skip( scalar keys %cdata,   "KNOWN BUG in 5.8.0 and 5.005 or with XML::Parser 2.27 with keep_encoding and long (>1024 char) CDATA, "
                              . "see RT #14008 at http://rt.cpan.org/Ticket/Display.html?id=14008"
        );
  }
elsif( perl_io_layer_used())
  { skip( scalar keys %cdata, "cannot test parseurl when UTF8 perIO layer used "
                            . "(due to PERL_UNICODE being set or -C command line option being used)\n"
        );
  }
else
  {
    foreach my $test (sort keys %cdata)
      { my $cdata=$cdata{$test};
        my $doc= qq{<?xml version="1.0" encoding="iso-8859-1" ?><doc><![CDATA[$cdata]]></doc>};
        my $twig= XML::Twig->new( keep_encoding => 1)->parse($doc);
        my $res = $twig->root->first_child->cdata;
        is( $res, $cdata, "long CDATA with keep_encoding $test");
      }
  }
}


# subs_text on text with new lines
{ my $doc= "<doc> foo1 \n foo2 </doc>";
   my $t= XML::Twig->new->parse( $doc);
   (my $expected= $doc)=~ s{foo}{bar}g;
   $t->subs_text( qr{foo}, "bar");
   is( $t->sprint, $expected, "subs_text on string with \n");
   $expected=~ s{ }{&nbsp;}g;
   $t->subs_text( qr{ }, q{&ent( "&nbsp;")} );
   if( 0 && $] =~ m{^5.006})
     { skip( 1, "known bug in perl 5.6.*: subs_text with an entity matches line returns\n"
              . "  this bug is under investigation\n");
     }
   else   
     { is( $t->sprint, $expected, "subs_text on string with \n"); }
}

# testing ID processing
{ # setting existing id to a different value
  my $t= XML::Twig->new->parse( '<doc id="i1"/>');
  $t->root->set_id( "i2");
  is( id_list( $t), "i2", "changing an existing id");
  $t->root->del_id();
  is( id_list( $t), "", "deleting an id");
  $t->root->del_id();
  is( id_list( $t), "", "deleting again an id");
  $t->root->set_id( "0");
  is( id_list( $t), "0", "changing an existing id to 0");
  $t->root->del_id();
  is( id_list( $t), "", "deleting again an id");
  

}

{ # setting id through the att
  my $t= XML::Twig->new->parse( '<doc id="i1"/>');
  $t->root->set_att( id => "i2");
  is( fid( $t, "i2"), "i2", "changing an existing id using set_att");
  $t->root->set_att( id => "0");
  is( fid( $t, "0"), "0", "using set_att with a id of 0");
	$t->root->set_atts( { id => "i3" });
  is( fid( $t, "i3"), "i3", "using set_atts");
	$t->root->set_atts( { id => "0" });
  is( fid( $t, "0"), "0", "using set_atts with an if of 0");
}

{ # setting id through a new element
  my $t= XML::Twig->new->parse( '<doc id="i1"/>');
  my $n= $t->root->insert_new_elt( elt => { id => "i2" });
	is( id_list( $t), "i1-i2", "setting id through a new element");
  $n= $t->root->insert_new_elt( elt => { id => "0" });
	is( id_list( $t), "0-i1-i2", "setting id through a new element");
}

{ # setting ids through a parse
  my $t= XML::Twig->new->parse( '<doc id="i1"/>');
  my $elt= XML::Twig::Elt->parse( '<elt id="i2"><selt id="i3"/><selt id="0"/></elt>');
	$elt->paste( $t->root);
	is( id_list( $t), "0-i1-i2-i3", "setting id through a parse");
}

{ # test ]]> in text
  my $doc=q{<doc att="]]&gt;">]]&gt;</doc>};
	is( XML::Twig->new->parse( $doc)->sprint, $doc, "]]> in char data");
}

sub fid { my $elt= $_[0]->elt_id( $_[1]) or return "unknown";
         return $elt->att( $_[0]->{twig_id});
		   }

# testing ignore messing up with whitespace handling
{ my $doc=qq{<doc>\n  <elt2 ignore="1">ba</elt2>\n  <elt>foo</elt>\n  <elt2>bar</elt2>\n</doc>};
  my $res;
  my $t= XML::Twig->new( twig_roots => { elt  => sub { $_->ignore; },
                                         elt2 => sub { $res.= $_->text; },
                                       },
                         start_tag_handlers => { elt2 => sub { $_[0]->ignore if( $_->att( 'ignore')); },
                                               },
                       );
  $t->parse( $doc);
  is( $res => 'bar', 'checking that ignore and whitespace handling work well together');
}

# test on handlers with ns
{ my $doc=q{<doc xmlns:ns="uri">
              <ns:elt ns:att="val" att2="ns_att"    >elt with ns att</ns:elt>
              <ns:elt att="val"    att2="non_ns_att">elt with no ns att</ns:elt>
            </doc>
           };
  my( $res1, $res2);
  my $t= XML::Twig->new( map_xmlns => { uri => 'n' },
                         twig_handlers => { 'n:elt[@n:att="val"]'  => sub { $res1 .= $_->text; },
                                            'n:elt[@att="val"]'    => sub { $res2 .= $_->text; },
                                          },
                       )
                  ->parse( $doc);
  is( $res1 => 'elt with ns att', 'twig handler on n:elt[@n:att="val"]');
  is( $res2 => 'elt with no ns att', 'twig handler on n:elt[@att="val"]');
}

# same with start_tag handlers
{ my $doc=q{<doc xmlns:ns="uri">
              <ns:elt ns:att="val" att2="ns_att"    >elt with ns att</ns:elt>
              <ns:elt att="val"    att2="non_ns_att">elt with no ns att</ns:elt>
            </doc>
           };
  my( $res1, $res2);
  my $t= XML::Twig->new( map_xmlns => { uri => 'n' },
                         start_tag_handlers => { 'n:elt[@n:att="val"]'  => sub { $res1 .= $_->att( 'att2'); },
                                                 'n:elt[@att="val"]'    => sub { $res2 .= $_->att( 'att2'); },
                                          },
                       )
                  ->parse( $doc);
  is( $res1 => 'ns_att', 'start_tag handler on n:elt[@n:att="val"]');
  is( $res2 => 'non_ns_att', 'start_tag handler on n:elt[@att="val"]');
}

# same with start_tag handlers and twig_roots
{ my $doc=q{<doc xmlns:ns="uri">
              <ns:elt ns:att="val" att2="ns_att"    >elt with ns att</ns:elt>
              <ns:elt att="val"    att2="non_ns_att">elt with no ns att</ns:elt>
            </doc>
           };
  my( $res1, $res2);
  my $t= XML::Twig->new( map_xmlns => { uri => 'n' },
                         twig_roots => { foo => 1 },
                         start_tag_handlers => { 'n:elt[@n:att="val"]'  => sub { my( $t, $gi, %atts)= @_;
                                                                                 $res1 .= $atts{att2};
                                                                               },
                                                 'n:elt[@att="val"]'    => sub { my( $t, $gi, %atts)= @_;
                                                                                 $res2 .= $atts{att2};
                                                                               },
                                          },
                       )
                  ->parse( $doc);
  is( $res1 => 'ns_att', 'start_tag handler on n:elt[@n:att="val"]');
  is( $res2 => 'non_ns_att', 'start_tag handler on n:elt[@att="val"]');
}


# tests for additional coverage
{ my $doc=q{<doc><elt>foo</elt><elt2>bar</elt2></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { elt => sub { $res.= $_->text}, });
  $t->setTwigHandlers();
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with no argument');
}


{ my $doc=q{<doc><elt>foo</elt><elt2>bar</elt2></doc>};
  my $res;
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { elt => sub { $res.= $_->text}, });
  $t->parse( $doc);
  is( $res => 'foo', 'setTwigHandlers by itself');
}

{ my $doc=q{<doc><elt>foo</elt><elt2>bar</elt2></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { '/doc/elt' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { '/doc/elt' => undef, });
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with an undef path');
}

{ my $doc=q{<doc><elt>foo</elt><elt2>bar</elt2></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { 'doc/elt' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'doc/elt' => undef, });
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with an undef subpath');
}
  
{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { 'elt[@att="baz"]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[@att="bak"]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[@att="baz"]' => undef, });
  $t->setTwigHandlers( { 'elt[@att="bal"]' => undef, });
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with an undef att cond');
}

{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { 'elt[@att=~/baz/]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[@att=~/bar/]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[@att=~/baz/]' => undef, });
  $t->setTwigHandlers( { 'elt[@att=~/bas/]' => undef, });
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with undef regexp on att conds');
}

{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { 'elt[string()="foo"]'  => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[string()="fool"]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[string()="foo"]'  => undef} );
  $t->setTwigHandlers( { 'elt[string()="food"]' => undef} );
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with undef string conds');
}

{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { 'elt[string()=~/foo/]'  => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[string()=~/fool/]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { 'elt[string()=~/foo/]'  => undef});
  $t->setTwigHandlers( { 'elt[string()=~/food/]' => undef});
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with undef string regexp conds');
}

{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { '*[@att="baz"]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { '*[@att="bak"]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { '*[@att="baz"]' => undef, });
  $t->setTwigHandlers( { '*[@att="bal"]' => undef, });
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with an undef start att cond');
}

{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setTwigHandlers( { '*[@att=~/baz/]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { '*[@att=~/bak/]' => sub { $res.= $_->text}, });
  $t->setTwigHandlers( { '*[@att=~/baz/]' => undef, });
  $t->setTwigHandlers( { '*[@att=~/bal/]' => undef, });
  $t->parse( $doc);
  is( $res => '', 'setTwigHandlers with an undef start att regexp cond');
}

{ my $doc=q{<doc><elt att="baz">foo</elt><elt>bar</elt></doc>};
  my $res='';
  my $t= XML::Twig->new;
  $t->setStartTagHandlers( { 'elt[@att="baz"]' => sub { $res.= 'not this one'}, });
  $t->setStartTagHandlers( { 'elt[@att="bal"]' => sub { $res.= $_->att( 'att') || 'none'}, });
  $t->setStartTagHandlers( { 'elt[@att="baz"]' => sub { $res.= $_->att( 'att') || 'none'}, });
  $t->parse( $doc);
  is( $res => 'baz', 'setStartTagHandlers');
}

{ my $doc=q{<doc><title>title</title><sect><elt>foo</elt><elt>bar</elt></sect></doc>};
  my $res='';
  my $t= XML::Twig->new( twig_handlers => { 'level(2)' => sub { $res .= $_->text;} })
                  ->parse( $doc);
  is( $res => 'foobar', 'level cond');
}

{ my $doc=q{<doc><title>title</title><sect><elt>foo</elt><elt>bar</elt></sect></doc>};
  my $res='';
  my $t= XML::Twig->new( twig_roots => { 'level(2)' => sub { $res .= $_->text;} })
                  ->parse( $doc);
  is( $res => 'foobar', 'level cond');
}


{ my $doc=q{<doc><?t1 d1?><elt/><?t2 d2?></doc>};
  my $res='';
  XML::Twig->new( pi => 'process', twig_handlers => { '?' => sub { $res.=$_->data } })->parse( $doc);
  is( $res => 'd1d2', '? (any pi) handler');
}

{ my $doc=q{<doc><elt>foo <!--commment--> bar</elt></doc>};
  my $t= XML::Twig->new->parse( $doc);
  is( $t->sprint, $doc, 'embedded comments, output asis');
  $t->root->first_child( 'elt')->first_child->set_pcdata( 'toto');
  is( $t->sprint, '<doc><elt>toto</elt></doc>', 'embedded comment removed');
}


{ my $doc=q{<?xml version="1.0" ?>
            <!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)>
                            <!ENTITY  ent "foo">
                          ]
            >
            <doc> a &ent; is here</doc>
            };
  my $t= XML::Twig->new->parse( $doc);
  $t->entity_list->add_new_ent( ent2 => 'bar');
  my $res= $t->sprint();
  is_like( $res, qq{<?xml version="1.0" ?><!DOCTYPE doc[<!ELEMENT doc (#PCDATA)><!ENTITY  ent "foo">]>}
                 .qq{<doc> a foo is here</doc>}, 'new ent, no update dtd');

  
  $res=$t->sprint( updateDTD => 1);
  is_like( $res, qq{<?xml version="1.0" ?><!DOCTYPE doc[<!ELEMENT doc (#PCDATA)><!ENTITY  ent "foo">}
                . qq{<!ENTITY  ent2 "bar">]><doc> a foo is here</doc>},
            'new ent update dtd'
          );
}

{ my $t=XML::Twig->new->parse( '<doc/>');
  $t->{entity_list}= XML::Twig::Entity_list->new;
  $t->entity_list->add_new_ent( foo => 'bar');
  is_like( $t->sprint( update_DTD => 1), '<!DOCTYPE doc [<!ENTITY foo "bar">]><doc/>', "new entity with update DTD");
}

{ my $t=XML::Twig->new( keep_encoding => 1)->parse( '<doc/>');
  $t->{entity_list}= XML::Twig::Entity_list->new;
  $t->entity_list->add_new_ent( foo => 'bar');
  is_like( $t->sprint( update_DTD => 1), '<!DOCTYPE doc [<!ENTITY foo "bar">]><doc/>',
           "new entity (keep_encoding)with update DTD"
         );
}

{ my $dtd= q{<!DOCTYPE doc [<!ELEMENT doc (elt+)>
                            <!ATTLIST doc id ID #IMPLIED>
                            <!ELEMENT elt (#PCDATA)>
                            <!ATTLIST elt att CDATA 'foo'
                                          fixed CDATA #FIXED 'fixed' 
                                          id ID #IMPLIED
                            >
                           ]>
            };
  my $doc= q{<doc id="d1"><elt id="e1" att="toto">tata</elt><elt/></doc>};
  my $t= XML::Twig->new->parse( $dtd . $doc);
  is_like( $t->dtd_text, $dtd, "dtd_text");
}

{ my $t=XML::Twig->new->parse( '<doc><elt/></doc>');
  is( $t->root->first_child( 'elt')->sprint, '<elt/>', "nav, first pass");
  is( $t->root->first_child( 'elt')->sprint, '<elt/>', "nav, second pass");
  is_undef( scalar $t->root->first_child( 'elt')->parent( 'toto'), "undef parent 1");
  is_undef( scalar $t->root->parent( 'toto'), "undef parent 2");
  is_undef( scalar $t->root->parent(), "undef parent 3");
}
  
{ my $t= XML::Twig->new->parse( '<doc id="myid"><elt/></doc>');
  my $id= $t->root->id;
  $t->root->add_id();
  is( $t->root->id, $id, "add_id on existing id");
  my $elt= $t->root->first_child( 'elt');
  $elt->cut;
  $elt->set_id( 'elt1');
  is_undef( $t->elt_id( 'elt1'), "id added to elt outside the doc"); 
  $elt->paste( $t->root);
  is( $t->elt_id( 'elt1')->gi => 'elt', "elt put back in the tree");

  # these tests show a bug: the id list is not updated when an element is cut
  $elt->cut;
  $elt->del_id;
  $elt->del_id; # twice to go through a different path
  $elt->paste( $t->root);
  is( $t->elt_id( 'elt1')->gi => 'elt', "elt put back in the tree without id");
  $elt->del_id;
  is( $t->elt_id( 'elt1')->gi => 'elt', "deleting an inexisting id which remains in the list");
  is( scalar $elt->ancestors_or_self( 'elt'), 1, "ancestors_or_self with cond");
  is( scalar $elt->ancestors_or_self(), 2, "ancestors_or_self without cond");
  my @current_ns_prefixes= $elt->current_ns_prefixes;
  is( scalar @current_ns_prefixes, 0, "current_ns_prefixes");
  is_undef( $elt->next_elt( $elt), 'next_elt on an empty elt (limited to the subtree)');
  is_undef( $elt->next_elt( $elt, 'foo'), 'next_elt on an empty elt (subtree and elt name)');
  is_undef( $elt->next_elt( 'foo'), 'next_elt on an empty elt (elt name)');
  is_undef( $elt->prev_elt( $elt), 'prev_elt on an empty elt (limited to the subtree)');
  is_undef( $elt->prev_elt( $elt, 'foo'), 'prev_elt on an empty elt (subtree and elt name)');
  is_undef( $elt->prev_elt( 'foo'), 'prev_elt on an empty elt (elt name)');
  is_undef( $elt->next_n_elt( 1, 'foo'), 'next_n_elt');
  is_undef( $elt->next_n_elt( 0, 'foo'), 'next_n_elt');
  is( $elt->level(), 1, "level");
  is( $elt->level( 'elt'), 0, "level");
  is( $elt->level( 'doc'), 1, "level");
  is( $elt->level( 'foo'), 0, "level");
  ok( $elt->in_context( 'doc'), "in_context doc ");
  ok( $elt->in_context( 'doc', 0), "in_context doc with level (0)");
  ok( $elt->in_context( 'doc', 1), "in_context doc with level");
  ok( $elt->in_context( 'doc', 2), "in_context doc with level");
  nok( $elt->in_context( 'foo'), "in_context foo");
  nok( $elt->in_context( 'foo', 0), "in_context foo with level (0)");
  nok( $elt->in_context( 'foo', 1), "in_context foo with level");
  nok( $elt->in_context( 'foo', 2), "in_context foo with level (0)");
  nok( $elt->in_context( 'elt'), "in_context elt");
  nok( $elt->in_context( 'elt', 0), "in_context elt with level (0)");
  nok( $elt->in_context( 'elt', 1), "in_context elt with level");
  nok( $elt->in_context( 'elt', 2), "in_context elt with level (0)");
}

{ foreach my $doc ( '<doc><!-- extra data --><ERS><sub/></ERS></doc>',
                    '<doc><!-- extra data --><ERS>toto<sub/></ERS>toto</doc>',
                    '<doc>toto<!-- extra data --><ERS>toto<sub/></ERS>toto</doc>',
                    '<doc>toto<!-- extra data -->tata<ERS>toto<sub/></ERS>toto</doc>',
                    '<doc>toto<!-- extra data --><ERS>titi <!-- more ed --> tutu<sub/></ERS>toto</doc>',
                    '<doc>toto<!-- extra data --><ERS><!-- more ed --> tutu<sub/></ERS>toto</doc>',
                    '<doc><!-- extra data --><ERS><!-- more ed --><sub/></ERS>toto</doc>',
                    '<doc><!-- extra data --><ERS><!-- more ed -->foo<sub/></ERS>toto</doc>',
                    '<doc><!-- extra data --><ERS>toto<sub/></ERS>toto</doc>',
                    '<doc><!-- extra data --><ERS></ERS><elt2/></doc>',
                    '<doc><!-- extra data --><ERS></ERS></doc>',
                    '<doc><!-- extra data --><ERS></ERS>toto</doc>',
                    '<doc><elt><!-- extra data --><ERS></ERS></elt></doc>',
                    '<doc><elt>foo<!-- extra data --><ERS></ERS></elt></doc>',
                    '<doc><elt><selt/><!-- extra data --><ERS></ERS></elt></doc>',
                    '<doc><!-- extra data --><ERS><foo/></ERS></doc>',
                    '<doc><elt><!-- extra data --><ERS></ERS></elt></doc>',
                    '<doc><elt><!-- extra data --><ERS><foo/></ERS></elt></doc>',
                    '<doc><elt><!-- extra data --><ERS></ERS></elt></doc>',
                    '<ERS><!-- extra data --><elt></elt></ERS>',
                    '<!-- extra data --><ERS><elt/></ERS>',
                    '<!-- first comment --><ERS><!-- extra data --><elt></elt></ERS>',
                    # this one does not work: nothing in XML::Twig to output stuff after the ﬁinal end tag
                    #'<!-- first comment --><ERS><!-- extra data --><elt></elt><!-- end comment --></ERS>',
                    '<doc><ERS>foo<!-- edbet --></ERS><!-- edbet 2 --></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS><elt/></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS><!-- edbet 2 --><elt/></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS><!-- edbet 2 --><elt>toto</elt></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS>foo</doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS>foo<!-- edbet 2 --><elt/></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS>foo<!-- edbet 2 --></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS><!-- edbet 2 -->foo<elt/></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS><!-- edbet 2 -->foo</doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS>foo<!-- edbet 2 -->foo<elt/></doc>',
                    '<doc><ERS>foo<!-- edbet --></ERS>foo<!-- edbet 2 -->foo</doc>',
                    '<doc><elt><ERS>foo<!-- edbet --></ERS><!-- edbet 2 --></elt></doc>',
                  )
    { my $t=XML::Twig->new->parse( $doc);
      $t->first_elt( 'ERS')->erase;
      (my $expected= $doc)=~ s{</?ERS/?>}{}g;
     is( $t->sprint, $expected, "erase in $doc");
    }
}
  
{ my $t=XML::Twig->new->parse( '<doc><p>toto</p></doc>');
  my $pcdata= $t->first_elt( '#PCDATA');
  $pcdata->split_at( 2);
  is( $t->sprint => '<doc><p>toto</p></doc>', 'split_at');
}

{ my $doc= q{<doc>tototata<e>tu</e></doc>};
  my $t= XML::Twig->new->parse( $doc);
  $t->subs_text( qr/(to)ta/, '&elt(p => $1)ti');
  is( $t->sprint,'<doc>to<p>to</p>tita<e>tu</e></doc>' , 'subs_text');
  $t->subs_text( qr/(to)ta/, '&elt(p => $1)ti');
  is( $t->sprint,'<doc>to<p>to</p>tita<e>tu</e></doc>' , 'subs_text (2cd try, same exp)');
  $t->subs_text( qr/(ta)/, '&elt(p1 => $1)ti');
  is( $t->sprint,'<doc>to<p>to</p>ti<p1>ta</p1>ti<e>tu</e></doc>' , 'subs_text cannot merge text with next sibling');
}

{ my $doc= q{<doc>tota<e>tu</e></doc>};
  my $t= XML::Twig->new->parse( $doc);
  $t->subs_text( qr/(to)/, '&elt(e => $1)');
  is( $t->sprint,'<doc><e>to</e>ta<e>tu</e></doc>' , 'subs_text (new elt)');
  $t->subs_text( qr/(ta)/, '&elt(e => $1)');
  is( $t->sprint,'<doc><e>to</e><e>ta</e><e>tu</e></doc>' , 'subs_text (new elt 2)');
  $t->subs_text( qr/(t.)/, '&elt(se => $1)');
  is( $t->sprint,'<doc><e><se>to</se></e><e><se>ta</se></e><e><se>tu</se></e></doc>' , 'subs_text (several subs)');
}

{ my $doc= q{<doc>totatitu</doc>};
  my $t= XML::Twig->new->parse( $doc);
  $t->subs_text( qr/(t[aeiou])/, '$1$1');
  is( $t->sprint,'<doc>tototatatititutu</doc>' , 'subs_text (duplicate string)');
  $t->subs_text( qr/((t[aeiou])\2)/, '$2');
  is( $t->sprint,'<doc>totatitu</doc>' , 'subs_text (use \2)');
  $t->subs_text( qr/(t[aeiou])/, '$1$1');
  is( $t->sprint,'<doc>tototatatititutu</doc>' , 'subs_text (duplicate string)');
  $t->subs_text( qr/(t[aeiou]t[aeiou])/, '&elt( p => $1)');
  is( $t->sprint,'<doc><p>toto</p><p>tata</p><p>titi</p><p>tutu</p></doc>' , 'subs_text (use \2)');
}
  
{ my $doc= q{<doc><!-- comment --><e> toto <!-- comment 2 --></e>
                 <e2 att="val1" att2="val2"><!-- comment --><e> toto <!-- comment 2 --></e></e2>
                 <e>foo <?tg pi?> bar <!-- duh --> baz</e>
                 <e><?tg pi?> bar <!-- duh --> baz</e>
                 <e><?tg pi?> bar <!-- duh --></e>
             </doc>
            };
  my $t= XML::Twig->new->parse( $doc);
  my $copy= $t->root->copy;
  is( $copy->sprint, $t->root->sprint, "copy with extra data");
  $t->root->insert_new_elt( first_child => a => { '#ASIS' => 1 }, 'a <b>c</b> a');
  $copy= $t->root->copy;
  is( $copy->sprint, $t->root->sprint, "copy with extra data, and asis");
}

{ my $save= $XML::Twig::weakrefs;
  $XML::Twig::weakrefs=0;
  my $t= XML::Twig->new->parse( '<doc><e id="e1"/><e id="e2">foo <f id="oo"/></e></doc>');
  $t->root->first_child->cut->DESTROY;
  $t->root->first_child->cut->DESTROY;
  is( $t->sprint, '<doc></doc>', 'DESTROY');
  $XML::Twig::weakrefs=$save;
}

{ # test _keep_encoding even with perl > 5.8.0
  if( $] < 5.008)
    { skip( 2 => "testing utf8 flag mongering only needed in perl 5.8.0+"); }
  else
    { require Encode; import Encode;
      my $s="a";
      Encode::_utf8_off( $s);
      nok( Encode::is_utf8( $s), "utf8 flag off");
      XML::Twig::Elt::_utf8_ify( $s);
      if( $] >= 5.008 and $] < 5.010)
        { ok( Encode::is_utf8( $s), "utf8 flag back on"); }
      else
        { nok( Encode::is_utf8( $s), "_utf8_ify is a noop"); }
    }
}

{ # test keep_encoding
  is( XML::Twig::Elt::_keep_encoding(), 0, "_keep_encoding not initialized");
  XML::Twig->new( keep_encoding => 0);
  is( XML::Twig::Elt::_keep_encoding(), 0, "_keep_encoding initialized (0)");
  XML::Twig->new( keep_encoding => 1);
  is( XML::Twig::Elt::_keep_encoding(), 1, "_keep_encoding initialized (1)");
  XML::Twig->new( keep_encoding => 0);
  is( XML::Twig::Elt::_keep_encoding(), 0, "_keep_encoding initialized (0)");
}
      
      
      
