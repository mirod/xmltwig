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
@nodes = $t->findnodes( '/descendant::*');
ok(@nodes, 11);

@nodes = $t->findnodes( '/AAA/BBB/descendant::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '//CCC/descendant::*');
ok(@nodes, 6);

@nodes = $t->findnodes( '//CCC/descendant::DDD');
ok(@nodes, 3);

exit 0;

__DATA__
<AAA>
<BBB><DDD><CCC><DDD/><EEE/></CCC></DDD></BBB>
<CCC><DDD><EEE><DDD><FFF/></DDD></EEE></DDD></CCC>
</AAA>
