use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;
use Test;
plan( tests => 4);
 

use XML::Twig::XPath;
ok(1);

my $t= XML::Twig::XPath->new->parse( \*DATA);

ok( $t);

my $first = $t->findvalue( '/AAA/BBB[1]/@id');
ok($first, "first");

my $last = $t->findvalue( '/AAA/BBB[last()]/@id');
ok($last, "last");

exit 0;

__DATA__
<AAA>
<BBB id="first"/>
<BBB/>
<BBB/>
<BBB id="last"/>
</AAA>
