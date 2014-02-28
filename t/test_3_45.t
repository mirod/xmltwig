#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 9;

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

# test & in HTML (RT #86633)
my $html_with_amp='<h1>Marco&amp;company</h1>';
my $expected_body= '<body><h1>Marco&amp;company</h1></body>';

SKIP: 
{ eval "use HTML::Tidy";
  skip "HTML::Tidy not available", 1 if $@ ;
  my $parsert = XML::Twig->new();
  my $html_tidy = $parsert->safe_parse_html( { use_tidy => 1 }, "<h1>Marco&amp;company</h1>");
  diag $@ if $@;
  is( $html_tidy->first_elt( 'body')->sprint, $expected_body, "&amp; in text, converting html with use_tidy");
}

SKIP:
{ eval "use HTML::TreeBuilder";
  skip "HTML::TreeBuilder not available", 1 if $@ ;
  my $parserh= XML::Twig->new();
  my $html = $parserh->safe_parse_html("<h1>Marco&amp;company</h1>");
  diag $@ if $@;
  is( $html->first_elt( 'body')->sprint , $expected_body, "&amp; in text, converting html with treebuilder");
}


exit;



