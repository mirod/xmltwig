# $Id: /xmltwig/trunk/t/pod_coverage.t 4 2007-03-16T12:16:25.259192Z mrodrigu  $

eval "use Test::Pod::Coverage 1.00 tests => 1";
if( $@)
  { print "1..1\nok 1\n";
    warn "Test::Pod::Coverage 1.00 required for testing POD coverage";
    exit;
  }

pod_coverage_ok( "XML::Twig");
