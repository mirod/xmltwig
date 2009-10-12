#!/usr/bin/perl -w
# $Id: /xmltwig/trunk/t/xmlxpath_05attrib.t 4 2007-03-16T12:16:25.259192Z mrodrigu  $

use Test;
plan( tests => 6);
 
use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @ids = $t->findnodes( '//BBB[@id]');
ok(@ids, 2);

my @names = $t->findnodes( '//BBB[@name]');
ok(@names, 1);

my @attribs = $t->findnodes( '//BBB[@*]');
ok(@attribs, 3);

my @noattribs = $t->findnodes( '//BBB[not(@*)]');
ok(@noattribs, 1);

exit 0;

__DATA__
<AAA>
<BBB id='b1'/>
<BBB id='b2'/>
<BBB name='bbb'/>
<BBB/>
</AAA>
