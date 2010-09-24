#!/usr/bin/perl -w
use strict;

use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;
use Config;
my $devnull = File::Spec->devnull;
my $DEBUG=1;

# be cautious: run this only on systems I have tested it on
my %os_ok=( linux => 1, solaris => 1, darwin => 1, MSWin32 => 1);
if( !$os_ok{$^O}) { print "1..1\nok 1\n"; warn "skipping, test runs only on some OSs\n"; exit; }

if( $] < 5.006) { print "1..1\nok 1\n"; warn "skipping, xml_merge runs only on perl 5.6 and later\n"; exit; }

print "1..13\n";

my $perl = used_perl();
my $xml_split = File::Spec->catfile( "tools", "xml_split", "xml_split");
my $xml_merge = File::Spec->catfile( "tools", "xml_merge", "xml_merge");

sys_ok( "$perl -c $xml_split", "xml_split compilation");
sys_ok( "$perl -c $xml_merge", "xml_merge compilation");

my $xml= q{<d>} . join( "\n  ", map { elt( $_) } (1..10)) . qq{\n</d>};
my $xml_file= "test_xml_split_g.xml";
spit( $xml_file => $xml);

systemq( "$perl $xml_split -g 3 -n 3 $xml_file");
my $main_file= "test_xml_split_g-000.xml";
my @files= map { sprintf( "test_xml_split_g-%03d.xml", $_) } (1..4);
foreach ( $main_file, @files) { ok( -f $_, "created $_"); }

is_like( slurp( "test_xml_split_g-000.xml"), q{<d>} . join( '', map { "<?merge subdocs = 0 :$_?>"} @files) . q{</d>},
                "main file content");

is_like( slurp( "test_xml_split_g-001.xml"), sub_file( 1..3), "test_xml_split_g-001.xml content");
is_like( slurp( "test_xml_split_g-002.xml"), sub_file( 4..6), "test_xml_split_g-002.xml content");
is_like( slurp( "test_xml_split_g-003.xml"), sub_file( 7..9), "test_xml_split_g-003.xml content");
is_like( slurp( "test_xml_split_g-004.xml"), sub_file( 10), "test_xml_split_g-004.xml content");

unlink $xml_file;

systemq( "$perl $xml_merge $main_file > $xml_file");

is_like( slurp( $xml_file), $xml, "merge result");

unlink $xml_file, $main_file, @files;

sub sub_file
  { my @elt_nb= @_;
    return   q{<xml_split:root xmlns:xml_split="http://xmltwig.com/xml_split">} 
           . join( '', map { elt( $_)} @elt_nb)
           . q{</xml_split:root>};
  }

sub elt
  { my( $nb)= @_;
    return qq{<e id="e$nb">element $nb</e>};
  } 

# slurp and remove spaces from the file 
sub slurp_trimmed
  { my( $file)= @_;
    local undef $/;
    open( FHSLURP, "<$file") or return "$file not found:$!";
    my $content=<FHSLURP>;
    $content=~ s{\s}{}g;
    return $content;
  }

sub systemq 
  { warn "$_[0]\n" if( !$DEBUG);
    system $_[0];
  }


