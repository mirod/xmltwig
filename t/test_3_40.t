#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=2;
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
      
