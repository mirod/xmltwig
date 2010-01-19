#!/usr/bin/perl -w
use strict;


# test designed to improve coverage of the module

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

#$|=1;
my $DEBUG=0;

use XML::Twig;

my $TMAX=1; 
print "1..$TMAX\n";

{ my $indented="<doc>\n  <elt/>\n</doc>\n";
  (my $straight=$indented)=~ s{\s}{}g;
  is( XML::Twig->new( pretty_print => 'indented')->parse( $indented)->sprint,
      $indented, "pretty printed doc"); exit;
  is( XML::Twig->new()->parse( $indented)->sprint,
      $straight, "non pretty printed doc");
}

