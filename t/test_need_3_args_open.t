#!/usr/bin/perl -w

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;


$|=1;

use XML::Twig;

# abort (before compiling so the 3 arg open doesn't cause a crash) unless perl 5.8+
BEGIN
  { if( $] < 5.008) { print "1..1\nok 1\n"; warn "skipping tests that require 3 args open\n"; exit 0; } }

my $TMAX=4; 
print "1..$TMAX\n";

{ my $out='';
  open( my $fh, '>', \$out);
  my $doc=q{<doc><elt att="a">foo</elt><elt att="b">bar</elt></doc>};
  my $t= XML::Twig->new( twig_handlers => { elt => sub { $_->flush( $fh) } });
  $t->parse( $doc);
  is( $out, $doc, "flush to a scalar (with autoflush)");
  $t->flush( $fh);
  is( $out, $doc, "double flush");
  $t->flush();
  is( $out, $doc, "triple flush");
}

{
my $out= '';
my $twig = XML::Twig->new( output_encoding => 'utf-8',);
$twig->parse( "<root/>");
my $greet = $twig->root->insert_new_elt( last_child => 'g');
$greet->set_text("Gr\x{00FC}\x{00DF}");
open(my $fh, '>:utf8', \$out);
$twig->print(\*$fh);
print {*$fh} "<c>Copyright \x{00A9} 2008 Me</c>";
close($fh);
is( $out, qq{<?xml version="1.0" encoding="utf-8"?><root><g>Grüß</g></root><c>Copyright © 2008 Me</c>}, 
          '$t->print and regular print mixed, with utf-8 encoding'
  );
}

