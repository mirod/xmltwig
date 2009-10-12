#!/usr/bin/perl -w

use strict;

use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;
use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;


BEGIN 
  { if( eval( 'require XML::Twig::XPath'))
      { import XML::Twig::XPath; }
    elsif( $@ =~ m{^cannot use XML::XPath or XML::XPathEngine})
      { print "1..1\nok 1\n"; warn no_xpath_engine();
        exit;
      }
    else
      { die $@; }
  }


print "1..75\n"; 

use XML::Twig::XPath;
ok(1, "loading");

{
my $t= XML::Twig::XPath->new->parse( '<doc>5</doc>');
is( $t->to_number->as_string, 5, "to_number");
}

{
my $t= XML::Twig::XPath->new->parse( '<doc><p>5</p></doc>');
is( $t->first_elt( 'p')->to_number->as_string, 5, "element to_number");
is( $t->getValue, 5, '$t->getValue');
}

{
my $t= XML::Twig::XPath->new->parse( '<doc><p>foo</p></doc>');
is( $t->first_elt( 'p')->to_number->as_string, "NaN", "to_number (NaN)");
}

{
my $t= XML::Twig::XPath->new->parse( '<doc><p>p1</p><foo>toto</foo><p>:p2</p>
                                           <s id="s1"><e>e1</e><e>:e2</e></s>
                                           <s id="s2"><e>e3</e><e>:e4</e></s>
                                      </doc>');
is( $t->findnodes_as_string( '//p'), '<p>p1</p><p>:p2</p>', "findnodes_as_string");
is( $t->root->findnodes_as_string( '//p'), '<p>p1</p><p>:p2</p>', "findnodes_as_string");
is( $t->root->findnodes_as_string( 'p'), '<p>p1</p><p>:p2</p>', "findnodes_as_string (from root)");

if( defined( $XML::XPathEngine::VERSION) ||
    ( $XML::XPath::VERSION && (($XML::XPath::VERSION  eq '1.13.1') || $XML::XPath::VERSION >= 1.13) )
  )
  { ok( $t->root->exists( '//p'), "exists //p (on root)");  
    ok( $t->exists( '//p'), "exists //p (on root)"); 
  }
else
  { skip( 2, "your version of XML::XPath has a bug in the 'exists' method, you cannot use it with XML::Twig::XPath"); }

my $p= $t->first_elt( 'p');
ok( $p->matches( 'p'), "\$p->matches( 'p')");
ok( $t->matches( '//p', $p), "\$p->matches( 'p') (from the twig)");
my $p2_set= $t->root->find( 'p[text()= ":p2"]');
is( $p2_set->size, 1, "find 1 node");
is( $p2_set->to_literal, ':p2', 'p2 text');
my $s_set= $t->find( '//s[e/text()= ":e2"]');
is( $s_set->size, 1, "find 1 s node (nodeset)");
my @s= $s_set->get_nodelist;
is( scalar @s, 1, "find 1 s node nodelist");
my $s= shift @s;
is( $s->getValue, 'e1:e2', 's text');
}

{
my $t= XML::Twig::XPath->new( pi => 'process', comments => 'process')
                       ->parse( '<doc><!-- comment --><p att="foo">text</p><?target pi?>
                                 <ns xmlns:foo="uri"><foo:bar foo:att="1">foobar</foo:bar></ns>
                                 </doc>');
nok( $t->isElementNode, '$t isElementNode');
nok( $t->isAttributeNode, '$t isAttributeNode');
nok( $t->isTextNode, '$t isTextNode');
nok( $t->isProcessingInstructionNode, '$t isProcessingInstructionNode');
nok( $t->isPINode, '$t isPINode');
nok( $t->isCommentNode, '$t isCommentNode');
nok( $t->isNamespaceNode, '$t isNamespaceNode');
ok( $t->getAttributes, '$t->getAttributes');

my $root= $t->root;
ok( $root->isElementNode, '$root isElementNode');
nok( $root->isAttributeNode, '$root isAttributeNode');
nok( $root->isTextNode, '$root isTextNode');
nok( $root->isProcessingInstructionNode, '$root isProcessingInstructionNode');
nok( $root->isPINode, '$root isPINode');
nok( $root->isCommentNode, '$root isCommentNode');
nok( $root->isNamespaceNode, '$root isNamespaceNode');


my $p= $t->first_elt( 'p');
ok( $p->isElementNode, '$p isElementNode');
nok( $p->isAttributeNode, '$p isAttributeNode');
nok( $p->isTextNode, '$p isTextNode');
nok( $p->isProcessingInstructionNode, '$p isProcessingInstructionNode');
nok( $p->isPINode, '$p isPINode');
nok( $p->isCommentNode, '$p isCommentNode');
nok( $p->isNamespaceNode, '$p isNamespaceNode');

my @att= $p->getAttributes;
my $att= shift @att;
is( $att->getName, 'att', '$att->getName');
is( $att->getValue, 'foo', '$att->getValue');
is( $att->toString, 'att="foo"', '$p attribute');
nok( $att->isElementNode, '$att isElementNode');
ok( $att->isAttributeNode, '$att isAttributeNode');
nok( $att->isTextNode, '$att isTextNode');
nok( $att->isProcessingInstructionNode, '$att isProcessingInstructionNode');
nok( $att->isPINode, '$att isPINode');
nok( $att->isCommentNode, '$att isCommentNode');
nok( $att->isNamespaceNode, '$att isNamespaceNode');

my $comment=$t->first_elt( '#COMMENT');
nok( $comment->isElementNode, '$comment isElementNode');
nok( $comment->isAttributeNode, '$comment isAttributeNode');
nok( $comment->isTextNode, '$comment isTextNode');
nok( $comment->isProcessingInstructionNode, '$comment isProcessingInstructionNode');
nok( $comment->isPINode, '$comment isPINode');
ok( $comment->isCommentNode, '$comment isCommentNode');
nok( $comment->isNamespaceNode, '$comment isNamespaceNode');

my $pi=$t->first_elt( '#PI');
nok( $pi->isElementNode, '$pi isElementNode');
nok( $pi->isAttributeNode, '$pi isAttributeNode');
nok( $pi->isTextNode, '$pi isTextNode');
ok( $pi->isProcessingInstructionNode, '$pi isProcessingInstructionNode');
ok( $pi->isPINode, '$pi isPINode');
nok( $pi->isCommentNode, '$pi isCommentNode');
nok( $pi->isNamespaceNode, '$pi isNamespaceNode');

is( $t->findvalue( '//foo:bar'), 'foobar', '//foo:bar');
is( $t->findvalue( '//*[@foo:att]'), 'foobar', '//*[@foo:att');
is( $t->findvalue( '//*[@foo:att=1]'), 'foobar', '//*[@foo:att=1]');
is( $t->findvalue( '//*[@foo:att=2]'), '', '//*[@foo:att=2]');

my $twig= ($root->findnodes( '..'))[0];
ok( UNIVERSAL::isa( $twig, 'XML::Twig'), 'findnodes returning the document node (' . ref( $twig) . ')');
my $back_to_root= ($root->findnodes( '../*'))[0];
is( $back_to_root->gi, 'doc' , 'findnodes returning the root through the document node');
}

# test namespace methods
{ my $ns= XML::Twig::XPath::Namespace->new( foo => "uri");
  ok( $ns->isNamespaceNode, '$ns isNamespaceNode');
  is( $ns->getPrefix, 'foo', 'getPrefix');
  is( $ns->getExpanded, 'uri', 'getExpanded');
  is( $ns->getValue, 'uri', 'getValue');
  is( $ns->getData, 'uri', 'getData');
}

# check that set_text works also with XML::Twig::XPath
{ my $elt= XML::Twig::XPath::Elt->new( p => "foo");
  $elt->set_text( "bar");
  ok( 1, "set_text using XML::Twig::XPath");
}

exit 0;

