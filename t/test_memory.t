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

# only display warnings, test is too unreliable (especially under Devel::Cover) to trust

my $mem_size= mem_size();

unless( $mem_size)
  { print "1..1\nok 1\n";
    warn "skipping: memory size not available\n";;
    exit;
  }

if( !XML::Twig::_weakrefs())
  {  print "1..1\nok 1\n";
    warn "skipping: weaken not available\n";;
    exit;
  }


my $TMAX=3;
print "1..$TMAX\n";

my $warn=0;

{ my $xml= qq{<doc>} . qq{<p>lorem ipsus whatever (clever latin stuff)</p>} x 100 .qq{</doc>};
  XML::Twig->new->parse( $xml);
  my $before= mem_size();
  for (1..10) { XML::Twig->new->parse( $xml); mem_size(); }
  my $after= mem_size();
  if( $after - $before > 1000)
     { warn "possible memory leak parsing xml ($after > $before)"; $warn++; } 
  ok(1, "testing memory leaks for xml parsing");
}

{ if( XML::Twig::_use( 'HTML::TreeBuilder', 3.13))
    { my $html= qq{<html><body>} . qq{<p>lorem ipsus whatever (clever latin stuff)</p>} x 500 .qq{</body></html>};
      XML::Twig->new->parse_html( $html);
      my $before= mem_size();
      for (1..5) { XML::Twig->new->parse_html( $html); mem_size(); }
      my $after= mem_size();
      if( $after - $before > 1000)
         { warn "possible memory leak parsing html ($after > $before)"; $warn++; } 
      ok(1, "testing memory leaks for html parsing");
    }
  else
    { skip( 1, "need HTML::TreeBuilder 3.13+"); }
}

{ if( XML::Twig::_use( 'HTML::Tidy'))
    { my $html= qq{<html><body>} . qq{<p>lorem ipsus whatever (clever latin stuff)</p>} x 500 .qq{</body></html>};
      XML::Twig->new( use_tidy => 1)->parse_html( $html);
      my $before= mem_size();
      for (1..5) { XML::Twig->new( use_tidy => 1)->parse_html( $html); mem_size(); }
      my $after= mem_size();
      if( $after - $before > 1000)
         { warn "possible memory leak parsing html ($after > $before)"; $warn++; } 
      ok(1, "testing memory leaks for html parsing using HTML::Tidy");
    }
  else
    { skip( 1, "need HTML::Tidy"); }
}


if( $warn)
  { warn "\nnote that memory leaks can happen even if the module itself doesn't leak, if running",
         "\ntests under Devel::Cover for exemple. So do not panic if you get a warning here.\n";
  }

sub mem_size
  { open( STATUS, "/proc/$$/status") or return;
    my( $size)= map { m{^VmSize:\s+(\d+\s+\w+)} } <STATUS>;
    $size=~ s{ kB}{};
    #warn "data size found: $size\n";
    return $size;
  }


