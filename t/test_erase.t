#!/usr/bin/perl -w
use strict;

use XML::Twig;

$|=1;

my $TMAX=1; # do not forget to update!
print "1..$TMAX\n";

undef $/;
my $doc=<DATA>;

my $t= XML::Twig->new(keep_spaces => 1);
$t->parse( $doc);
foreach my $erase ($t->descendants( 'erase'))
  { $erase->erase; }
my $result=$t->sprint;
$result=~ s{\s*$}{}s;     # remove trailing spaces (and \n)

my $expected_result= $doc; 
  $expected_result=~ s{</?erase/?>}{}g;
$expected_result=~ s{\s*$}{}s;     # remove trailing spaces (and \n)

if( $result eq $expected_result)
  { print "ok 1\n"; }
else
  { print "not ok 1\n"; 
    print STDERR "expected: \n$expected_result\n",
                 "real: \n$result\n";
  }
  
exit 0;


__DATA__
<doc>
  <!-- erase an empty element -->
  <test1>
    <elt><erase/></elt>
    <elt>text <erase/></elt>
    <elt><erase/> text (1)</elt>
    <elt>text <erase/> text (2)</elt>
    <elt><child/><erase/><child/></elt>
    <elt><erase/><child/></elt>
    <elt><child/><erase/></elt>
  </test1>
  <!-- erase an element with 1 text child -->
  <test2>
    <elt><erase>text (3)</erase></elt>
    <elt>text <erase>text (4)</erase></elt>
    <elt><erase>text (5)</erase> text (6)</elt>
    <elt>text (7)<erase>text (8)</erase> text (9)</elt>
    <elt><child/><erase>text (10)</erase><child/></elt>
    <elt><erase>text (11)</erase><child/></elt>
    <elt><child/><erase>text</erase></elt>
  </test2>
  <!-- erase an element with several children -->
  <test3>
    <elt><erase><child>text (12)</child><child/></erase></elt>
    <elt>text (13)<erase><child>text (14)</child><child/></erase></elt>
    <elt><erase><child>text (15)</child><child/></erase> text (16)</elt>
    <elt>text (17)<erase><child>text (18)</child><child/></erase> text (19)</elt>
    <elt><child/><erase><child>text (20)</child><child/></erase>child/></elt>
    <elt><erase><child>text (21)</child><child/></erase>child/></elt>
    <elt><child/><erase><child>text (22)</child><child/></erase></elt>
  </test3>
</doc>
