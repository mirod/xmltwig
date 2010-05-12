#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=1;
print "1..$TMAX\n";

# escape_gt option
{
is( XML::Twig->parse( '<d/>')->root->insert_new_elt( '#COMMENT' => '- -- -')->twig->sprint,
    '<d><!-- - - - - --></d>', 'comment escaping');
}

1;
