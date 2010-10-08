#!/usr/bin/perl -w
use strict;


use strict;
use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;

use lib File::Spec->catdir(File::Spec->curdir,"blib/lib");
use XML::Twig;



my $TMAX=181;
print "1..$TMAX\n";

{ # testing how well embedded comments and pi's are kept when changing the content
  my @tests= ( [ "foo <!-- comment -->bar baz", "foo bar", "foo <!-- comment -->bar" ],
               [ "foo <!-- comment -->bar baz",  "foo bar baz foobar", "foo <!-- comment -->bar baz foobar" ],
               [ "foo bar<!-- comment --> foobar tutu", "bar tutu", "bar tutu" ],
               [ "foo bar<!-- comment --> foobar baz", "foobar baz", "foobar baz"],
               [ "foo <!-- comment -->baz",  "foo bar baz", "foo bar <!-- comment -->baz"],
               [ "foo <!-- comment --> baz",  "foo bar baz", "foo bar<!-- comment --> baz"],
               [ "foo bar <!-- comment -->baz",  "bar baz", "bar <!-- comment -->baz"],
               [ "foo bar <!-- comment --> baz toto",  "foo toto", "foo toto"],
             );

  foreach my $test (@tests)
    { my( $initial, $set, $expected)= @$test;
      my $t= XML::Twig->nparse( "<doc>$initial</doc>");
      $t->root->set_content( $set);
      is( $t->sprint, "<doc>$expected</doc>", "set_content '$initial' => '$set'");
    }
}

{ # RT #17145
  my $twig= new XML::Twig()->parse("<root></root>");
  is( scalar( $twig->get_xpath('//root/elt[1]/child')), 0, "Context position of non-existent elements in XPATH expressions");
}
  
 
{ # some extra coverage
  my @siblings=  XML::Twig->nparse( "<doc/>")->root->following_elts;
  is( scalar(  @siblings), 0, "following_elts on last sibling");

  
  is(  XML::Twig->nparse( "<doc/>")->root->del_id->sprint, "<doc/>", "del_id on elt with no atts");

  # next_elt with deep tree (
  my $t= XML::Twig->nparse( q{
  <doc n="12">
    <elt n="0"/>
    <elt1 n="10">
      <selt n="4">
        <sselt1 n="1"><ssselt n="0"/></sselt1>
        <sselt2 n="1"><ssselt n="0"/></sselt2>
      </selt>
      <selt1 n="4">
        <sselt3 n="1"><ssselt n="0"/></sselt3>
        <sselt4 n="1"><ssselt n="0"/></sselt4>
      </selt1>
    </elt1>
  </doc>
  });

  foreach my $e ($t->root->descendants_or_self)
    { is( scalar( $e->_descendants), $e->att( 'n'), "_descendant " . $e->tag . "\n");
      is( scalar( $e->_descendants( 1)), $e->att( 'n') + 1, "_descendant(1) " . $e->tag . "\n");
    }
}
  
{ 
  my $exp= '/foo/1^%';
  eval { XML::Twig->nparse( "<doc/>")->get_xpath( $exp); };
  matches( $@, "^error in xpath expression", "xpath with valid expression then stuff left");
}

{ 
  my $t = XML::Twig->nparse( "<doc/>");
  my $root = $t->root;
  my $elt  =XML::Twig::Elt->new( 'foo');
  foreach my $pos ( qw( before after))
    { eval {  $elt->paste( $pos => $root); }; 
      matches( $@, "^cannot paste $pos root", "paste $pos root");
      eval " \$elt->paste_$pos( \$root)";
      matches( $@, "^cannot paste $pos root", "paste $pos root");
    }
}

{ is( XML::Twig->nparse( comments => "process", pi => "process", "<doc><!-- c --><?t data?><?t?></doc>")->_dump,
     "document\n|-doc\n| |-COMMENT: '<!-- c -->'\n| |-PI:      't' - 'data'\n| |-PI:      't' - ''\n",
     "_dump PI/comment"
    );
}

{ is(  XML::Twig->nparse( '<doc/>')->root->get_xpath( '.', 0)->gi, 'doc', 'get_xpath: .'); }

{ my $t= XML::Twig->nparse( '<doc><![CDATA[foo]]></doc>');
  $t->first_elt( '#CDATA')->set_text( 'bar');
  is( $t->sprint, '<doc><![CDATA[bar]]></doc>', " set_text on CDATA");
  $t->root->set_text( 'bar');
  is( $t->sprint, '<doc>bar</doc>', " set_text on elt containing CDATA");
  $t= XML::Twig->nparse( '<doc><![CDATA[foo]]></doc>');
  $t->first_elt( '#CDATA')->set_text( 'bar', force_pcdata => 1);
  is( $t->sprint, '<doc>bar</doc>', " set_text on CDATA with force_pcdata");}

  # print/flush entity
  # SAX export entity

{ my $enc= "a_non_existent_encoding_bwaaahhh";
  eval { XML::Twig->iconv_convert( $enc); };
  matches( $@, "^(Unsupported|Text::Iconv not available|Can't locate)", "unsupported encoding");
}

{ # test comments handlers
  my $doc= qq{<doc><!-- comment --><elt/></doc>};
  is( XML::Twig->nparse( twig_handlers => { '#COMMENT' => sub { return uc( $_[1]); } }, $doc)->sprint,
      qq{<doc><!-- COMMENT --><elt/></doc>},
      "comment handler"
    );
  is( XML::Twig->nparse( twig_handlers => { '#COMMENT' => sub { return uc( $_[1]); } }, keep_encoding => 1, $doc)->sprint,
      qq{<doc><!-- COMMENT --><elt/></doc>},
      "comment handler (with keep_encoding)"
    );
  is( XML::Twig->nparse( twig_handlers => { '#COMMENT' => sub { return; } }, keep_encoding => 0, $doc)->sprint,
      qq{<doc><elt/></doc>},
      "comment handler returning undef comment"
    );
  is( XML::Twig->nparse( twig_handlers => { '#COMMENT' => sub { return ''; } }, keep_encoding => 1, $doc)->sprint,
      qq{<doc><elt/></doc>},
      "comment handler  returning empty comment (with keep_encoding)"
    );
  is( XML::Twig->nparse( comments => 'process', twig_handlers => { '#COMMENT' => sub { $_->set_comment( uc( $_->comment)); } }, 
                         keep_encoding => 0, $doc)->sprint,
      qq{<doc><!-- COMMENT --><elt/></doc>},
      "comment handler, process mode"
    );
  is( XML::Twig->nparse( comments => 'process', twig_handlers => { '#COMMENT' => sub { $_->set_comment( uc( $_->comment)); } }, 
                         keep_encoding => 1, $doc)->sprint, 
      qq{<doc><!-- COMMENT --><elt/></doc>},
      "comment handler (with keep_encoding), process mode"
    );
  is( XML::Twig->nparse( comments => 'process', twig_handlers => { elt => sub { $_->cut; } }, keep_encoding => 0, $doc)->sprint,
      qq{<doc><!-- comment --></doc>},
      "comment handler deletes comment, process mode"
    );
  is( XML::Twig->nparse( comments => 'process', twig_handlers => { '#COMMENT' => sub { $_->cut; } }, keep_encoding => 0, $doc)->sprint,
      qq{<doc><elt/></doc>},
      "comment handler deletes comment, process mode"
    );
  is( XML::Twig->nparse( comments => 'process', twig_handlers => { '#COMMENT' => sub { $_->set_comment( ''); } }, keep_encoding => 1, $doc)->sprint,
      qq{<doc><!----><elt/></doc>},
      "comment handler returning empty comment (with keep_encoding), process mode"
    );
}

{ # check pi element handler in keep_encoding mode
  is( XML::Twig->nparse( pi => 'process', twig_handlers => { '?t' => sub { $_->set_data( uc( $_->data)); } }, '<doc><?t data?></doc>')->sprint,
       '<doc><?t DATA?></doc>', 'pi element handler');
  is( XML::Twig->nparse( pi => 'process', keep_encoding => 1,twig_handlers => { '?t' => sub { $_->set_data( uc( $_->data)); } }, 
                         '<doc><?t data?></doc>')->sprint,
       '<doc><?t DATA?></doc>', 'pi element handler in keep_encoding mode');
}

{ # test changes on comments before the root element 
  my $doc= q{<!-- comment1 --><?t pi?><!--comment2 --><doc/>};
  is( XML::Twig->nparse( $doc)->sprint, $doc, 'comment after root element');
  is_like( XML::Twig->nparse( pi => 'process', comments => 'process', $doc)->sprint, $doc, 'comment before root element (pi/comment => process)');
  is_like( XML::Twig->nparse( pi => 'process', $doc)->sprint, $doc, 'comment before root element (pi => process)');
  is_like( XML::Twig->nparse( comments => 'process', $doc)->sprint, $doc, 'comment before root element (comment => process)');
}

{ # test bug on comments after the root element RT #17064
  my $doc= q{<doc/><!-- comment1 --><?t pi?><!--comment2 -->};
  is( XML::Twig->nparse( $doc)->sprint, $doc, 'comment after root element');
  is( XML::Twig->nparse( pi => 'process', comments => 'process', $doc)->sprint, $doc, 'comment after root element (pi/comment => process)');
  is_like( XML::Twig->nparse( pi => 'process', $doc)->sprint, $doc, 'comment before root element (pi => process)');
  is_like( XML::Twig->nparse( comments => 'process', $doc)->sprint, $doc, 'comment before root element (comment => process)');
}

{ # test bug on doctype declaration (RT #17044)
  my $doc= qq{<!DOCTYPE doc PUBLIC "-//XMLTWIG//Test//EN" "dummy.dtd">\n<doc/>};
  is( XML::Twig->nparse( $doc)->sprint, $doc, "doctype with public id");
  is( XML::Twig->nparse( $doc)->sprint( Update_DTD => 1), $doc, "doctype with public id (update_DTD => 1)");
  $doc= qq{<!DOCTYPE doc SYSTEM "dummy.dtd">\n<doc/>};
  is( XML::Twig->nparse( $doc)->sprint, $doc, "doctype with public id");
  is( XML::Twig->nparse( $doc)->sprint( updateDTD => 1) , $doc, "doctype with public id (update_DTD => 1)");
}

{ # test bug on tag names similar to internal names RT #16540
  ok( XML::Twig->nparse( twig_handlers => { level => sub {} }, '<level/>'), " bug on tag names similar to internal names RT #16540");
}

{ # test parsing of an html string
  if( XML::Twig::_use( 'HTML::TreeBuilder',  3.13) && XML::Twig::_use( 'HTML::Entities::Numbered'))
    { 
      ok( XML::Twig->parse( error_context => 1, '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
    <html>
     <head>
      <link rel="stylesheet" href="/s/style.css" type="text/css">
      </head>
      <body>
        foo<p>
        bar<br>
        &eacute;t&eacute;
      </body>
      </html>'), "parsing an html string");
    }
  else
    { skip( 1, "need HTML::TreeBuilder 3.13+ and HTML::Entities::Numbered for this test"); }
}

{ # testing print_to_file
  my $tmp= "print_to_file.xml";
  my $doc= "<doc>foo</doc>";
  unlink( $tmp); # no check, it could not be there
  my $t1= XML::Twig->nparse( $doc)->print_to_file( $tmp);
  ok( -f $tmp, "print_to_file created document");
  my $t2= XML::Twig->nparse( $tmp);
  is( $t2->sprint, $t1->sprint, "generated document identical to original document");
  unlink( $tmp); 

  my $e1=  XML::Twig->parse( '<d><a>foo</a><b>bar</b></d>')->first_elt( 'b')->print_to_file( $tmp);
  ok( -f $tmp, "print_to_file on elt created document");
  $t2= XML::Twig->nparse( $tmp);
  is( $t2->sprint, '<b>bar</b>', "generated sub-document identical to original sub-document");
  unlink( $tmp); 

  # failure modes
  eval { XML::Twig->nparse( $tmp); };
  mtest( $@, "Couldn't open $tmp:");
  my $non_existent="non_existent_I_hope_01/tmp";
  while( -f $non_existent) { $non_existent++; } # most likely unnecessary ;--)
  eval { $t1->print_to_file( $non_existent); };
  mtest( $@, "cannot create file $non_existent:");
} 
  

{
  my $doc=q{<doc><elt id="elt1" att="v1" att2="v1"/><elt id="elt2" att="v1" att2="v2"/></doc>};
  my $t= XML::Twig->nparse( $doc);
  test_get_xpath( $t, q{/doc/elt[1][@att2="v2"]}, ''); 
}

{ my $doc=q{<d id="d1"><e a="1" id="e1">foo</e><e a="1" id="e2">bar</e><e a="2" id="e3">baz</e><e a="1" id="e4">foobar</e></d>};
  my $t= XML::Twig->nparse( $doc);
  test_get_xpath( $t, q{/d/e[@a="1"][2]}, 'e2');
  test_get_xpath( $t, q{/d/e[@a="1"][-2]}, 'e2');
  test_get_xpath( $t, q{/d/e[@a="1"][-1]}, 'e4');
  test_get_xpath( $t, q{/d/e[@a="1"][-3]}, 'e1');
}

{ # test support for new conditions condition in get_xpath
  my $doc=q{<doc id="d1" a="1"><elt id="elt1" a="2">foo</elt><elt id="elt2">bar</elt><elt id="elt3">baz</elt></doc>}; 
  my $t= XML::Twig->nparse( $doc);
  
  # just checking
  test_get_xpath( $t, q{//elt[@a]}, 'elt1');
  is( ids( $t->get_xpath( q{//*[@a]})), 'd1:elt1', '//*[@a] xpath exp');
  
   # test support for !@att condition in get_xpath
  is( ids( $t->get_xpath( q{//elt[!@a]})), 'elt2:elt3', '//elt[!@a] xpath exp');
  is( ids( $t->get_xpath( q{//elt[not@a]})), 'elt2:elt3', '//elt[not@a] xpath exp');
  is( ids( $t->get_xpath( q{/doc/elt[not@a]})), 'elt2:elt3', '/doc/elt[not@a] xpath exp');
  is( ids( $t->get_xpath( q{//*[!@a]})), 'elt2:elt3', '//*[!@a] xpath exp');
  is( ids( $t->get_xpath( q{//*[not @a]})), 'elt2:elt3', '//*[not @a] xpath exp');
  is( ids( $t->get_xpath( q{/doc/*[not @a]})), 'elt2:elt3', '/doc/*[not @a] xpath exp');
  
  # support for ( and )
  test_get_xpath( $t, q{//*[@id="d1" or @a and @id="elt1"]}, 'd1:elt1');
  test_get_xpath( $t, q{//*[(@id="d1" or @a) and @id="elt1"]}, 'elt1');
  
}

{ # more test on new XPath support: axis in node test part
  my $doc=q{<doc id="d1">
              <elt id="elt1"><selt id="selt1"/></elt>
              <elta id="elta1"><selt id="selt2"/></elta>
              <elt id="elt2"/>
              <eltb id="eltb1"><seltb id="seltb1"><sseltb id="sseltb1"/></seltb></eltb>
              <eltc id="eltc1"><seltb id="seltb2"><sseltb id="sseltb2"/></seltb></eltc>
            </doc>}; 
  my $t= XML::Twig->nparse( $doc);
  # parent axis in node test part
  test_get_xpath( $t, q{/doc//selt/..}, 'elt1:elta1');
  test_get_xpath( $t, q{/doc//selt/parent::elt}, 'elt1');
  test_get_xpath( $t, q{/doc//selt/parent::elta}, 'elta1');
  test_get_xpath( $t, q{//sseltb/ancestor::eltc}, 'eltc1');
  test_get_xpath( $t, q{//sseltb/ancestor::*}, 'd1:eltb1:seltb1:eltc1:seltb2');
  test_get_xpath( $t, q{//sseltb/ancestor-or-self::eltc}, 'eltc1');
  test_get_xpath( $t, q{//sseltb/ancestor-or-self::*}, 'd1:eltb1:seltb1:sseltb1:eltc1:seltb2:sseltb2');

  test_get_xpath( $t, q{/doc//*[@id="eltc1"]/descendant::*}, 'seltb2:sseltb2');
  test_get_xpath( $t, q{/doc//*[@id="eltc1"]/descendant::sseltb}, 'sseltb2');
  test_get_xpath( $t, q{/doc//*[@id="eltc1"]/descendant::eltc}, '');
  test_get_xpath( $t, q{/doc//*[@id="eltc1"]/descendant-or-self::*}, 'eltc1:seltb2:sseltb2');
  test_get_xpath( $t, q{/doc//*[@id="eltc1"]/descendant-or-self::eltc}, 'eltc1');
  test_get_xpath( $t, q{/doc//*[@id="eltc1"]/descendant-or-self::seltb}, 'seltb2');

  test_get_xpath( $t, q{/doc/elt/following-sibling::*}, 'elta1:elt2:eltb1:eltc1');
  test_get_xpath( $t, q{/doc/elt/preceding-sibling::*}, 'elt1:elta1');
  test_get_xpath( $t, q{/doc/elt[@id="elt1"]/preceding-sibling::*}, '');
  test_get_xpath( $t, q{/doc/elt/following-sibling::elt}, 'elt2');
  test_get_xpath( $t, q{/doc/elt/preceding-sibling::elt}, 'elt1');
  test_get_xpath( $t, q{/doc/elt[@id="elt1"]/preceding-sibling::elt}, '');
 
  is( $t->elt_id( "sseltb1")->following_elt->id, 'eltc1', 'following_elt');
  is( ids( $t->elt_id( "sseltb1")->following_elts), 'eltc1:seltb2:sseltb2', 'following_elts');
  is( ids( $t->elt_id( "sseltb1")->following_elts( '')), 'eltc1:seltb2:sseltb2', 'following_elts( "")');
  my @elts=  $t->elt_id( "eltc1")->descendants_or_self;
  is( ids( @elts), 'eltc1:seltb2:sseltb2', 'descendants_or_self');
  is( ids( XML::Twig::_unique_elts( @elts)), 'eltc1:seltb2:sseltb2', '_unique_elts');
  
  test_get_xpath( $t, q{/doc//[@id="sseltb1"]/following::*}, 'eltc1:seltb2:sseltb2');
  test_get_xpath( $t, q{/doc//[@id="sseltb1"]/following::seltb}, 'seltb2');
  test_get_xpath( $t, q{/doc//[@id="selt1"]/following::elt}, 'elt2');
 
  ok( $t->root->last_descendant( 'doc'), "checking if last_descendant returns the element itself");
  test_get_xpath( $t, q{/doc/preceding::*}, '');
  test_get_xpath( $t, q{/doc/elt[1]/preceding::*}, '');
  test_get_xpath( $t, q{/doc/elt/preceding::*}, 'd1:elt1:selt1:elta1:selt2');
  test_get_xpath( $t, q{/doc//[@id="sseltb2"]/preceding::seltb}, 'seltb1');
  test_get_xpath( $t, q{/doc//[@id="selt1"]/preceding::elt}, '');
  test_get_xpath( $t, q{/doc//[@id="selt2"]/preceding::elt}, 'elt1');

  test_get_xpath( $t, q{/doc/self::doc}, 'd1');
  test_get_xpath( $t, q{/doc/self::*}, 'd1');
  test_get_xpath( $t, q{/doc/self::elt}, '');
  test_get_xpath( $t, q{//[@id="selt1"]/self::*}, 'selt1');
  test_get_xpath( $t, q{//[@id="selt1"]/self::selt}, 'selt1');
  test_get_xpath( $t, q{//[@id="selt1"]/self::elt}, '');
}

{ # more tests: more than 1 predicate
  
  my $doc=q{<doc><elt id="elt1" att="v1" att2="v1"/><elt id="elt2" att="v1" att2="v2"/></doc>};
  my $t= XML::Twig->nparse( $doc);
  test_get_xpath( $t, q{/doc/elt[@id][@att="v1"]}, 'elt1:elt2');
  test_get_xpath( $t, q{/doc/elt[@id][@att2="v1"]}, 'elt1');
  test_get_xpath( $t, q{/doc/elt[@id][1]}, 'elt1');
  test_get_xpath( $t, q{/doc/elt[@att="v1"][1]}, 'elt1');
  test_get_xpath( $t, q{/doc/elt[@att="v2"][1]}, '');
  test_get_xpath( $t, q{/doc/elt[@att="v1"][2]}, 'elt2');
  test_get_xpath( $t, q{/doc/elt[1][@att2="v1"]}, 'elt1');
  test_get_xpath( $t, q{/doc/elt[1][@att2="v2"]}, ''); 
  test_get_xpath( $t, q{/doc/elt[@att2="v2"][1]}, 'elt2'); 
  test_get_xpath( $t, q{/doc/elt[@att2="v2"][2]}, ''); 
  test_get_xpath( $t, q{/doc/elt[@att2][1]}, 'elt1'); 
  test_get_xpath( $t, q{/doc/elt[@att2][2]}, 'elt2'); 
  test_get_xpath( $t, q{/doc/elt[@att2][3]}, ''); 
  test_get_xpath( $t, q{/doc/elt[@att2][-1]}, 'elt2'); 
  test_get_xpath( $t, q{/doc/elt[@att2][-2]}, 'elt1'); 
  test_get_xpath( $t, q{/doc/elt[@att2][-3]}, ''); 
}
  
  

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

{ # test bug on tests on attributes with a value of 0 (RT #15671)
  my $t= XML::Twig->nparse( '<foo><bar id="0"/><bar id="1"/></foo>');
  my $root = $t->root();
  is( scalar $root->children('*[@id="1"]'), 1, 'testing @att="1"');
  is( scalar $root->children('*[@id="0"]'), 1, 'testing @att="0"');
  is( scalar $root->children('*[@id="0" or @id="1"]'), 2, 'testing @att="0" or');
  is( scalar $root->children('*[@id="0" and @id="1"]'), 0, 'testing @att="0" and');
}

{ # test that the '>' after the doctype is properly output when there is no DTD RT#
  my $doctype='<!DOCTYPE doc SYSTEM "doc.dtd">';
  my $doc="$doctype<doc/>";
  is_like( XML::Twig->nparse( $doc)->sprint, $doc);
  is_like( XML::Twig->nparse( $doc)->doctype, $doctype);
}

