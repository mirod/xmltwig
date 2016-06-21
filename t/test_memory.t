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

my $long_test= $ARGV[0] && $ARGV[0] eq '-L';

my $conf= $long_test ? { iter => 10, p => 1000 }
                     : { iter => 5, p =>  500 }
                                       ;
$conf->{normal}= $conf->{p} * $conf->{iter};
$conf->{normal_html}= $conf->{normal} * 2;

my $TMAX=6;
print "1..$TMAX\n";

my $warn=0;

my $paras=  join '', map { qq{<p>lorem ipsus whatever <i id="i$_">(clever latin stuff) no $_</i></p>}} 1..$conf->{p};

my $test_nb=1;

foreach my $wr (0..1)
{
  # first pass if with weakrefs, second without
  my $wrm='';
  if( $wr)
    { XML::Twig::_set_weakrefs( 0);
      $wrm= " (no weak references)";
    }

    { my $xml= qq{<doc>$paras</doc>};
      XML::Twig->new->parse( $xml);
      my $before= mem_size();
      for (1..$conf->{iter}) 
        { my $t= XML::Twig->new->parse( $xml); 
          if( $wr) 
            { really_clear( $t) } 
        }
      my $after= mem_size();
      if( $after - $before > $conf->{normal})
         { warn "test $test_nb: possible memory leak parsing xml ($after > $before)$wrm"; $warn++; } 
      elsif( $long_test) 
         { warn "$before => $after\n"; }
      ok(1, "testing memory leaks for xml parsing$wrm");
      $test_nb++;
    } 
    
    { if( XML::Twig::_use( 'HTML::TreeBuilder', 3.13))
        { my $html= qq{<html><head><title>with HTB</title></head><body>$paras</body></html>};
          XML::Twig->new->parse_html( $html);
          my $before= mem_size();
          for (1..$conf->{iter}) { XML::Twig->new->parse_html( $html); }
          my $after= mem_size();
          if( $after - $before > $conf->{normal_html})
             { warn "test $test_nb: possible memory leak parsing html ($after > $before)$wrm"; $warn++; } 
          elsif( $long_test) 
             { warn "$before => $after\n"; }
          ok(1, "testing memory leaks for html parsing$wrm");
        }
      else
        { skip( 1, "need HTML::TreeBuilder 3.13+"); }
      $test_nb++;
    }
    
    { if( XML::Twig::_use( 'HTML::Tidy'))
        { my $html= qq{<html><head><title>with tidy</title></head><body>$paras</body></html>};
          XML::Twig->new( use_tidy => 1)->parse_html( $html);
          my $before= mem_size();
          for (1..$conf->{iter}) { XML::Twig->new( use_tidy => 1)->parse_html( $html); }
          my $after= mem_size();
          if( $after - $before > $conf->{normal_html})
             { warn "test $test_nb: possible memory leak parsing html ($after > $before)$wrm"; $warn++; } 
          elsif( $long_test) 
             { warn "$before => $after\n"; }
          ok(1, "testing memory leaks for html parsing using HTML::Tidy$wrm");
        }
      else
        { skip( 1, "need HTML::Tidy"); }
      $test_nb++;
    }
   
  } 
    
if( $warn)
  { warn "\nnote that memory leaks can happen even if the module itself doesn't leak, if running",
         "\ntests under Devel::Cover for example. So do not panic if you get a warning here.\n";
  }



sub mem_size
  { open( STATUS, "/proc/$$/status") or return;
    my( $size)= map { m{^VmSize:\s+(\d+\s+\w+)} } <STATUS>;
    $size=~ s{ kB}{};
    #warn "data size found: $size\n";
    return $size;
  }

sub really_clear
  { my( $t)= shift; 
    my $elt= $t->root->DESTROY; 
    delete $t->{twig_dtd};
    delete $t->{twig_doctype};
    delete $t->{twig_xmldecl};
    delete $t->{twig_root};
    delete $t->{twig_parser};

    return;

    local $SIG{__WARN__} = sub {};
    
    while( $elt) 
      { my $nelt= nelt( $elt); 
        $elt->del_id( $t);
        foreach ( qw(gi att empty former)) { undef $elt->{$_}; delete $elt->{$_}; }
        $elt->delete; 
        $elt= $nelt; 
      }
    $t->dispose; 
  }

    
sub nelt
  { my( $elt)= @_;
    if( $elt->_first_child)  { return deepest_child( $elt); }
    if( $elt->_next_sibling) { return deepest_child( $elt->_next_sibling); }
    return $elt->parent;
  }

sub deepest_child
  { my( $elt)= @_;
    while( $elt->_first_child) { $elt= $elt->_first_child; }
    return $elt;
  }
