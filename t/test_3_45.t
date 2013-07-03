#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 3;

{
my $d='<d><e>e1</e><e>e2</e><f>f1</f></d>';
is( XML::Twig->parse( twig_handlers => { f => sub { $_->cut} }, $d)->sprint,
    '<d><e>e1</e><e>e2</e></d>',
    'cut element during parse'
  );
is( XML::Twig->parse( twig_handlers => { '#TEXT' => sub { $_->cut} }, $d)->sprint,
    '<d><e></e><e></e><f></f></d>',
    'cut text during parse'
  );
}
is( XML::Twig->new( keep_encoding => 1)->parse( q{<d a='"foo'/>})->sprint, q{<d a="&quot;foo"/>}, "quote in att with keep_encoding");
