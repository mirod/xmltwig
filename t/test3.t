#!/usr/bin/perl -w

use strict;


use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

# This just tests a complete twig, no callbacks
# additional tests for element creation/parse and 
# space policy
# plus test for the is_pcdata method

$|=1;

use XML::Twig;

my $i=0;
my $failed=0;

my $TMAX=23; # do not forget to update!

print "1..$TMAX\n";

my $p1= XML::Twig::Elt->new( 'para', 'p1');
$p1->set_id( 'p1');
etest( $p1, 'para', 'p1', 'Element creation');
my $p2= XML::Twig::Elt->parse( '<para id="p2">para2</para>');
etest( $p2, 'para', 'p2', 'Element parse');
my $s1= parse XML::Twig::Elt( '<section id="s1"><title id="t1">title1</title><para id="p3">para 3</para></section>');
etest( $s1, 'section', 's1', 'Element parse (complex)');
my $p3= $s1->first_child( 'para');
etest( $p3, 'para', 'p3', 'Element parse (sub-element)');

my $string= "<doc>\n<p>para</p><p>\n</p>\n</doc>";

my $t1= new XML::Twig( DiscardSpacesIn => [ 'doc']);
$t1->parse( $string);
sttest( $t1->root, "<doc><p>para</p><p>\n</p></doc>", 'DiscardSpacesIn');
my $t2= new XML::Twig( DiscardSpacesIn => [ 'doc', 'p']);
$t2->parse( $string);
sttest( $t2->root, "<doc><p>para</p><p></p></doc>", 'DiscardSpacesIn');
my $t3= new XML::Twig( KeepSpaces =>1);
$t3->parse( $string);
sttest( $t3->root, $string, 'KeepSpaces');
my $t4= new XML::Twig( KeepSpacesIn =>[ 'p']);
$t4->parse( $string);
sttest( $t4->root, "<doc><p>para</p><p>\n</p></doc>", 'KeepSpacesIn');


my $p4= XML::Twig::Elt->parse( $string, KeepSpaces => 1);
sttest( $p4, $string, 'KeepSpaces');

my $p5= XML::Twig::Elt->parse( $string, DiscardSpaces => 1);
sttest( $p5, '<doc><p>para</p><p></p></doc>', "DiscardSpaces"); 

$p5= XML::Twig::Elt->parse( $string);
sttest( $p5, '<doc><p>para</p><p></p></doc>', "DiscardSpaces (def)"); 

my $p6= XML::Twig::Elt->parse( $string, KeepSpacesIn => ['p']);
sttest( $p6, "<doc><p>para</p><p>\n</p></doc>", "KeepSpacesIn 1"); 

my $p7= XML::Twig::Elt->parse( $string, KeepSpacesIn => [ 'doc', 'p']);
sttest( $p7, "<doc>\n<p>para</p><p>\n</p>\n</doc>", "KeepSpacesIn 2"); 

my $p8= XML::Twig::Elt->parse( $string, DiscardSpacesIn => ['doc']);
sttest( $p8, "<doc><p>para</p><p>\n</p></doc>", "DiscardSpacesIn 1 "); 

my $p9= XML::Twig::Elt->parse( $string, DiscardSpacesIn => [ 'doc', 'p']);
sttest( $p9, "<doc><p>para</p><p></p></doc>", "DiscardSpacesIn 2"); 

my $string2= "<p>para <b>bold</b> end of para</p>";
my $p10= XML::Twig::Elt->parse( $string2,);
sttest( $p10, '<p>para <b>bold</b> end of para</p>', "mixed content");

my $string3= "<doc>\n<p>para</p>\n<p>\n</p>\n</doc>";
my $p11= XML::Twig::Elt->parse( $string3, KeepSpaces => 1);
sttest( $p4, $string, 'KeepSpaces');
my $p12= XML::Twig::Elt->parse( $string3, KeepSpacesIn => [ 'doc']);
sttest( $p12, "<doc>\n<p>para</p>\n<p></p>\n</doc>", 'KeepSpacesIn');
my $p13= XML::Twig::Elt->parse( $string3, KeepSpaces => 1);
sttest( $p13, "<doc>\n<p>para</p>\n<p>\n</p>\n</doc>", 'KeepSpaces');

my $p14= XML::Twig::Elt->parse( $string2);
my $is_pcdata= $p14->is_pcdata;
ok( $is_pcdata ? 0 : 1, "is_pcdata on a <para>");
my $pcdata= $p14->first_child( PCDATA);
$is_pcdata=  $pcdata->is_pcdata;
ok( $pcdata->is_pcdata, "is_pcdata on PCDATA");

my $erase_string='<?xml version="1.0"?><doc><elt id="elt1"><selt id="selt1"
>text 1</selt><selt id="selt2"><selt id="selt3"> text 2</selt></selt
><selt id="selt4"><selt id="selt5"> text 3</selt> text 4</selt
></elt></doc>';
my $er_t= new XML::Twig( TwigHandlers => { selt => sub { $_[1]->erase; } });
$er_t->parse( $erase_string);
sttest( $er_t->root, '<doc><elt id="elt1">text 1 text 2 text 3 text 4</elt></doc>',
 "erase");

# test whether Twig packs strings
my $br_pcdata= "line 1\nline 2\nline 3\n";
my $doc_br_pcdata= "<doc>$br_pcdata</doc>";
my $t_br_pcdata= new XML::Twig();
$t_br_pcdata->parse( $doc_br_pcdata);
$pcdata= $t_br_pcdata->root->first_child->pcdata;
stest( $pcdata, $br_pcdata, "multi-line pcdata");

exit 0;

