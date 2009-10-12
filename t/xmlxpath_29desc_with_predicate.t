#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @bbb = $t->findnodes( '/descendant::BBB[1]');
ok(@bbb, 1);
ok($bbb[0]->string_value, "OK");

exit 0;

__DATA__
<AAA>
<BBB>OK</BBB>
<CCC/>
<BBB/>
<DDD><BBB/></DDD>
<CCC><DDD><BBB/><BBB>NOT OK</BBB></DDD></CCC>
</AAA>
