#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 13);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @nodes;
@nodes = $t->findnodes( '//GGG/ancestor::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '//GGG/descendant::*');
ok(@nodes, 3);

@nodes = $t->findnodes( '//GGG/following::*');
ok(@nodes, 3);
ok($nodes[0]->getName, "VVV");
ok($nodes[1]->getName, "CCC");
ok($nodes[2]->getName, "DDD");

@nodes = $t->findnodes( '//GGG/preceding::*');
ok(@nodes, 5);
ok($nodes[0]->getName, "BBB"); # document order, not HHH

@nodes = $t->findnodes( '//GGG/self::*');
ok(@nodes, 1);
ok($nodes[0]->getName, "GGG");

@nodes = $t->findnodes( '//GGG/ancestor::* | //GGG/descendant::* | //GGG/following::* | //GGG/preceding::* | //GGG/self::*');
ok(@nodes, 16);

exit 0;

__DATA__
<AAA>
    <BBB>
        <CCC/>
        <ZZZ/>
    </BBB>
    <XXX>
        <DDD>
            <EEE/>
            <FFF>
                <HHH/>
                <GGG> <!-- Watch this node -->
                    <JJJ>
                        <QQQ/>
                    </JJJ>
                    <JJJ/>
                </GGG>
                <VVV/>
            </FFF>
        </DDD>
    </XXX>
    <CCC>
        <DDD/>
    </CCC>
</AAA>
