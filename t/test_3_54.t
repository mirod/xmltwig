#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir( File::Spec->curdir, "t" );
use tools;

my $TMAX = 30;
print "1..$TMAX\n";

# test that del_atts/set_att keeps the attribute hash tied
# see https://stackoverflow.com/a/79392733/9410
if ( _use('Tie::IxHash') ) {

    my $doc = qq{<d z="1" id="2" a="3" b="4"/>};
    my $t   = XML::Twig->new( keep_atts_order => 1 )->parse($doc);
    is( $t->sprint, $doc, 'keep_atts_order, initial output' );

    my $root = $t->root;

    $root->del_atts;
    is( $t->sprint, '<d/>', 'del_atts applied' );

    $root->set_att( z  => 1 );
    $root->set_att( id => 2 );
    $root->set_att( a  => 3 );
    $root->set_att( b  => 4 );
    is( $t->sprint, $doc, 'keep_atts_order, attributes added' );

    $root->del_atts;
    $root->set_atts( { z => 1 } );
    $root->set_att( id => 2 );
    $root->set_att( a  => 3 );
    $root->set_att( b  => 4 );
    is( $t->sprint, $doc, 'keep_atts_order, attributes added, first with set_atts' );

    $root->del_atts;
    $root->set_att( z => 1 );
    $root->set_id(2);
    $root->set_att( a => 3 );
    $root->set_att( b => 4 );
    is( $t->sprint, $doc, 'keep_atts_order, using set_id' );

    $root->del_atts;
    $root->set_id(1);
    $root->set_att( z => 2 );
    $root->set_att( a => 3 );
    $root->set_att( b => 4 );
    my $expected_doc = qq{<d id="1" z="2" a="3" b="4"/>};
    is( $t->sprint, $expected_doc, 'keep_atts_order, using set_id first' );
} else {
    skip( 6, "Tie::IxHash not available, skipping del_atts test with the keep_atts_order option" );
}

# test that twig handlers on #TEXT are correctly called when set using setTwigHandlers
# see https://github.com/mirod/xmltwig/issues/36
{
    my $doc               = '<d>text</d>';
    my $handler_triggered = 0;
    my $t1 = XML::Twig->new( twig_handlers => { '#TEXT' => sub { $handler_triggered = 1; } } )->parse($doc);
    ok( $handler_triggered, 'handler on #TEXT' );
    my $t2 = XML::Twig->new();
    $handler_triggered = 0;
    $t2->setTwigHandlers( { '#TEXT' => sub { $handler_triggered = 1; } } );
    $t2->parse($doc);

    ok( $handler_triggered, 'setTwigHandlers on #TEXT' );

}

# test strip_att with a list of attributes
{
    my $doc          = q{<d a_strip="a" b="b" c_strip="c"><e a="a" b_strip="b" c_strip="c"/></d>};
    my $expected_doc = $doc;
    $expected_doc =~ s{ ._strip="."}{}g;
    my $t = XML::Twig->new->parse($doc);
    $t->root->strip_att( 'a_strip', 'b_strip', 'c_strip' );
    is( $t->sprint, $expected_doc, 'strip_att with a list of attributes' );

}

# test DOM style positions like beforebegin...
{
    my $doc          = q{<d><e/></d>};
    my $expected_doc = q{<d><bb/><e><ab/><be/></e><ae/></d>};

    my $t = XML::Twig->new->parse($doc);
    my $e = $t->first_elt('e');
    $e->insert_new_elt( beforebegin => 'bb' );
    $e->insert_new_elt( afterbegin  => 'ab' );
    $e->insert_new_elt( beforeend   => 'be' );
    $e->insert_new_elt( afterend    => 'ae' );
    is( $t->sprint, $expected_doc, 'insert_new_elt using HTML style position' );

    $t = XML::Twig->new->parse($doc);
    $e = $t->first_elt('e');
    XML::Twig::Elt->new('bb')->paste( beforebegin => $e );
    XML::Twig::Elt->new('ab')->paste( afterbegin  => $e );
    XML::Twig::Elt->new('be')->paste( beforeend   => $e );
    XML::Twig::Elt->new('ae')->paste( afterend    => $e );
    is( $t->sprint, $expected_doc, 'paste using HTML style position' );

}

# test insert_new_elt with a string argument
{
    my $doc = q{<d><e/></d>};
    my $t   = XML::Twig->new->parse($doc);

    my $root = $t->root;
    $root->insert_new_elt( afterbegin => '<ne/>' );
    is( $t->sprint, '<d><ne/><e/></d>', 'insert_new_elt with string (afterbegin)' );
    $root->insert_new_elt( beforeend => '<ne/>' );
    is( $t->sprint, '<d><ne/><e/><ne/></d>', 'insert_new_elt with string (beforeend)' );
    $root->first_child('e')->insert_new_elt( afterbegin => '<ne/>' );
    is( $t->sprint, '<d><ne/><e><ne/></e><ne/></d>', 'insert_new_elt with string (afterbegin)' );
    $root->first_child('e')->insert_new_elt( afterend => '<ne2/>' );
    is( $t->sprint, '<d><ne/><e><ne/></e><ne2/><ne/></d>', 'insert_new_elt with string (afterend)' );

}

# test the error message for wrong positions
{
    my $t   = XML::Twig->new->parse('<d/>');
    my $elt = XML::Twig::Elt->parse('<e/>');
    my $res = eval { $elt->paste( beforebefore => $t->root ); };
    nok( $res, 'wrong position argument causes an error' );
    matches(
        $@,
        qr/wrong position.*after.*before.*first_child.*last_child/,
        'wrong position argument error message includes allowed values'
    );
}

# test triggering TEXT handler with PI/comments in the content
{
    my $doc = '<d>foo<e/>bar</d>';
    my @seen;
    XML::Twig->new( twig_handlers => { '#TEXT' => sub { push @seen, $_->text; } } )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in mixed content');
}

{
    my @seen;
    my @thandlers = ( twig_handlers => { '#TEXT' => sub { push @seen, $_->text; } } );

    my $doc='<d>foo<!-- comment -->bar</d>';
    XML::Twig->new( comments => 'keep', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in content with comment (keep comments)');
    @seen=();
    XML::Twig->new( comments => 'process', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in content with comment (process comments)');
    @seen=();
    XML::Twig->new( comments => 'drop', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in content with comment (drop comments)');

    $doc = '<d>foo<?target duh?>bar</d>';
    @seen=();
    XML::Twig->new( pi => 'keep', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in content with PI (keep PIs)');
    @seen=();
    XML::Twig->new( pi => 'drop', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in content with PI (drop PIs)');
    @seen=();
    XML::Twig->new( pi => 'process', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar', 'triggering TEXT handler in content with PI (process PIs)');

    $doc='<d>foo<!-- comment -->bar<!-- comment 2 -->baz</d>';
    @seen=();
    XML::Twig->new( comments => 'keep', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar-baz', 'triggering TEXT handler in content with 2 comments (keep)');
    @seen=();
    XML::Twig->new( comments => 'process', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar-baz', 'triggering TEXT handler in content with 2 comments (process)');
    @seen=();
    XML::Twig->new( comments => 'drop', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar-baz', 'triggering TEXT handler in content with 2 comments (drop)');

    $doc='<d>foo<!-- comment -->bar<?target pi ?>baz</d>';
    @seen=();
    XML::Twig->new( comments => 'keep', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar-baz', 'triggering TEXT handler in content with comment + pi (keep)');
    @seen=();
    XML::Twig->new( comments => 'process', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar-baz', 'triggering TEXT handler in content with comment + pi (process)');
    @seen=();
    XML::Twig->new( comments => 'drop', @thandlers )->parse($doc);
    is( join('-', @seen), 'foo-bar-baz', 'triggering TEXT handler in content with comment + pi (drop)');

}

exit;

