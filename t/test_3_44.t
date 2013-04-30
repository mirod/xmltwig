#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 82;


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

{  my $t= XML::Twig->parse( '<d>a foo a<e/>foo<g>bar</g></d>');
   my $c=$t->root->copy->subs_text( qr/(foo)/, '&elt( e => "$1")');
   is( $c->sprint, '<d>a <e>foo</e> a<e/><e>foo</e><g>bar</g></d>', 'subs_text');
   $c=$t->root->copy->subs_text( qr/(foo)/, 'X &elt( e => "$1") X');
   is( $c->sprint, '<d>a X <e>foo</e> X a<e/>X <e>foo</e> X<g>bar</g></d>', 'subs_text');
   $c=$t->root->copy->subs_text( qr/(foo)/, 'X &elt( e => "Y $1 Y") X');
   is( $c->sprint, '<d>a X <e>Y foo Y</e> X a<e/>X <e>Y foo Y</e> X<g>bar</g></d>', 'subs_text');
   $c->subs_text( qr/(foo)/, 'X &elt( e => "Y $1 Y") X');
   is( $c->sprint, '<d>a X <e>Y X <e>Y foo Y</e> X Y</e> X a<e/>X <e>Y X <e>Y foo Y</e> X Y</e> X<g>bar</g></d>', 'subs_text (re-using previous substitution)');
}

{ my $e= XML::Twig::Elt->new( 'e');
  is( $e->att_nb, 0, 'att_nb on element with no attributes');
  ok( $e->has_no_atts, 'has_no_atts on element with no attributes');
  my $e2= XML::Twig::Elt->new( e => { a => 1 })->del_att( 'a');;
  is( $e->att_nb, 0, 'att_nb on element with no more attributes');
  ok( $e->has_no_atts, 'has_no_atts on element with no more attributes');
  is( $e->split_at( 1), '', 'split_at on a non text element');
}

SKIP: { 
        skip 'XML::XPath not available', 1 unless XML::Twig::_use( 'XML::XPath');
        XML::Twig::_disallow_use( 'XML::XPathEngine');
        XML::Twig::_use( 'XML::Twig::XPath');
        my $t= XML::Twig::XPath->parse( '<d><e a="1">e1</e><e a="2">e2</e><e a="3">e3</e></d>');
        is( $t->findvalue( '//e[@a>=3]|//e[@a<=1]'), 'e1e3', 'xpath search with XML::XPath');
      }

SKIP: { # various tests on _fix_xml
  skip 'HTML::TreeBuilder not available', 2 unless XML::Twig::_use( 'HTML::TreeBuilder');
  my $html= '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body><p 1="1">&Amp;</p></body></html>';
  my $t= HTML::TreeBuilder->new_from_content( $html);
  local $@='not well-formed (invalid token)';
  local $HTML::TreeBuilder::VERSION=3.23;
  XML::Twig::_fix_xml( $t, \$html);
  unlike( $html, qr{Amp}, '&Amp with old versions of HTML::TreeBuilder');
  like( $html, qr{<p a1="1"}, 'fix improper naked attributes in old versions of HTML::TreeBuilder');
      }

SKIP: {
        skip 'cannot use XML::Twig::XPath', 1, unless  XML::Twig::_use( 'XML::Twig::XPath') && (XML::Twig::_use( 'XML::XPathEngine') ||  XML::Twig::_use( 'XML::XPath'));
        my $t= XML::Twig::XPath->parse( '<d xmlns:pr="uri"><pr:e>pre1</pr:e><e>e1</e><pr:e>pre2</pr:e><a>a 1</a></d>');
        is( $t->findvalue( '/d/*[local-name()="e"]'), 'pre1e1pre2', 'local-name()');
   
      }

{ my $doc= qq{<d><e xml:space="preserve">\n<se/></e><e xml:space="default">\n<se/></e></d>};
  (my $expected= $doc)=~ s{("default">)\n}{$1}; # this space should be discarded
  my $t=  XML::Twig->parse( $doc);
  is( $t->sprint, $expected, 'xml:space effect on whitespace discarding');
}

{ my $d= "<d><e/></d>";
  my $got=0;
  my $t= XML::Twig->new( start_tag_handlers => { e => sub { $got=1; } } );
  $t->parse( $d);
  is( $got, 1, 'setStartTagHandlers');
  $t->setStartTagHandlers(  { e => sub { $got=2; } });
  $t->parse( $d);
  is( $got, 2, 'setStartTagHandlers changed');
}

{ my $d= "<d><e><se/></e></d>";
  my $got=0;
  my $st;
  my $t= XML::Twig->new( start_tag_handlers => { se => sub { $got=1; } },
                         ignore_elts => { e => \$st },
                       );
  $t->parse( $d);
  is( $got, 0, 'check that ignore_elts skips element');
  is( $st, '<e><se/></e>', 'check that ignore_elts stores the ignored content');

  $st='';
  $t->setIgnoreEltsHandler( e  => 'discard');
  is( $got, 0, 'check that ignore_elts still skips element');
  is( $st, '', 'check that ignore_elts now discards the ignored content');
  
}

{ my $content= '<p>here a <a href="/foo?a=1&amp;b=2">dodo</a> bird</p>';

  is( XML::Twig::Elt->new( $content)->sprint, $content, 'XML::Twig::Elt->new with litteral content');
}

{ my $doc= '<d><?pi foo?><e/></d>';
  my $doc_no_pi= '<d><e/></d>'; 
  my $t= XML::Twig->parse(  $doc);
  is( $t->sprint,  $doc, 'pi is keep by default'); 
  my $tk= XML::Twig->parse( pi => 'keep', $doc);
  is( $tk->sprint,  $doc, 'pi is keep'); 
  my $td= XML::Twig->parse( pi => 'drop', $doc);
  is( $td->sprint,  $doc_no_pi, 'pi is keep'); 
  my $tp= XML::Twig->parse( pi => 'process', $doc);
  is( $tp->sprint,  $doc, 'pi is process');
  foreach my $pi ($t->descendants( '#PI')) { $pi->delete; }
  is( $t->sprint,  $doc, 'pi cannot be cut when pi => keep (by default)'); 
  foreach my $pi ($tk->descendants( '#PI')) { $pi->delete; }
  is( $tk->sprint,  $doc, 'pi cannot be cut when pi => keep'); 
  foreach my $pi ($tp->descendants( '#PI')) { $pi->delete; }
  is( $tp->sprint,  $doc_no_pi, 'pi can be cut when pi => process'); 
}

{ my $doc= '<d><!-- comment --><e/></d>';
  my $doc_no_comment= '<d><e/></d>'; 
  my $t= XML::Twig->parse(  $doc);
  is( $t->sprint,  $doc, 'comments is keep by default'); 
  my $tk= XML::Twig->parse( comments => 'keep', $doc);
  is( $tk->sprint,  $doc, 'comments is keep'); 
  my $td= XML::Twig->parse( comments => 'drop', $doc);
  is( $td->sprint,  $doc_no_comment, 'comments is keep'); 
  my $tp= XML::Twig->parse( comments => 'process', $doc);
  is( $tp->sprint,  $doc, 'comments is process');
  foreach my $comment ($t->descendants( '#COMMENT')) { $comment->delete; }
  is( $t->sprint,  $doc, 'comment cannot be cut when comment => keep (by default)'); 
  foreach my $comment ($tk->descendants( '#COMMENT')) { $comment->delete; }
  is( $tk->sprint,  $doc, 'comment cannot be cut when comment => keep'); 
  foreach my $comment ($tp->descendants( '#COMMENT')) { $comment->delete; }
  is( $tp->sprint,  $doc_no_comment, 'comment can be cut when comment => process'); 
}

{ my $d='<d><s l="1"><t>t1</t><s l="2"><t>t2</t><p id="t">p</p></s></s></d>';
  my $t= XML::Twig->parse( $d);
  my $p= $t->elt_id( 't');
  is( $p->level, 3, 'level');
  is( $p->level( 's'), 2, 'level with cond');
  is( $p->level( 's[@l]'), 2, 'level with cond on attr');
  is( $p->level( 's[@l="2"]'), 1, 'level with more cond on attr');
  is( $p->level( 's[@g]'), 0, 'level with unsatisfied more cond on attr');
}

{ my $d='<d><e id="i">e1</e><e id="i2">e2</e><e id="i3">e3</e><e>e4</e><e id="iii">e5</e><f>f1</f><f id="ff">f1</f><f id="fff">f2</f></d>';
  my $r;
  XML::Twig->parse( twig_handlers => { 'e#i' => sub { $r.= $_->text}}, $d);
  is( $r, 'e1', '# in twig handlers (1 letter id)');
  $r='';
  XML::Twig->parse( twig_handlers => { 'e#iii' => sub { $r.= $_->text}}, $d);
  is( $r, 'e5', '# in twig handlers (3 letter id)');
  $r='';
  XML::Twig->parse( twig_handlers => { 'e#i2' => sub { $r.= $_->text}}, $d);
  is( $r, 'e2', '# in twig handlers (letter + digits)');
  $r='';
  XML::Twig->parse( twig_handlers => { '*#ff' => sub { $r.= $_->text}}, $d);
  is( $r, 'f1', '*# in twig handlers');
}
