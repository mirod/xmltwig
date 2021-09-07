#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;
use Test::More;

use utf8;

my $doc_with_dots = q{
    <doc>
      <elt id="elt-1">
        <selt id="selt-1">selt #1</selt>
      </elt>
      <elt id="elt-2">
        <selt id="selt-2">selt #2</selt>
        <selt.dot id="selt.dot-1">selt.dot #1 (in elt-2)</selt.dot>
      </elt>
      <elt id="elt-3">
        <selt id="selt-3">selt #3</selt>
        <selt.dot id="selt.dot-2">selt.dot #2 (in elt-3)</selt.dot>
      </elt>
    </doc>
};

{
    my @selt_dot_found;
    XML::Twig->new(
        twig_handlers => {
            'd1elt' => sub {
                my $selt_dot = $_->field('d1selt.dot');
                push @selt_dot_found, $selt_dot if $selt_dot;
            }
        },
        css_sel => 0,
    )->parse( _doc( d1 => $doc_with_dots ) );
    is( join( ':', @selt_dot_found ),
        'selt.dot #1 (in elt-2):selt.dot #2 (in elt-3)',
        'looking for element with dot in the name'
      );
}

{
    my @selt_dot_found;
    XML::Twig->new(
        twig_handlers => {
            'd2-elt' => sub {
                my $selt_dot = $_->field('d2-selt.dot');
                push @selt_dot_found, $selt_dot if $selt_dot;
            }
        },
        css_sel => 0,
    )->parse( _doc( 'd2-' => $doc_with_dots ) );
    is( join( ':', @selt_dot_found ),
        'selt.dot #1 (in elt-2):selt.dot #2 (in elt-3)',
        'looking for element with dot and dash in the name'
      );
}


{
    my $t = XML::Twig->new()->parse('<d><e class="c1-dash" id="e1">e1</e><e class="c1" id="e2">e2</e></d>');
    is( $t->first_elt('e.c1-dash')->id, 'e1', 'selector using class with dash' );
}

{
    my $t = XML::Twig->new()->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $t->first_elt('e.c1.c2')->id, 'e2', 'selector using chained classes' );
}

{   my $res='';
    my $t = XML::Twig->new( twig_handlers => { 'e.c1' => sub { $res.= $_->id; } } )->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $res, '', 'handler trigger using chained classes does not trigger when not using css_sel' );
}
{   my $res;
    my $t = XML::Twig->new( css_sel => 1, twig_handlers => { 'e.c1' => sub { $res.= $_->id; } } )->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $res, 'e1e2', 'handler trigger using chained classes' );
}

{   my $res;
    my $t = XML::Twig->new( css_sel => 1, twig_handlers => { 'e.c1.c2' => sub { $res.= $_->id; } } )->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $res, 'e2', 'handler trigger using multi chained classes' );
}

done_testing();

# sometimes we need different tags otherwise the tag tables are reused
sub _doc {
    my ( $root, $doc ) = @_;
    $doc =~ s{(</?)}{$1$root}g;
    return $doc;
}

exit;

