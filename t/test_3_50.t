#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 18;

use utf8;

{
use XML::Twig::XPath;
ok( XML::Twig::XPath->new()->
    parse('<xml xmlns:foo="www.bar.com"/>')->findnodes('//namespace::*'));
}

{
my $doc=q{<d><title>title</title><para>p 1</para><para>p 2</para></d>};
my $out;
open( my $out_fh, '>', \$out);
my $t= XML::Twig->new ( twig_handlers => { _default_ => sub { $_->flush( $out_fh); } });
$t->parse( $doc);
is( $out, $doc, 'flush with _default_ handler');
}

{
my $doc=q{<d><title>title</title><para>p 1</para><para>p 2</para></d>};
my $out;
open( my $out_fh, '>', \$out);
my $t= XML::Twig->new ( twig_handlers => { 'd' => sub { $_->flush( $out_fh); } });
$t->parse( $doc);
#is( $out, $doc, 'flush with handler on the root');
}


{ # test notations
  my $doc=q{<?xml version="1.0"?>
              <!DOCTYPE d [
                <!ELEMENT d (code+)>
                <!ELEMENT code (#PCDATA)>
                <!NOTATION vrml PUBLIC "VRML 1.0">
                <!NOTATION perl PUBLIC "Perl 22.4" "/usr/bin/perl">
                <!ATTLIST code lang NOTATION (vrml|perl) #REQUIRED>
              ]>
              <d>
                <code lang="vrml">DirectionalLight { direction 0 -1 0 }</code>
                <code lang="perl">XML::Twig->parse( 'file.xml');</code>
              </d>
           };
  my $t= XML::Twig->parse( $doc);
  my $n= $t->notation_list;
  is( join( ':', sort $t->notation_names), 'perl:vrml', 'notation_names');
  is( join( ':', sort map { $_->name } $n->list), 'perl:vrml', 'notation_list (names)');
  is( join( ':', sort map { $_->pubid } $n->list), 'Perl 22.4:VRML 1.0', 'notation_list (pubid)');
  is( join( ':', sort map { $_->sysid || '' } $n->list), ':/usr/bin/perl', 'notation_list (pubid)');
  is( $n->notation( 'perl')->pubid, 'Perl 22.4', 'individual notation pubid');
  is( $n->notation( 'vrml')->base, undef, 'individual notation base');
  is( $n->text, qq{<!NOTATION perl PUBLIC "Perl 22.4" "/usr/bin/perl">\n<!NOTATION vrml PUBLIC "VRML 1.0">}, 'all notations');
  my $notations= () = ( $t->sprint() =~ m{<!NOTATION}g);
  is( $notations, 2, 'count notations (unchanged)');
  $notations= () = ( $t->sprint( update_DTD => 1) =~ m{<!NOTATION}g);
  is( $notations, 2, 'count notations (unchanged, with update_DTD)'); 
  $n->delete( 'perl');
  $notations= () = ( $t->sprint( update_DTD => 1) =~ m{<!NOTATION}g);
  is( $notations, 1, 'count notations (updated)'); 
  is( $t->notation( 'vrml')->pubid(), 'VRML 1.0', 'notation method');
  $n->add_new_notation( 'svg', '', 'image/svg', 'SVG');
  is( $n->notation( 'svg')->text, qq{<!NOTATION svg PUBLIC "SVG" "image/svg">}, 'new notation');

}

{ # somehow these were never tested (they are inlined within the module)
  my $t= XML::Twig->parse( '<d><e2/></d>');
  my $d= $t->root;

  my $e2= $t->first_elt( 'e2');
  my $e1= XML::Twig::Elt->new( 'e1');
  $d->set_first_child( $e1);
  $e2->set_prev_sibling( $e1);
  $e1->set_next_sibling( $e2);
  is( $t->sprint, '<d><e1/><e2/></d>', 'set_first_child');

  my $e3= XML::Twig::Elt->new( 'e3');
  $d->set_last_child( $e3);
  $e2->set_next_sibling( $e3);
  $e3->set_prev_sibling( $e2);
  is( $t->sprint, '<d><e1/><e2/><e3/></d>', 'set_last_child');

  $e2->insert_new_elt( first_child => '#PCDATA')->_set_pcdata( 'foo');
  is( $t->sprint, '<d><e1/><e2>foo</e2><e3/></d>', '_set_pcdata');

  $e1->insert_new_elt( first_child => '#CDATA')->_set_cdata( 'bar');
  is( $t->sprint, '<d><e1><![CDATA[bar]]></e1><e2>foo</e2><e3/></d>', '_set_cdata');
}

exit;



