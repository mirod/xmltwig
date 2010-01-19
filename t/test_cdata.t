#!/usr/bin/perl -w
use strict;


use XML::Twig;

$|=1;

$/= "\n\n"; 
my $xml= <DATA>;

print "1..4\n";

my( $t, $result, $expected_result);

$t= XML::Twig->new( twig_handlers => { 'ehtml/#CDATA' => sub { $_->set_asis; } });
$t->parse( $xml);
$result= $t->sprint;
($expected_result=<DATA>)=~ s{\n*$}{}s; 
if( $result eq $expected_result) { print "ok 1\n"; }
else { print "not ok 1\n"; warn "expected: $expected_result\n result  : $result"; }

$t= XML::Twig->new( twig_handlers => { 'ehtml/#CDATA' => sub { $_->remove_cdata; } });
$t->parse( $xml);
$result= $t->sprint;
($expected_result=<DATA>)=~ s{\n*$}{}s; 
if( $result eq $expected_result) { print "ok 2\n"; }
else { print "not ok 2\n"; warn "expected: $expected_result\n result  : $result"; }

$t= XML::Twig->new( keep_encoding => 1, twig_handlers => { 'ehtml/#CDATA' => sub { $_->set_asis; } });
$t->parse( $xml);
$result= $t->sprint;
($expected_result=<DATA>)=~ s{\n*$}{}s; 
if( $result eq $expected_result) { print "ok 3\n"; }
else { print "not ok 3\n"; warn "test keep_encoding / asis\n  expected: $expected_result\n  result  : $result"; }

$t= XML::Twig->new( keep_encoding => 1, twig_handlers => { 'ehtml/#CDATA' => sub { $_->remove_cdata; } });
$t->parse( $xml);
$result= $t->sprint;
($expected_result=<DATA>)=~ s{\n*$}{}s; 
if( $result eq $expected_result) { print "ok 4\n"; }
else { print "not ok 4\n"; warn "test keep_encoding / remove_cdata\n  expected: $expected_result\n  result  : $result"; }

exit 0;

__DATA__
<doc>
  <elt>text</elt>
  <ehtml><![CDATA[hello<br>world & all]]></ehtml>
</doc>

<doc><elt>text</elt><ehtml>hello<br>world & all</ehtml></doc>

<doc><elt>text</elt><ehtml>hello&lt;br>world &amp; all</ehtml></doc>

<doc><elt>text</elt><ehtml>hello<br>world & all</ehtml></doc>

<doc><elt>text</elt><ehtml>hello&lt;br>world &amp; all</ehtml></doc>

