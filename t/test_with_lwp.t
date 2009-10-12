#!/usr/bin/perl -w

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;


$|=1;

use XML::Twig;

eval { require LWP; };
if( $@) { import LWP; print "1..1\nok 1\n"; warn "skipping, LWP not available\n"; exit }

# skip on Win32, it looks like we have a problem there (named pipes?)
if( ($^O eq "MSWin32") && ($]<5.008) ) { print "1..1\nok 1\n"; warn "skipping, *parseurl methods not available on Windows with perl < 5.8.0\n"; exit }

if( perl_io_layer_used())
    { print "1..1\nok 1\n"; 
      warn "cannot test parseurl when UTF8 perIO layer used (due to PERL_UNICODE or -C option used)\n";
      exit;
    }

my $TMAX=13; 

chdir 't';

print "1..$TMAX\n";

{ my $t= XML::Twig->new->parseurl( 'file:test_with_lwp.xml', LWP::UserAgent->new);
  is( $t->sprint, '<doc><elt>text</elt></doc>', "parseurl");
}

{
my $t= XML::Twig->new->parseurl( 'file:test_with_lwp.xml');
is( $t->sprint, '<doc><elt>text</elt></doc>', "parseurl");
}

{
my $t= XML::Twig->new->safe_parseurl( 'file:test_with_lwp.xml');
is( $t->sprint, '<doc><elt>text</elt></doc>', "parseurl");
}

{
warn "\n\n### warning is normal here ###\n\n";
my $t=0;
if ($^O ne 'VMS')
  { # On VMS we get '%SYSTEM-F-ABORT, abort' and an exit when a file does not exist
    # Behaviour is probably different on VMS due to it not having 'fork' to do the
    # LWP::UserAgent request and (safe) parse of that request not happening in a child process.
    $t = XML::Twig->new->safe_parseurl( 'file:test_with_lwp_no_file.xml');
    ok( !$t, "no file");
    matches( $@, '^\s*(no element found|Ran out of memory for input buffer)', "no file, error message");
  }
else
  { skip( 2 => "running on VMS, cannot test error message for non-existing file"); }
}

{
my $t= XML::Twig->new->safe_parseurl( 'file:test_with_lwp_not_wf.xml');
ok( !$t, "not well-formed");
matches( $@, '^\s*mismatched tag', "not well-formed, error message");
}

{
my $t= XML::Twig->new->parsefile( 'test_with_lwp.xml');
is( $t->sprint, '<doc><elt>text</elt></doc>', "parseurl");
}

{
my $t= XML::Twig->new->safe_parsefile( 'test_with_lwp.xml');
is( $t->sprint, '<doc><elt>text</elt></doc>', "parseurl");
}

{
my $t= XML::Twig->new->safe_parsefile( 'test_with_lwp_no_file.xml');
ok( !$t, "no file");
matches( $@, '^\s*Couldn', "no file, error message");
}

{
my $t= XML::Twig->new->safe_parsefile( 'test_with_lwp_not_wf.xml');
ok( !$t, "not well-formed");
matches( $@, '^\s*mismatched tag', "not well-formed, error message");
}

exit 0;

