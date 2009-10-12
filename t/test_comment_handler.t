#!/usr/bin/perl -w
use strict;
use Carp;

# test for the various conditions in navigation methods

use XML::Twig;

my $nb_tests=4;
print "1..$nb_tests\n";

my $result;
my $t= XML::Twig->new( comments => 'process',
                       twig_handlers => { '#COMMENT' => sub { $result .=$_->text; } },
                     );
$t->parse( q{<doc id="doc"><!-- comment in doc --></doc>});
my $expected= ' comment in doc ';
if( $result eq $expected)
  { print "ok 1\n"; }
else
  { print "not ok 1\n";
    warn "expected: $expected\nfound   : $result\n";
  }

$result='';
$t= XML::Twig->new( comments => 'process',
                       twig_handlers => { '#COMMENT' => sub { $result .=$_->text; } },
                     );
$t->parse( q{<!-- comment in doc --><doc id="doc"></doc>});
$expected= ' comment in doc ';
if( $result eq $expected)
  { print "ok 2\n"; }
else
  { print "not ok 2\n";
    warn "expected: $expected\nfound   : $result\n";
  }

$result='';
$t= XML::Twig->new( twig_handlers => { 'doc' => sub { $result= $_->{extra_data}; } },);
$t->parse( q{<!-- comment in doc --><doc id="doc"></doc>});
$expected= '<!-- comment in doc -->';
if( $result eq $expected)
  { print "ok 3\n"; }
else
  { print "not ok 3\n";
    warn "expected: $expected\nfound   : $result\n";
  }


$result='';
$t= XML::Twig->new( comments => 'process',
                    twig_roots => { '/#COMMENT' => sub { $result= $_->{extra_data}; },
                                    elt         => sub { },
                                  });
$t->parse( q{<!-- comment in doc --><doc id="doc"><elt/></doc>});
$expected= '';  # This is a bug!
if( $result eq $expected)
  { print "ok 4\n"; }
else
  { print "not ok 4\n";
    warn "expected: $expected\nfound   : $result\n";
  }
exit 0;

