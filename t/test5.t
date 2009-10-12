#!/usr/bin/perl -w
use strict;

use XML::Twig;

$|=1;

my $doc= '<doc>
  <elt1>
    <elt2 id="elt1">
      <elt3 id="elt2">
      </elt3>
    </elt2>
    <elt2 id="elt3">
    </elt2>
  </elt1>
  <p1 id="p1_1"><p2 id="p2_1">p2 (/doc/p1/p2) </p2>
                <p3 id="p3_1"><p2 id="p2_2">p2 (/doc/p1/p3/p2) </p2></p3>
  </p1>
  <p2 id="p2_3">p2 (/doc/p2) </p2>
  <p2 id="p2_4">p2 (/doc/p2) </p2>
  <p4><p2 id="p2_5">p2 (/doc/p2) </p2></p4>
  <p4><p2 id="p2_6">p2 (/doc/p2) </p2></p4>
  <p3 id="p3_2"><p2 id="p2_7">p2 (/doc/p3/p2) </p2></p3>
</doc>
';

my $TMAX=80; # do not forget to update
print "1..$TMAX\n";

my $t= new XML::Twig;
$t->parse( $doc);

my $elt1= $t->elt_id( 'elt1');
my $elt2= $t->elt_id( 'elt2');
my $elt3= $t->elt_id( 'elt3');
my $root= $t->root;

# testing before and after
my $res= $elt1->before( $elt2);
if( $res) { print "ok 1\n"; } else { print "not ok 1\n"; }

$res= $elt2->before( $elt3);
if( $res) { print "ok 2\n"; } else { print "not ok 2\n"; }

$res= $elt1->before( $elt3);
if( $res) { print "ok 3\n"; } else { print "not ok 3\n"; }

$res= $elt3->before( $elt2);
unless( $res) { print "ok 4\n"; } else { print "not ok 4\n"; }

$res= $elt1->after( $elt2);
unless( $res) { print "ok 5\n"; } else { print "not ok 5\n"; }

$res= $elt1->after( $elt3);
unless( $res) { print "ok 6\n"; } else { print "not ok 6\n"; }

$res= $elt3->after( $elt2);
if( $res) { print "ok 7\n"; } else { print "not ok 7\n"; }

$res= $elt1->before( $root);
unless( $res) { print "ok 8\n"; } else { print "not ok 8\n"; }

$res= $root->before( $elt1);
if( $res) { print "ok 9\n"; } else { print "not ok 9\n"; }

# testing path capabilities
my $path=  $elt1->path;
my $exp_path=  '/doc/elt1/elt2';
if( $path eq $exp_path)
  { print "ok 10\n"; } else { print "not ok 10\n"; print "$path instead\n"; warn "of $exp_path\n"; }

$path=  $elt2->path;
$exp_path=  '/doc/elt1/elt2/elt3';
if( $path eq $exp_path)
  { print "ok 11\n"; } else { print "not ok 11\n"; warn "$path instead of $exp_path\n"; }

$path=  $elt3->path;
$exp_path=  '/doc/elt1/elt2';
if( $path eq $exp_path)
  { print "ok 12\n"; } else { print "not ok 12\n"; warn "$path instead of $exp_path\n"; }

$path=  $root->path;
$exp_path=  '/doc';
if( $path eq $exp_path)
  { print "ok 13\n"; } else { print "not ok 13\n"; warn "$path instead of $exp_path\n"; }

my $id1=''; my $exp_id1= 'p2_1';
my $id2=''; my $exp_id2= 'p2_3p2_4';
my $id3=''; my $exp_id3= 'p2_2p2_7';
my $id4=''; my $exp_id4= 'p2_5p2_6';
my $path_error='';
my $t2= new XML::Twig( TwigHandlers => 
                         { '/doc/p1/p2' => sub { $id1.= $_[1]->id; return; },
                           '/doc/p2'    => sub { $id2.= $_[1]->id; return; },
                           'p3/p2'      => sub { $id3.= $_[1]->id; return; },
                           'p2'         => sub { $id4.= $_[1]->id; return; },
   _all_  => sub { my( $t, $elt)= @_;
                   my $gi= $elt->gi;
                   my $tpath= $t->path( $gi); my $epath= $elt->path;
                   unless( $tpath eq $epath)
                     { $path_error.= " $tpath <> $epath\n"; }
                 }  
                         }
                     );
$t2->parse( $doc);
if( $id1 eq $exp_id1) 
  { print "ok 14\n"; } else { print "not ok 14\n"; warn "$id1 instead of $exp_id1\n"; }
if( $id2 eq $exp_id2) 
  { print "ok 15\n"; } else { print "not ok 15\n"; warn "$id2 instead of $exp_id2\n"; }
if( $id3 eq $exp_id3) 
  { print "ok 16\n"; } else { print "not ok 16\n"; warn "$id3 instead of $exp_id3\n"; } 
if( $id4 eq $exp_id4) 
  { print "ok 17\n"; } else { print "not ok 17\n"; warn "$id4 instead of $exp_id4\n"; } 
unless( $path_error)
  { print "ok 18\n"; } else { print "not ok 18\n"; warn "$path_error\n"; } 

$id1=''; $exp_id1= 'p2_1';
my $t3= new XML::Twig( TwigRoots => { '/doc/p1/p2' => sub { $id1.= $_[1]->id; } } );
$t3->parse( $doc);
if( $id1 eq $exp_id1) 
  { print "ok 19\n"; } else { print "not ok 19\n"; warn "$id1 instead of $exp_id1\n"; }

$id2=''; $exp_id2= 'p2_3p2_4';
$t3= new XML::Twig( TwigRoots => { '/doc/p2'    => sub { $id2.= $_[1]->id;} } );
$t3->parse( $doc);
if( $id2 eq $exp_id2) 
  { print "ok 20\n"; } else { print "not ok 20\n"; warn "$id2 instead of $exp_id2\n"; }

$id3=''; $exp_id3= 'p2_2p2_7';
$t3= new XML::Twig( TwigRoots => { 'p3/p2'    => sub { $id3.= $_[1]->id;} } );
$t3->parse( $doc);
if( $id3 eq $exp_id3) 
  { print "ok 21\n"; } else { print "not ok 21\n"; warn "$id3 instead of $exp_id3\n"; }

# test what happens to 0 in pcdata/cdata
my $pcdata= '<test><text>0</text></test>';
my $cdata= '<test><text><![CDATA[0]]></text></test>';
my $t4= new XML::Twig;

$t4->parse( $pcdata);
if( my $res= $t4->sprint eq $pcdata) { print "ok 22\n"; } 
else { print "not ok 22\n"; warn "sprint returns $res instead of $pcdata\n"; }

$t4->parse( $pcdata);
if( my $res= $t4->root->text eq '0') { print "ok 23\n"; } 
else { print "not ok 23\n"; warn "sprint returns $res instead of '0'\n"; }

$t4->parse( $cdata);
if( my $res= $t4->sprint eq $cdata) { print "ok 24\n"; } 
else { print "not ok 23\n"; warn "sprint returns $res instead of $cdata\n"; }

$t4->parse( $cdata);
if( my $res= $t4->root->text eq '0') { print "ok 25\n"; } 
else { print "not ok 25\n"; warn "sprint returns $res instead of '0'\n"; }

my $test_inherit=
'<doc att1="doc1" att2="doc2" att3="doc3"><elt att1="elt1" att_null="0">
  <subelt att1="subelt1" att2="subelt2"></subelt>
</elt></doc>';

my $t5= new XML::Twig;
$t5->parse( $test_inherit);
my $subelt= $t5->root->first_child->first_child;

if( my $att= $subelt->att( 'att1') eq "subelt1") { print "ok 26\n"; }
else { print "not ok 26\n"; warn "sprint returns $att instead of 'subelt1'\n"; }

if( my $att= $subelt->inherit_att( 'att1') eq "subelt1") { print "ok 27\n"; }
else { print "not ok 27\n"; warn "sprint returns $att instead of 'subelt1'\n"; }

if( my $att= $subelt->inherit_att( 'att1', 'elt') eq "elt1") { print "ok 28\n"; }
else { print "not ok 28 sprint returns $att instead of 'elt1'\n"; }

if( my $att= $subelt->inherit_att( 'att1', 'elt', 'doc') eq "elt1") { print "ok 29\n"; }
else { print "not ok 29\n"; warn "sprint returns $att instead of 'elt1'\n"; }

if( my $att= $subelt->inherit_att( 'att1', "doc") eq "doc1") { print "ok 30\n"; }
else { print "not ok 30\n"; warn "sprint returns $att instead of 'doc1'\n"; }

if( my $att= $subelt->inherit_att( 'att3') eq "doc3") { print "ok 31\n"; }
else { print "not ok 31\n"; warn "sprint returns $att instead of 'doc3'\n"; }

if( my $att= $subelt->inherit_att( 'att3') eq "doc3") { print "ok 32\n"; }
else { print "not ok 32\n"; warn "sprint returns $att instead of 'doc3'\n"; }

if( my $att= $subelt->inherit_att( 'att_null') == 0) { print "ok 33\n"; }
else { print "not ok 33\n"; warn "sprint returns $att instead of '0'\n"; }

# test attribute paths
my $test_att_path=
'<doc>
  <elt id="elt1" att="val1">
    <subelt id="subelt1" att="val1"/>
    <subelt id="subelt2" att="val1"/>
    <subelt id="subelt3" att="val2"/>
  </elt>
  <elt id="elt2" att="val1">
    <subelt id="subelt4" att="val1"/>
    <subelt id="subelt5" att="val1"/>
    <subelt id="subelt6" att="val2"/>
  </elt>
 </doc>';

my $res1='';
my $t6= new XML::Twig
          ( TwigHandlers =>    #'' (or VIM messes up colors)
            { 'elt[@id="elt1"]' => sub { $res1.= $_[1]->id} } 
          );
$t6->parse( $test_att_path);

if( $res1 eq 'elt1') { print "ok 34\n"; }
else { print "not ok 34\n"; warn "returns $res1 instead of elt1\n"; }

$res1='';
my $res2='';
$t6= new XML::Twig
          ( TwigHandlers =>
            { 'elt[@id="elt1"]'  => sub { $res1.= $_[1]->id},
              'elt[@att="val1"]' => sub { $res2.= $_[1]->id} },
          );
$t6->parse( $test_att_path);
if( $res1 eq 'elt1') { print "ok 35\n"; }
else { print "not ok 35\n"; warn "returns $res1 instead of 'elt1'\n"; }
if( $res2 eq 'elt1elt2') { print "ok 36\n"; }
else { print "not ok 36\n"; warn "returns $res2 instead of 'elt1elt2'\n"; }

my $doc_with_escaped_entities=
q{<doc att="m &amp; m">&lt;apos>&apos;&apos;&lt;apos&gt;&lt;&quot;></doc>};
my $exp_res1= q{<doc att="m &amp; m">&lt;apos>''&lt;apos>&lt;"></doc>}; 
my $exp_res2= q{<doc att="m & m"><apos>''<apos><"></doc>};
my $t7= new XML::Twig();
$t7->parse( $doc_with_escaped_entities);
$res= $t7->sprint;
if( $res eq $exp_res1) { print "ok 37\n"; }
else { print "not ok 37\n"; warn "returns \n$res instead of \n$exp_res1\n"; }

$t7= new XML::Twig( KeepEncoding => 1, NoExpand => 1);
$t7->parse( $doc_with_escaped_entities);
$res= $t7->sprint;
if( $res eq $doc_with_escaped_entities) { print "ok 38\n"; }
else { print "not ok 38\n"; warn "returns \n$res instead of \n$doc_with_escaped_entities\n"; }

# test extra options for new
my $elt= XML::Twig::Elt->new( 'p');
$res= $elt->sprint;
my $exp_res= '<p/>';
if( $res eq $exp_res) { print "ok 39\n"; }
else { print "not ok 39\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', q{#EMPTY}); 
$res= $elt->sprint;
$exp_res= '<p/>';
if( $res eq $exp_res) { print "ok 40\n"; }
else { print "not ok 40\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att => 'val'});
$res= $elt->sprint;
$exp_res= '<p att="val"/>';
if( $res eq $exp_res) { print "ok 41\n"; }
else { print "not ok 41\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att => 'val'}, '#EMPTY');
$res= $elt->sprint;
$exp_res= '<p att="val"/>';
if( $res eq $exp_res) { print "ok 42\n"; }
else { print "not ok 42\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att1 => 'val1', att2=> 'val2'});
$res= $elt->sprint;
$exp_res= '<p att1="val1" att2="val2"/>';
if( $res eq $exp_res) { print "ok 43\n"; }
else { print "not ok 43\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att1 => 'val1', att2=>'val2'}, '#EMPTY');
$res= $elt->sprint;
$exp_res= '<p att1="val1" att2="val2"/>';
if( $res eq $exp_res) { print "ok 44\n"; }
else { print "not onot ok 44\n"; warn "returns $res instead of $exp_res\n"; }


$elt= XML::Twig::Elt->new( 'p', "content");
$res= $elt->sprint;
$exp_res= '<p>content</p>';
if( $res eq $exp_res) { print "ok 45\n"; }
else { print "not ok 45\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att1 => 'val1'}, "content");
$res= $elt->sprint;
$exp_res= '<p att1="val1">content</p>';
if( $res eq $exp_res) { print "ok 46\n"; }
else { print "not ok 46\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att1 => 'val1', att2=>'val2'}, "content");
$res= $elt->sprint;
$exp_res= '<p att1="val1" att2="val2">content</p>';
if( $res eq $exp_res) { print "ok 47\n"; }
else { print "not ok 47\n"; warn "returns $res instead of $exp_res\n"; }

$elt= XML::Twig::Elt->new( 'p', { att1 => 'val1'}, "content", " more content");
$res= $elt->sprint;
$exp_res= '<p att1="val1">content more content</p>';
if( $res eq $exp_res) { print "ok 48\n"; }
else { print "not ok 48\n"; warn "returns $res instead of $exp_res\n"; }

my $sub1= XML::Twig::Elt->new( 'sub', '#EMPTY');
my $sub2= XML::Twig::Elt->new( 'sub', { att => 'val'}, '#EMPTY');
my $sub3= XML::Twig::Elt->new( 'sub', "sub3");
my $sub4= XML::Twig::Elt->new( 'sub', "sub4");
my $sub5= XML::Twig::Elt->new( 'sub', "sub5", $sub3, "sub5 again", $sub4);

$elt= XML::Twig::Elt->new( 'p', { att1 => 'val1'}, $sub1, $sub2, $sub5);
$res= $elt->sprint;
$exp_res= '<p att1="val1"><sub/><sub att="val"/>'.
          '<sub>sub5<sub>sub3</sub>sub5 again<sub>sub4</sub></sub></p>';
if( $res eq $exp_res) { print "ok 49\n"; }
else { print "not ok 49\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$elt->set_empty_tag_style( 'html');
$res= $elt->sprint;
$exp_res= '<p att1="val1"><sub></sub><sub att="val"></sub>'.
          '<sub>sub5<sub>sub3</sub>sub5 again<sub>sub4</sub></sub></p>';
if( $res eq $exp_res) { print "ok 50\n"; }
else { print "not ok 50\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$elt->set_empty_tag_style( 'expand');
$res= $elt->sprint;
$exp_res= '<p att1="val1"><sub></sub><sub att="val"></sub>'.
          '<sub>sub5<sub>sub3</sub>sub5 again<sub>sub4</sub></sub></p>';
if( $res eq $exp_res) { print "ok 51\n"; }
else { print "not ok 51\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$elt->set_empty_tag_style( 'normal');
$res= $elt->sprint;
$exp_res= '<p att1="val1"><sub/><sub att="val"/>'.
          '<sub>sub5<sub>sub3</sub>sub5 again<sub>sub4</sub></sub></p>';
if( $res eq $exp_res) { print "ok 52\n"; }
else { print "not ok 52\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

my $new_elt= parse XML::Twig::Elt( $res);
$res= $new_elt->sprint;
$exp_res= '<p att1="val1"><sub/><sub att="val"/>'.
          '<sub>sub5<sub>sub3</sub>sub5 again<sub>sub4</sub></sub></p>';
if( $res eq $exp_res) { print "ok 53\n"; }
else { print "not ok 53\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$doc='<doc><elt att="val1">text1</elt><root>root1</root><elt>text 2</elt></doc>';
$res='';
$exp_res= '<elt att="val1">text1</elt>';
$t= new XML::Twig( TwigHandlers => 
                        { 'elt[string()="text1"]' => \&display1,
                          'elt[@att="val1"]' => \&display1,
			},
		    );
$t->parse( $doc);

sub display1 { $res .=$_[1]->sprint; return 0; }
if( $res eq $exp_res) { print "ok 54\n"; }
else { print "not ok 54\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$res='';
$exp_res= '<elt att="val1">text1</elt>' x 2;
$t= new XML::Twig( TwigHandlers => 
                        { 'elt[string()="text1"]' => \&display2,
                          'elt[@att="val1"]' => \&display2,
			},
		    );
$t->parse( $doc);

sub display2 { $res .=$_[1]->sprint; }
if( $res eq $exp_res) { print "ok 55\n"; }
else { print "not ok 55\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$doc= '<doc id="doc1"><elt id="elt1"><sub id="sub1"/><sub id="sub2"/></elt></doc>';
$t= new XML::Twig;
$t->parse( $doc);

$res= $t->first_elt->id;
$exp_res= 'doc1';
if( $res eq $exp_res) { print "ok 56\n"; }
else { print "not ok 56\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$res= $t->first_elt( 'doc')->id;
$exp_res= 'doc1';
if( $res eq $exp_res) { print "ok 57\n"; }
else { print "not ok 57\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$res= $t->first_elt( 'sub')->id;
$exp_res= 'sub1';
if( $res eq $exp_res) { print "ok 58\n"; }
else { print "not ok 58\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$sub1= $t->first_elt( 'sub');
$res= $sub1->next_elt( 'sub')->id;
$exp_res= 'sub2';
if( $res eq $exp_res) { print "ok 59\n"; }
else { print "not ok 59\n"; warn "returns \n$res\n instead of \n$exp_res\n"; }

$sub1= $t->first_elt( 'sub');
$res= $sub1->next_elt( $sub1, 'sub');
unless( defined $res) { print "ok 60\n"; }
else { print "not ok 60\n"; warn "should return undef, returned elt is " . $res->id; }

$sub1= $t->first_elt( 'sub');
$sub2= $sub1->next_elt( 'sub');
$res= $sub2->next_elt( 'sub');
unless( defined $res) { print "ok 61\n"; }
else { print "not ok 61\n"; warn "should return undef, returned elt is" . $res->id; }

# test : (for name spaces) in elements
$doc="<doc><ns:p>p1</ns:p><p>p</p><ns:p>p2</ns:p></doc>";
$res='';
$exp_res='p1p2';
$t= new XML::Twig( TwigHandlers => { 'ns:p' => sub { $res .= $_[1]->text; } });
$t->parse( $doc);
if( $res eq $exp_res) { print "ok 62\n"; }
else                  { print "not ok 62\n"; warn "should return $exp_res, returned $res"; }

$exp_res="p";
my $e_res= $t->get_xpath( '/doc/p', 0);
$res= $e_res->text;
if( $res eq $exp_res) { print "ok 63\n"; }
else                  { print "not ok 63\n"; warn "should return $exp_res, returned $res"; }

$exp_res='p1p2';
$res='';
foreach ($t->get_xpath( 'ns:p'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 64\n"; }
else                  { print "not ok 64\n"; warn "should return $exp_res, returned $res"; }


# test : (for name spaces) in attributes
$doc='<doc><ns:p ns:a="a1">p1</ns:p><p ns:a="a1">p</p><p a="a1">p3</p>
      <ns:p ns:a="a2">p2</ns:p></doc>';
$res='';
$exp_res='p1';
$t= new XML::Twig( TwigHandlers => 
                   { 'ns:p[@ns:a="a1"]' => sub { $res .= $_[1]->text; } });
$t->parse( $doc);
if( $res eq $exp_res) { print "ok 65\n"; }
else                  { print "not ok 65\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p3';
foreach ($t->find_nodes( 'p[@a="a1"]'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 66\n"; }
else                  { print "not ok 66\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p1';
foreach ($t->find_nodes( 'ns:p[@ns:a="a1"]'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 67\n"; }
else                  { print "not ok 67\n"; warn "should return $exp_res, returned $res"; }


$res='';
$exp_res='p1p2';
foreach ($t->get_xpath( 'ns:p[@ns:a="a1" or @ns:a="a2"]'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 68\n"; }
else                  { print "not ok 68\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p';
foreach ($t->get_xpath( 'p[@b="a1" or @ns:a="a1"]'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 69\n"; }
else                  { print "not ok 69\n"; warn "should return $exp_res, returned $res"; }

$doc='<doc><p ns:a="a1">p1</p><p a="a1">p2</p><p>p3</p><p a="0">p4</p></doc>';
$res='';
$exp_res='p2p4';
$t= new XML::Twig( twig_handlers =>
                           { 'p[@a]' =>  sub { $res .= $_[1]->text; } });
$t->parse( $doc);
if( $res eq $exp_res) { print "ok 70\n"; }
else                  { print "not ok 70\n"; warn "should return $exp_res, returned $res"; }

$res='';
foreach ($t->get_xpath( '//p[@a]'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 71\n"; }
else                  { print "not ok 71\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p1p2p4';
foreach ($t->get_xpath( '//p[@ns:a or @a ]'))
  {  $res .= $_->text; }
if( $res eq $exp_res) { print "ok 72\n"; }
else                  { print "not ok 72\n"; warn "should return $exp_res, returned $res"; }

$doc='<doc><p a="a1">p1</p><ns:p a="a1">p2</ns:p>
      <p>p3</p><p a="0">p4</p></doc>';

$res='';
$exp_res='p1p2p4';
$t= new XML::Twig();
$t->parse( $doc);
$res .= $_->text foreach ($t->get_xpath( '//*[@a]'));
if( $res eq $exp_res) { print "ok 73\n"; }
else                  { print "not ok 73\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p1p2';
$res .= $_->text foreach ($t->get_xpath( '*[@a="a1"]'));
if( $res eq $exp_res) { print "ok 74\n"; }
else                  { print "not ok 74\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p1p2';
$res .= $_->text foreach ($t->get_xpath( '//*[@a="a1"]'));
if( $res eq $exp_res) { print "ok 75\n"; }
else                  { print "not ok 75\n"; warn "should return $exp_res, returned $res"; }

$res='';
$exp_res='p1';
$res .= $_->text foreach ($t->get_xpath( 'p[string()= "p1"]'));
if( $res eq $exp_res) { print "ok 76\n"; }
else                  { print "not ok 76\n"; warn "should return $exp_res, returned $res"; }

$doc='<doc><ns:p ns:a="a1">p1</ns:p><p ns:a="a1">p</p><p a="a1">p3</p>
      <ns:p ns:a="a2">p2</ns:p></doc>';
$res='';
$exp_res='p1p';
$t= new XML::Twig( TwigHandlers => 
                   { '[@ns:a="a1"]' => sub { $res .= $_[1]->text; } });
$t->parse( $doc);
if( $res eq $exp_res) { print "ok 77\n"; }
else                  { print "not ok 77\n"; warn "should return $exp_res, returned $res"; }

$res='';
$res2='';
$exp_res2='p2';
$t= new XML::Twig( TwigHandlers => 
                   { '[@ns:a="a1"]' => sub { $res  .= $_[1]->text; },
                     '[@ns:a="a2"]' => sub { $res2 .= $_[1]->text; } });
$t->parse( $doc);
if( $res eq $exp_res) { print "ok 78\n"; }
else                  { print "not ok 78\n"; warn "should return $exp_res, returned $res"; }
if( $res2 eq $exp_res2) { print "ok 79\n"; }
else                 { print "not ok 79\n"; warn "should return $exp_res2, returned $res2"; }

$elt= XML::Twig::Elt->new( 'p', { att => 'val', '#EMPTY' => 0 });
$res= $elt->sprint;
$exp_res= '<p att="val"></p>';
if( $res eq $exp_res) { print "ok 80\n"; }
else { print "not ok 80\n"; warn "returns $res instead of $exp_res\n"; }

exit 0;


