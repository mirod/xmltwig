#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new( keep_spaces => 1)->parse( \*DATA);
ok( $t);

my @en = $t->findnodes( '//*[lang("en")]');
ok(@en, 2);

my @de = $t->findnodes( '//content[lang("de")]');
ok(@de, 1);

exit 0;

__DATA__
<page xml:lang="en">
  <content>Here we go...</content>
  <content xml:lang="de">und hier deutschsprachiger Text :-)</content>
</page>
