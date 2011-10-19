#!/usr/bin/perl -w
use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 5);

ok(1);
my $t= XML::Twig::XPath->new->parse( \*DATA);
ok($t);

my @root = $t->findnodes('/AAA');
ok(@root, 1);

my @ccc = $t->findnodes('/AAA/CCC');
ok(@ccc, 3);

my @bbb = $t->findnodes('/AAA/DDD/BBB');
ok(@bbb, 2);

exit 0;

__DATA__
<AAA>
    <BBB/>
    <CCC/>
    <BBB/>
    <CCC/>
    <BBB/>
    <!-- comment -->
    <DDD>
        <BBB/>
        Text
        <BBB/>
    </DDD>
    <CCC/>
</AAA>
