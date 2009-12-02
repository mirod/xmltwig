#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,'t');
use tools;

my @DATA;
while( <DATA>) { chomp; my( $cond, $expected)= split /\s*=>\s*/; push @DATA, [$cond, $expected]; }

my $TMAX= 20;

print "1..$TMAX\n";

my $doc=q{<d><e class="c1">e1</e><e class="c1 c2" a="v1">e2</e><e class="c2" a="v2">e3</e></d>};
my $doc_dot=q{<d><e class="c1">wrong e1</e><e class="c1 c2" a="v1">wrong e2</e><e class="c2" a="v2">wrong e3</e><e.c1>e1</e.c1><e.c1 a="v1">e2</e.c1><e.c2 a="v2">e3</e.c2></d>};

my $t= XML::Twig->parse( $doc);

foreach my $test (@DATA)
  { my( $cond, $expected)= @$test;
    my $got= join '', map { $_->text } $t->root->children( $cond);
    is( $got, $expected, "navigation: $cond" );
  }


foreach my $test (@DATA)
  { my( $cond, $expected)= @$test;
    my $got='';
    XML::Twig->new( twig_handlers => { $cond => sub { $got.= $_->text } },
                    css_sel => 1,
                  )
             ->parse( $doc);
    is( $got, $expected, "handlers (css_sel enabled): $cond" ); 
  }

foreach my $test (@DATA)
  { my( $cond, $expected)= @$test;
    next if $cond !~ m{^e};
    my $got='';
    XML::Twig->new( twig_handlers => { $cond => sub { $got.= $_->text } },)
             ->parse( $doc_dot);
    is( $got, $expected, "handlers (css_sel NOT enabled): $cond" );
  } 



__DATA__
e.c1           => e1e2
e.c1[@a="v1"]  => e2
e.c1[@a]       => e2
e.c1[@a="v2"]  => 
*.c1[@a="v1"]  => e2
*.c1[@a="v2" or @a="v1"]  => e2
.c1[@a="v1"]  => e2
.c1[@a="v2" or @a="v1"]  => e2
