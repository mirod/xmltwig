#!/usr/bin/perl -w
use strict;

use XML::Twig;

$|=1;

my $i=1;

my $TMAX=43; # do not forget to update!

print "1..$TMAX\n";

print "ok $i\n"; # loading
$i++;

my $t= XML::Twig->new();
$t->parse( \*DATA);


foreach my $elt ($t->descendants)
  { if( ($elt->tag eq 'field') && !$elt->is_field)
      { print "not ok $i ";
        warn $elt->id, " not recognized as field\n";
      }
    elsif( ($elt->tag ne 'field') && $elt->is_field)
      { print "not ok $i ";
        my $elt_id= $elt->id || $elt->text;
        warn " $elt_id recognized as field\n";
      }
    else
      { print "ok $i\n"; }
    $i++;
  }
       
exit 0;


__DATA__
<not_field id="n1">
  <field id="f1"> field 1 </field>
  <not_field id="n2"> <field id="f2"/></not_field>
  <not_field id="n3"> text 1 <field id="f3"/> text 2</not_field>
  <not_field id="n4"> text 3 <field id="f4">field 2</field> text 4</not_field>
  <not_field id="n5"> text 5<field id="f5">field</field></not_field>
  <field id="f6"> field 3 </field>
  <not_field id="n6"><field id="f7">field 4</field></not_field>
  <not_field id="n7"><field id="f8">field 5</field><field id="f9">field 6</field></not_field>
  <not_field id="n8">
    <not_field id="n9"><field id="f10">field 7</field></not_field>
    <field id="f11">field 8</field>
  </not_field>
  <field id="f12">field 9</field>
  <field id="f13">0</field>
  <field id="f14"><!-- still a field --></field>
  <field id="f15">a <!-- still a field --> field 10</field>
</not_field>
  
