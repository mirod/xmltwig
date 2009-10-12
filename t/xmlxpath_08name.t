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
@nodes = $t->findnodes( '//*[name() = "BBB"]');
ok(@nodes, 5);

@nodes = $t->findnodes( '//*[starts-with(name(), "B")]');
ok(@nodes, 7);

@nodes = $t->findnodes( '//*[contains(name(), "C")]');
ok(@nodes, 3);

exit 0;

__DATA__
<AAA>
<BCC><BBB/><BBB/><BBB/></BCC>
<DDB><BBB/><BBB/></DDB>
<BEC><CCC/><DBD/></BEC>
</AAA>
