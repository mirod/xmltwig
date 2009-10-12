#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//*[name() = /AAA/SELECT]');
ok(@nodes, 2);
ok($nodes[0]->getName, "BBB");

exit 0;

__DATA__
<AAA>
<SELECT>BBB</SELECT>
<BBB/>
<CCC/>
<DDD>
<BBB/>
</DDD>
</AAA>
