#!/usr/bin/perl -w
use strict;

use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;
use Config;
my $devnull = File::Spec->devnull;
my $DEBUG=0;

# be cautious: run this only on systems I have tested it on
my %os_ok=( linux => 1, solaris => 1, darwin => 1, MSWin32 => 1);
if( !$os_ok{$^O}) { print "1..1\nok 1\n"; warn "skipping, test runs only on some OSs\n"; exit; }

if( $] < 5.006) { print "1..1\nok 1\n"; warn "skipping, xml_merge runs only on perl 5.6 and later\n"; exit; }

print "1..18\n";

my $perl= $Config{perlpath};
if ($^O ne 'VMS') { $perl .= $Config{_exe} unless $perl =~ m/$Config{_exe}$/i; }
$perl = "$^X -Mblib ";
my $xml_split = File::Spec->catfile( "tools", "xml_split", "xml_split");
my $xml_merge = File::Spec->catfile( "tools", "xml_merge", "xml_merge");

sys_ok( "$perl -c $xml_split", "xml_split compilation");
sys_ok( "$perl -c $xml_merge", "xml_merge compilation");

my $test_dir=File::Spec->catfile( "t", "test_xml_split");
my $test_file= File::Spec->catfile( "t", "test_xml_split.xml");

my $base_nb; # global, managed by test_split_merge
test_split_merge( $test_file, "",             ""   );
test_split_merge( $test_file, "-i",           "-i" );
test_split_merge( $test_file, "-c elt1",      ""   );
test_split_merge( $test_file, "-i -c elt1",   "-i" );
test_split_merge( $test_file, "-c elt2",      ""   );
test_split_merge( $test_file, "-i -c elt2",   "-i" );

$test_file=File::Spec->catfile( "t", "test_xml_split_entities.xml");
test_split_merge( $test_file, "",         ""   );
test_split_merge( $test_file, "-c elt",   "" );


sub test_split_merge
  { my( $file, $split_opts, $merge_opts)= @_;
    $split_opts ||= '';
    $merge_opts ||= '';
    $base_nb++;
    my $verbifdebug = $DEBUG ? '-v' : '';
    my $expected_base= File::Spec->catfile( "$test_dir", "test_xml_split_expected-$base_nb"); 
    my $base= File::Spec->catfile( "$test_dir", "test_xml_split-$base_nb"); 

    systemq( "$perl $xml_split $verbifdebug -b $base $split_opts $file");
    ok( same_files( $expected_base, $base), "xml_split $split_opts $test_file");

    system "$perl $xml_merge $verbifdebug -o $base.xml $merge_opts $base-00.xml";
    ok( same_file( "$base.xml", $file), "xml_merge $merge_opts $test_file");
    
    unlink( glob( "$base*")) unless( $DEBUG);
  }

sub same_files
  { my( $expected_base, $base)= @_;
    my $nb="00";
    while( -f "$base-$nb.xml")
      { unless( same_file( "$expected_base-$nb.xml", "$base-$nb.xml"))
          { warn "  $expected_base-$nb.xml and $base-$nb.xml are different";
            return 0;
          }
        $nb++;
      }
    return 1;
  }

sub same_file
  { my( $file1, $file2)= @_;
    return slurp_mod( $file1) eq slurp_mod( $file2);
  }

# slurp and remove spaces and _expected from the file 
sub slurp_mod
  { my( $file)= @_;
    local undef $/;
    open( FHSLURP, "<$file") or return "$file not found:$!";
    my $content=<FHSLURP>;
    $content=~ s{\s}{}g;
    $content=~ s{_expected}{}g;
    return $content;
  }

sub systemq 
  { if( !$DEBUG)
      { system "$_[0] 1>$devnull 2>$devnull"; }
    else
      { warn "$_[0]\n";
        system $_[0];
      }
  }


