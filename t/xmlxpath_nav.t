#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

$|=1;

my $t= XML::Twig::XPath->new;
$t->parse(
'<doc id="doc">
    <elt id="elt-1" att="1">elt 1</elt>
    <elt id="elt-2" att="2">elt 2</elt>
    <elt2 id="elt2-1">
      <elt id="elt-3">elt 3</elt>
    </elt2>
    <elt2 id="elt2-2">
      <elt2 att_int="2" id="elt2-3">2</elt2>
      <elt2 att_int="3" id="elt2-4">3</elt2>
    </elt2>
    <elt id="elt-4" att="3">elt 3</elt>
 </doc>');

my @data= grep { !/^##/  && m{\S} } <DATA>;

my @exp;
my %result;

foreach( @data)
  { chomp;
    my ($exp, $id_list) = split /\s*=>\s*/ ;
    $result{$exp}= $id_list;
    push @exp, $exp;
  }

my $nb_tests= keys %result;
print "1..$nb_tests\n";

my $i=1;

foreach my $exp ( @exp)
  { my $expected_result= $result{$exp};
    my $result_elt= $t->root->first_child( $exp);
    my $result= $result_elt ? $result_elt->att( 'id') : 'none';

    if( $result eq $expected_result)
      { print "ok $i\n"; }
    else
      { print "nok $i\n";
        print STDERR "$exp: expected $expected_result - real $result\n";
      }
    $i++;
  }

exit 0;

__DATA__
elt               => elt-1
elt[@id="elt-4"]  => elt-4
elt[@id="elt-3"]  => none
*[@att > 1]       => elt-2
elt2[2]           => elt2-2
##elt2[./elt2]      => elt2-2
elt3              => none
