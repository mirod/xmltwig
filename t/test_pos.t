#!/usr/bin/perl -w
use strict;
use Carp;

$|=1;

# test for the various conditions in navigation methods

use XML::Twig;


my $t= XML::Twig->new;
$t->parse( 
'<doc id="doc">
  <elt1 id="elt1_1">an element</elt1>
  <elt1 id="elt1_2">an element</elt1>
  <elt1 id="elt1_3">an element</elt1>
  <elt2 id="elt2_1">an element</elt2>
  <elt1 id="elt1_4">an element</elt1>
  <elt2 id="elt2_2">an element</elt2>
  <elt1 id="elt1_5">an element</elt1>
 </doc>');

my @data=<DATA>;
my @data_without_comments= grep { !m{^\s*(#.*)?$} } @data;
my @test= map { s{\#.*$}{}; $_ }  @data_without_comments; 

#my @test= map { s{#.*$}{}; $_ } grep { !m{^\s*(#.*)?$} } <DATA>;

my $nb_test= @test;
print "1..$nb_test\n";

my $i=1;
foreach my $test (@test)
  { my( $id, $exp, $expected_pos)= split /\t+/, $test;
    chomp $expected_pos;
    $exp= '' if( $exp eq '_');
    test( $i++, $id, $exp, $expected_pos);
  }


sub test
  { my( $i, $id, $exp, $expected_pos)= @_;
    my $elt= $t->elt_id( $id);
    my $pos= $elt->pos( $exp);
    
    if( $pos == $expected_pos)
      { print "ok $i\n"; }
    else
      { print "not ok $i\n";
        my $filter=  $exp ? " filter: $exp" : '';
        warn "test $i: $id $filter - expected $expected_pos, actual $pos\n";
      }  
  }

exit 0;

__DATA__
#id	exp		expected
doc	_		1
doc	elt1		0
doc	toto		0
elt1_1	_		1
elt1_1	elt1		1
elt1_1	toto		0
elt1_2	_		2
elt1_2	elt1		2
elt1_2	toto		0
elt2_1	_		4
elt2_1	elt1		0
elt2_1	elt2		1
elt2_1	toto		0
elt2_2	_		6
elt2_2	elt1		0
elt2_2	elt2		2
elt2_2	toto		0
