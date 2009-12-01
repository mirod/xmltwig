#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,'t');
use tools;

my $TMAX=6; # don't forget to update!

print "1..$TMAX\n";

my $doc=q{<d><e class="c1">e1</e><e class="c1 c2" a="v1">e2</e><e class="c2" a="v2">e3</e></d>};

my $t= XML::Twig->parse( $doc);

while( <DATA>)
  { chomp;
    my( $cond, $expected)= split /\s*=>\s*/;
    my $got= join ':', map { $_->text } $t->root->children( $cond);
    is( $got, $expected, "navigation: $cond" );
  } 

__DATA__
e.c1           => e1:e2
e.c1[@a="v1"]  => e2
e.c1[@a]       => e2
e.c1[@a="v2"]  => 
*.c1[@a="v1"]  => e2
*.c1[@a="v2" or @a="v1"]  => e2
.c1[@a="v1"]  => e2
.c1[@a="v2" or @a="v1"]  => e2
