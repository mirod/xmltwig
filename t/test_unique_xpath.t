#!/usr/bin/perl -w
use strict; 


use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

use XML::Twig;
print "1..65\n";

my $t= XML::Twig->new->parse( \*DATA);

foreach my $c ($t->descendants( 'c'))
  { is( $c->xpath, $c->text, "xpath"); 
    is( $t->findvalue( $c->text), $c->text, "findvalue (>0)"); 
  }
foreach my $d ($t->descendants( 'd'))
  { is( $t->findvalue( $d->text), $d->text, "findvalue (<0)"); }

foreach( 1..4)
  { is( $_, $t->root->first_child( "[$_]")->att( 'pos'), "first_child[$_]");
    is( 5-$_, $t->root->first_child( "[-$_]")->att( 'pos'), "first_child[-$_]");
    is( $_, $t->root->first_child( "b[$_]")->att( 'pos'), "first_child b[$_]");
    is( 5-$_, $t->root->first_child( "b[-$_]")->att( 'pos'), "first_child b[-$_]");
  }

my $e= $t->get_xpath( '/a/b[-1]/e', 0);
foreach( 1..4)
  { is( $_, $e->first_child( "f[$_]")->att( 'fpos'), "first_child f[$_]");
    is( 5-$_, $e->first_child( "f[-$_]")->att( 'fpos'), "first_child f[-$_]");
    is( $_, $e->first_child( "g[$_]")->att( 'gpos'), "first_child g[$_]");
    is( 5-$_, $e->first_child( "g[-$_]")->att( 'gpos'), "first_child g[-$_]");
  }

foreach( 1..8)
  { is( $_, $e->first_child( "[$_]")->att( 'pos'), "first_child [$_]");
    is( 9-$_, $e->first_child( "[-$_]")->att( 'pos'), "first_child [-$_]");
  }


exit 0;

__DATA__
<a>
  <b pos="1">
    <c>/a/b[1]/c[1]</c>
    <c>/a/b[1]/c[2]</c>
    <d>/a/b[-4]/d[-2]</d>
    <d>/a/b[-4]/d[-1]</d>
  </b>
  <b pos="2">
    <c>/a/b[2]/c[1]</c>
    <d>/a/b[-3]/d[-2]</d>
    <d>/a/b[-3]/d[-1]</d>
    <bar>tata</bar>
    <c>/a/b[2]/c[2]</c>
  </b>
  <b pos="3">
    <c>/a/b[3]/c</c>
  </b>
  <b pos="4">
    <baz>titi</baz>
    <c>/a/b[4]/c</c>
    <d>/a/b[4]/d[-1]</d>
    <foobar>tutu</foobar>
    <e>
      <f pos="1" fpos="1"/>
      <g pos="2" gpos="1"/>
      <f pos="3" fpos="2"/>
      <f pos="4" fpos="3"/>
      <g pos="5" gpos="2"/>
      <f pos="6" fpos="4"/>
      <g pos="7" gpos="3"/>
      <g pos="8" gpos="4"/>
    </e>
  </b>
</a>
