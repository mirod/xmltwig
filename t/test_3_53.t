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

{
    my $res = '';
    my $t   = XML::Twig->new(
        twig_handlers => {
            'e.c1' => sub { $res .= $_->id; }
        }
    )->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $res, '', 'handler trigger using chained classes does not trigger when not using css_sel' );
}
{
    my $res;
    my $t = XML::Twig->new(
        css_sel       => 1,
        twig_handlers => {
            'e.c1' => sub { $res .= $_->id; }
        }
    )->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $res, 'e1e2', 'handler trigger using chained classes' );
}

{
    my $res;
    my $t = XML::Twig->new(
        css_sel       => 1,
        twig_handlers => {
            'e.c1.c2' => sub { $res .= $_->id; }
        }
    )->parse('<d><e class="c1" id="e1">e1</e><e class="c1 c2" id="e2">e2</e></d>');
    is( $res, 'e2', 'handler trigger using multi chained classes' );
}

{    # check whether the no_xxe option actually prevents loading an external entity
    my $tmp = 'tmp-3-53.ent';
    open( my $ent, '>', $tmp ) or die "cannot create temp file $tmp: $!";
    my $ent_text = 'text of ent';
    print {$ent} $ent_text;
    close $ent;

    my $doc
        = qq{<?xml version="1.0" standalone="no"?><!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)> <!ENTITY e SYSTEM "$tmp">]><doc>&e;</doc>};
    my $t = XML::Twig->new()->parse($doc);
    is( $t->root->text, $ent_text, 'include external entity' );

    $t = XML::Twig->new( no_xxe => 1 )->safe_parse($doc);
    is( $t, undef, 'no_xxe' );
}

{
    my $notation_public
        = qq{<!NOTATION gif89a PUBLIC "-//CompuServe//NOTATION Graphics Interchange Format 89a//EN" "gif">};
    my $notation_system = qq{<!NOTATION mif SYSTEM "MIF">};
    my $notations       = $notation_public . "\n" . $notation_system ."\n";
    my $doc
        = qq{<?xml version="1.0" standalone="no"?><!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)> $notations ]><doc>foo</doc>};
    my $t = XML::Twig->new()->parse($doc);
    is( $t->notation_list->sprint, $notations, 'sprint notation list' );

    {
        my $out;
        open( my $out_fh, '>', \$out ) or die "cannot open fh to string: $!";
        $t->notation_list->print($out_fh);
        close $out_fh;
        is( $out, $notations, 'print notation list' );
    }
    is( $t->notation('mif')->sprint,    $notation_system, 'sprint system notation' );
    is( $t->notation('gif89a')->sprint, $notation_public, 'sprint public notation' );

    {
        my $out;
        open( my $out_fh, '>', \$out ) or die "cannot open fh to string: $!";
        $t->notation('mif')->print($out_fh);
        is( $out, $notation_system ."\n", 'print system notation' );
        close $out_fh;
    }

    {
        my $out;
        open( my $out_fh, '>', \$out ) or die "cannot open fh to string: $!";
        $t->notation('gif89a')->print($out_fh);
        is( $out, $notation_public ."\n", 'print public notation' );
        close $out_fh;
    }
}

done_testing();

# sometimes we need different tags otherwise the tag tables are reused
sub _doc {
    my ( $root, $doc ) = @_;
    $doc =~ s{(</?)}{$1$root}g;
    return $doc;
}

exit;

