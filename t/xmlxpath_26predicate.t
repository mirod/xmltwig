#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my @bbb = $t->findnodes( '//a/b[2]');
ok(@bbb, 2);

@bbb = $t->findnodes( '(//a/b)[2]');
ok(@bbb, 1);

exit 0;

__DATA__
<xml>
    <a>
        <b>some 1</b>
        <b>value 1</b>
    </a>
    <a>
        <b>some 2</b>
        <b>value 2</b>
    </a>
</xml>
