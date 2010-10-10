#!/usr/bin/perl -w
use strict;

use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=82;
print "1..$TMAX\n";

{ # test reverse call mode
  my $doc=q{<doc id="d"><a id="a1"><b id="b1"/><b id="b2"/><c id="c1"/><b id="b3"/></a>
                        <e id="e1"/>
                        <a id="a2"><b id="b4"/><b id="b5"/><c id="c2"/><b id="b6"/></a>
            </doc>
           };
  my $res='';
  my $t= XML::Twig->new( twig_handlers => { '_all_' => sub { $res.= $_->id } },
                         top_down_handlers => 1,
                       )
                  ->parse( $doc);
  is( $res, 'da1b1b2c1b3e1a2b4b5c2b6', 'top_down_handlers _all_');

  $res='';
  $t= XML::Twig->new( twig_handlers => { 'b' => sub { $res.= $_->id } },
                      top_down_handlers => 1,
                    )
               ->parse( $doc);
  is( $res, 'b1b2b3b4b5b6', 'top_down_handlers b)');

  $res='';
  $t= XML::Twig->new( twig_handlers => { _default_ => sub { $res.= $_->id } },
                      top_down_handlers => 1,
                    )
               ->parse( $doc);
  is( $res, 'da1b1b2c1b3e1a2b4b5c2b6', 'top_down_handlers _default_)');

  $res='';
  $t= XML::Twig->new( twig_handlers => { a => sub { $res.= $_->id; },
                                         b => sub { $res.= $_->id; },
                                         c => sub { $res.= $_->id; },
                                         e => sub { $res.= $_->id; },
                                       },
                      top_down_handlers => 1,
                    )
               ->parse( $doc);
  is( $res, 'a1b1b2c1b3e1a2b4b5c2b6', 'top_down_handlers with purge)');
}

{ my $called=0;
  my $t= XML::Twig->new( twig_handlers => { 'doc[@a="="]' => sub { $called++; } })
                  -> parse( '<doc a="="/>');
  is( $called, 1, 'handler on attribute with a value of "="');
} 

{ # test error message for XPath query starting with a / on a node when the twig is not available
    my $sect;
    { my $t= XML::Twig->nparse( '<doc><sect><elt/></sect></doc>');
      $sect= $t->root->first_child( 'sect');
    }
  unless( $XML::Twig::weakrefs) { $sect->cut; } # or the twig is not destroyed
  is( $sect->get_xpath( './elt', 0)->sprint, '<elt/>', " XPath query ok");
  eval { $sect->get_xpath( '/doc/elt'); };
  matches( $@, qr/^cannot use an XPath query starting with a \/ on a node not attached to a whole twig/, "XPath query starting with a /")
;
}

{ # test updating #att in start_tag_handlers
  my( $b, $e11, $e12)= '' x 3;
  my $t= XML::Twig->new( start_tag_handlers => { a => sub { $_->parent->set_att( '#a' => 1); }, },
                         twig_handlers      => { 'e1[@#a]/b'   => sub { $b   .= $_->id || $_->tag }, 
                                                 'e1[@#a]'     => sub { $e11 .= $_->id || $_->tag }, 
                                                 'e1[!@#a]'    => sub { $e12 .= $_->id || $_->tag }, 
                                                 'e1[@#a=1]/b' => sub { $b   .= $_->id || $_->tag }, 
                                               },
                       )
                  ->parse( q{<d id="d"><e1 id="e1-1"><a id="a1"/><b id="b1"/></e1><e1 id="e1-2"><c id="c1"/><b id="b2"/></e1></d>})
                  ;
  is( $b  , 'b1b1',   'trigger on e1[@#a]/b');
  is( $e11, 'e1-1', 'trigger on e1[@#a]'  );
  is( $e12, 'e1-2', 'trigger on e1[!@#a]' );
}

{ # numerical tests in handlers
  my( $ngt, $nlt, $nge, $nle, $neq, $nne)= '' x 6;
  my( $agt, $alt, $age, $ale, $aeq, $ane)= '' x 6;
  my $t= XML::Twig->new( twig_handlers => { 'n[@a>2]'    => sub { $ngt .= $_->id }, 
                                            'n[@a>=2]'   => sub { $nge .= $_->id },
                                            'n[@a<2]'    => sub { $nlt .= $_->id },
                                            'n[@a<=2]'   => sub { $nle .= $_->id },
                                            'n[@a=2]'    => sub { $neq .= $_->id },
                                            'n[@a!=2]'   => sub { $nne .= $_->id },
                                            'a[@a>"b"]'  => sub { $agt .= $_->id },
                                            'a[@a>="b"]' => sub { $age .= $_->id },
                                            'a[@a<"b"]'  => sub { $alt .= $_->id },
                                            'a[@a<="b"]' => sub { $ale .= $_->id },
                                            'a[@a="b"]'  => sub { $aeq .= $_->id },
                                            'a[@a!="b"]' => sub { $ane .= $_->id },
                                          },
                       )
                  ->parse( q{<d id="d"><n id="n1" a="1.0"/><n id="n2" a="2.0"/><n id="n3" a="3.0"/><n id="n4"/>
                                       <a id="a1" a="a"/><a id="a2" a="b"/><a id="a3" a="c"/><a id="a4"/>
                             </d>
                            });
  is( $ngt, 'n3',     ' numerical test: >' );
  is( $nge, 'n2n3',   ' numerical test: >=');
  is( $nlt, 'n1n4',   ' numerical test: <' );
  is( $nle, 'n1n2n4', ' numerical test: <=');
  is( $neq, 'n2',     ' numerical test: =');
  is( $nne, 'n1n3n4', ' numerical test: !=');

  is( $agt, 'a3',     ' string test: >' );
  is( $age, 'a2a3',   ' string test: >=');
  is( $alt, 'a1a4',   ' string test: <' );
  is( $ale, 'a1a2a4', ' string test: <=');
  is( $aeq, 'a2',     ' string test: =');
  is( $ane, 'a1a3a4', ' string test: !=');
}

{ # test former_* methods
  my $t= XML::Twig->nparse( '<d id="d"><e id="e1"/><e id="e2"/><e id="e3"/></d>');
  my $e2= $t->elt_id( 'e2');
  ok( ! defined( $e2->former_parent),       "former_parent on uncut element"      );
  ok( ! defined( $e2->former_prev_sibling), "former_prev_sibling on uncut element");
  ok( ! defined( $e2->former_next_sibling), "former_next_sibling on uncut element");
  $e2->cut;
  is( $e2->former_parent->id,       "d",  "former_parent on cut element"      );
  is( $e2->former_prev_sibling->id, "e1", "former_prev_sibling on cut element");
  is( $e2->former_next_sibling->id, "e3", "former_next_sibling on cut element");
  $e2->paste( after => $e2->former_next_sibling);
  is( $e2->former_parent->id,       "d",  "former_parent on cut element (after paste)"      );
  is( $e2->former_prev_sibling->id, "e1", "former_prev_sibling on cut element (after paste)");
  is( $e2->former_next_sibling->id, "e3", "former_next_sibling on cut element (after paste)");
}

{ # test merge
  my $t= XML::Twig->nparse( '<d id="d"><e>foo</e><e>bar</e></d>');
  my $e= $t->first_elt( 'e');
  $e->merge( $e->next_sibling);
  is( $e->text, 'foobar', "merge");
}

{ # testing ignore on the current element
  my $calls;
  my $h= sub { $calls.= $_[1]->tag; };
  my $t= XML::Twig->new( twig_handlers      => { _all_ => sub { $calls.= $_[1]->tag; } },
                         start_tag_handlers => { b     => sub { shift()->ignore } }
                       )
                  ->parse( q{<a><b><c/><d/><e/></b><b><c/><d/><e/></b><g/></a>}) ;
  is( $calls, 'ga', 'ignore on an element');
  is( $t->sprint, '<a><g/></a>', 'tree build with ignore on an element');

  # testing ignore on a non-current element
  $calls='';
  my $t2= XML::Twig->new( twig_handlers      => { _all_ => sub { $calls.= $_[1]->tag; } },
                          start_tag_handlers => { d     => sub { $_[1]->parent->ignore } }
                       )
                  ->parse( q{<a><f><b><c/><d/><e/></b></f><f><b><c/><d/><e/></b></f></a>})
                  ;
  is( $calls, 'cfcfa', 'ignore on a parent element');
  is( $t2->sprint, '<a><f></f><f></f></a>', 'tree build with ignore on the parent of an element');

  $calls='';
  my $t3= XML::Twig->new( twig_handlers      => { _all_ => sub { $calls.= $_[1]->tag; } },
                          start_tag_handlers => { d     => sub { $_[1]->parent( 'b')->ignore } }
                       )
                  ->parse( q{<a><f><b><c/><g><d/></g><e/></b></f><f><b><c/><g><d/></g><e/></b></f><h/></a>})
                  ;
  is( $calls, 'cfcfha', 'ignore on a grand-parent element');
  is( $t3->sprint, '<a><f></f><f></f><h/></a>', 'tree build with ignore on the grand parent of an element');

  $calls='';
  # ignore from a regular handler
  my $t4= XML::Twig->new( twig_handlers      => { _default_ => sub { $calls.= $_[1]->tag; },
                                                  g         => sub { $calls.= $_[1]->tag; 
                                                                     $_[1]->parent( 'b')->ignore;
                                                                   }, 
                                                }
                       )
                  ->parse( q{<a><f><b><c/><g><d/></g><e/></b></f><f><b><c/><g><d/></g><e/></b></f><h/></a>})
                  ;
  is( $calls, 'cdgfcdgfha', 'ignore from a regular handler');
  is( $t4->sprint, '<a><f></f><f></f><h/></a>', 'tree build with ignore on the parent of an element in a regular handler');

  $calls='';
  # ignore from a regular handler
   my $t5= XML::Twig->new( twig_handlers      => { _default_ => sub { $calls.= $_[1]->tag; },
                                                  g         => sub { $calls.= $_[1]->tag; 
                                                                     $_[1]->parent( 'b')->ignore;
                                                                   }, 
                                                }
                       )
                  ->parse( q{<a><x/><f><b><c/><g><d/></g><e/></b></f><f><b><c/><g><d/></g><e/></b></f><h/></a>})
                  ;
  is( $calls, 'xcdgfcdgfha', 'ignore from a regular handler (2)');
  is( $t5->sprint, '<a><x/><f></f><f></f><h/></a>', 'tree build with ignore from a regular handler (2)');
  
  eval { my $t6= XML::Twig->new( twig_handlers => { c => sub { $_->prev_elt( 'f')->ignore } })
                          ->parse( '<a><f/><c/></a>');
       };
  matches( $@, '^element to be ignored must be ancestor of current element', 'error ignore-ing an element (not ancestor)'); 

  eval { my $t6= XML::Twig->new( twig_handlers => { f => sub { $_->first_child( 'c')->ignore } })
                          ->parse( '<a><f><c/></f></a>');
       };
  matches( $@, '^element to be ignored must be ancestor of current element', 'error ignore-ing an element ( descendant)'); 
}


 
{ my $doc='<l0><l1><l2></l2></l1><l1><l2></l2><l2></l2></l1></l0>';
  (my $indented_doc= $doc)=~ s{(</?l(\d)>)}{"  " x $2 . $1}eg;
  $indented_doc=~ s{>}{>\n}g;
  $indented_doc=~ s{<l2>\s*</l2>}{<l2></l2>}g;
  is( XML::Twig->nparse( $doc)->sprint, $doc, "nparse output");
  is( XML::Twig->nparse_e( $doc)->sprint, $doc, "nparse_e output");
  is( XML::Twig->nparse_pp( $doc)->sprint, $indented_doc, "nparse_pp output");
  is( XML::Twig->nparse_ppe( $doc)->sprint, $indented_doc, "nparse_ppe output");
}

if( _use( 'HTML::TreeBuilder', 4.00) )
  { # first alternative is pre-3.23_1, second one with 3.23_1 (and beyond?)
    
    { my $doc=qq{<html><head><meta 555="er"/></head><body><p>dummy</p>\</body></html>};
      eval { XML::Twig->nparse( $doc); };
      ok( $@, "error in html (normal mode, HTB < 2.23 or >= 4.00): $@"); 
      eval { XML::Twig->nparse_e( $doc); };
      ok( $@, "error in html (nparse_e mode): $@"); 
    }
    
    { my $doc=qq{<html><head></head><body><!-- <foo> bar </foo> --><p 1="a">dummy</p></body></html>};
      eval { XML::Twig->nparse_e( $doc); };
      ok( $@, "error in html (nparse_e mode 2, HTB < 3.23 or >= 4.00: $@)");
    }
    
    { my $doc=qq{<html><head></head><body><![CDATA[  <foo> bar </foo>  ]]>\n\n<p 1="a">dummy</p></body>\n</html>};
      eval { XML::Twig->nparse_e( $doc); };
      ok( $@, "error in html (nparse_e mode 3, HTB < 3.23 or >= 4.00: $@)");
    }
  }
else
  { skip( 4 => "need HTML::TreeBuilder > 4.00 to test error display with HTML data"); }

{ my $e= XML::Twig::Elt->new( 'e');
  is( $e->tag_to_span->sprint, '<span class="e"/>', "tag_to_span");
  is( $e->tag_to_span->sprint, '<span class="e"/>', "tag_to_span again ");
  is( $e->tag_to_div->sprint, '<div class="span"/>', "tag_to_div");
  is( $e->tag_to_div->sprint, '<div class="span"/>', "tag_to_div again ");
}

# added coverage
{ my $doc= "<doc><![CDATA[ foo ]]></doc>\n";
  my $t= XML::Twig->nparse( $doc);
  (my $expected= $doc)=~ s{foo}{bar};
  $t->root->first_child( '#CDATA')->set_content( ' bar ');
  is( $t->root->sprint , $expected, 'set_content on a CDATA element');
}

{ my $doc= "<doc><br></br><br/><br /></doc>";
  my $t= XML::Twig->nparse( pretty_print => 'none', $doc);
  (my $expected= $doc)=~ s{(<br></br>|<br\s*/>)}{<br></br>}g;
  is( $t->root->sprint( { empty_tags => 'expand' } ) , $expected, 'sprint br with empty_tags expand');
  ($expected= $doc)=~ s{(<br></br>|<br\s*/>)}{<br />}g;
  is( $t->root->sprint( { empty_tags => 'html' } ) , $expected, 'sprint br with empty_tags html');
  ($expected= $doc)=~ s{(<br></br>|<br\s*/>)}{<br/>}g;
  is( $t->root->sprint( { empty_tags => 'normal' } ) , $expected, 'sprint br with empty_tags normal');
}

{ my $doc= "<doc><p>foo</p><p>bar</p></doc>";
  my $t= XML::Twig->nparse( pretty_print => 'none', $doc);
  is( $t->root->sprint( { pretty_print => 'indented' } ) , "<doc>\n  <p>foo</p>\n  <p>bar</p>\n</doc>\n", 'sprint br with pretty_print indented');
  is( $t->root->sprint( { pretty_print => 'none' } ) , $doc, 'sprint br with pretty_print none');
}

{ my $doc='<d>&amp;</d>';
  my $t= XML::Twig->new;
  $t->set_keep_encoding( 1);
  is( $t->parse( $doc)->sprint, $doc, 'set_keep_encoding(1)');
  $t->set_keep_encoding( 0);
  is( $t->parse( $doc)->sprint, $doc, 'set_keep_encoding(1)');
}

{ my $doc='<d att="foo"/>';
  is( XML::Twig->nparse( quote => 'single', $doc)->sprint, q{<d att='foo'/>}, 'quote option');
}

{ my $doc= qq{<!DOCTYPE doc SYSTEM "dummy.dtd" [<!ENTITY obj.1 SYSTEM "o1.bmp" NDATA bmp>]>\n<doc/>};
  (my $expected= $doc)=~ s{ \[.*?\]}{};
  my $t= XML::Twig->nparse( $doc);
  my $entity_list = $t->entity_list;
  foreach my $entity ($entity_list->list()) { $entity_list->delete($entity->name); }
  is( $t->sprint( Update_DTD => 1 ), $expected,  'parse entities with all chars in their name');
}

{ my $tmp= "tmp";
  foreach my $doc ( qq{<!DOCTYPE d [<!ENTITY e SYSTEM "e.jpeg" NDATA JPEG>]><d/>},
                    qq{<!DOCTYPE d><d/>},
                    qq{<!DOCTYPE d []><d/>},
                  )
    { foreach my $keep_encoding ( 0..1)
        { open( MYOUT, ">$tmp") or die "cannot open $tmp: $!";
          my $t= XML::Twig->new( twig_roots=> { dummy => sub {} }, 
                                 twig_print_outside_roots => \*MYOUT,
                                 keep_encoding => $keep_encoding,
                               )
                          ->parse( $doc);
          close MYOUT; 
          is_like( slurp( $tmp), $doc, "file with no DTD but entities (keep_encoding: $keep_encoding)");
          unlink $tmp;
        }
    }
}

{ my $doc=qq{<d><e1 id="e1">foo<e id="e">bar</e>baz</e1><e1 id="e2">toto <![CDATA[tata]]> tutu</e1></d>};
  my $t= XML::Twig->parse( $doc);
  is( $t->elt_id( "e1")->text( 'no_recurse'), 'foobaz', "text_only");
  is( $t->elt_id( "e2")->text_only, 'toto tata tutu', "text_only (cdata section)");
  is( $t->elt_id( "e")->text_only,  'bar', "text_only (no embedded elt)");
}

{ my $doc=qq{<!DOCTYPE d SYSTEM "dummy.dtd" []><d><e1 id="e1">tutu &lt;&ent; <b>no</b>tata</e1></d>};
  my $t= XML::Twig->parse( $doc);
  is( $t->elt_id( "e1")->text(), 'tutu <&ent; notata', "text wih ent");
  is( $t->elt_id( "e1")->text( 'no_recurse'), 'tutu <&ent; tata', "text no_recurse wih ent");
  is( $t->elt_id( "e1")->xml_text( ), 'tutu &lt;&ent; notata', "xml_text wih ent");
  is( $t->elt_id( "e1")->xml_text( 'no_recurse'), 'tutu &lt;&ent; tata', "xml_text no_recurse wih ent");
}

{ my $r;
  XML::Twig->parse( twig_handlers => { '/a/b//c' => sub { $r++; } },
                    q{<a><b><b><c>foo</c></b></b></a>}
                  );
  ok( $r, "handler condition with // and nested elts (/a//b/c)");
}


{ my @r;
  XML::Twig->parse( twig_handlers => { 's[@#a="1"]'   => sub { push @r, $_->id},
                                       's/e[@x="1"]' => sub { $_->parent->set_att( '#a' => 1); },
                                     },
                    q{<d><s id="s1"><e x="2"/><e /></s><s id="s2"><e x="1" /></s><s id="s3"><e x="2" /> <e x="1"/></s></d>},
                  );
  is( join( ':', @r), 's2:s3', 'inner handler changing parent attribute value');
}


{ my @r;
  XML::Twig->parse( twig_roots => { '/d/s[@a="1"]/e[@a="1"]' =>  => sub { push @r, $_->id}, },
                    q{<d><s><e a="1" id="e1"/><e id="e2"/></s>
                         <s a="1"><e a="1" id="e3"/><e id="e4"/></s>
                         <s><e a="1" id="e5"/><e id="e6"/></s>
                         <s a="1"><e id="e7"/><e id="e8" a="1"/></s>
                      </d>},
                  );
  is( join( ':', @r), 'e3:e8', 'complex condition with twig_roots');
}

exit; # or you get a weird error under 5.6.2
