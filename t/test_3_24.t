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

my $TMAX=15;
print "1..$TMAX\n";

{ # adding comments or pi's before/after the root
  my $doc= XML::Twig->nparse( '<doc/>');
  my $xsl = XML::Twig::Elt->new('#PI');
     $xsl->set_target('xml-stylesheet');
     $xsl->set_data('type= "text/xsl" href="xsl_style.xsl"');
  $xsl->paste( before => $doc->root);
  is( $doc->sprint, '<?xml-stylesheet type= "text/xsl" href="xsl_style.xsl"?><doc/>',
      'PI before the root'
    );
  my $comment= XML::Twig::Elt->new( '#COMMENT');
  $comment->set_comment( 'foo');
  $comment->paste( before => $doc->root);

  is( $doc->sprint, '<?xml-stylesheet type= "text/xsl" href="xsl_style.xsl"?><!--foo--><doc/>',
      'Comment before the root'
    );

  XML::Twig::Elt->new( '#COMMENT')->set_comment( 'bar')->paste( after => $doc->root);
  XML::Twig::Elt->new( '#PI')->set_target( 'foo')->set_data( 'bar')->paste( after => $doc->root);
  is( $doc->sprint, '<?xml-stylesheet type= "text/xsl" href="xsl_style.xsl"?><!--foo--><doc/><!--bar--><?foo bar?>',
      'Pasting things after the root'
    );

}

{ # adding comments or pi's before/after the root
  my $doc= XML::Twig->nparse( '<doc/>');
  $doc->add_stylesheet( xsl => 'xsl_style.xsl');
  is( $doc->sprint, '<?xml-stylesheet type="text/xsl" href="xsl_style.xsl"?><doc/>', 'add_stylesheet');
  eval{ $doc->add_stylesheet( foo => 'xsl_style.xsl') };
  matches( $@, q{^unsupported style sheet type 'foo'}, 'unsupported stylesheet type');
}

{ # creating a CDATA element
  my $elt1= XML::Twig::Elt->new( foo => { '#CDATA' => 1 }, '<&>');
  is( $elt1->sprint, '<foo><![CDATA[<&>]]></foo>', "creating a CDATA element");
  my $elt2= XML::Twig::Elt->new( foo => { '#CDATA' => 1, att => 'v1' }, '<&>');
  is( $elt2->sprint, '<foo att="v1"><![CDATA[<&>]]></foo>', "creating a CDATA element");
  eval { my $elt3= XML::Twig::Elt->new( foo => { '#CDATA' => 1 }, "bar", $elt1); };
  matches( $@, qr/^element #CDATA can only be created from text/, 
           "error in creating CDATA element");
  my $elt4= XML::Twig::Elt->new( foo => { '#CDATA' => 1 }, '<&>', 'bar');
  is( $elt4->sprint, '<foo><![CDATA[<&>bar]]></foo>', "creating a CDATA element (from list)");
  
}

{ # errors creating text/comment/pi elements
  eval { my $elt= XML::Twig::Elt->new( '#PCDATA', []); };
  matches( $@, qr/^element #PCDATA can only be created from text/, "error in creating PCDATA element");

  eval { my $elt= XML::Twig::Elt->new( '#COMMENT', "foo", []); };
  matches( $@, qr/^element #COMMENT can only be created from text/, "error in creating COMMENT element");

  eval { my $elt= XML::Twig::Elt->new( '#PI', "foo", [], "bah!"); };
  matches( $@, qr/^element #PI can only be created from text/, "error in creating PI element");

}

{ # set_cdata on non CDATA element
  my $elt = XML::Twig::Elt->new("qux");
  $elt->set_cdata("test this '<' & this '>'");
  is( $elt->sprint, q{<qux><![CDATA[test this '<' & this '>']]></qux>}, "set_cdata on non CDATA element");
}

{ # set_comment on non comment element
  my $elt = XML::Twig::Elt->new(qux => "toto");
  $elt->set_comment( " booh ");
  is( $elt->sprint, q{<!-- booh -->}, "set_comment on non comment element");
}

{ # set_pi on non pi element
  my $elt = XML::Twig::Elt->new(qux => "toto");
  $elt->set_pi( ta => "tie ramisu");
  is( $elt->sprint, q{<?ta tie ramisu?>}, "set_pi on non pi element");
}
