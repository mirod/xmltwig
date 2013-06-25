#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

$t->set_var('foo_att', literal => 'bar');

my @b_foo = $t->findnodes( '//b[@foo=$foo_att]');
ok(@b_foo, 1);

$t->set_var('b_foo', selector => '/a/b');
my @c = $t->findnodes('//*[$b_foo]/c');
ok(@c, 4);

## TODO: would be nice if this were possible:
# my $thing = $t->findnodes(//@foo);
# # set variable to be arbitrary XPath node in parameter
# $t->set_var('foo', nodes => $thing);
# my @b_foo = $t->findnodes('//b[@foo=$foo]');
# ok(@b_foo, 1);
#
# TODO: this too
# my $var = $t->get_var('foo');
# ok($var, ?);


exit 0;

__DATA__
<a>
    <b foo="bar">
        <c>some 1</c>
        <c>value 1</c>
    </b>
    <b>
        <c>some 2</c>
        <c>value 2</c>
    </b>
</a>
