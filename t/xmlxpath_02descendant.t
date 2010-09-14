#!/usr/bin/perl -w
use strict; 

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);

ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);
ok($t);

my @bbb = $t->findnodes('//BBB');
ok(@bbb, 5);

my @subbbb = $t->findnodes('//DDD/BBB');
ok(@subbbb, 3);

exit 0;

__DATA__
<AAA>
<BBB/>
<CCC/>
<BBB/>
<DDD><BBB/></DDD>
<CCC><DDD><BBB/><BBB/></DDD></CCC>
</AAA>
