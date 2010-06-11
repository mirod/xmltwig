#!/usr/bin/perl -w
use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

use XML::Twig;

my $TMAX=85; 

my $DEBUG=0;

print "1..$TMAX\n";

# state information are now attached to each twig

# default/fixed attribute values are now filled when the "load_DTD" option is used 

my $dtd_file= 'test_default_att.dtd';
my $dtd=<<'DTD'; 
<!ELEMENT doc (elt+)> 
<!ATTLIST doc att1 (toto|tata) "tata"
              att2 CDATA #FIXED "0"
              att3 CDATA #IMPLIED
              att4 CDATA "tutu"
>
<!ELEMENT elt (#PCDATA)>
<!ATTLIST elt att1 (foo|bar) "foo"
              att2 CDATA #FIXED "baz"
              att3 CDATA #IMPLIED
              att5 CDATA "0"
>
DTD

my $doc        =  q{<doc><elt/><elt att1="bar" /><elt att5="titi"/><elt att3="foobar"/></doc>};
my $filled_doc =  q{<doc att1="tata" att2="0" att4="tutu">}
                 .q{<elt att1="foo" att2="baz" att5="0"/>}
                 .q{<elt att1="bar" att2="baz" att5="0"/>}
                 .q{<elt att1="foo" att2="baz" att5="titi"/>}
                 .q{<elt att1="foo" att2="baz" att3="foobar" att5="0"/>}
                 .q{</doc>};

{
open( FHDTD, ">$dtd_file") or die "cannot open dtd file '$dtd': $!";
print FHDTD $dtd;
close FHDTD;
my $doc_with_external_dtd= qq{<!DOCTYPE doc SYSTEM "$dtd_file">$doc};
my $result= XML::Twig->new( error_context => 1, load_DTD => 1)
                     ->parse( $doc_with_external_dtd)
                     ->root->sprint;
is( $result => $filled_doc, 'filling attribute default values with EXTERNAL DTD');
unlink $dtd_file;
}

{
my $doc_with_internal_dtd= qq{<!DOCTYPE doc [$dtd]>$doc};
my $result= XML::Twig->new( error_context => 1, load_DTD => 1)
                     ->parse( $doc_with_internal_dtd)
                     ->root->sprint;
is( $result => $filled_doc, 'filling attribute default values with INTERNAL DTD');
}

# test the first_descendant method
{
my $t= XML::Twig->new->parse( '<doc><elt><a/></elt><b/></doc>');
is( $t->root->first_child->first_descendant( 'a')->tag, 'a', 'first_descendant succeeds');
nok( $t->root->first_child->first_descendant( 'b'), 'first_descendant fails (match outside of the subtree)');
}

# test the index option and method
{ my $doc=q{<doc><elt><t>t1</t></elt><t>t2</t></doc>};
  my $t= XML::Twig->new( index => [ 't', 'none' ])->parse( $doc);
  is( $t->index( 't', 0)->text, 't1', 'index');
  is( $t->index( 't', 1)->text, 't2', 'index');
  is_undef( $t->index( 't', 2), 'index');
  is( $t->index( 't', -1)->text, 't2', 'index');
 
  my $index= $t->index( 't');
  is( $index->[0]->text, 't1', 'index');
  is( $index->[ 1]->text, 't2', 'index');
  is_undef( $index->[ 2], 'index');
  is( $index->[-1]->text, 't2', 'index');
}

{ my $doc=q{<doc><elt><t>t1</t></elt><t>t2</t></doc>};
  my $t= XML::Twig->new( index => { target => 't' })->parse( $doc);
  is( $t->index( 'target', 0)->text, 't1', 'index');
  is( $t->index( 'target', 1)->text, 't2', 'index');
  is_undef( $t->index( 'target', 2), 'index');
  is( $t->index( 'target', -1)->text, 't2', 'index');
 
  my $index= $t->index( 'target');
  is( $index->[0]->text, 't1', 'index');
  is( $index->[ 1]->text, 't2', 'index');
  is_undef( $index->[ 2], 'index');
  is( $index->[-1]->text, 't2', 'index');
}


# test the remove_cdata option
{ my $doc        = q{<doc><![CDATA[<tag&>]]></doc>};
  my $escaped_doc= q{<doc>&lt;tag&amp;></doc>};
  my $t= XML::Twig->new( remove_cdata => 1)->parse( $doc);
  is( $t->sprint, $escaped_doc, 'remove_cdata on');
  $t= XML::Twig->new( remove_cdata => 0)->parse( $doc);
  is( $t->sprint, $doc, 'remove_cdata off');
}

# test the create_accessors method
if( $] < 5.006)
  { skip( 11 => "create_accessors not tested with perl < 5.006"); }
else
{ my $doc= '<doc att1="1" att3="foo"/>';
  my $t= XML::Twig->new->parse( $doc);
  $t->create_accessors( qw(att1 att2));
  my $root= $t->root;
  is( $root->att1, 1, 'attribute getter');
  $root->att1( 2);
  is( $root->att1, 2, 'attribute setter');
  eval '$root->att1=3'; # eval'ed to keep 5.005 from barfing
  is( $root->att1, 3, 'attribute as lvalue');
  eval '$root->att1++'; # eval'ed to keep 5.005 from barfing
  is( $root->att1, 4, 'attribute as lvalue (++)');
  is( $root->att1, $root->att( 'att1'), 'check with regular att method');
  eval { $^W=0;  $root->att3; $^W=1;  };
  matches( $@, q{^Can't locate object method "att3" via package "XML::Twig::Elt" }, 'unknow accessor');
  is( $root->att2, undef, 'get non-existent att');
  $root->att2( 'bar');
  is( $root->att2, "bar", 'get non-existent att');
  is( $t->sprint, '<doc att1="4" att2="bar" att3="foo"/>', 'final output');
  eval { $t->create_accessors( 'tag'); };
  matches( $@, q{^attempt to redefine existing method tag using att_accessors }, 'duplicate accessor');
  $@='';
  eval { XML::Twig->create_accessors( 'att2'); };
  is( $@, '', 'redefining existing accessor');
}
  
{ # test embedded comments/pis
  foreach my $doc ( 
                    q{<doc>text <!--cdata coming--><![CDATA[here]]></doc>},
                    q{<doc>text<!--comment-->more</doc>},
                    q{<doc>text<!--comment-->more<!--comment2--></doc>},
                    q{<doc>text<!--comment-->more<!--comment2-->more2</doc>},
                    q{<doc><!--comment-->more<!--comment2-->more2</doc>},
                    q{<doc><!--comment--></doc>},
                    q{<doc>tata<!--comment & all-->toto</doc>},
                    q{<doc>tata &lt;<!--comment &amp; tu &lt; all-->toto &lt;</doc>},
                    q{<doc>text<!--comment-->more &amp; even more<!--comment2-->more2</doc>},
                    q{<doc>text <!--cdata coming--> <![CDATA[here]]></doc>},
                    q{<doc> <!--comment--> more <!--comment2--> more2 </doc>},
                    q{<doc><!--comment--> more <!--comment2--> more2</doc>},
                  )
    { my $t= XML::Twig->new->parse( $doc);
      is( $t->sprint, $doc, "comment within pcdata ($doc)");
      my $t2= XML::Twig->new( keep_encoding => 1)->parse( $doc);
      is( $t2->sprint, $doc, "comment within pcdata in keep encoding mode($doc)");
      my $doc_pi= $doc;
      $doc_pi=~ s{<!--}{<?pi}g; $doc_pi=~ s{-->}{?>}g;
      my $t3= XML::Twig->new->parse( $doc_pi);
      is( $t3->sprint, $doc_pi, "pi within pcdata ($doc_pi)");
      my $t4= XML::Twig->new( keep_encoding => 1)->parse( $doc_pi);
      is( $t4->sprint, $doc_pi, "pi within pcdata in keep encoding mode($doc_pi)");
    }
}

{ # test processing of embedded comments/pis 
  my $doc= q{<doc><elt>foo<!--comment-->bar</elt><elt>foobar</elt></doc>};
  my $t=  XML::Twig->new->parse( $doc);
  my @elt= $t->findnodes( '//elt[string()="foobar"]');
  is( scalar( @elt), 2, 'searching on text with embedded comments');
  foreach my $elt (@elt) { $elt->set_text( 'toto'); }
  is( $t->sprint, q{<doc><elt>toto</elt><elt>toto</elt></doc>}, "set_text");
  my $t2=  XML::Twig->new( keep_encoding => 1)->parse( $doc);
  @elt= $t2->findnodes( '//elt[string()="foobar"]');
  is( scalar( @elt), 2, 'searching on text with embedded comments');
  foreach my $elt (@elt) { $elt->set_text( 'toto'); }
  is( $t2->sprint, q{<doc><elt>toto</elt><elt>toto</elt></doc>}, "set_text");
}
