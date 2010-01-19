#!/usr/bin/perl -w
use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;


use XML::Twig;


  { 
    if( eval 'require Tie::IxHash') 
      { import Tie::IxHash; 
        print "1..7\n";
      }
    else 
      { warn( "Tie::IxHash not available, option keep_atts_order not allowed\n");
        print "1..1\nok 1\n";
        exit 0;
      }

    my $nb_elt=10;
    my $doc= gen_doc( $nb_elt);

    my $result= XML::Twig->new( pretty_print => 'indented')->parse( $doc)->sprint;
    isnt( $result, $doc, "keep_atts_order => 0 (first try)");

    $result= XML::Twig->new( keep_atts_order => 1, pretty_print => 'indented')->parse( $doc)->sprint;
    is( $result, $doc, "keep_atts_order => 1 (first try)");

    $result= XML::Twig->new( pretty_print => 'indented')->parse( $doc)->sprint;
    isnt( $result, $doc, "keep_atts_order => 0 (second try)");

    $result= XML::Twig->new( keep_atts_order => 1, pretty_print => 'indented')->parse( $doc)->sprint;
    is( $result, $doc, "keep_atts_order => 1 (second try)");

    $result= XML::Twig->new( keep_atts_order => 1, keep_encoding => 1, pretty_print => 'indented')
                      ->parse( $doc)->sprint;
    is( $result, $doc, "keep_atts_order => 1, keep_encoding => 1 (first time)");

    $result= XML::Twig->new( keep_encoding => 1, pretty_print => 'indented');

    $result= XML::Twig->new( keep_atts_order => 1, keep_encoding => 1, pretty_print => 'indented')
                      ->parse( $doc)->sprint;
    is( $result, $doc, "keep_atts_order => 1, keep_encoding => 1 (second time)");

    $result= XML::Twig->new( keep_encoding => 1, pretty_print => 'indented')
                      ->parse( $doc)->sprint;
    isnt( $result, $doc, " keep_encoding => 1 (second time)");

};

exit 0;

sub gen_doc
  { my( $nb_elt)= @_;
    my $doc= "<doc>\n";

    foreach (1..$nb_elt)
      { $doc .= "  <elt";

        my @atts= randomize( 'a'..'e');
        my %atts;
        tie %atts, 'Tie::IxHash';
        %atts= map { $atts[$_] => $_ + 1 } (0..4) ;

        while( my( $att, $value)= each %atts)
          { $doc .= qq{ $att="$value"}; }

        $doc .= "/>\n";
      }
    $doc .= "</doc>\n";
    return $doc;
  }

sub randomize
  { my @list= @_;
    my $n= @list;
    foreach (1..10)
      { my $i= int rand( $n);
        my $j= int rand( $n);
        ($list[$i], $list[$j])=($list[$j], $list[$i])
      }
    return @list;
  }
