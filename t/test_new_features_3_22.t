#!/usr/bin/perl -w
use strict;

use Carp;

use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

use XML::Twig;

my $DEBUG=0;
print "1..20\n";

         
{ my $doc= q{<?xml version="1.0" ?>
<!DOCTYPE doc [ <!ENTITY foo 'toto'>]>
<doc>&foo;</doc>};
  XML::Twig->new( keep_encoding => 1)->parse( $doc);
}

{ # testing parse_html
 
  if( XML::Twig::_use( 'HTML::TreeBuilder', 3.13) && XML::Twig::_use( 'LWP::Simple') && XML::Twig::_use( 'LWP::UserAgent'))
    { my $html= q{<html><head><title>T</title><meta content="mv" name="mn"></head><body>t<br>t2<p>t3</body></html>};
      my $expected= HTML::TreeBuilder->new->parse( $html)->as_XML;
      $expected=~ s{></(meta|br)}{ /}g;
      is_like( XML::Twig->new->parse_html( $html)->sprint, $expected, 'parse_html string using HTML::TreeBuilder');

      my $html_file= File::Spec->catfile( "t", "test_new_features_3_22.html");
      spit( $html_file => $html);
      if( -f $html_file)
        { is_like( XML::Twig->new->parsefile_html( $html_file)->sprint, $expected, 'parsefile_html using HTML::TreeBuilder'); 

          open( HTML, "<$html_file") or die "cannot open HTML file '$html_file': $!";
          is_like( XML::Twig->new->parse_html( \*HTML)->sprint, $expected, 'parse_html fh using HTML::TreeBuilder');
        }
      else
        { skip( 2, "could not write HTML file in t directory, check permissions"); }
      
    }
  else
    { skip( 3 => 'need  HTML::TreeBuilder 3.13+ and LWP to test parse_html'); }
}

{ # testing _use
  ok( XML::Twig::_use( 'XML::Parser'), '_use XML::Parser');
  ok( XML::Twig::_use( 'XML::Parser'), '_use XML::Parser (2cd time)'); # second time tests the caching
  nok( XML::Twig::_use( 'I::HOPE::THIS::MODULE::NEVER::MAKES::IT::TO::CPAN'), '_use non-existent-module');
  nok( XML::Twig::_use( 'I::HOPE::THIS::MODULE::NEVER::MAKES::IT::TO::CPAN'), '_use non-existent-module (2cd time)');
}

{ # testing auto-new features
  
  my $doc= '<doc/>';
  is( XML::Twig->nparse(  empty_tags => 'normal', $doc)->sprint, $doc, 'nparse string');
  is( XML::Twig->nparse( empty_tags => 'expand', $doc)->sprint, '<doc></doc>', 'nparse string and option');
  my $doc_file= 'doc.xml';
  
  spit( $doc_file => $doc);
  # doc is still expanded because empty_tags was set above
  is( XML::Twig->nparse( $doc_file)->sprint, '<doc></doc>', 'nparse file');
  is( XML::Twig->nparse( twig_handlers => { doc => sub { $_->set_tag( 'foo'); } }, $doc_file)->sprint, '<foo></foo>', 'nparse file and option');
  unlink $doc_file;

if( XML::Twig::_use( 'HTML::TreeBuilder', 3.13) && XML::Twig::_use( 'LWP::Simple') && XML::Twig::_use( 'LWP::UserAgent'))
  {
      $doc=q{<html><head><title>foo</title></head><body><p>toto</p></body></html>}; 
      is( XML::Twig->nparse( $doc)->sprint, $doc, 'nparse well formed html string');
      $doc_file="doc.html";
      spit( $doc_file => $doc);
      is( XML::Twig->nparse( $doc_file)->sprint, $doc, 'nparse well formed html file');
      #is( XML::Twig->nparse( "file://$doc_file")->sprint, $doc, 'nparse well formed url');
      unlink $doc_file;

      XML::Twig::_disallow_use( 'HTML::TreeBuilder');
      eval{ XML::Twig->new->parse_html( '<html/>'); };
      matches( $@, "^cannot parse HTML: missing HTML::TreeBuilder", "parse_html without HTML::TreeBuilder");
      XML::Twig::_allow_use( 'HTML::TreeBuilder');
  }
else
  { skip( 3, "need HTML::TreeBuilder 3.13+"); }

if( XML::Twig::_use( 'HTML::TreeBuilder', 3.13) && XML::Twig::_use( 'LWP::Simple') && XML::Twig::_use( 'LWP::UserAgent'))
    { $doc=q{<html><head><title>foo</title></head><body><p>toto<br>tata</p></body></html>}; 
      (my $expected= $doc)=~ s{<br>}{<br />};
      $doc_file="doc.html";
      spit( $doc_file => $doc);
      is( XML::Twig->nparse( $doc_file)->sprint, $expected, 'nparse html file');
      #is( XML::Twig->nparse( "file://$doc_file")->sprint, $doc, 'nparse html url');
      unlink $doc_file;
    }
  else
    { skip ( 1, "need HTML::TreeBuilder 3.13+"); }
}

{ 
  my $file= File::Spec->catfile( $Bin, "test_new_features_3_22.html");
  if( -f $file) 
    { XML::Twig::_disallow_use( 'LWP::Simple');
      eval { XML::Twig->nparse( "file://$file"); };
      matches( $@, "^missing LWP::Simple", "nparse html url without LWP::Simple");
      XML::Twig::_allow_use( 'LWP::Simple');
      if( XML::Twig::_use( 'LWP::Simple')  && XML::Twig::_use( 'LWP::UserAgent') && XML::Twig::_use( 'HTML::TreeBuilder', 3.13))
        { my $url= "file://$file";
          $url=~ s{\\}{/}g; # we need a URL, not a file name
           my $content= XML::Twig->nparse( $url)->sprint;
          (my $expected= slurp( $file))=~ s{(<(meta|br)[^>]*>)}{$1</$2>}g;
          $expected=~s{<p>t3}{<p>t3</p>};
          $expected=~ s{></(meta|br)}{ /}g;
          is( $content, $expected, "nparse url");
        }
      else
        { skip( 1 => "cannot test html url parsing without LWP::Simple and HTML::TreeBuilder 3.13+"); }
      
    }
  else
    { skip( 2 => "cannot find $file"); }
}

{ 
  my $file= File::Spec->catfile( $Bin, "test_new_features_3_22.xml");
  if( -f $file) 
    { XML::Twig::_disallow_use( 'LWP::Simple');
      eval { XML::Twig->nparse( "file://$file"); };
      matches( $@, "^missing LWP::Simple", "nparse url without LWP::Simple");
      XML::Twig::_allow_use( 'LWP::Simple');
      if( perl_io_layer_used())
        { skip( 1 => "cannot test url parsing when UTF8 perlIO layer used"); }
      elsif( XML::Twig::_use( 'LWP::Simple') && XML::Twig::_use( 'LWP::UserAgent'))
        { my $url= "file://$file";
          $url=~ s{\\}{/}g; # we need a URL, not a file name 
          if( LWP::Simple::get( $url))
            { my $content= XML::Twig->nparse( $url)->sprint;
              is( $content, "<doc></doc>", "nparse url (nothing there)");
            }
          else
            { skip( 1 => "it looks like your LWP::Simple's get cannot handle '$url'"); } 
        }
      else
        { skip( 1 => "cannot test url parsing without LWP"); }
    }
  else
    { skip( 2 => "cannot find $file"); }
}
 

{ my $file= File::Spec->catfile( "t", "test_new_features_3_22.xml");
  open( FH, "<$file") or die "cannot find test file '$file': $!";
  my $content= XML::Twig->nparse( \*FH)->sprint;
  is( $content, "<doc></doc>", "nparse glob");
}
