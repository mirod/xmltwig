#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=17;
print "1..$TMAX\n";

my $d= '<d/>';

{ my $r= XML::Twig->parse( $d)->root;
  my $result = $r->att('a');
  is( $r->sprint, $d, 'att');
}


{ my $r= XML::Twig->parse( $d)->root;
  my $result = foo($r->att('a'));
  is( $r->sprint, $d, 'att in sub(1)');
}

{ my $r= XML::Twig->parse( $d)->root;
  my $result = sub { return @_ }->($r->att('a'));
  is( $r->sprint, $d, 'att in anonymous sub');
}

{ my $r= XML::Twig->parse( $d)->root;
  my $a= $r->att( 'a');
  is( $r->sprint, $d, 'att in scalar context');
}

{ my $r= XML::Twig->parse( $d)->root;
  my( $a1, $a2)= ($r->att( 'a1'), $r->att( 'a2'));
  is( $r->sprint, $d, 'att in list context');
}

{ my $r= XML::Twig->parse( $d)->root;
  $r->att( 'a');
  is( $r->sprint, $d, 'att in void context');
}

{ my $r= XML::Twig->parse( $d)->root;
  my $result = $r->att('a');
  is( $r->sprint, $d, 'att');
}


{ my $r= XML::Twig->parse( $d)->root;
  my $result = foo($r->class);
  is( $r->sprint, $d, 'class in sub(1)');
}

{ my $r= XML::Twig->parse( $d)->root;
  my $result = sub { return @_ }->($r->class);
  is( $r->sprint, $d, 'att in anonymous sub');
}

{ my $r= XML::Twig->parse( $d)->root;
  my $a= $r->class;
  is( $r->sprint, $d, 'class in scalar context');
}

{ my $r= XML::Twig->parse( $d)->root;
  my( $a1, $a2)= ($r->class, $r->class);
  is( $r->sprint, $d, 'class in list context');
}

{ my $r= XML::Twig->parse( $d)->root;
  $r->class;
  is( $r->sprint, $d, 'class in void context');
}

{ my $t= XML::Twig->new->parse( '<d/>');
  $t->root->latt( 'a')= 1; 
  is( $t->sprint, '<d a="1"/>', 'latt');
}

{ my $r= XML::Twig->parse( $d)->root;
  my $att= $r->att( 'foo');
  is( $att, undef, 'unexisting att');
}


#  my $value = $root->att('any_attribute');
#  $result = length($value);

sub foo { return @_; }

{
my $r;
my $doc='<d><_e id="e1"><foo _a="2" id="bar"/></_e><_e id="e2"><_foo a="2" id="foo"/></_e></d>';
my $t= XML::Twig->new( twig_handlers => { _e => sub { $r.= $_->id } })
                ->parse( $doc);
is( $r, 'e1e2', 'handler, condition on tag starting with an underscore');
is( $t->first_elt( '_foo')->id, 'foo', 'navigation, element name starts with underscore'); 
is( $t->first_elt( '*[@_a="2"]')->id, 'bar', 'navigation, attribute name starts with underscore'); 
}

1;
