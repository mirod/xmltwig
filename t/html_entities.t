#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use XML::Twig;
use Test::More;
use HTML::TreeBuilder;
use Data::Dumper;
binmode STDOUT, ':encoding(utf-8)';


plan tests => 4;

my $parser = new XML::Twig ();
my $problem =<< 'EOF';
<h1>Here&amp;there</h1>
EOF

my $html = $parser->safe_parse_html($problem);
ok($html, "entities decoded ok");
diag $@ if $@;

my $safe =<< 'EOF';
<h1>Here &amp; there&nbsp;</h1>
EOF

$html = $parser->safe_parse_html($safe);
diag $@ if $@;
ok($html, "amp surrounded by spaces ok");

my $tree = HTML::TreeBuilder->new;
$tree->ignore_ignorable_whitespace( 0);
$tree->ignore_unknown( 0);
$tree->no_space_compacting( 1);
$tree->store_comments( 1);
$tree->store_pis(1);
$tree->parse("<h1>Marco&amp;company</h1>");
$tree->eof;
my $tb = $tree->as_XML;
is ($tb, "<html><head></head><body><h1>Marco&amp;company</h1></body></html>\n");
$parser = XML::Twig->new();
$html = $parser->safe_parse_html("<h1>Marco&amp;company</h1>");
diag $@ if $@;
is($html->sprint . "\n", $tb, "treebuilder and twig yield the same (with trailing linefeed)");


