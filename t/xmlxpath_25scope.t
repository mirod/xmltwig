#!/usr/bin/perl -w

use strict;


use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;
plan( tests => 4);
 

use XML::Twig::XPath;
ok(1);

eval
{
  # Removing the 'my' makes this work?!?
  my $t= XML::Twig::XPath->new->parse( '<test/>');
  ok( $t);

  $t->findnodes( '/test');

  ok(1);

  die "This should be caught\n";

};

if ($@)
{
  ok(1);
}
else {
    ok(0);
}

exit 0;
