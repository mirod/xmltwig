#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More tests => 2;

use utf8;

# test CDATA sections in HTML escaping https://rt.cpan.org/Ticket/Display.html?id=86773

               # module              =>  XML::Twig->new options
my %html_conv= ( 'HTML::TreeBuilder' =>  {},
                 'HTML::Tidy'        =>  { use_tidy => 1 },
               );
foreach my $module ( sort keys  %html_conv)
  { SKIP: 
      { eval "use $module";
        skip "$module not available", 3 if $@ ;

        my $in = q{<h1>Here&amp;there v&amp;r;</h1><p>marco&amp;company; and marco&amp;company &pound; &#163; &#xA3; £</p>};
        my $expected= q{<h1>Here&amp;there v&amp;r;</h1><p>marco&amp;company; and marco&amp;company £ £ £ £</p>};

        my $parser= XML::Twig->new( %{$html_conv{$module}});
        my $t = $parser->safe_parse_html($in);
        print $@ if $@;

        like $t->sprint, qr{\Q$expected\E}, "In and out are the same ($module)";

      }
  }

exit;



