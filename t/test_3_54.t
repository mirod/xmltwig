#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

my $TMAX=8;
print "1..$TMAX\n";

# test that del_atts/set_att keeps the attribute hash tied
# see https://stackoverflow.com/a/79392733/9410
if( _use( 'Tie::IxHash')) {

    my $doc=qq{<d z="1" id="2" a="3" b="4"/>};
    my $t=XML::Twig->new(keep_atts_order => 1)->parse($doc);
    is( $t->sprint, $doc, 'keep_atts_order, initial output');

    my $root = $t->root;

    $root->del_atts;
    is( $t->sprint, '<d/>', 'del_atts applied');

    $root->set_att( z => 1);
    $root->set_att( id => 2);
    $root->set_att( a => 3);
    $root->set_att( b => 4);
    is( $t->sprint, $doc, 'keep_atts_order, attributes added');

    $root->del_atts;
    $root->set_atts( { z => 1 } );
    $root->set_att( id => 2);
    $root->set_att( a => 3);
    $root->set_att( b => 4);
    is( $t->sprint, $doc, 'keep_atts_order, attributes added, first with set_atts');

    $root->del_atts;
    $root->set_att( z => 1);
    $root->set_id ( 2);
    $root->set_att( a => 3);
    $root->set_att( b => 4);
    is( $t->sprint, $doc, 'keep_atts_order, using set_id');

    $root->del_atts;
    $root->set_id ( 1);
    $root->set_att( z => 2);
    $root->set_att( a => 3);
    $root->set_att( b => 4);
    my $expected_doc = qq{<d id="1" z="2" a="3" b="4"/>};
    is( $t->sprint, $expected_doc, 'keep_atts_order, using set_id first');
}
else {
    skip( 6, "Tie::IxHash not available, skipping del_atts test with the keep_atts_order option");
}

# test that twig handlers on #TEXT are correctly called when set using setTwigHandlers
# see https://github.com/mirod/xmltwig/issues/36
{
my $doc = '<d>text</d>';
my $handler_triggered = 0;
my $t1                = XML::Twig->new( twig_handlers => { '#TEXT' => sub { $handler_triggered=1; } } )->parse($doc);
ok( $handler_triggered, 'handler on #TEXT' );
my $t2 = XML::Twig->new();
$handler_triggered = 0;
$t2->setTwigHandlers( { '#TEXT' => sub { $handler_triggered=1; } } );
$t2->parse($doc);

ok( $handler_triggered, 'setTwigHandlers on #TEXT' );

}

exit;

