#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 7);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[count(BBB) = 2]');
ok($nodes[0]->getName, "DDD");

@nodes = $t->findnodes( '//*[count(*) = 2]');
ok(@nodes, 2);

@nodes = $t->findnodes( '//*[count(*) = 3]');
ok(@nodes, 2);
ok($nodes[0]->getName, "AAA");
ok($nodes[1]->getName, "CCC");

exit 0;

__DATA__
<AAA>
<CCC><BBB/><BBB/><BBB/></CCC>
<DDD><BBB/><BBB/></DDD>
<EEE><CCC/><DDD/></EEE>
</AAA>
