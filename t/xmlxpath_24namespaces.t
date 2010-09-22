#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

use Test;

if( defined $XML::XPathEngine::VERSION && $XML::XPathEngine::VERSION < 0.09)
  { print "1..1\nok 1\n"; 
    warn "cannot use set_namespace, needs XML::XPathEngine 0.09+ (installed version is $XML::XPathEngine::VERSION)\n"; 
    exit;
  }

plan( tests => 15);


my $t= XML::Twig::XPath->new->parse( *DATA);

my $node= $t->findvalue( '//attr:node/@attr:findme');
ok( $node, 'someval');

my @nodes;

# Do not set namespace prefixes - uses element context namespaces

@nodes = $t->findnodes('//foo:foo', $t); # should find foobar.com foos
ok( @nodes, 3);

@nodes = $t->findnodes('//goo:foo', $t); # should find no foos
ok( @nodes, 0);

@nodes = $t->findnodes('//foo', $t); # should find default NS foos
ok( @nodes, 2);

$node= $t->findvalue( '//*[@attr:findme]');
ok( $node, 'attr content');

# Set namespace mappings.


$t->set_namespace("foo" => "flubber.example.com");
$t->set_namespace("goo" => "foobar.example.com");

@nodes = $t->findnodes('//foo:foo', $t); # should find flubber.com foos
ok( @nodes, 2);

@nodes = $t->findnodes('//goo:foo', $t); # should find foobar.com foos
ok( @nodes, 3);

@nodes = $t->findnodes('//foo', $t); # should find default NS foos
ok( @nodes, 2);

ok( $t->findvalue('//attr:node/@attr:findme'), 'someval');

## added to test set_namespace
if( ! defined $XML::XPathEngine::VERSION )
  { my_skip( 5, "can only test set_strict_namespaces with XML::XPathEngine 0.09+ installed"); }
else
  { my $xml= '<root xmlns="http://example.com/">
                <node>
                   <foo>Node 1</foo>
                   <bar xmlns:ex="http://example.com/">
                      <ex:foo>Node 2</ex:foo>
                   </bar>
                </node>
             </root>
            ';
    {
      my $twig = XML::Twig::XPath->new();
      $twig->parse( $xml); 
      $twig->set_namespace('example','http://example.com/');
      $twig->set_strict_namespaces(1);
      my $v = $twig->findvalue('//foo');
      ok( $v, '', '//foo (strict_namespaces)');
      $twig->set_strict_namespaces(0);
      my $v1 = $twig->findvalue('//foo');
      ok( $v1, 'Node 1', '//foo (default behaviour)');
    }
    
    
    {
      my $twig = XML::Twig::XPath->new();
      $twig->set_namespace('example','http://example.com/');
      $twig->parse( $xml); 
    
      my $v = $twig->findvalue('//example:foo');
      ok( $v, 'Node 1Node 2', '//example:foo');
    }
    
    {
      my $twig = XML::Twig::XPath->new();
      $twig->parse( $xml); 
      my $v = $twig->findvalue('//foo');
      ok( $v, 'Node 1', '//foo');
    }
    
    {
      my $twig = XML::Twig::XPath->new();
      $twig->parse( $xml); 
      $twig->set_namespace('example','http://example.com/');
      my $v = $twig->findvalue('//foo');
      ok( $v, 'Node 1', '//foo (default behaviour)');
    }
  }

# added to test namespaces on attributes

{ 
  my $xml= '<root>
                <node xmlns:a="http://example.com/"><foo a:att="1">Node 1</foo></node>
                <node xmlns:a="http://notexample.com/"><foo a:att="1">Node 2</foo></node>
                <node xmlns:b="http://example.com/"><foo b:att="1">Node 3</foo></node>
                <node xmlns:b="http://notexample.com/"><foo b:att="1">Node 4</foo></node>
             </root>
            ';
  my $twig = XML::Twig::XPath->new();
  $twig->parse( $xml); 
  $twig->set_namespace('b','http://example.com/');
  ok( $twig->findvalue( '//*[@b:att]'), 'Node 1Node 3', 'namespaces on attributes');
}
 
{       
my %seen_message;
  sub my_skip
    { my( $nb_skip, $message)= @_;
      $message ||='';
      unless( $seen_message{$message})
        { warn "\n$message: skipping $nb_skip tests\n";
          $seen_message{$message}++;
        }
      for (1..$nb_skip) { ok( 1); }
    }
}

        
    
exit 0;

__DATA__
<xml xmlns:foo="foobar.example.com"
    xmlns="flubber.example.com">
    <foo>
        <bar/>
        <foo/>
    </foo>
    <foo:foo>
        <foo:foo/>
        <foo:bar/>
        <foo:bar/>
        <foo:foo/>
    </foo:foo>
    <attr:node xmlns:attr="attribute.example.com"
        attr:findme="someval">attr content</attr:node >
</xml>
