#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 6);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @nodes;
@nodes = $t->findnodes( '/AAA/BBB/following-sibling::*');
ok(@nodes, 2);
ok($nodes[1]->getName, "CCC"); # test document order

@nodes = $t->findnodes( '//CCC/following-sibling::*');
ok(@nodes, 3);
ok($nodes[1]->getName, "FFF");

exit 0;

__DATA__
<AAA>
<BBB><CCC/><DDD/></BBB>
<XXX><DDD><EEE/><DDD/><CCC/><FFF/><FFF><GGG/></FFF></DDD></XXX>
<CCC><DDD/></CCC>
</AAA>
