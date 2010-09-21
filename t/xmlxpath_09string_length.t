#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 5);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[string-length(name()) = 3]');
ok(@nodes, 2);

@nodes = $t->findnodes( '//*[string-length(name()) < 3]');
ok(@nodes, 2);

@nodes = $t->findnodes( '//*[string-length(name()) > 3]');
ok(@nodes, 3);

exit 0;

__DATA__
<AAA>
<Q/>
<SSSS/>
<BB/>
<CCC/>
<DDDDDDDD/>
<EEEE/>
</AAA>
