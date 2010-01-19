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


my $TMAX=13;
print "1..$TMAX\n";

unless( XML::Twig::_use( 'Text::Wrap')) { print "1..1\nok 1\n"; warn "skipping: Text::Wrap not available\n"; exit; }

while( my $doc= get_doc())
  { my $result= XML::Twig->nparse( pretty_print => 'wrapped', $doc)->sprint;
    my $expected= get_doc();
    foreach ($result, $expected) { s{ }{.}g; }
    is( $result, $expected, '');
  }

XML::Twig::Elt->set_wrap(0);
is( XML::Twig::Elt->set_wrap(1), 0, "set_wrap - 1");
is( XML::Twig::Elt->set_wrap(1), 1, "set_wrap - 2");
is( XML::Twig::Elt->set_wrap(0), 1, "set_wrap - 3");
is( XML::Twig::Elt->set_wrap(0), 0, "set_wrap - 4");

is( XML::Twig::Elt::set_wrap(1), 0, "set_wrap - 5");
is( XML::Twig::Elt::set_wrap(1), 1, "set_wrap - 6");
is( XML::Twig::Elt::set_wrap(0), 1, "set_wrap - 7");
is( XML::Twig::Elt::set_wrap(0), 0, "set_wrap - 8");

sub get_doc
  { local $/="\n\n";
    my $doc= <DATA>;
    if( $doc)
      { $doc=~ s{\n\n}{\n};
        $doc=~ s/\{([^}]*)\}/$1/eeg;
      }
    return $doc;
  }


__DATA__
<doc><elt>{"foo" x 40}</elt></doc>

<doc>
  <elt>foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo
    foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo</elt>
</doc>

<doc><elt>{"foo" x 80}</elt></doc>

<doc>
  <elt>foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo
    foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofo
    ofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoof
    oofoofoofoofoofoofoofoofoofoofoo</elt>
</doc>

<doc><section><elt>{"foo" x 40}</elt></section></doc>

<doc>
  <section>
    <elt>foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoof
      oofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo</elt>
  </section>
</doc>

<doc>
  <elt att="foo">{"foo " x 40}</elt>
  <elt att="bar">{"bar " x 40}</elt>
</doc>

<doc>
  <elt att="foo">foo foo foo foo foo foo foo foo foo foo foo foo foo foo
    foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo
    foo foo foo foo foo foo foo foo </elt>
  <elt att="bar">bar bar bar bar bar bar bar bar bar bar bar bar bar bar
    bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar
    bar bar bar bar bar bar bar bar </elt>
</doc>

<doc>
  <elt att="foo">{"foo " x 40}{ "aaa" x 60}{ "foo "x20 }</elt>
  <elt att="bar">{"bar " x 40}</elt>
</doc>

<doc>
  <elt att="foo">foo foo foo foo foo foo foo foo foo foo foo foo foo foo
    foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo
    foo foo foo foo foo foo foo foo
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaafoo foo foo foo foo foo foo foo
    foo foo foo foo foo foo foo foo foo foo foo foo </elt>
  <elt att="bar">bar bar bar bar bar bar bar bar bar bar bar bar bar bar
    bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar bar
    bar bar bar bar bar bar bar bar </elt>
</doc>
