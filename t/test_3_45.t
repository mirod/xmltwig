#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 1;

{
my $d='<d><e>e1</e><e>e2</e><f>f1</f></d>';
is( XML::Twig->parse( twig_handlers => sub { f => sub { $_->cut} }, $doc,
                      '<d><e>e1</e><e>e2</e></d>'
                      'cut element during parse'
                    );
}
