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

my $DECL=qq{<?xml version="1.0" encoding="iso-8859-1"?>\n};
$DECL='';

my $TMAX=18;
print "1..$TMAX\n";

{ # testing set_inner_xml
  my $doc= '<doc><elt/><elt2>with content <p>toto</p></elt2></doc>';
  my $t= XML::Twig->nparse( $doc);
  my $inner= '<p1/><p>foo</p><bar><elt id="toto">duh</elt></bar>';
  $t->first_elt( 'elt')->set_inner_xml( $inner);
  (my $expected= $doc)=~ s{<elt/>}{<elt>$inner</elt>};
  is( $t->sprint, $expected, "set_inner_xml");

  $t->first_elt( 'elt2')->set_inner_xml( $inner);
  $expected=~ s{<elt2>.*</elt2>}{<elt2>$inner</elt2>};
  is( $t->sprint, $expected, "set_inner_xml (of an elt with content)");

}

{ # testing set_inner_html
  if( !XML::Twig::_use( 'HTML::TreeBuilder', 3.13))
    { skip( 4 => "need HTML::TreeBuilder 3.13+ to use set_inner_html method");
    }
  elsif( !XML::Twig::_use( 'LWP'))
    { skip( 4 => "need LWP to use set_inner_html method");
    }
  else
    {
      my $doc= '<html><head><title>a title</title></head><body>par 1<p>par 2<br>after the break</body></html>';
      my $t= XML::Twig->nparse( $doc);
      my $inner= '<ul><li>foo</li><li>bar</li></ul>';
      $t->first_elt( 'p')->set_inner_html( $inner);
      (my $expected= $t->sprint)=~ s{<p>.*</p>}{<p>$inner</p>};
      is( $t->sprint, $expected, "set_inner_html");

      $inner= q{<title>2cd title</title><meta content="bar" name="foo">};
      $t->first_elt( 'head')->set_inner_html( $inner);
      $inner=~ s{>$}{/>};
      $expected=~ s{<head>.*</head>}{<head>$inner</head>};
      $expected=~ s{(<meta[^>]*)(/>)}{$1 $2}g;
      is( $t->sprint, $expected, "set_inner_html (in head)");

      $inner= q{<p>just a p</p>};
      $t->root->set_inner_html( $inner);
      $expected= qq{$DECL<html><head></head><body>$inner</body></html>};
      is( $t->sprint, $expected, "set_inner_html (all doc)");

      $inner= q{the content of the <br/> body};
      $t->first_elt( 'body')->set_inner_html( $inner);
      $expected= qq{$DECL<html><head></head><body>$inner</body></html>};
      $expected=~ s{<br/>}{<br />}g;
      is( $t->sprint, $expected, "set_inner_html (body)");
    }
  
}

{ if( !XML::Twig::_use( "File::Temp"))
    { skip( 5, "File::Temp not available"); }
  else
    {
      # parsefile_inplace
      my $file= "test_3_26.xml";
      spit( $file, q{<doc><foo>nice hey?</foo></doc>});
      XML::Twig->new( twig_handlers => { foo => sub { $_->set_tag( 'bar')->flush; }})
               ->parsefile_inplace( $file);
      matches( slurp( $file), qr/<bar>/, "parsefile_inplace");
      
      XML::Twig->new( twig_handlers => { bar => sub { $_->set_tag( 'toto')->flush; }})
               ->parsefile_inplace( $file, '.bak');
      matches( slurp( $file), qr/<toto>/, "parsefile_inplace (with backup, checking file)");
      matches( slurp( "$file.bak"), qr/<bar>/, "parsefile_inplace (with backup, checking backup)");
      unlink( "$file.bak");
    
      XML::Twig->new( twig_handlers => { toto => sub { $_->set_tag( 'tata')->flush; }})
               ->parsefile_inplace( $file, 'bak_*');
      matches( slurp( $file), qr/<tata>/, "parsefile_inplace (with complex backup, checking file)");
      matches( slurp( "bak_$file"), qr/<toto>/, "parsefile_inplace (with complex backup, checking backup)");
      unlink( "bak_$file");
      unlink $file;
    }
}

{ if( !XML::Twig::_use( "File::Temp"))
    { skip( 5, "File::Temp not available"); }
  elsif( !XML::Twig::_use( "HTML::TreeBuilder"))
    { skip( 5, "HTML::TreeBuilder not available"); }
  elsif( !XML::Twig::_use( "LWP"))
    { skip( 5, "LWP not available"); }
  elsif( !XML::Twig::_use( "LWP::UserAgent"))
    { skip( 5, "LWP::UserAgent not available"); }

  else
    {
      # parsefile_html_inplace
      my $file= "test_3_26.html";
      spit( $file, q{<html><head><title>foo</title><body><p>this is it</p></body></html>>});
      XML::Twig->new( twig_handlers => { p => sub { $_->set_tag( 'h1')->flush; }})
               ->parsefile_html_inplace( $file);
      matches( slurp( $file), qr/<h1>/, "parsefile_html_inplace");

      XML::Twig->new( twig_handlers => { h1 => sub { $_->set_tag( 'blockquote')->flush; }}, error_context => 6)
               ->parsefile_html_inplace( $file, '.bak');
      matches( slurp( $file), qr/<blockquote>/, "parsefile_html_inplace (with backup, checking file)");
      matches( slurp( "$file.bak"), qr/<h1>/, "parsefile_html_inplace (with backup, checking backup)");
      unlink( "$file.bak");
    
      XML::Twig->new( twig_handlers => { blockquote => sub { $_->set_tag( 'div')->flush; }})
               ->parsefile_html_inplace( $file, 'bak_*');
      matches( slurp( $file), qr/<div>/, "parsefile_html_inplace (with complex backup, checking file)");
      matches( slurp( "bak_$file"), qr/<blockquote>/, "parsefile_html_inplace (with complex backup, checking backup)");
      unlink( "bak_$file");
      unlink $file;
    }
}


{ use Cwd;
  if(  XML::Twig::_use( "LWP::Simple") && XML::Twig::_use( "LWP::UserAgent"))
    { my $file = "test_uri";
      my $uri  = sprintf( "file://%s/%s", getcwd, $file);
      my $content= "ok";
      spit( test_uri => $content);
      is( XML::Twig::_slurp_uri( $uri), $content, "testing _slurp_uri");
    }
  else
    { skip( 1, "LWP::Simple or LWP::UserAgent not available"); }
}

{ # test syntax error in XPath predicate (RT #19499)
  my $t= XML::Twig->nparse( '<doc/>');
  eval { $t->get_xpath( '/*[@!a]'); };
  matches( $@, qr/^error in xpath expression/, "syntax error in XPath predicate");
}
