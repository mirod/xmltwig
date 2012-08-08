#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=12;
print "1..$TMAX\n";

{ 
my $doc='<d>foo bar fooo baz</d>';

my $t= XML::Twig->parse( $doc);
$t->root->split( '(fo+)', e => { att => '$1' } );
is( $t->sprint, '<d><e att="foo">foo</e> bar <e att="fooo">fooo</e> baz</d>', 'split, with $1 on attribute value');

$t= XML::Twig->parse( $doc);
$t->root->split( '(fo+)', e => { '$1' => 'v$1' } );
is( $t->sprint, '<d><e foo="vfoo">foo</e> bar <e fooo="vfooo">fooo</e> baz</d>', 'split, with $1 on attribute name and value');

$t= XML::Twig->parse( $doc);
$t->root->split( '(fo+)', '$1' );
is( $t->sprint, '<d><foo>foo</foo> bar <fooo>fooo</fooo> baz</d>', 'split, with $1 on tag name');


$t= XML::Twig->parse( $doc);
$t->root->split( '(foo+)', '$1', '' );
is( $t->sprint, '<d><foo>foo</foo> bar <fooo>fooo</fooo> baz</d>', 'split, with $1 on tag name');

$t= XML::Twig->parse( $doc);
$t->root->split( '(fo+)(.*?)(a[rz])', x => { class => 'f' }, '',  a => { class => 'x' });
is( $t->sprint, '<d><x class="f">foo</x> b<a class="x">ar</a> <x class="f">fooo</x> b<a class="x">az</a></d>', 'split, checking that it works with non capturing grouping');

$t= XML::Twig->parse( $doc);
$t->root->split( '(fo+)(.*?)(a[rz])', x => { class => '$1' }, '', a => { class => '$3' });
is( $t->sprint, '<d><x class="foo">foo</x> b<a class="ar">ar</a> <x class="fooo">fooo</x> b<a class="az">az</a></d>', 'split, with $1 and $3 on att value');

}

{ my $t= XML::Twig->parse( '<d><e>e1</e><s><e>e2</e></s></d>');
  is( join( '-', $t->findvalues( '//e')), 'e1-e2', 'findvalues');
}

{ my $html='<html xmlns="http://www.w3.org/1999/xhtml"><head><meta content="text/html; charset=utf-8" http-equiv="Content-Type"/></head><body><p>boo</p></body></html>';

  my $well_formed   = qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">$html};
  my $short_doctype = qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">$html};

  my $t= XML::Twig->new->parse( $well_formed);
  is_like( $t->sprint, $well_formed, 'valid xhtml');
  if( _use( 'HTML::TreeBuilder'))
    { my $th= XML::Twig->new->parse_html( $well_formed);
      is_like( $t->sprint, $well_formed, 'valid xhtml (parsed as html)');

      my $t3= XML::Twig->new->parse_html( $short_doctype);
      is_like( $t3->sprint, $html, 'xhtml without SYSTEM in DOCTYPE (parsed as html, no DOCTYPE output)');

      my $t4= XML::Twig->new( output_html_doctype => 1)->parse_html( $short_doctype);
      is_like( $t4->sprint, $well_formed, 'xhtml without SYSTEM in DOCTYPE (parsed as html, with proper DOCTYPE output)');
    }
  else
    { skip( 3); }

  my $t2= XML::Twig->new->safe_parse( $short_doctype);
  nok( $t2, 'xhtml without SYSTEM in DOCTYPE');


}


