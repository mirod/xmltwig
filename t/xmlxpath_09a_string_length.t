#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 5);
 

use XML::Twig::XPath;

my $doc_one = qq|<doc><para>para one</para></doc>|;

my $t= XML::Twig::XPath->new( keep_spaces => 1);
$t->parse( $doc_one);
ok( $t);

my $doc_one_chars = $t->find( 'string-length(/doc/text())');
ok($doc_one_chars == 0, 1);

my $doc_two = qq|
<doc>
  <para>para one has <b>bold</b> text</para>
</doc>
|;

$t->parse( $doc_two);
ok( $t);

my $doc_two_chars = $t->find( 'string-length(/doc/text())');
ok($doc_two_chars == 3, 1);

my $doc_two_para_chars = $t->find( 'string-length(/doc/para/text())');
ok($doc_two_para_chars == 13, 1);

exit 0;

