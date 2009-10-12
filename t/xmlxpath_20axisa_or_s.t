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
@nodes = $t->findnodes( '/AAA/XXX/DDD/EEE/ancestor-or-self::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '//GGG/ancestor-or-self::*');
ok(@nodes, 5);

exit 0;

__DATA__
<AAA>
<BBB><CCC/><ZZZ><DDD/></ZZZ></BBB>
<XXX><DDD><EEE/><DDD/><CCC/><FFF/><FFF><GGG/></FFF></DDD></XXX>
<CCC><DDD/></CCC>
</AAA>
