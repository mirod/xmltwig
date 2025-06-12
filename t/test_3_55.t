#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir( File::Spec->curdir, "t" );
use tools;

my $TMAX = 28;
print "1..$TMAX\n";

# fixing holes in test coverage (and bugs in the code)
{
    my $doc = '<d>
    <e id="e1"><c>0</c></e>
    <e id="e2"><c>1</c></e>
    <e id="e3"><c>1</c></e>
    <e id="e4"><c>0</c></e>
    <e id="e5"><c>foo</c></e>
    </d>';
    my ( $res_e0, $res_e1, $res_c0, $res_c1, $res_efoo, $res_cfoo );
    my %tests = (
        'c[string()=0]'     => 'e1e4',
        'c[string()=0.0]'     => 'e1e4',
        'c[string()=1]'     => 'e2e3',
        'c[string()=1.0]'     => 'e2e3',
        'c[string()="foo"]' => 'e5',
        'c[string() >= 1]'  => 'e2e3',
        'c[string() >= 0]'  => 'e1e2e3e4',
        'c[string() != 0]'  => 'e2e3',
        'c[string() < 1]'  => 'e1e4',
        'c[string() <= 1]'  => 'e1e2e3e4',
        'c[string() <= 0]'  => 'e1e4',
        'c[string() < 0]'  => '',
        'c[string() > 1]'  => '',
        'c[string() =~ /^1$/]'  => 'e2e3',
    );
    my $handlers = {};
    my $res={};
    foreach my $sel ( keys %tests ) {
        $handlers->{$sel} = sub { add_parent_id( $res, $sel ); };
        my $esel = esel($sel);
        $handlers->{$esel} = sub { add_id( $res, $esel ); };
    }

    XML::Twig->new( twig_handlers => $handlers )->parse($doc);

    foreach my $sel ( keys %tests ) {
        is( $res->{$sel}, $tests{$sel}, "testing twig_handlers trigger $sel" );
        my $esel = esel($sel);
        is( $res->{$esel}, $tests{$sel}, "testing twig_handlers trigger $esel" );
    }

}

sub esel {
    my ($sel) = @_;
    return $sel =~ s{\Qc[string()}{e[string(c)}r;
}

sub add_id {
    my ( $res, $key ) = @_;
    $res->{$key} .= $_->id;
    1;
}

sub add_parent_id {
    my ( $res, $key ) = @_;
    $res->{$key} .= $_->parent->id;
    1;
}

exit;

