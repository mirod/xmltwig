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
@nodes = $t->findnodes( '/AAA/XXX/preceding-sibling::*');
ok(@nodes, 1);
ok($nodes[0]->getName, "BBB");

@nodes = $t->findnodes( '//CCC/preceding-sibling::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '/AAA/CCC/preceding-sibling::*[1]');
ok($nodes[0]->getName, "XXX");

@nodes = $t->findnodes( '/AAA/CCC/preceding-sibling::*[2]');
ok($nodes[0]->getName, "BBB");

exit 0;

__DATA__
<AAA>
    <BBB>
        <CCC/>
        <DDD/>
    </BBB>
    <XXX>
        <DDD>
            <EEE/>
            <DDD/>
            <CCC/>
            <FFF/>
            <FFF>
                <GGG/>
            </FFF>
        </DDD>
    </XXX>
    <CCC>
        <DDD/>
    </CCC>
</AAA>
