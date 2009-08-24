#!/usr/bin/perl

# $Id: /xmltwig/trunk/t/zz_dump_config.t 23 2007-06-21T08:52:17.136221Z mrodrigu  $

my $ok; # global, true if the last call to version found the module, false otherwise
use Config;

warn "\n\nConfiguration:\n\n";

# required
warn "perl: $]\n";
warn "OS: $Config{'osname'} - $Config{'myarchname'}\n";

print "\n";

warn version( XML::Parser, 'required');

# We obviously have expat on VMS, but a symbol/logical might
# not be set to xmlwf, and when this is the case a
#   '%DCL-W-IVVERB, unrecognized command verb - check validity and spelling
#   \XMLWF\'
# will be returned.

my $skip_xmlwf_test = 0;
if ($^O eq 'VMS') {
    if(`write sys\$output "''xmlwf'"` !~ m/[a-z]+/i) {
        $skip_xmlwf_test = 1;
        warn format_warn( 'expat', "Skipping expat (version) test as don't have a symbol for 'xmlwf'.");
    }
}

if (! $skip_xmlwf_test) 
  { # try getting this info
    my $xmlwf_v= `xmlwf -v`;
    if( $xmlwf_v=~ m{xmlwf using expat_(.*)$}m)
      { warn format_warn( 'expat', $1, '(required)'); }
    else
      { warn format_warn( 'expat', '<no version information found>'); }
  }

print "\n";

# must-have
warn version( Scalar::Util, 'for improved memory management');
if( $ok)
  { unless( defined( &Scalar::Util::weaken))
      { warn format_warn( '', 'NOT USED, weaken not available in this version');
        warn version( WeakRef); 
      }
  }
else
  { warn version( WeakRef, 'for improved memory management'); }

# encoding
warn version( Encode, 'for encoding conversions');
unless( $ok) { warn version( Text::Iconv, 'for encoding conversions'); }
unless( $ok) { warn version( Unicode::Map8, 'for encoding conversions'); }

print "\n";

# optional
warn version( LWP, 'for the parseurl method');
warn version( HTML::Entities, 'for the html_encode filter');
warn version( Tie::IxHash, 'for the keep_atts_order option');
warn version( XML::XPathEngine, 'to use XML::Twig::XPath');
warn version( XML::XPath, 'to use XML::Twig::XPath if Tree::XPathEngine not available');
warn version( HTML::TreeBuilder, 'to use parse_html and parsefile_html');
warn version( Text::Wrap, 'to use the "wrapped" option for pretty_print');

print "\n";

# used in tests
warn version( Test, 'for testing purposes');
warn version( Test::Pod, 'for testing purposes');
warn version( XML::Simple, 'for testing purposes');
warn version( XML::Handler::YAWriter, 'for testing purposes');
warn version( XML::SAX::Writer, 'for testing purposes');
warn version( XML::Filter::BufferText, 'for testing purposes');
warn version( IO::Scalar, 'for testing purposes');

my $zz_dump_config= File::Spec->catfile( t => "zz_dump_config.t");
warn "\n\nPlease add this information to bug reports (you can run $zz_dump_config to get it)\n\n";
warn "if you are upgrading the module from a previous version, make sure you read the\n",
     "Changes file for bug fixes, new features and the occasional COMPATIBILITY WARNING\n\n";

print "1..1\nok 1\n";
exit 0;

sub version
  { my $module= shift;
    my $info= shift || '';
    $info &&= "($info)";
    my $version;
    if( eval "require $module")
      { $ok=1;
        import $module;
        $version= ${"$module\::VERSION"};
        $version=~ s{\s*$}{};
      }
    else
      { $ok=0;
        $version= '<not available>';
      }
    return format_warn( $module, $version, $info);
  }

sub format_warn
  { return  sprintf( "%-25s: %16s %s\n", @_); }
