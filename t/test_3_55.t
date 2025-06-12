#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir( File::Spec->curdir, "t" );
use tools;

my $TMAX = 5;
print "1..$TMAX\n";

# fixing a hole in test coverage
{
    my $doc = '<d>
    <e id="e1"><c>0</c></e>
    <e id="e2"><c>1</c></e>
    <e id="e3"><c>1</c></e>
    <e id="e4"><c>0</c></e>
    <e id="e5"><c>foo</c></e>
    </d>';
    my ( $res_e0, $res_e1, $res_c0, $res_c1, $res_efoo, $res_cfoo );
    XML::Twig->new(
        twig_handlers => {
            'c[string()=1]'      => sub { $res_c1   .= $_->parent->id },
            'c[string()=0]'      => sub { $res_c0   .= $_->parent->id },
            'e[string(c)=1]'     => sub { $res_e1   .= $_->id },
            'e[string(c)=0]'     => sub { $res_e0   .= $_->id },
            'c[string()="foo"]'  => sub { $res_cfoo .= $_->parent->id },
            'e[string(c)="foo"]' => sub { $res_efoo .= $_->id },
        }
    )->parse($doc);
    is( $res_efoo, 'e5',   'testing twig_handlers trigger <elt>[string(<child>)]="foo"' );
    is( $res_e1,   'e2e3', 'testing twig_handlers trigger <elt>[string(<child>)]=<nb>' );
    is( $res_e0,   'e1e4', 'testing twig_handlers trigger <elt>[string(<child>)]=0' );
    is( $res_e1,   'e2e3', 'testing twig_handlers trigger <elt>[string()]=<nb>' );
    is( $res_e0,   'e1e4', 'testing twig_handlers trigger <elt>[string()]=0' );
}

exit;

