#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 16;


{
  my $in= '<plant><flower>Rose</flower><fruit><berry>Blackberry</berry></fruit><veggie>Carrot</veggie></plant>';
  my $expected= '<plant><flower>Rose</flower><fruit><berry>Tomato</berry><berry>Blackberry</berry></fruit><veggie>Carrot</veggie></plant>';

  { my $t = XML::Twig->new( twig_handlers => { '//plant/fruit' => sub { XML::Twig::Elt->new( berry => 'Tomato')->paste( $_); }  })
                     ->parse( $in);
    is( $t->sprint, $expected, 'paste within handler from new element');
  }

  { my $t = XML::Twig->new( twig_handlers => { '//plant/fruit' => sub { XML::Twig->new->parse( '<berry>Tomato</berry>')->root->cut->paste( first_child => $_); }  })
                     ->parse( $in);
    is( $t->sprint, $expected, 'paste new element from twig within handler from parsed element (cut)');
  }
  { my $t = XML::Twig->new( twig_handlers => { '//plant/fruit' => sub { XML::Twig->new->parse( '<berry>Tomato</berry>')->root->paste( $_); }  })
                     ->parse( $in);
    is( $t->sprint, $in, 'paste new element from twig within handler from parsed element (non cut)');
  }
}

{ my $d='<d><f/><e>foo</e></d>';
  my $calls;
  XML::Twig->new( twig_roots => { f => 1 },
                  end_tag_handlers => { e     => sub { $calls .= ":e"; },
                                        'd/e' => sub { $calls .= "d/e" },
                                      },
                )
           ->parse( $d);
   is( $calls, 'd/e:e', 'several end_tag_handlers called');
  $calls='';
  XML::Twig->new( twig_roots => { f => 1 },
                  end_tag_handlers => { e     => sub { $calls .= ":e"; },
                                        'd/e' => sub { $calls .= "d/e"; return 0; },
                                      },
                )
           ->parse( $d);
   is( $calls, 'd/e', 'end_tag_handlers chain broken by false return');
}

{ my $d='<d><f><e>foo</e><g/></f></d>';
  my $calls;
  XML::Twig->new( twig_roots => { f => 1 },
                  ignore_elts => { e => 1 },
                  end_tag_handlers => { e     => sub { $calls .= ":e"; },
                                        'f/e' => sub { $calls .= "f/e" },
                                      },
                )
           ->parse( $d);
   is( $calls, 'f/e:e', 'several end_tag_handlers called with ignore_elts active');
  $calls='';
  XML::Twig->new( twig_roots => { f => 1 },
                  ignore_elts => { e => 1 },
                  end_tag_handlers => { e     => sub { $calls .= ":e"; },
                                        'f/e' => sub { $calls .= "f/e"; return 0; },
                                      },
                )
           ->parse( $d);
   is( $calls, 'f/e', 'end_tag_handlers chain with ignore_elts active broken by false return');
}

is( XML::Twig->parse( '<d/>')->encoding, undef, 'encoding, no xml declaration');
is( XML::Twig->parse( '<?xml version="1.0"?><d/>')->encoding, undef, 'encoding, xml declaration but no encoding given');
is( XML::Twig->parse( '<?xml version="1.0" encoding="utf-8"?><d/>')->encoding, 'utf-8', 'encoding, encoding given');

is( XML::Twig->parse( '<d/>')->standalone, undef, 'standalone, no xml declaration');
is( XML::Twig->parse( '<?xml version="1.0"?><d/>')->standalone, undef, 'standalone, xml declaration but no standalone bit');
ok( XML::Twig->parse( '<?xml version="1.0" standalone="yes"?><d/>')->standalone, 'standalone, yes');
ok( ! XML::Twig->parse( '<?xml version="1.0" standalone="no"?><d/>')->standalone, 'standalone, no');

{
  XML::Twig::_set_weakrefs(0);
  my $t= XML::Twig->parse( '<d><e/><e><f/><f/></e><e/></d>');
  $t->root->first_child( 'e')->next_sibling( 'e')->erase;
  is( $t->sprint, '<d><e/><f/><f/><e/></d>', 'erase without weakrefs');
  XML::Twig::_set_weakrefs(1)
}

{
my $doc='<ns1:list xmlns:ns1="http://namespace/CommandService" xmlns:ns2="http://namespace/ShelfService" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <commands>
    <commandId>1</commandId>
    <command xsi:type="ns2:find">
      <equipmentFilter>...</equipmentFilter>
    </command>
  </commands>
  <commands>
    <commandId>2</commandId>
    <command xsi:type="ns2:getByName">
      <name>...</name>
    </command>
  </commands>
</ns1:list>
';

my $expected= $doc;
$expected=~ s{ns1}{cmdsvc}g;
$expected=~ s{ns2}{shlsvc}g;

my %map= reverse ( cmdsvc => "http://namespace/CommandService",
                   shlsvc => "http://namespace/ShelfService",
                   xsi    => "http://www.w3.org/2001/XMLSchema-instance",
                 );

my $x = XML::Twig->new( map_xmlns => { %map }, 
                        twig_handlers => { '*[@xsi:type]' => sub { upd_xsi_type( @_, \%map) } },
                        pretty_print => "indented"
                      );
$x->parse($doc);

is( $x->sprint, $expected, 'original_uri');

sub upd_xsi_type
  { my( $t, $elt, $map)= @_;
    my $type= $elt->att( 'xsi:type');
    my( $old_prefix)= $type=~ m{^([^:]*):}; 
    if( my $new_prefix=  $map->{$t->original_uri( $old_prefix)})
      { $type=~ s{^$old_prefix}{$new_prefix}; 
        $elt->set_att( 'xsi:type' => $type);
      }
    return 1; # to make sure other handlers are called
  }
    
}
