#!/usr/bin/perl -w

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;

use XML::Twig;

my $TMAX=3; 

print "1..$TMAX\n";

my $xml_file= File::Spec->catfile( "t", "test_expand_external_entities.xml");
my $dtd_file= File::Spec->catfile( "t", "test_expand_external_entities.dtd");

my( $xml, $dtd, $xml_expanded, %ent);
{ local undef $/;
  open XML, "<$xml_file" or die "cannot open $xml_file: $!";
  $xml= <XML>;
  close XML;
  open DTD, "<$dtd_file" or die "cannot open $dtd_file: $!";
  $dtd= <DTD>;
  close DTD;
}

# extract entities
while( $dtd=~ m{<!ENTITY \s+ (\w+) \s+ "([^"]*)" \s* >}gx) { $ent{$1}= $2; } #"
# replace in xml
($xml_expanded= $xml)=~ s{&(\w+);}{$ent{$1}}g;

{
my $t= XML::Twig->new( load_DTD => 1);
$t->set_expand_external_entities;
$t->parsefile( $xml_file);
is( normalize_xml( $t->sprint), normalize_xml( $xml_expanded), "expanded document");
}

{
my $t= XML::Twig->new( load_DTD => 1, expand_external_ents => 1);
$t->parsefile( $xml_file);
is( normalize_xml( $t->sprint), normalize_xml( $xml_expanded), "expanded document");
}

{
(my $xml_no_dtd= $xml_expanded)=~ s{^<!DOCTYPE.*?>}{}s;
my $t= XML::Twig->new( load_DTD => 1, expand_external_ents => 1, do_not_output_DTD => 1);
$t->parsefile( $xml_file);
is( normalize_xml( $t->sprint), normalize_xml( $xml_no_dtd), "expanded document");
}

exit 0;
