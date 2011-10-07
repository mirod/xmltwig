#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=5;
print "1..$TMAX\n";

{ my $d="<d><title section='1'>title</title><para>p 1</para> <para>p 2</para></d>";
  is( lf_in_t( XML::Twig->parse( pretty_print => 'indented', discard_spaces => 1, $d)), 1, 'space prevents indentation'); 
  is( lf_in_t( XML::Twig->parse( pretty_print => 'indented', discard_all_spaces => 1, $d)), 5, 'discard_all_spaces restores indentation'); 
}

sub lf_in_t
  { my($t)= @_;
    my @lfs= $t->sprint=~ m{\n}g;
    return scalar @lfs;
  }



{ my $d='<d id="d"><t1 id="t1"/><t2 id="t2"/><t3 att="a|b" id="t3-1" /><t3 att="a" id="t3-2"/><t3 id="t3-3"><t4 id="t4"/></t3></d>';
  my @tests=
    ( [ 't1|t2',                         2 ],
      [ 't1|t2|t3[@att="a|b"]',          3, 't1t2t3-1' ],
      [ 't1|t2|t3[@att!="a|b"]',         4, 't1t2t3-2t3-3' ],
      [ 't1|level(1)',                   6 ],
      [ 't1|level(2)',                   2 ],
      [ 't1|_all_',                      8, 't1t1t2t3-1t3-2t4t3-3d'],
      [ qr/t[12]/ . '|t3/t4',            3, 't1t2t4' ],
   );
  foreach my $test (@tests)
    { my $nb=0;
      my $ids='';
      my( $trigger, $expected_nb, $expected_ids)= @$test;
      XML::Twig->new( twig_handlers => { $trigger => sub { $nb++; $ids.=$_->id; } })->parse( $d);
      is( $nb, $expected_nb, "trigger with alt (nb): '$trigger'");
      if( $expected_ids) { is( $ids, $expected_ids, "trigger with alt (ids): '$trigger'"); }
    }

}
