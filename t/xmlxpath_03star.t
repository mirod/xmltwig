#!/usr/bin/perl -w

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 5);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @nodes;

@nodes = $t->findnodes( '/AAA/CCC/DDD/*');
ok(@nodes, 4);

@nodes = $t->findnodes( '/*/*/*/BBB');
ok(@nodes, 5);

@nodes = $t->findnodes( '//*');
ok(@nodes, 17);

exit 0;

__DATA__
<AAA>
<XXX><DDD><BBB/><BBB/><EEE/><FFF/></DDD></XXX>
<CCC><DDD><BBB/><BBB/><EEE/><FFF/></DDD></CCC>
<CCC><BBB><BBB><BBB/></BBB></BBB></CCC>
</AAA>
