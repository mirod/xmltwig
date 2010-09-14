#!/usr/bin/perl -w
use strict;


use strict;
use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=87;
print "1..$TMAX\n";

if( _use( 'Tie::IxHash'))
  { # test the new indent format example from http://tinyurl.com/2kwscq
    my $doc=q{<?xml version="1.0" encoding="UTF-8"?>
<widget
    xmlns="http://xmlns.oracle.com/widgets"
    id="first.widget"
    class="FirstWidgetClass">
  <!-- This is a comment about widget instance -->
  <widget-instance>
    <!-- This is OK, on one line because there is only one attribute -->
    <subwidget id="sub.widget" />
    <!-- This one has two attributes, so is split up. -->
    <subwidget
        id="sub.widget.2"
        name="SubWidget2"
    />
  </widget-instance>
</widget>
};
    my $formatted= XML::Twig->parse( keep_atts_order => 1, pretty_print => cvs => $doc)->sprint;
    is( $formatted, $doc, 'cvs pretty_print');
  }
else
  { skip( 1, "Tie::IxHash not available, cannot test the cvs pretty_print option"); }

if( $XML::Parser::VERSION > 2.27)
  { my $test_dir= "ent_test";
    mkdir( $test_dir, 0777) or die "cannot create $test_dir: $!" unless( -d $test_dir);
    my $xml_file_base = "test.xml"; 
    my $xml_file= File::Spec->catfile( $test_dir => $xml_file_base);
    my $ent_file_base  = "ent.xml"; 
    my $ent_file= File::Spec->catfile( $test_dir => $ent_file_base);
    my $doc= qq{<!DOCTYPE x [ <!ENTITY ent SYSTEM "$ent_file_base" > ]><x>&ent;</x>};
    my $ent= qq{<foo/>};
    spit( $xml_file, $doc);
    spit( $ent_file, $ent);

    my $expected= '<x><foo/></x>';
  
    is( XML::Twig->parse( pretty_print => 'none', $xml_file)->root->sprint, $expected, 'entity resolving when file is in a subdir');
    unlink $xml_file or die "cannot remove $xml_file: $!";
    unlink $ent_file or die "cannot remove $ent_file: $!";
    rmdir  $test_dir or die "cannot remove $test_dir: $!";
  }
else
  { skip( 1 => "known bug with old XML::Parser versions: base uri not taken into account,\n"
              . "see RT #25113 at http://rt.cpan.org/Public/Bug/Display.html?id=25113"
         );
  }
{ my $doc= "<d><s><a/><e/><e/></s></d>";
  my $doc_file= "doc.xml";
  spit( $doc_file, $doc);
  my $t= XML::Twig->new;
  foreach (1..3)
    { $t->parse( $doc);
      is( $t->sprint, $doc, "re-using a twig with parse (run $_)");
      $t->parse( $doc);
      is( $t->sprint, $doc, "re-using a twig with parse (run $_)");
      $t->parsefile( $doc_file);
      is( $t->sprint, $doc, "re-using a twig with parsefile (run $_)");
      $t->parsefile( $doc_file);
      is( $t->sprint, $doc, "re-using a twig with parsefile (run $_)");
    }
  unlink $doc_file;
}

 
{ my $invalid_doc= "<d><s><a/><e/><e/><a></d>";
  my $invalid_doc_file= "invalid_doc.xml";
  spit( $invalid_doc_file, $invalid_doc);
  my $expected="e";
  my( $result);
  my $expected_sprint="<d><s><a/><e/></s></d>";
  my $t= XML::Twig->new( twig_handlers => { e => sub { $result.= $_->tag; shift->finish_now } });
  foreach (1..3)
    { $result='';
      $t->parse( $invalid_doc);
      is( $result, $expected, "finish_now with parse (run $_)");
      is( $t->sprint, $expected_sprint, "finish_now with parse (sprint, run $_)");
      $result='';
      $t->parsefile( $invalid_doc_file);
      is( $result, $expected, "finish_now with parsefile (run $_)");
      is( $t->sprint, $expected_sprint, "finish_now with parse (sprint, run $_)");
    }
  unlink $invalid_doc_file;
}
 
{ my $doc1=qq{<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE d1 [\n<!ELEMENT d1 (#PCDATA)><!ENTITY e1 "[e1]"><!ENTITY e2 "[e2]">\n]>\n<d1> t1 &e1; &e2;</d1>};
  my $doc2=qq{<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE d2 [\n<!ELEMENT d2 (#PCDATA)><!ENTITY e1 "[e1]"><!ENTITY e3 "[e3]">\n]>\n<d2> t1 &e1; &e3;</d2>};
  (my $edoc1 = $doc1)=~ s{&e(\d);}{[e$1]}g;
  (my $edoc2 = $doc2)=~ s{&e(\d);}{[e$1]}g;
  my $t= XML::Twig->new( keep_spaces => 1);
  is( $t->parse( $doc1)->sprint, $edoc1, "XML::Twig reuse (run 1: doc1)");
  is( $t->parse( $doc2)->sprint, $edoc2, "XML::Twig reuse (run 2: doc2)");
  is( $t->parse( $doc1)->sprint, $edoc1, "XML::Twig reuse (run 3: doc1)");
  is( $t->parse( $doc1)->sprint, $edoc1, "XML::Twig reuse (run 4: doc1)");
  is( $t->parse( $doc2)->sprint, $edoc2, "XML::Twig reuse (run 5: doc2)");
  is( $t->parse( $doc2)->sprint, $edoc2, "XML::Twig reuse (run 6: doc2)");
}

# some additional coverage
{ # entity sprint
  my $tata= "tata content";
  spit( "tata.txt", $tata);
  my %ent_desc=( foo => q{"toto"},  bar => q{SYSTEM "tata.txt"}, baz => q{SYSTEM "tutu.txt" NDATA gif});
  my %decl= map { $_ => "<!ENTITY $_ $ent_desc{$_}>" } keys %ent_desc;
  my $decl_string= join( '', values %decl);
  my $doc= qq{<!DOCTYPE d [ $decl_string ]><d/>};
  my $t= XML::Twig->parse( $doc);
  foreach my $ent (sort keys %decl)
    { is( $t->entity( $ent)->sprint, $decl{$ent}, "sprint entity $ent ($decl{$ent})"); }
}

{ # purge on an element
  { my $t= XML::Twig->parse( twig_handlers => { e2 => sub { $_->purge } }, q{<d><e1/><e2/><e3/></d>});
    is( $t->root->first_child->tag, 'e3', "purge on the current element");
  }
  { my $t= XML::Twig->parse( twig_handlers => { e2 => sub { $_->prev_sibling->purge } }, q{<d><e1/><e2/><e3/></d>});
    is( $t->root->first_child->tag, 'e2', "purge on an element");
  }
  { my $t= XML::Twig->parse( twig_handlers => { e2 => sub { $_->prev_sibling->purge( $_) } }, q{<d><e1/><e2/><e3/></d>});
    is( $t->root->first_child->tag, 'e3', "purge on an element up to the current element");
  }
  { my $t= XML::Twig->parse( twig_handlers => { e3 => sub { $_->prev_sibling( 'e1')->purge( $_->prev_sibling) } }, q{<d><e1/><e2/><e3/></d>});
    is( $t->root->first_child->tag, 'e3', "purge on an element up to an other element");
  }
  { my $t= XML::Twig->parse( twig_handlers => { e2 => sub { $_[0]->purge_up_to( $_->prev_sibling) } }, q{<d><e1/><e2/><e3/></d>});
    is( $t->root->first_child->tag, 'e2', "purge_up_to");
  }
}

{ my $t= XML::Twig->parse( '<!DOCTYPE foo PUBLIC "-//xmltwig//DTD xmltwig test 1.0//EN" "foo.dtd" [<!ELEMENT d (#PCDATA)>]><d/>');
  is( $t->doctype_name, 'foo', 'doctype_name (with value)');
  is( $t->system_id, 'foo.dtd', 'system_id (with value)');
  is( $t->public_id, '-//xmltwig//DTD xmltwig test 1.0//EN', 'public_id (with value)');
  is( $t->internal_subset, '<!ELEMENT d (#PCDATA)>', 'internal subset (with value)');
}
{ my $t= XML::Twig->parse( '<d/>');
  is( $t->doctype_name, '', 'doctype_name (no value)');
  is( $t->system_id, '', 'system_id (no value)');
  is( $t->public_id, '', 'public_id (no value)');
  is( $t->internal_subset, '', 'internal subset (no value)');
}
{ my $t= XML::Twig->parse( '<!DOCTYPE foo SYSTEM "foo.dtd"><d/>');
  is( $t->doctype_name, 'foo', 'doctype_name (with value)');
  is( $t->system_id, 'foo.dtd', 'system_id (with value)');
  is( $t->public_id, '', 'public_id (no value)');
  is( $t->internal_subset, '', 'internal subset (no value)');
}
{ my $t= XML::Twig->parse( '<!DOCTYPE foo [<!ELEMENT d (#PCDATA)>]><d/>');
  is( $t->doctype_name, 'foo', 'doctype_name (with value)');
  is( $t->system_id, '', 'system_id (no value)');
  is( $t->public_id, '', 'public_id (no value)');
  is( $t->internal_subset, '<!ELEMENT d (#PCDATA)>', 'internal subset (with value)');
}

{ my $prolog= '<!DOCTYPE foo PUBLIC "-//xmltwig//DTD xmltwig test 1.0//EN" "foo.dtd" [<!ELEMENT d (#PCDATA)>]>';
  my $doc= '<d/>';
  my $t= XML::Twig->parse( $prolog . $doc);
  (my $expected_prolog= $prolog)=~ s{foo}{d};
  $t->set_doctype( 'd');
  is_like( $t->doctype, $expected_prolog, 'set_doctype');
  is_like( $t->sprint, $expected_prolog . $doc);
}

{ # test external entity declaration with SYSTEM _and_ PUBLIC

  # create external entities
  my @ext_files= qw( tata1 tata2);
  foreach my $file (@ext_files) { spit( $file => "content of $file"); }

  my $doc= q{<!DOCTYPE foo [<!ENTITY % bar1 PUBLIC "toto1" "tata1">%bar1;<!ENTITY bar2 PUBLIC "toto2" "tata2">%bar2;]><d><elt/></d>};
  is_like( XML::Twig->parse( $doc)->sprint, $doc, 'external entity declaration with SYSTEM _and_ PUBLIC, regular parse/sprint');

  my $out_file= "tmp_test_ext_ent.xml";
  open( OUT, ">$out_file") or die "cannot create temp result file '$out_file': $!";
  XML::Twig->parse( twig_roots => { elt => sub { $_->print( \*OUT) } }, twig_print_outside_roots => \*OUT, $doc);
  close OUT;
  is_like( slurp( $out_file), $doc, 'external entity declaration with SYSTEM _and_ PUBLIC, with twig_roots');
  unlink $out_file;

  open( OUT, ">$out_file") or die "cannot create temp result file '$out_file': $!";
  XML::Twig->parse( twig_roots => { elt => sub { $_->print( \*OUT) } }, twig_print_outside_roots => \*OUT, keep_encoding => 1, $doc);
  close OUT;
  is_like( slurp( $out_file), $doc, 'external entity declaration with SYSTEM _and_ PUBLIC, with twig_roots and keep_encoding');

  unlink @ext_files, $out_file;
}

{ my $doc= q{<doc><elt><selt>selt 1</selt><selt>selt 2</selt></elt></doc>};
  my $t= XML::Twig->parse( pretty_print => 'indented', $doc);
  my $elt_indented     = "\n    <selt>selt 1</selt>\n    <selt>selt 2</selt>";
  my $elt_not_indented = "<selt>selt 1</selt><selt>selt 2</selt>";
  is( $t->first_elt( 'elt')->xml_string, $elt_indented, 'xml_string, indented');
  is( $t->first_elt( 'elt')->xml_string( { pretty_print => 'none'} ), $elt_not_indented, 'xml_string, NOT indented');
  is( $t->first_elt( 'elt')->xml_string, $elt_indented, 'xml_string, indented again');
}

{ my $doc=q{<!DOCTYPE foo [ <!ENTITY zzent SYSTEM "zznot_there"> ]><foo>&zzent;</foo>};
  eval { XML::Twig->new->parse( $doc); };
  matches( $@, qr{zznot_there}, "missing SYSTEM entity: file info in the error message ($@)");
  matches( $@, qr{zzent},       "missing SYSTEM entity: entity info in the error message ($@)");
}

{ if( _use( 'HTML::TreeBuilder', 3.13))
    { XML::Twig->set_pretty_print( 'none');

      my $html=q{<html><body><h1>Title</h1><p>foo<br>bar</p>};
      my $expected= q{<html><head></head><body><h1>Title</h1><p>foo<br />bar</p></body></html>};
 
      is( XML::Twig->new->safe_parse_html( $html)->sprint, $expected, 'safe_parse_html');

      my $html_file= "t/test_3_30.html";
      spit( $html_file, $html);
      is( XML::Twig->new->safe_parsefile_html( $html_file)->sprint, $expected, 'safe_parsefile_html');

      if( _use( 'LWP'))
        { is( XML::Twig->new->safe_parseurl_html( "file:$html_file")->sprint, $expected, 'safe_parseurl_html'); }
      else
        { skip( 1, "LWP not available, cannot test safe_parseurl_html"); }

      unlink $html_file;

    }
  else
    { skip( 3, "HTML::TreeBuilder not available, cannot test safe_parse.*_html methods"); }

}

{ my $dump= XML::Twig->parse( q{<doc id="1"><elt>text</elt></doc>})->_dump;
  my $sp=qr{[\s|-]*};
  matches( $dump, qr{^document $sp doc $sp id="1" $sp elt $sp PCDATA: $sp 'text'\s*}x, "twig _dump");
}

{ my $dump=  XML::Twig->parse( q{<!DOCTYPE d [ <!ENTITY foo "bar">]><d>&foo;</d>})->entity( 'foo')->_dump;
  is( $dump, q{name => 'foo' - val => 'bar'}, "entity dump");
}

{ if( $XML::Parser::VERSION > 2.27)
    { my $t= XML::Twig->parse( q{<!DOCTYPE d [ <!ENTITY afoo "bar"> <!ENTITY % bfoo "baz">]><d>&afoo;</d>});
      my $non_param_ent= $t->entity( 'afoo');
      nok( $non_param_ent->param, 'param on a non-param entity');
      my $param_ent= $t->entity( 'bfoo');
      ok( $param_ent->param, 'param on a parameter entity');
    }
  else
    { skip( 2, "cannot use the param method with XML::Parser 2.27"); }
}

{ my $entity_file  = "test_3_30.t.ent";
  my $missing_file = "not_there";
  spit( $entity_file => "entity text");
  my $doc= qq{<!DOCTYPE d [<!ENTITY foo SYSTEM "$entity_file"><!ENTITY bar SYSTEM "$missing_file">]><d>&foo;</d>};
  ok( eval { XML::Twig->parse( $doc)}, 'doc with missing external SYSTEM ents');

  eval { XML::Twig->parse( expand_external_ents => 1, $doc)};
  matches( $@, qr{cannot load SYSTEM entity 'bar' from 'not_there': }, 'missing SYSTEM entity');
  ok( eval { XML::Twig->parse( $doc)}, 'doc with missing external SYSTEM ents');

  my $t= XML::Twig->parse( expand_external_ents => -1, $doc);
  my $missing_entities= $t->{twig_missing_system_entities};
  is( scalar( values %$missing_entities), 1, 'number of missing system entities');
  is( (values %$missing_entities)[0]->{name}, 'bar', 'name of missing system entity');
  is( (values %$missing_entities)[0]->{sysid}, $missing_file, 'sysid of missing system entity');

  eval { XML::Twig->parse( $doc)};
  ok( eval { XML::Twig->parse( $doc)}, 'doc with missing external SYSTEM NDATA ents');
  unlink( $entity_file);
}

{ my $entity_file  = "test_3_30.t.gif";
  my $missing_file = "not_there.gif";
  spit( $entity_file => "entity text");

  my $doc= qq{<!DOCTYPE d [ <!ENTITY foon SYSTEM "$entity_file" NDATA gif> <!ENTITY barn SYSTEM "$missing_file" NDATA gif>]>
              <d><elt ent1="foon" ent2="barn" /></d>};
  my $t= XML::Twig->parse( $doc);
  my $missing_entities= $t->{twig_missing_system_entities};
  is( scalar( values %$missing_entities), 1, 'number of missing system entities');
  is( $missing_entities->{barn}->name, 'barn', 'name of missing system entity');
  is( $missing_entities->{barn}->sysid, $missing_file, 'sysid of missing system entity');

  unlink( $entity_file);
}

{ my $doc= q{<d><elt>foo <b>bar</b> baz <b>foobar</b><c>xyz</c><b>toto</b>tata<b>tutu</b></elt></d>};
  my $t= XML::Twig->parse( twig_handlers => { b => sub { $_->erase } }, $doc);
  is( scalar( $t->descendants( '#TEXT')), 3, 'text descendants, no melding');
  $t->normalize;  
  is( scalar( $t->descendants( '#TEXT')), 3, 'text descendants, normalized');
}

{ my $doc=q{<d><e>e</e><e1>e1</e1><e1>e1-2</e1></d>};
  XML::Twig::Elt->init_global_state(); # depending on which modules are available, the state could have been modified
  my $tmp= "tmp";
  open( TMP, ">$tmp") or die "cannot create temp file";
  XML::Twig->parse( twig_roots => { e1 => sub { $_->flush( \*TMP) } }, twig_print_outside_roots => \*TMP, $doc);
  close TMP;
  my $res= slurp( $tmp);
  is( $res, $doc, "bug in flush with twig_print_outside_roots");
  unlink $tmp;
}

{ # test bug where #default appeared in attributes (RT #27617)
  my $doc= '<ns1:doc xmlns:ns1="foo" xmlns="bar"><ns1:elt att="bar"/></ns1:doc>';
  my $t= XML::Twig->new( map_xmlns => { 'foo' => 'ns2' },)->parse( $doc);
  ok( grep { $_ eq 'att' } keys %{$t->root->first_child->atts}, 'no #default in attribute names');
}

exit;
1;
