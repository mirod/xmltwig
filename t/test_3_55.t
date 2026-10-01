#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir( File::Spec->curdir, "t" );
use tools;

my $TMAX = 75;
print "1..$TMAX\n";

# fixing holes in test coverage (and bugs in the code)
{
    my $doc = '<d>
    <e id="e1" att="0"><c>0</c></e>
    <e id="e2" att="1"><c>1</c></e>
    <e id="e3" att="1"><c>1</c></e>
    <e id="e4" att="0"><c>0</c></e>
    <e id="e5" att="foo"><c>foo</c></e>
    </d>';
    my ( $res_e0, $res_e1, $res_c0, $res_c1, $res_efoo, $res_cfoo );
    my %tests = (
        'c[string() =  0     ]'  => 'e1e4e5',
        'c[string() =  0.0   ]'  => 'e1e4e5',
        'c[string() =  1     ]'  => 'e2e3',
        'c[string() =  1.0   ]'  => 'e2e3',
        'c[string() =  "foo" ]'  => 'e5',
        'c[string() !=  "foo" ]' => 'e1e2e3e4',
        'c[string() >= 1     ]'  => 'e2e3',
        'c[string() >= 0     ]'  => 'e1e2e3e4e5',
        'c[string() != 0     ]'  => 'e2e3',
        'c[string() < 1      ]'  => 'e1e4e5',
        'c[string() <= 1     ]'  => 'e1e2e3e4e5',
        'c[string() <= 0     ]'  => 'e1e4e5',
        'c[string() <  0     ]'  => '',
        'c[string() >  1     ]'  => '',
        'c[string() =~ /^1$/ ]'  => 'e2e3',
    );

    my $res;
    my $handlers = {};
    foreach my $sel ( keys %tests ) {
        $handlers->{$sel} = sub { add_parent_id( $res, $sel ); };
        my $esel = esel($sel);
        $handlers->{$esel} = sub { add_id( $res, $esel ); };
        my $asel = asel($sel);
        $handlers->{$asel} = sub { add_id( $res, $asel ); };
    }

    $res = {};
    my $t = XML::Twig->new( twig_handlers => $handlers )->parse($doc);

    foreach my $sel ( keys %tests ) {

        my $expected = $tests{$sel};

        # check that handlers triggered properly
        is( $res->{$sel}, $expected, "testing twig_handlers trigger $sel" );
        my $esel = esel($sel);
        is( $res->{$esel}, $expected, "testing twig_handlers trigger $esel" );
        my $asel = asel($sel);
        is( $res->{$asel}, $expected, "testing twig_handlers trigger $asel" );

        # check navigation
        my $c_res = join '', map { $_->parent->id } $t->root->descendants($sel);
        is( $c_res, $expected, "testing sel (//) $sel" );
        my $e_res = join '', map { $_->id } $t->root->children($esel);
        is( $e_res, $expected, "testing sel (/) $esel" );
    }
}

# subs that create more tests from the initial ones in %test

# turn a c[string() <cond>] predicate into a e[string(c) <cond>] predicate
# the resulting predicate will yield the same result as the input one
sub esel {
    my ($sel) = @_;
    return $sel =~ s{\Qc[string()}{e[string(c)}r;
}

# turn a c[string() <cond>] predicate into a e[@att <cond>] predicate
# the resulting predicate will yield the same result as the input one
sub asel {
    my ($sel) = @_;
    return $sel =~ s{\Qc[string()}{e[\@att}r;
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

