#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=67;
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
      $t->first_elt( 'e')->latt( 'a')= 'b';
      is( $t->sprint, q{<d><e a="b"/></d>}, 'lvalued attribute (no attributes)');
      $t->first_elt( 'e')->latt( 'c')= 'd';
      is( $t->sprint, q{<d><e a="b" c="d"/></d>}, 'lvalued attribute (attributes)');
      $t->first_elt( 'e')->latt( 'c')= '';
      is( $t->sprint, q{<d><e a="b" c=""/></d>}, 'lvalued attribute (modifying existing attributes)');
      $t->root->lclass= 'foo';
      is( $t->sprint, q{<d class="foo"><e a="b" c=""/></d>}, 'lvalued class (new class)');
      $t->root->lclass=~ s{fo}{tot};
      is( $t->sprint, q{<d class="toto"><e a="b" c=""/></d>}, 'lvalued class (modify class)');
      $t= XML::Twig->parse( '<d a="1"/>');
      $t->root->latt( 'a')++;
      is( $t->sprint, '<d a="2"/>', '++ on attribute');
    }
  else
    { skip( 6 => "cannot use lvalued attributes with perl $]"); }
}

# used for all HTML parsing tests with HTML::Tidy 
my $DECL= qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n};
my $NS= 'xmlns="http://www.w3.org/1999/xhtml"';
 
{ # testing set_inner_html
  if( !XML::Twig::_use( 'HTML::Tidy'))
    { skip( 4 => "need HTML::Tidy to use the use_tidy method method");
    }
  elsif( !XML::Twig::_use( 'LWP'))
    { skip( 4 => "need LWP to use set_inner_html method");
    }
  else
    {
      my $doc= '<html><head><title>a title</title></head><body>par 1<p>par 2<br>after the break</body></html>';
      my $t= XML::Twig->new( use_tidy => 1)->parse_html( $doc);
      my $inner= '<ul><li>foo</li><li>bar</li></ul>';
      $t->first_elt( 'p')->set_inner_html( $inner);
      (my $expected= $t->sprint)=~ s{<p>.*</p>}{<p>$inner</p>};
      is( $t->sprint, $expected, "set_inner_html");

      $inner= q{<title>2cd title</title><meta content="bar" name="foo">};
      $t->first_elt( 'head')->set_inner_html( $inner);
      $inner=~ s{>$}{/>};
      $expected=~ s{<head>.*</head>}{<head>$inner</head>};
      $expected=~ s{(<meta[^>]*)(/>)}{$1 $2}g;
      is( $t->sprint, $expected, "set_inner_html (in head)");

      $inner= q{<p>just a p</p>};
      $t->root->set_inner_html( $inner);
      $expected= qq{$DECL<html $NS><head></head><body>$inner</body></html>};
      is( $t->sprint, $expected, "set_inner_html (all doc)");

      $inner= q{the content of the <br/> body};
      $t->first_elt( 'body')->set_inner_html( $inner);
      $expected= qq{$DECL<html $NS><head></head><body>$inner</body></html>};
      $expected=~ s{<br/>}{<br />}g;
      is( $t->sprint, $expected, "set_inner_html (body)");
    }
  
}

{ if( !XML::Twig::_use( "File::Temp"))
    { skip( 5, "File::Temp not available"); }
  elsif( !XML::Twig::_use( "HTML::Tidy"))
    { skip( 5, "HTML::Tidy not available"); }
  elsif( !XML::Twig::_use( "LWP"))
    { skip( 5, "LWP not available"); }
  elsif( !XML::Twig::_use( "LWP::UserAgent"))
    { skip( 5, "LWP::UserAgent not available"); }

  else
    {
      # parsefile_html_inplace
      my $file= "test_3_36.html";
      spit( $file, q{<html><head><title>foo</title><body><p>this is it</p></body></html>>});
      XML::Twig->new( use_tidy => 1, twig_handlers => { p => sub { $_->set_tag( 'h1')->flush; }})
               ->parsefile_html_inplace( $file);
      matches( slurp( $file), qr/<h1>/, "parsefile_html_inplace");

      XML::Twig->new( use_tidy => 1, twig_handlers => { h1 => sub { $_->set_tag( 'blockquote')->flush; }}, error_context => 6)
               ->parsefile_html_inplace( $file, '.bak');
      matches( slurp( $file), qr/<blockquote>/, "parsefile_html_inplace (with backup, checking file)");
      matches( slurp( "$file.bak"), qr/<h1>/, "parsefile_html_inplace (with backup, checking backup)");
      unlink( "$file.bak");
    
      XML::Twig->new( use_tidy => 1, twig_handlers => { blockquote => sub { $_->set_tag( 'div')->flush; }})
               ->parsefile_html_inplace( $file, 'bak_*');
      matches( slurp( $file), qr/<div>/, "parsefile_html_inplace (with complex backup, checking file)");
      matches( slurp( "bak_$file"), qr/<blockquote>/, "parsefile_html_inplace (with complex backup, checking backup)");
      unlink( "bak_$file");
      unlink $file;
    }
}

{ if( _use( 'HTML::Tidy'))
    { XML::Twig->set_pretty_print( 'none');

      my $html=q{<html><body><h1>Title</h1><p>foo<br>bar</p>};
      my $expected= qq{$DECL<html $NS><head><title></title></head><body><h1>Title</h1><p>foo<br />\nbar</p></body></html>};
 
      is( XML::Twig->new( use_tidy => 1 )->safe_parse_html( $html)->sprint, $expected, 'safe_parse_html');

      my $html_file= "t/test_3_30.html";
      spit( $html_file, $html);
      is( XML::Twig->new( use_tidy => 1 )->safe_parsefile_html( $html_file)->sprint, $expected, 'safe_parsefile_html');

      if( _use( 'LWP'))
        { is( XML::Twig->new( use_tidy => 1 )->safe_parseurl_html( "file:$html_file")->sprint, $expected, 'safe_parseurl_html'); }
      else
        { skip( 1, "LWP not available, cannot test safe_parseurl_html"); }

      unlink $html_file;

    }
  else
    { skip( 3, "HTML::Tidy not available, cannot test safe_parse.*_html methods with the use_tidy option"); }
}


{ # testing parse_html with use_tidy
 
  if( XML::Twig::_use( 'HTML::Tidy') && XML::Twig::_use( 'LWP::Simple') && XML::Twig::_use( 'LWP::UserAgent'))
    { my $html= q{<html><head><title>T</title><meta content="mv" name="mn"></head><body>t<br>t2<p>t3</body></html>};
      my $tidy=  HTML::Tidy->new(  { output_xhtml => 1, # duh!
                         tidy_mark => 0,    # do not add the "generated by tidy" comment
                         numeric_entities => 1,
                         char_encoding =>  'utf8',
                         bare => 1,
                         clean => 1,
                         doctype => 'transitional',
                         fix_backslash => 1,
                         merge_divs => 0,
                         merge_spans => 0,
                         sort_attributes => 'alpha',
                         indent => 0,
                         wrap => 0,
                         break_before_br => 0 } );
      $tidy->ignore( type =>1, type => 2);
      my $expected= $tidy->clean( $html);
      $expected=~ s{></(meta|br)}{ /}g;
      is_like( XML::Twig->new( use_tidy => 1)->parse_html( $html)->sprint, $expected, 'parse_html string using HTML::Tidy');

      my $html_file= File::Spec->catfile( "t", "test_new_features_3_22.html");
      spit( $html_file => $html);
      if( -f $html_file)
        { is_like( XML::Twig->new( use_tidy => 1)->parsefile_html( $html_file)->sprint, $expected, 'parsefile_html using HTML::Tidy'); 

          open( HTML, "<$html_file") or die "cannot open HTML file '$html_file': $!";
          is_like( XML::Twig->new( use_tidy => 1)->parse_html( \*HTML)->sprint, $expected, 'parse_html fh using HTML::Tidy');
        }
      else
        { skip( 2, "could not write HTML file in t directory, check permissions"); }
      
    }
  else
    { skip( 3 => 'need HTML::Tidy and LWP to test parse_html with the use_tidy option'); }
}

{ if( XML::Twig::_use( 'HTML::TreeBuilder'))
    { my $html_with_Amp= XML::Twig->new->parse_html( '<html><head></head><body>&Amp;</body></html>')->sprint;
      if( $HTML::TreeBuilder::VERSION <= 3.23)
        { is( $html_with_Amp, '<html><head></head><body>&amp;</body></html>', '&Amp; used in html (fixed HTB < 4.00)'); }
      else
        { is( $html_with_Amp, '<html><head></head><body>&amp;Amp;</body></html>', '&Amp; used in html (NOT fixed HTB > r.00)'); }

      is( XML::Twig->new->parse_html( '<html><head></head><body><?xml version="1.0" ?></body></html>')->sprint,
          '<html><head></head><body></body></html>',
          'extra XML declaration in html'
        );
      my $doc=q{<html><head><script><![CDATA[some script with < and >]]></script></head><body><!-- just a <> comment --></body><div><p>foo<b>ah</b></p><p/></div></html>};
      (my $expected= $doc)=~s{<p/>}{<p></p>}g;
      is_like( XML::Twig->parse($doc)->sprint, $expected, 'CDATA and comments in html');
    }
  else
    { skip( 3, 'need HTML::TreeBuilder for additional HTML tests'); }
}

{ my $t= XML::Twig->parse( '<d><e/></d>');
  $t->{twig_root}= undef;
  is( $t->first_elt, undef, 'first_elt on empty tree');
  is( $t->last_elt, undef, 'last_elt on empty tree');
}


{ if( XML::Twig::_use( 'XML::XPathEngine') && XML::Twig::_use( 'XML::Twig::XPath'))
    { my $t= XML::Twig::XPath->new->parse( '<d><p/></d>');
      eval { $t->get_xpath( '//d[.//p]'); };
      matches( $@, qr{the expression is a valid XPath statement, and you are using XML::Twig::XPath}, 'non XML::Twig xpath with get_xpath');
    }
  else
    { skip( 1); }
}

{ my $r= XML::Twig->parse( '<d><e/><e1/></d>')->root;
  is( $r->is_empty, 0, 'non empty element');
  $r->cut_children( 'e');
  is( $r->is_empty, 0, 'non empty element after cut_children');
  $r->cut_children( 'e1');
  is( $r->is_empty, 1, 'empty element after cut_children');
}

{ my $r= XML::Twig->parse( '<d><e/><e1/></d>')->root;
  is( $r->is_empty, 0, 'non empty element');
  $r->cut_descendants( 'e');
  is( $r->is_empty, 0, 'non empty element after cut_descendants');
  $r->cut_descendants( 'e1');
  is( $r->is_empty, 1, 'empty element after cut_descendants');
}

{ if( XML::Twig::_use( 'LWP::Simple'))
    { eval { XML::Twig->parse( 'file://not_there'); };
      matches( $@, 'no element found', 'making xparse fail');
    }
  else
    { skip( 1); }
}

{  is( XML::Twig::Elt::_short_text( 'a', 0), 'a', 'shorten with no length');
}
 
{ is( XML::Twig->parse( comments => 'process', pi => 'process', pretty_print => 'indented',
                        "<d><e><?pi foo?><e1></e1></e><e><!-- comment--><e1></e1></e></d>"
                      )->sprint,
      "<d>\n  <e>\n    <?pi foo?>\n    <e1></e1>\n  </e>\n  <e>\n    <!-- comment-->\n    <e1></e1>\n  </e>\n</d>\n",
      'indenting pi and comments'
     );
}

{ XML::Twig::_set_debug_handler( 3);
  XML::Twig->new( twig_handlers => { 'foo[@a="bar"]' => sub { $_->att( 'a')++; } });
  is( XML::Twig::_return_debug_handler(), q#

parsing path 'foo[@a="bar"]'
predicate is: '@a="bar"'
predicate becomes: '$elt->{'a'} eq "bar"'

perlfunc:
no warnings;
my( $stack)= @_;                    
my @current_elts= (scalar @$stack); 
my @new_current_elts;               
my $elt;                            
warn q{checking path 'foo\[\@a=\"bar\"\]'
};
foreach my $current_elt (@current_elts)              
  { next if( !$current_elt);                         
    $current_elt--;                                  
    $elt= $stack->[$current_elt];                    
    if( ($elt->{_tag} eq "foo") && $elt->{'a'} eq "bar") { push @new_current_elts, $current_elt;} 
  }                                                  
unless( @new_current_elts) { warn qq%fail at cond '($elt->{_tag} eq "foo") && $elt->{'a'} eq "bar"'%;
 return 0; } 
@current_elts= @new_current_elts;           
@new_current_elts=();                       
warn "handler for 'foo\[\@a=\"bar\"\]' triggered\n";
return q{foo[@a="bar"]};

last tag: 'foo', test_on_text: '0'
score: anchored: 0 predicates: 3 steps: 1 type: 3
#, 'handler content');
  XML::Twig::_set_debug_handler( 0);
}

{ my $t=XML::Twig->parse( elt_class => 'XML::Twig::Elt', '<d/>');
  is( ref($t->root), 'XML::Twig::Elt', 'alternate class... as the default one!');
}


{ my( $triggered_bare, $triggered_foo);
 my $t= XML::Twig->new( twig_handlers => { 'e1[@#a]'       => sub { $triggered_bare.=$_->id; },
                                           'e1[@#a="foo"]' => sub { $triggered_foo .=$_->id; },
                                            e2             => sub { $_->parent->set_att( '#a', 1); },
                                            e4             => sub { $_->parent->set_att( '#a', 'foo'); },
                                         }
                      )
                 ->parse( '<d><e1 id="e1.1"><e4/></e1><e1 id="e1.2"><e2/></e1><e1 id="e1.3"><e3><e2/></e3></e1><e1 id="e1.4"/></d>');
 is( $triggered_bare, 'e1.1e1.2', 'handler condition on bare private attribute');
 is( $triggered_foo , 'e1.1', 'handler condition on valued private attribute');
}

{ my $t= XML::Twig->parse( '<d class="foo"><e class="bar baz"/></d>');
  $t->root->remove_class( 'foo');
  is( $t->root->class, '', 'empty class after remove_class');
  my $e= $t->first_elt( 'e');
  $e->remove_class( 'foo');
  is( $e->class, 'bar baz', 'remove_class on non-existent class');
  $e->remove_class( 'baz');
  is( $e->class, 'bar', 'remove_class');
  $e->remove_class( 'foo');
  is( $e->class, 'bar', 'remove_class on non-existent class (again)');
  $e->remove_class( 'bar');
  is( $e->class, '', 'remove_class until no class is left');
}

{ if( XML::Twig::_use( 'Text::Wrap'))
    { my $out= "t/test_wrapped.xml";
      my $out_fh;
      open( $out_fh, ">$out") or die "cannot create temp file $out: $!";
      $Text::Wrap::columns=40;
      $Text::Wrap::columns=40;
      XML::Twig->parse( pretty_print => 'wrapped', '<d a="foo"><e>' . "foobarbaz " x 10 . '</e></d>')
               ->print( $out_fh);
      close $out_fh;
      is( slurp( $out),qq{<d a="foo">\n  <e>foobarbaz foobarbaz foobarbaz\n    foobarbaz foobarbaz foobarbaz\n    foobarbaz foobarbaz foobarbaz\n    foobarbaz </e>
</d>\n},
         'wrapped print'
        );
      unlink $out;
    }
  else
    { skip( 1); }
}

sub all_text
  { return join ':' => map { $_->text } @_; }

1;
