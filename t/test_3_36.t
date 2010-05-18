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

{ my $doc=q{<d><s id="s1"><t>title 1</t><s id="s2"><t>title 2</t></s><s id="s3"></s></s><s id="s4"></s></d>};
  my $ids;
  XML::Twig->parse( twig_handlers => { 's[t]' => sub { $ids .= $_->id; } }, $doc);
  is( $ids, 's2s1', 's[t]');
}

{
    my $string = q{<foo>power<baz/><bar></bar></foo>};
    my $t=XML::Twig->parse( $string);
    my $root = $t->root();
    my $copy = $root->copy();
    is( $copy->sprint, $root->sprint, 'empty elements in a copy') 

}

1;
