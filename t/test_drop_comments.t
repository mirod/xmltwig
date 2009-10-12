#!/usr/bin/perl -w
use strict;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

use XML::Twig;

print "1..3\n";

my $xml = <<XML_TEST;
<xml_root>
  <!-- some comment -->
  <key>value</key>
</xml_root>
XML_TEST

{
    my $twig1 = XML::Twig->new(comments => 'keep', keep_spaces => 1);
    $twig1->parse($xml);
    ok ($twig1->sprint() =~ /<!--.*-->/s, 'keep comments');
    #print $twig1->sprint, "\n", '-'x80, "\n"; # keeps comments ok
    $twig1->dispose;
}

{
    my $twig2 = XML::Twig->new(comments => 'drop', keep_spaces => 1);
    $twig2->parse($xml);
    ok ($twig2->sprint() !~ /<!--.*-->/s, 'drop comments');
    #print $twig2->sprint, "\n", '-'x80, "\n"; # drops comments ok
    $twig2->dispose;
}

{
    my $twig3 = XML::Twig->new(comments => 'keep', keep_spaces => 1);
    $twig3->parse($xml);
    ok ($twig3->sprint() =~ /<!--.*-->/s, 'keep comments');
    #print $twig3->sprint, "\n", '-'x80, "\n"; # drops comments!!
    $twig3->dispose;
}
exit 0;
