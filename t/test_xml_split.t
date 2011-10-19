#!/usr/bin/perl -w
use strict;

use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;
use Config;
my $devnull = File::Spec->devnull;
my $DEBUG=0;

my $extra_flags= $Devel::Cover::VERSION ? '-MDevel::Cover -Ilib' : '-Ilib';

# be cautious: run this only on systems I have tested it on
my %os_ok=( linux => 1, solaris => 1, darwin => 1, MSWin32 => 1);
if( !$os_ok{$^O}) { print "1..1\nok 1\n"; warn "skipping, test runs only on some OSs\n"; exit; }

if( $] < 5.006) { print "1..1\nok 1\n"; warn "skipping, xml_merge runs only on perl 5.6 and later\n"; exit; }

print "1..54\n";

my $perl= $Config{perlpath};
if ($^O ne 'VMS') { $perl .= $Config{_exe} unless $perl =~ m/$Config{_exe}$/i; }
$perl.= " $extra_flags";
my $xml_split = File::Spec->catfile( "tools", "xml_split", "xml_split");
my $xml_merge = File::Spec->catfile( "tools", "xml_merge", "xml_merge");
my $xml_pp    = File::Spec->catfile( "tools", "xml_pp", "xml_pp");

sys_ok( "$perl -c $xml_split", "xml_split compilation");
sys_ok( "$perl -c $xml_merge", "xml_merge compilation");

my $test_dir   = File::Spec->catfile( "t", "test_xml_split");
my $test_file  = File::Spec->catfile( "t", "test_xml_split.xml");

my $base_nb; # global, managed by test_split_merge
test_split_merge( $test_file, "",             ""   );
test_split_merge( $test_file, "-i",           "-i" );
test_split_merge( $test_file, "-c elt1",      ""   );
test_split_merge( $test_file, "-i -c elt1",   "-i" );
test_split_merge( $test_file, "-c elt2",      ""   );
test_split_merge( $test_file, "-i -c elt2",   "-i" );
test_split_merge( $test_file, "-s 1K",   "" );
test_split_merge( $test_file, "-i -s 1K",   "-i" );
test_split_merge( $test_file, "-l 1",   "" );
test_split_merge( $test_file, "-i -l 1",   "-i" );
test_split_merge( $test_file, "-g 5",   "" );
test_split_merge( $test_file, "-i -g 5",   "-i" );

$test_file=File::Spec->catfile( "t", "test_xml_split_entities.xml");
test_split_merge( $test_file, "",   "" );
test_split_merge( $test_file, "-g 2",   "" );
test_split_merge( $test_file, "-l 1",   "" );

$test_file=File::Spec->catfile( "t", "test_xml_split_w_decl.xml");
test_split_merge( $test_file, "",   "" );
test_split_merge( $test_file, "-c elt1",   "" );
test_split_merge( $test_file, "-g 2",   "" );
test_split_merge( $test_file, "-l 1",   "" );
test_split_merge( $test_file, "-s 1K",   "" );
test_split_merge( $test_file, "-g 2 -l 2",   "" );

if( _use( 'IO::CaptureOutput'))
  { test_error( $xml_split => "-h", 'xml_split ');
    test_error( $xml_merge => "-h", 'xml_merge ');
    test_out( $xml_split => "-V", 'xml_split ');
    test_out( $xml_merge => "-V", 'xml_merge ');
    test_out( $xml_split => "-m", 'NAME\s*xml_split ');
    test_out( $xml_merge => "-m", 'NAME\s*xml_merge ');

    test_error( $xml_split => "-c foo -s 1K", 'cannot use -c and -s at the same time');
    test_error( $xml_split => "-g 100 -s 1K", 'cannot use -g and -s at the same time');
    test_error( $xml_split => "-g 100 -c fo", 'cannot use -g and -c at the same time');
    test_error( $xml_split => "-s 1Kc", 'invalid size');


  }
else
  { skip( 10, 'need IO::CaptureOutput to test tool options'); }


sub test_error
  { my( $command, $options, $expected)= @_;
    my( $stdout, $stderr, $success, $exit_code) = IO::CaptureOutput::capture_exec( "$perl $command $options test_xml_split.xml");
    matches( $stderr, qr/^$expected/, "$command $options");
  }

sub test_out
  { my( $command, $options, $expected)= @_;
    my( $stdout, $stderr, $success, $exit_code) = IO::CaptureOutput::capture_exec( "$perl $command $options test_xml_split.xml");
    matches( $stdout, qr/^$expected/, "$command $options");
  }


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

    my $merged= "$base.xml";
    system "$perl $xml_merge $verbifdebug -o $merged $merge_opts $base-00.xml";
    system "$xml_pp -i $merged";
    ok( same_file( $merged, $file), "xml_merge $merge_opts $test_file ($merged  $base-00.xml");
    
    unlink( glob( "$base*")) unless( $DEBUG);
  }

sub same_files
  { my( $expected_base, $base)= @_;
    my $nb="00";
    while( -f "$base-$nb.xml")
      { my( $real, $expected)= ( "$base-$nb.xml", "$expected_base-$nb.xml");
        if( ! -z $expected) { _use( 'File::Copy'); copy( $real, $expected); }
        unless( same_file( $expected, $real))
          { warn "  $expected and $real are different";
            if( $DEBUG) { warn `diff $expected, $real`; }
            return 0;
          }
        $nb++;
      }
    return 1;
  }

sub same_file
  { my( $file1, $file2)= @_;
    my $eq= slurp_mod( $file1) eq slurp_mod( $file2);
    if( $DEBUG && ! $eq) { system "diff $file1 $file2\n"; }
    return $eq;
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


