#!/usr/bin/perl -w
use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,'t');
use tools;
use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;


$|=1;

my $t= XML::Twig::XPath->new;
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

my $nb_tests= 2 + keys %result;
print "1..$nb_tests\n";

my $i=1;

foreach my $exp ( @exp)
  { my $expected_result= $result{$exp};
    my @result= $t->findnodes( $exp);
    my $result;
    if( @result)
      { $result= join ' ', map { $_->id } @result; }
    else
      { $result= 'none'; }

    if( $result eq $expected_result)
      { print "ok $i\n"; }
    else
      { print "nok $i\n";
        print STDERR "$exp: expected $expected_result - real $result\n";
      }
    $i++;
  }

my $exp=  '//* |//@* | /';
my @result= $t->findnodes( $exp);
my @elts= $t->descendants( '#ELT');

# first check the number of results
my $result= @result;
my $nb_atts=0;
foreach (@elts) { $nb_atts+= $_->att_nb; }
my $expected_result= scalar @elts + $nb_atts + 1;

if( $result == $expected_result)
  { print "ok $i\n"; }
else
  { print "nok $i\n";
    print STDERR "$exp: expected $expected_result - real $result\n";
  }
$i++;

# then check the results (to make sure they are in hte right order)
my @expected_results;
push @expected_results, "XML::Twig::XPath '" . $t->sprint ."'";
foreach my $elt (@elts)
  { push @expected_results, ref( $elt) . " '" . $elt->sprint . "'" ;
    foreach my $att ($elt->att_names)
      { push @expected_results, qq{XML::Twig::XPath::Attribute '$att="} . $elt->att( $att) . q{"'} ; }
  }
$expected_result= join( "\n          ", @expected_results);
$result= join( "\n          ", map { ref( $_) . " '" . $_->toString ."'" } @result);
if( $result eq $expected_result)
  { print "ok $i\n"; }
else
  { print "nok $i\n";
    print STDERR "$exp:\nexpected: $expected_result\n\nreal     : $result\n";
  }
$i++;

exit 0;

__DATA__
/elt                  => none
//elt                 => elt-1 elt-2 elt-3
/doc/elt              => elt-1 elt-2
/doc/elt[ last()]     => elt-2
//elt[@id='elt-1']    => elt-1
//elt[@id="elt-1"] | //elt[@id="elt-2"] | //elt[@id="elt-3"]  => elt-1 elt-2 elt-3
//elt[@id="elt-1" or @id="elt-2" or @id="elt-3"]      => elt-1 elt-2 elt-3
//elt2[@att_int > 2]  => elt2-4
/doc/elt2[ last()]/*  => elt2-3 elt2-4
//*[@id="elt2-2"]     => elt2-2
/doc/elt2[./elt[@id="elt-3"]] => elt2-1
