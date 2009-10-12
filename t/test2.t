#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

# This tests the doctype and DTD access functions

$|=1;

use XML::Twig;
use Cwd;

$0 =~ s!\\!/!g;
my ($DIR,$PROG) = $0 =~ m=^(.*/)?([^/]+)$=;
$DIR =~ s=/$== || chop($DIR = cwd());

chdir $DIR;

my $i=0;
my $failed=0;

my $TMAX=15; # don't forget to update!

print "1..$TMAX\n";

# test twig creation
my $t= new XML::Twig();
ok( $t, 'twig creation');

# first test an internal DTD

my $in_file=  "test2_1.xml";

my $res_file= "test2_1.res";
my $exp_file= "test2_1.exp";

# test parse no dtd info required
$t->parsefile( $in_file, ErrorContext=>2);
ok( $t, 'parse');

open( RES, ">$res_file") or die "cannot open $res_file:$!";
$t->print( \*RES);
close RES;
ok( $res_file, $exp_file, "flush");

$res_file= 'test2_2.res';
$exp_file= 'test2_2.exp';
open( RES, ">$res_file") or die "cannot open $res_file:$!";
$t->print( \*RES, Update_DTD => 1);
close RES;
ok( $res_file, $exp_file, "flush");

$t= new XML::Twig();
ok( $t, 'twig creation');

$in_file=  "test2_2.xml";
$res_file= "test2_3.res";
$exp_file= "test2_3.exp";

$t->parsefile( $in_file, ErrorContext=>2);
ok( $t, 'parse');
open( RES, ">$res_file") or die "cannot open $res_file:$!";

my $e2=new XML::Twig::Entity( 'e2', 'entity2');
my $entity_list= $t->entity_list;
$entity_list->add( $e2);

my $e3=new XML::Twig::Entity( 'e3', undef, 'pic.jpeg', 'JPEG');
$entity_list= $t->entity_list;
$entity_list->add( $e3);

$t->print( \*RES, Update_DTD => 1);
close RES;

ok( $res_file, $exp_file, "flush");

my $dtd= $t->dtd;
ok( !$dtd, 'dtd exits');

$t= new XML::Twig(LoadDTD=>1);
ok( $t, 'twig creation');
$t->parsefile( $in_file, ErrorContext=>2, );

$dtd= $t->dtd;
ok( $dtd, 'dtd not found');

my @model= sort keys %{$dtd->{model}};
stest( stringify( @model), 'doc:intro:note:para:section:title', 'element list');

stest( $t->model( 'title'), '(#PCDATA)', 'title model');
mtest( $t->model( 'section'), '\(intro\?,\s*title,\s*\(para|note\)+\)', 'section model');
stest( $t->dtd->{att}->{section}->{id}->{type}, 'ID', 'section id type');
stest( $t->dtd->{att}->{section}->{id}->{default}, '#IMPLIED', 'section id default');
exit 0;


