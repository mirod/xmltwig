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
    <elt><erase/> text</elt>
    <elt>text <erase/> text</elt>
    <elt><child/><erase/><child/></elt>
    <elt><erase/><child/></elt>
    <elt><child/><erase/></elt>
  </test1>
  <!-- erase an element with 1 text child -->
  <test2>
    <elt><erase>text</erase></elt>
    <elt>text <erase>text</erase></elt>
    <elt><erase>text</erase> text</elt>
    <elt>text <erase>text</erase> text</elt>
    <elt><child/><erase>text</erase><child/></elt>
    <elt><erase>text</erase><child/></elt>
    <elt><child/><erase>text</erase></elt>
  </test2>
  <!-- erase an element with several children -->
  <test3>
    <elt><erase><child>text</child><child/></erase></elt>
    <elt>text <erase><child>text</child><child/></erase></elt>
    <elt><erase><child>text</child><child/></erase> text</elt>
    <elt>text <erase><child>text</child><child/></erase> text</elt>
    <elt><child/><erase><child>text</child><child/></erase>child/></elt>
    <elt><erase><child>text</child><child/></erase>child/></elt>
    <elt><child/><erase><child>text</child><child/></erase></elt>
  </test3>
</doc>
