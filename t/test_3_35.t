#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=10;
print "1..$TMAX\n";

# escape_gt option
{
is( XML::Twig->parse( '<d/>')->root->insert_new_elt( '#COMMENT' => '- -- -')->twig->sprint,
    '<d><!-- - - - - --></d>', 'comment escaping');
}

{ my $t=  XML::Twig->parse( '<d><e a="c">foo<e>bar</e></e><e a="b">baz<e>foobar</e></e><e a="b">baz2<e a="c">foobar2</e></e></d>');
  $t->root->cut_descendants( 'e[@a="c"]');
  is( $t->sprint, '<d><e a="b">baz<e>foobar</e></e><e a="b">baz2</e></d>', 'cut_descendants');
}

{ my $t=XML::Twig->new( pretty_print => 'none')->parse( '<d />');
  is( $t->root->_pretty_print, 0, '_pretty_print');
  $t->set_pretty_print( 'indented');
  is( $t->root->_pretty_print, 3, '_pretty_print');
}

# additional tests to increase coverage
{ is( XML::Twig->parse( no_expand => 1, q{<!DOCTYPE d SYSTEM "dd.dtd" [<!ENTITY foo SYSTEM "x.xml">]><d>&foo;</d>})->root->sprint, "<d>&foo;</d>\n", 'external entities with no_expand');
}

{ my $doc= q{<d id="i1"><e id="i2"><f id="i3"/></e><g><f id="i4">fi4</f></g></d>};
  open( my $fh, '>', 'tmp_file'); 
  my $t= XML::Twig->new( twig_handlers => { e => sub { $_->flush( $fh); },
                                            g => sub { is( $_[0]->elt_id( 'i4')->text, 'fi4', 'elt_id, id exists'); 
                                                       nok(  $_[0]->elt_id( 'i3'), 'elt_id, id flushed');
                                                     },
                                          }
                       )
                  ->parse( $doc);
}

{ my $xpath='';
  XML::Twig->parse( map_xmlns => { "http://foo.com" => 'bar' }, 
                    twig_handlers => { "bar:e" => sub { $xpath= $_[0]->path( $_->gi);}, },
                    q{<foo:d xmlns:foo="http://foo.com"><foo:e/></foo:d>}
                  );
  is( $xpath, '/bar:d/bar:e');
  XML::Twig->parse( map_xmlns => { "http://foo.com" => 'bar' }, 
                    twig_handlers => { "bar:e" => sub { $xpath= $_[0]->path( $_->local_name);}, },
                    q{<d xmlns="http://foo.com"><e/></d>}
                  );
  is( $xpath, '/bar:d/bar:e');
}

{ my $t=XML::Twig->parse( pretty_print => 'none', '<d><e1/><e2/><e3/></d>');
  $t->first_elt( 'e3')->replace( $t->first_elt( 'e1'));
  is( $t->sprint, '<d><e3/><e2/></d>', 'replace called on an element that has not been cut yet');
}
1;
