#!/usr/bin/perl -w
#
use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

print "1..2\n";

if( $] < 5.008) 
  { skip( 2, "needs perl 5.8 or above to test auto conversion"); }
else
  { _use( 'Encode');

    my $char_utf8   = qq{\x{e9}};
    my $char_latin1 = encode("iso-8859-1", $char_utf8);
    my $doc_utf8    = qq{<d>$char_utf8</d>};
    my $doc_latin1  = qq{<?xml version="1.0" encoding="iso-8859-1"?><d>$char_latin1</d>};

    my $file_utf8   = "doc_utf8.xml";
    spit( $file_utf8, $doc_utf8);
    my $file_latin1 = "doc_latin1.xml";
    spit( $file_latin1, $doc_latin1);

    my( $q, $q2) = ( ($^O eq "MSWin32") || ($^O eq 'VMS') ) ? ('"', "'") : ("'", '"');
    my $lib= File::Spec->catfile( 'blib', 'lib');
    my $run_it=qq{$^X -I $lib -MXML::Twig -e$q print XML::Twig->parse( $q2$file_latin1$q2)->root->text$q};
    my $parsed= `$run_it`;
    is( $parsed, $char_utf8, 'testing auto transcoding of latin1 output');
    is( $parsed, $char_latin1, 'testing auto transcoding of latin1 output');
  }
