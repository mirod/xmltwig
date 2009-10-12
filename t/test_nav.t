#!/usr/bin/perl -w
use strict;
use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

# test for the various conditions in navigation methods

use XML::Twig;


my $t= XML::Twig->new;
$t->parse( 
'<doc id="doc">
    <elt id="elt-1" toto="foo" val="1">
      <subelt id="subelt-1">text1</subelt>
    </elt>
    <elt id="elt-2" val="2"/>
    <elt2 id="elt2-1"/>
    <elt2 id="elt2-2">text</elt2>
    <elt2 id="elt2-3">
      <subelt id="subelt-2">text</subelt>
      <subelt id="subelt-3">text}</subelt>
      <subelt id="subelt-3">text"</subelt>
      <subelt id="subelt-3">text\'</subelt>
      <subelt id="subelt-4">text 2</subelt>
    </elt2>
    text level1
  </doc>');

my $root= $t->root;

my @data= grep { !/^##/  && m{\S} } <DATA>;
my %result= map { chomp; split /\s*=>\s*/} @data;

my $nb_tests= keys %result;
print "1..$nb_tests\n";

foreach my $cond ( sort keys %result)
  { my $expected_result= $result{$cond};
    my $result;
    my $res= $root->first_child( $cond);
    if( $res) 
      { if( $res->id) { $result= $res->id;   }
        else          { $result= $res->text;
	                $result=~ s/^\s+//;
	                $result=~ s/\s+$//;
	              }
      }
    else              { $result= 'none';  }
    is( $result => $expected_result, "$cond");
  }

exit 0;

__DATA__
                           => elt-1
elt                        => elt-1
#ELT                       => elt-1
!#ELT                      => text level1
#TEXT                      => text level1
!#TEXT                     => elt-1
elt2                       => elt2-1
foo                        => none
elt[@id]                   => elt-1
elt[@id!="elt-1"]          => elt-2
elt[@duh!="elt-1"]         => elt-1
elt[@toto]                 => elt-1
elt[!@toto]                => elt-2
/2$/                       => elt2-1
elt[@id="elt-1"]           => elt-1
elt[@id="elt-1" or @foo="bar"] => elt-1
elt[@id="elt-1" and @foo!="bar"] => elt-1
elt[@id="elt-1" and @foo="bar"] => none
elt2[@id=~/elt2/]          => elt2-1
elt[@id="elt2-1"]          => none
elt2[@id="elt2-1"]         => elt2-1
elt[@id=~/elt2/]           => none
*[@id="elt1-1"]             => none
*[@foo]                     => none
*[@id]                      => elt-1
*[@id="elt-1" or @foo="bar"] => elt-1
*[@id=~/elt2$/]             => none
*[@id=~/2-2$/]              => elt2-2
*[@id=~/^elt2/]             => elt2-1
[@id="elt1-1"]             => none
[@foo]                     => none
[@id]                      => elt-1
[@id="elt-1" or @foo="bar"] => elt-1
[@id=~/elt2$/]             => none
[@id=~/2-2$/]              => elt2-2
[@id=~/^elt2/]             => elt2-1
#PCDATA                    => text level1
elt[text(subelt)="text}" ] => none
elt2[text(subelt)="text}"] => elt2-3
elt2[text()="text}"]       => none
elt2[text(subelt)='text"'] => elt2-3
elt2[text(subelt)="text'"] => elt2-3
[text(subelt)="text}"]     => elt2-3
[text(subelt)="text1"]     => elt-1
[text(subelt)="text 2"]    => elt2-3
*[text(subelt)="text1"]     => elt-1
*[text(subelt)="text 2"]    => elt2-3
elt2[text(subelt)="text 2"]=> elt2-3
elt[text(subelt)="text 2"] => none
*[text(subelt)="foo"]       => none
*[text(subelt)=~/text/]     => elt-1
*[text(subelt)=~/^ext/]     => none
[text(subelt)="foo"]       => none
[text(subelt)=~/text/]     => elt-1
[text(subelt)=~/^ext/]     => none
elt2[text(subelt)="text"]  => elt2-2 
elt[text(subelt)="text"]   => none
elt[text(subelt)="foo"]    => none
elt[text(subelt)=~/text/]  => elt-1
elt[text(subelt)=~/^ext/]  => none
elt2[text(subelt)="text"]  => elt2-3
elt2[text(subelt)="foo"]   => none
elt2[text(subelt)=~/tex/]  => elt2-3
elt2[text(subelt)=~/^et/]  => none
elt2[text(subelt)=~/^et}/]  => none
/ELT/i                     => elt-1
elt2[text(subelt)='text"'] => elt2-3
elt[@val>'1']                => elt-2
@val>"1"                     => elt-2
elt[@val<"2"]                => elt-1
@val<"2"                     => elt-1
elt[@val>1]                  => elt-2
@val>1                       => elt-2
elt[@val<2]                  => elt-1
@val<2                       => elt-1
@val                         => elt-1
[@val="1" or @dummy="2"]     => elt-1
[@val="2" or @dummy="2"]     => elt-2
*[@val="1" or @dummy="2"]     => elt-1
*[@val="2" or @dummy="2"]     => elt-2
@val="1" and @dummy="2"      => none
@val="1" or @dummy="2"       => elt-1
@val="2" or @dummy="2"       => elt-2
[@val=~/2/]                  => elt-2
*[@val=~/2/]                  => elt-2
@val=~/^2/                  => elt-2
@val!~/^1/                  => elt-2
