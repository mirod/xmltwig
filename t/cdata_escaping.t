use strict;
use warnings;
use XML::Twig;
use Test::More;
plan tests => 2;

my $html = <<'EOF';
<div id="body">body</div>
<script>
//<![CDATA[
if ( this.value && ( !request.term || matcher.test(text) ) && 1 > 0 && 0 < 1 )
//]]>
</script>
EOF

my $parser = XML::Twig->new();

my $xml = $parser->safe_parse_html($html);
print $@ if $@;

my @elts = $xml->get_xpath('//script');

foreach my $el (@elts) {
    $el->set_asis;
    diag $el->text;
    ok(((index $el->text, "//]]>") >= 0), "end of cdata ok");
}

ok(((index $xml->sprint, "//]]>") >= 0), "end of cdata ok");
diag $xml->sprint;
