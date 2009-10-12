#!/usr/bin/perl -w
use strict;

use XML::Twig;

$|=1;

my $t= XML::Twig->new;
$t->parse(
'<doc id="doc">
    <elt id="elt-1">elt 1</elt>
    <elt id="elt-2">elt 2</elt>
    <elt2 id="elt2-1">
      <elt id="elt-3">elt 3</elt>
    </elt2>
    <elt2 id="elt2-2">
      <elt2 att_int="2" id="elt2-3">2</elt2>
      <elt2 att_int="3" id="elt2-4">3</elt2>
    </elt2>
    <:elt id=":elt">yep, that is a valid name</:elt>
 </doc>');

my @data= grep { !/^##/  && m{\S} } <DATA>;

my @exp;
my %result;

foreach( @data)
  { chomp;
    my ($exp, $id_list) = split /\s*=>\s*/ ;
    $id_list=~ s{\s+$}{};
    $result{$exp}= $id_list;
    push @exp, $exp;
  }

my $nb_tests= keys %result;
print "1..$nb_tests\n";

my $i=1;

foreach my $exp ( @exp)
  { my $expected_result= $result{$exp};
    my @result= $t->get_xpath( $exp);
    my $result;
    if( @result)
      { $result= join ' ', map { $_->id || $_->gi } @result; }
    else
      { $result= 'none'; }

    if( $result eq $expected_result)
      { print "ok $i\n"; }
    else
      { print "not ok $i\n";
        print STDERR "$exp: expected '$expected_result' - real '$result'\n";
      }
    $i++;
  }

exit 0;

__DATA__
/elt			=> none
/elt[@foo="bar"] => none
/*[@foo="bar"] => none
//*[@foo="bar"] => none
/* => doc
/*[@id="doc"] => doc
//*[@id="doc"] => doc
//elt			=> elt-1 elt-2 elt-3
//*/elt			=> elt-1 elt-2 elt-3
/doc/elt		=> elt-1 elt-2
/*/elt		=> elt-1 elt-2
/doc/elt[ last()]	=> elt-2
/doc/*[ last()]	=> :elt
//elt[@id='elt-1']	=> elt-1
//*[@id='elt-1']	=> elt-1
//[@id='elt-1']	=> elt-1
//elt[@id='elt-1' or @id='elt-2']	=> elt-1 elt-2
//elt[@id='elt-1' and @id='elt-2']	=> none
//elt[@id='elt-1' and @id!='elt-2']	=> elt-1
//elt[@id=~ /elt/]	=> elt-1 elt-2 elt-3
//[@id='elt-1' or @id='elt-2']	=> elt-1 elt-2
//[@id='elt-1' and @id='elt-2']	=> none
//[@id='elt-1' and @id!='elt-2']	=> elt-1
//[@id=~ /elt/]	=> elt-1 elt-2 elt2-1 elt-3 elt2-2 elt2-3 elt2-4 :elt
//*[@id='elt-1' or @id='elt-2']	=> elt-1 elt-2
//*[@id='elt-1' and @id='elt-2']	=> none
//*[@id='elt-1' and @id!='elt-2']	=> elt-1
//*[@id=~ /elt/]	=> elt-1 elt-2 elt2-1 elt-3 elt2-2 elt2-3 elt2-4 :elt
//elt2[@att_int > 2]	=> elt2-4
/doc/elt2[ last()]/*	=> elt2-3 elt2-4
//*[@id=~/elt2/]        => elt2-1 elt2-2 elt2-3 elt2-4
/doc/*[@id=~/elt2/]     => elt2-1 elt2-2
/doc//*[@id=~/elt2/]    => elt2-1 elt2-2 elt2-3 elt2-4
//*[@id=~/elt2-[34]/]   => elt2-3 elt2-4
//*[@id!~/^elt/]        => doc :elt
//[@id=~/elt2-[34]/]    => elt2-3 elt2-4
//[@id!~/elt2-[34]/]    => doc elt-1 elt-2 elt2-1 elt-3 elt2-2 :elt
//elt2[@id=~/elt2-[34]/] => elt2-3 elt2-4
//*[@id!~/elt2-[34]/]   => doc elt-1 elt-2 elt2-1 elt-3 elt2-2 :elt
//:elt                  => :elt
//elt[string()="elt 1"]   => elt-1
//elt[string()=~/elt 1/]  => elt-1
//elt[string()=~/^elt 1/]  => elt-1
//*[string()="elt 1"]   => elt-1 #PCDATA
//*[string()=~/elt 1/]  => doc elt-1 #PCDATA
//*[string()=~/^elt 1/]  => doc elt-1 #PCDATA
//[string()="elt 1"]   => elt-1 #PCDATA
//[string()=~/elt 1/]  => doc elt-1 #PCDATA
//[string()=~/^elt 1/]  => doc elt-1 #PCDATA
//[string()="elt 2"]   => elt-2 #PCDATA
//[string()=~/elt 2/]  => doc elt-2 #PCDATA
//[string()=~/^elt 2/]  => elt-2 #PCDATA
