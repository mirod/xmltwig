#!/usr/bin/perl -w


# tests that require IO::Scalar to run
use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

#$|=1;
my $DEBUG=0;

use XML::Twig;

BEGIN 
  { eval "use bytes";
    if( $@) 
      { print "1..1\nok 1\n"; 
        warn "skipping, need to be able to use bytes\n";
        exit;
      } 
  }

print "1..2\n";

my $text= "&#233;t&#233;";
my $text_safe= "&#233;t&#233;";
my $text_safe_hex= "&#xe9;t&#xe9;";
my $doc=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text</doc>};
my $doc_safe=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text_safe</doc>};
my $doc_safe_hex=qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>$text_safe_hex</doc>};

my $t= XML::Twig->new()->parse( $doc);

if( $] == 5.008)
  { skip( 2); }
else
  { $t->set_output_text_filter( sub { my $text= shift;
                                      use bytes;
                                      $text=~ s{([\xC0-\xDF].|[\xE0-\xEF]..|[\xF0-\xFF]...)}
                                               {XML::Twig::_XmlUtf8Decode($1)}egs;
                                      return $text;
                                    }
                          );
    is( $t->sprint, $doc_safe, 'safe with _XmlUtf8Decode');  # test 338
    $t->set_output_text_filter( sub { my $text= shift;
                                      use bytes;
                                      $text=~ s{([\xC0-\xDF].|[\xE0-\xEF]..|[\xF0-\xFF]...)}
                                               {XML::Twig::_XmlUtf8Decode($1, 1)}egs;
                                      return $text;
                                    }
                          );
    is( $t->sprint, $doc_safe_hex, 'safe_hex with _XmlUtf8Decode');  # test 339
  }


exit 0;
