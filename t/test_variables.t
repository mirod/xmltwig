#!/usr/bin/perl -w
use strict;
use XML::Twig;

$|=1;

print "1..6\n";
#warn "\n\n### warnings are normal here ###\n\n";

my $t= XML::Twig->new->parse( \*DATA);

# intercept warnings
$SIG{__WARN__} = sub { print STDERR @_ if( $_[0]=~ /^test/); };


my $s= $t->simplify( var_attr => 'var', variables => { 'v2' => 'elt2'});
if( $s->{elt2} eq 'elt using elt1') { print "ok 1\n" }
else { print "not ok 1\n"; warn "test 1: /$s->{elt2}/ instead of 'elt using elt1'\n"; }
if( $s->{elt3} eq 'elt using elt1') { print "ok 2\n" }
else { print "not ok 2\n"; warn "test 2: /$s->{elt3}/ instead of 'elt using elt1'\n"; }
if( $s->{elt4} eq 'elt using elt2') { print "ok 3\n"; warn "\n"; }
else { print "not ok 3\n"; warn "test 3: /$s->{elt4}/ instead of 'elt using elt2'\n"; }
if( $s->{elt5}->{att1} eq 'att with elt1') { print "ok 4\n" }
else { print "not ok 4\n"; warn "test 4: /$s->{elt5}->{att1}/ instead of 'att with elt1'\n"; }


$s= $t->simplify( variables => { 'v2' => 'elt2'});
if( $s->{elt2} eq 'elt using $v1') { print "ok 5\n" }
else { print "not ok 5\n"; warn "test 5: /$s->{elt2}/ instead of 'elt using \$v1'\n"; }
if( $s->{elt4} eq 'elt using elt2') { print "ok 6\n" }
else { print "not ok 6\n"; warn "test 6: /$s->{elt4}/ instead of 'elt using elt2'\n"; }

exit 0;

__DATA__
<doc>
  <elt1 var="v1">elt1</elt1>
  <elt2>elt using $v1</elt2>
  <elt3>elt using ${v1}</elt3>
  <elt4>elt using $v2</elt4>
  <elt5 att1="att with $v1"/>
</doc>
