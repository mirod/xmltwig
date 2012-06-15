#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 14;


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

