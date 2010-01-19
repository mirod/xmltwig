#!/usr/bin/perl -w
use strict;

use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

use XML::Twig;

my $DEBUG=0;
print "1..44\n";

{ # test tag regexp handler
  my @res;
  my $doc=q{<doc><foo_f1/><foo_f2/><foo_f1/><foo_f3/><afoo_f1/><FOO_f4/></doc>};
  my $handlers= { qr/^foo_/ => sub { push @res, $_->tag; },
                  foo_f2    => sub { push @res, uc $_->tag; 0 },
                };
  my $expected= 'foo_f1:FOO_F2:foo_f1:foo_f3';
  XML::Twig->new( twig_handlers => $handlers)->parse( $doc);
  my $res= join( ':', @res);
  is( $res, $expected, "tag regexp handlers");
}

{ # test tag regexp handler with i modifier
  my @res;
  my $doc=q{<doc><foo_f1/><foo_f2/><foo_f1/><foo_f3/><afoo_f1/><FOO_f4/></doc>};
  my $handlers= { qr/^foo_/i => sub { push @res, $_->tag; },
                  foo_f2     => sub { push @res, uc $_->tag; 0 },
                };
  my $expected= 'foo_f1:FOO_F2:foo_f1:foo_f3:FOO_f4';
  XML::Twig->new( twig_handlers => $handlers)->parse( $doc);
  my $res= join( ':', @res);
  is( $res, $expected, "tag regexp handlers");
}

{ # test tag regexp handler with all modifier
  my @res;
  my $doc=q{<doc><foo_f1/><foo_f2/><foo_f1/><foo_f3/><afoo_f1/><FOO_f4/></doc>};
  my $handlers= { qr/^foo_/xism => sub { push @res, $_->tag; },
                  foo_f2     => sub { push @res, uc $_->tag; 0 },
                };
  my $expected= 'foo_f1:FOO_F2:foo_f1:foo_f3:FOO_f4';
  XML::Twig->new( twig_handlers => $handlers)->parse( $doc);
  my $res= join( ':', @res);
  is( $res, $expected, "tag regexp handlers");
}


{ # testing last_descendant
  my $t= XML::Twig->new->parse( '<doc id="doc">
                                   <e3 id="e3">t_e_3</e3>
                                   <e4 id="e4" />
                                   <e id="e1">t_e_1</e>
                                   <e id="e2">t_e_2<n id="n1">t_n</n></e>
                                 </doc>
                                '
                              );
  my %exp2id= ( ''            => 't_n',
                'n'           => 'n1',
                '#ELT'        => 'n1',
                'e'           => 'e2',
                'e[@id="e1"]' => 'e1',
                'e2'          => undef,
              );
  foreach my $exp (sort keys %exp2id)
    { my $expected= $exp2id{$exp};
      is( result( $t->last_elt( $exp)), $expected, "last_elt( $exp)");
      is( result( $t->root->last_descendant( $exp)), $expected, "last_descendant( $exp)");
    }

  # some more tests to check that we stay in te subtree and that we get the last descendant if it is itself
  is( result( $t->last_elt( 'e3')), 'e3', 'last_elt( e3)');
  is( result( $t->root->last_descendant( 'e3')), 'e3', 'last_descendant( e3)');
  is( result( $t->root->first_child( 'e3')->last_descendant( 'e3')), 'e3', 'last_descendant( e3) (on e3)');
  is( result( $t->root->first_child( 'e3')->last_descendant()), 't_e_3', 'last_descendant() (on e3)');
  is_undef( $t->root->last_child->last_descendant( 'e3'), 'last_descendant (no result)');

  is( result( $t->root->first_child( 'e4')->last_descendant( 'e4')), 'e4', 'last_descendant( e4) (on e4)');
  is( result( $t->root->first_child( 'e4')->last_descendant( )), 'e4', 'last_descendant( ) (on e4)');

  sub result
    { my( $elt)= @_;
      return undef unless $elt;
      return $elt->id || $elt->text;
    }
}        

{# testing trim
  my $expected;
  while( <DATA>)
    { chomp;
      next unless( m{\S});
      if( s{^#}{}) { $expected= $_; }
      is( XML::Twig->new->parse( $_)->trim->root->sprint, $expected, "trimming '$_'");
    }
}

{ # testing children_trimmed_text
  my $t = XML::Twig->new; 
  $t->parse("<o><e> hell </e><i> foo </i><e> o, \n   world</e></o>"); 
  is( join( ':', $t->root->children_trimmed_text("e")), "hell:o, world" , "children_trimmed_text (list context)");
  my $scalar= $t->root->children_trimmed_text("e");
  is( $scalar, "hello, world" , "children_trimmed_text (scalar context)");
  is( join( ':', $t->root->children_text("e")), " hell : o, \n   world" , "children_text (list context)");
  $scalar= $t->root->children_text("e");
  is( $scalar, " hell  o, \n   world" , "children_text (scalar context)");
}


__DATA__
#<doc>text1 text2</doc>
<doc>  text1 text2</doc>
<doc>   text1 text2</doc>
<doc>text1 text2 </doc>
<doc>text1 text2  </doc>
<doc>text1 text2   </doc>
<doc>text1  text2</doc>
<doc> text1  text2 </doc>
<doc>  text1   text2  </doc>

#<doc>text1 <e>text2</e> text3</doc>
<doc>text1  <e>text2</e> text3 </doc>


#<doc>text1 <e> text2 </e> text3</doc>
<doc>text1  <e>  text2  </e>  text3 </doc>

#<doc><![CDATA[text1 text2]]></doc>
<doc> <![CDATA[text1  text2]]> </doc>
<doc><![CDATA[ text1  text2 ]]></doc>

#<doc>text <b> hah! </b> yep</doc>
<doc>  text <b>  hah! </b>  yep</doc>
