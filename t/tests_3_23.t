#!/usr/bin/perl -w
use strict;

use Carp;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

my $DEBUG=0;
print "1..6\n";

if( _use( 'XML::XPathEngine') || _use( 'XML::XPath') )
  { _use( 'XML::Twig::XPath');
    my $t= XML::Twig::XPath->nparse( q{<d>
    <s a="sa1"><e a="ea1">foo</e><e a="ea2">bar</e></s>
    <s a="sa2"><e a="ea3">baz</e><e a="ea4">foobar</e></s>
</d>});
    is( $t->findvalue( '//e[.="foo"]/@a'), "ea1", 'xpath on attributes');
    is( $t->findvalue( '//s[./e="foo"]/@a'), "sa1", 'xpath with elt content test');
    is( $t->findvalue( '/d/s[e="foo"]/@a'), "sa1", 'xpath with elt content test (short form)');
  }
else
  { skip( 3); }

{ my $t= XML::Twig->nparse( '<doc/>');
  my @xpath_result= $t->get_xpath( '/');
  is( ref( $xpath_result[0]), 'XML::Twig', "get_xpath( '/')");
  @xpath_result= $t->get_xpath( '/doc[1]');
  is( $xpath_result[0]->tag, 'doc', "get_xpath( '/doc[1]')");
  @xpath_result= $t->get_xpath( '/notdoc[1]');
  is( scalar( @xpath_result), 0, "get_xpath( '/notdoc[1]')");
}


