#!/usr/bin/perl -w
use strict;

use strict;
use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=1;
print "1..$TMAX\n";

if( $] >= 5.008)
  { # test non ascii letters at the beginning of an element name in a selector
    # can't use non ascii chars in script, so the tag name needs to come from the doc!
    my $doc=q{<doc><tag>&#233;t&#233;</tag><elt>summer</elt><elt>estate</elt></doc>};
    my $t= XML::Twig->parse( $doc);
    my $tag= $t->root->first_child( 'tag')->text;
    foreach ($t->root->children( 'elt')) { $_->set_tag( $tag); }
    is( $t->root->first_child( $tag)->text, 'summer', 'non ascii letter to start a name in a condition');
  }
else
  { skip( 1, "known bug in perl $]: tags starting with a non ascii letter cannot be used in expressions"); }

exit;
1;
