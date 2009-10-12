#!/usr/bin/perl -w
use strict;
use XML::Twig;

$/="\n\n";

print "1..3\n";

my $twig=XML::Twig->new( keep_spaces_in => [ 'e']);
test( $twig, 1);
$twig=XML::Twig->new( keep_spaces_in => [ 'e', 'sub1']);
test( $twig, 2);
$twig=XML::Twig->new( keep_spaces => 1);
test( $twig, 3);

sub test
  { my( $twig, $test_nb)= @_;
    my $doc= <DATA>; chomp $doc;
    my $expected_res= <DATA>; chomp $expected_res;


    $twig->parse( $doc);

    my $res= $twig->sprint; 
    $res=~ s/\n+$//;

    if( $res eq $expected_res)
      { print "ok $test_nb\n"; }
    else
      { print "not ok $test_nb\n";
        warn "  expected: \n$expected_res\n  result: \n$res\n";
      }
  }

exit 0;

__DATA__
<!DOCTYPE e SYSTEM "dummy.dtd">
<e> &c;b</e>

<!DOCTYPE e SYSTEM "dummy.dtd">
<e> &c;b</e>

<!DOCTYPE e SYSTEM "dummy.dtd">
<e><sub1> &c;b</sub1>
   <sub1> 
     &c;
   </sub1>
</e>

<!DOCTYPE e SYSTEM "dummy.dtd">
<e><sub1> &c;b</sub1>
   <sub1> 
     &c;
   </sub1>
</e>

<!DOCTYPE e SYSTEM "dummy.dtd">
<e><sub1> &c;b</sub1>
   <sub1> 
     &c;
   </sub1>
</e>

<!DOCTYPE e SYSTEM "dummy.dtd">
<e><sub1> &c;b</sub1>
   <sub1> 
     &c;
   </sub1>
</e>


