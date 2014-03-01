#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test::More;

use XML::Twig::XPath;

eval "use XML::XPathEngine";
if( $@) { print "1..1\nok 1\n"; warn "skipping, using variables in XPath requires XML::XPathEngine\n"; exit; }

plan( tests => 8);

my( $employees, $areas)= do { local $/="\n\n"; <DATA>; };

{ 
  # test all data in 1 single file
  my $data= "<data>$employees$areas</data>";
  my $t = XML::Twig::XPath->new->parse( $data);

  { $t->set_var( salary => 12000);
    my @nodes=  $t->findnodes('/data/employees/employee[@salary=$salary]/name');
    is( results( @nodes), 'e3:e4', '1 doc, var is a litteral');
  }

  { $t->set_var( E => $t->find( '/data/employees/employee[@salary>10000]'));
    $t->set_var( A => $t->find( '/data/areas/area[district="Brooklyn"]/street'));
    my @nodes = $t->findnodes('$E[work_area/street = $A]/name');
    is( results( @nodes), 'e3:e4', '1 doc, var is a node set');
  }

  { $t->set_var( org => 'A');
    my @nodes=  $t->findnodes('/data/employees/employee[@org=$org]/name');
    is( results( @nodes), 'e5', '1 doc, var is a simple litteral');
  }

  { $t->set_var( org => 'A/B');
    my @nodes=  $t->findnodes('/data/employees/employee[@org=$org]/name');
    is( results( @nodes), 'e6', '1 doc, var is an XPath-like litteral');
  }

}

{ # test with data in 2 single file
  my $te = XML::Twig::XPath->new->parse( $employees);
  my $ta = XML::Twig::XPath->new->parse( $areas);

  { $te->set_var( salary => 12000);
    my @nodes=  $te->findnodes('/employees/employee[@salary=$salary]/name');
    is( results( @nodes), 'e3:e4', '2 docs, var is a litteral');
  }

  SKIP: 
    { skip "node sets in an XPath variable are not supported with perl < 5.12", 1 unless $] >= 5.012;
      $te->set_var( E => $te->find( '/employees/employee[@salary>10000]'));
      $te->set_var( A => $ta->find( '/areas/area[district="Brooklyn"]/street'));
      my @nodes = $te->findnodes('$E[work_area/street = $A]/name');
      is( results( @nodes), 'e3:e4', '2 docs, var is a node set');
    }

  { $te->set_var( org => 'A');
    my @nodes=  $te->findnodes('/employees/employee[@org=$org]/name');
    is( results( @nodes), 'e5', '2 docs, var is a simple litteral');
  }

  { $te->set_var( org => 'A/B');
    my @nodes=  $te->findnodes('/employees/employee[@org=$org]/name');
    is( results( @nodes), 'e6', '2 docs, var is an XPath-like litteral');
  }

}


sub results
  { return join ':', map { $_->id || 'XX' } @_; }

__DATA__
<employees id="e">
  <employee salary="11000" id="s1">
    <name id="e1">Employee 1</name>
    <work_area id="w1">
      <street id="st1">Fifth Avenue</street>
    </work_area>
  </employee>
  <employee salary="9000" id="s2">
    <name id="e2">Employee 2</name>
    <work_area id="w2">
      <street>Abbey Court</street>
    </work_area>
  </employee>
  <employee salary="12000" id="s3">
    <name id="e3">Employee 3</name>
    <work_area id="w3">
      <street>Abbey Court</street>
    </work_area>
  </employee>
  <employee salary="12000" id="s4">
    <name id="e4">Employee 4</name>
    <work_area id="w4">
      <street>Broad Street</street>
      <street>Abbey Court</street>
    </work_area>
  </employee>
  <employee salary="1000" org="A" id="s5">
    <name id="e5">Employee 5</name>
    <work_area id="w5">
      <street>Broad Street</street>
      <street>Abbey Court</street>
    </work_area>
  </employee>
  <employee salary="1000" org="A/B" id="s6">
    <name id="e6">Employee 6</name>
    <work_area id="w6">
      <street>Broad Street</street>
      <street>Abbey Court</street>
    </work_area>
  </employee>
</employees>

<areas>
  <area>
    <district>Brooklyn</district>
    <street>Abbey Court</street>
    <street>Aberdeen Street</street>
    <street>Adams Street</street>
  </area>
  <area>
    <district>Manhattan</district>
    <street>Fifth Avenue</street>
    <street>Broad Street</street>
  </area>
</areas>

