#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 7;

is( XML::Twig->new( keep_encoding => 1)->parse( q{<d a='"foo'/>})->sprint, q{<d a="&quot;foo"/>}, "quote in att with keep_encoding");

# test CDATA sections in HTML escaping https://rt.cpan.org/Ticket/Display.html?id=86773
my $html = <<'EOF';
<div id="body">body</div>
<script>
//<![CDATA[
if ( this.value && ( !request.term || matcher.test(text) ) && 1 > 0 && 0 < 1 )
//]]>
</script>
EOF

               # module              =>  XML::Twig->new options
my %html_conv= ( 'HTML::TreeBuilder' =>  {},
                 'HTML::Tidy'        =>  { use_tidy => 1 },
               );
foreach my $module ( sort keys  %html_conv)
  { SKIP: 
      { eval "use $module";
        skip "$module not available", 3 if $@ ;

        my $parser= XML::Twig->new( %{$html_conv{$module}});
        my $xml = $parser->safe_parse_html($html);
        print $@ if $@;

        my @cdata = $xml->get_xpath('//#CDATA');
        ok(@cdata == 1, "1 CDATA section found (using $module)");

        ok(((index $xml->sprint, "//]]>") >= 0), "end of cdata ok in doc (using $module)");
        #diag "\n", $xml->sprint, "\n";

        my @elts = $xml->get_xpath('//script');

        foreach my $el (@elts) 
          { #diag $el->sprint;
            ok(((index $el->sprint, "//]]>") >= 0), "end of cdata ok in script element (using $module)");
          }
      }
  }


exit;



