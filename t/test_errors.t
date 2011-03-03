#!/usr/bin/perl -w

# test error conditions

use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use Config;
use tools;

#$|=1;

use XML::Twig;

my $TMAX=110; 
print "1..$TMAX\n";

my $error_file= File::Spec->catfile('t','test_errors.errors');
my( $q, $q2) = ( ($^O eq "MSWin32") || ($^O eq 'VMS') ) ? ('"', "'") : ("'", '"');

{ # test insufficient version of XML::Parser (not that easy, it is already too late here)
my $need_version= 2.23;


use Config;
my $perl= used_perl();

my $version= $need_version - 0.01;
unlink $error_file if -f $error_file;
if ($^O eq 'VMS') {
    system( qq{$perl $q-Mblib$q -e$q use vmsish qw(hushed);use XML::Parser; BEGIN { \$XML::Parser::VERSION=$version}; use XML::Twig $q 2> $error_file});
} else {
    system( qq{$perl $q-Iblib/lib$q -e$q use XML::Parser; BEGIN { \$XML::Parser::VERSION=$version}; use XML::Twig $q 2> $error_file});
}

ok( -f $error_file, "error generated for low version of XML::Parser");
matches( slurp_error( $error_file), "need at least XML::Parser version ", "error message for low version of XML::Parser");

$version= $need_version;
unlink $error_file if -f $error_file;
system( qq{$perl $q-Mblib$q -e$q use XML::Parser; BEGIN { \$XML::Parser::VERSION=$version}; use XML::Twig $q 2> $error_file});
ok( ! -f $error_file || slurp_error( $error_file)!~ "need at least XML::Parser version",
    "no error generated for proper version of XML::Parser"
  );

$version= $need_version + 0.01;
unlink $error_file if -f $error_file;
system( qq{$^X -e$q use XML::Parser; BEGIN { \$XML::Parser::VERSION=$version}; use XML::Twig$q 2> $error_file});
ok( ! -f $error_file || slurp_error( $error_file)!~ "need at least XML::Parser version", 
    "no error generated for high version of XML::Parser"
  );

unlink $error_file if -f $error_file;

}

my $warning;
my $init_warn= $SIG{__WARN__};

{ $SIG{__WARN__}= sub { $warning= join '', @_; };
  XML::Twig->new( dummy => 1);
  $SIG{__WARN__}= $init_warn;
  matches( $warning, "invalid option Dummy", "invalid option");
}

{ eval { XML::Twig::_slurp( $error_file) };
  matches( $@, "cannot open '\Q$error_file\E'", "_slurp inexisting file");
}

{ eval {XML::Twig->new->parse( '<doc/>')->root->first_child( 'du,')};
  matches( $@, "wrong navigation condition", "invalid navigation expression");
}

{ eval {XML::Twig->new->parse( '<doc/>')->root->first_child( '@val=~/[/')};
  matches( $@, "wrong navigation condition", "invalid navigation expression");
}



{ eval {XML::Twig->new( twig_print_outside_roots => 1)};
  matches( $@, "cannot use twig_print_outside_roots without twig_roots", "invalid option");
}

{ eval {XML::Twig->new( keep_spaces => 1, discard_spaces => 1 )};
  matches( $@, "cannot use both keep_spaces and discard_spaces", "invalid option combination 1");
  eval {XML::Twig->new( keep_spaces => 1, keep_spaces_in => ['p'])};
  matches( $@, "cannot use both keep_spaces and keep_spaces_in", "invalid option combination 2");
  eval {XML::Twig->new( discard_spaces => 1, keep_spaces_in => ['p'])};
  matches( $@, "cannot use both discard_spaces and keep_spaces_in", "invalid option combination 3");
  eval {XML::Twig->new( keep_spaces_in => [ 'doc' ], discard_spaces_in => ['p'])};
  matches( $@, "cannot use both keep_spaces_in and discard_spaces_in", "invalid option combination 4");
  eval {XML::Twig->new( comments => 'wrong') };
  matches( $@, "wrong value for comments argument: 'wrong'", "invalid option value for comment");
  eval {XML::Twig->new( pi => 'wrong') };
  matches( $@, "wrong value for pi argument: 'wrong'", "invalid option value for pi");
}

{ my $t=XML::Twig->new->parse( '<doc><p> p1</p><p>p 2</p></doc>');
  my $elt= $t->root;
  eval { $elt->sort_children( sub  { }, type => 'wrong'); };
  matches( $@, "wrong sort type 'wrong', should be either 'alpha' or 'numeric'", "sort type");
}
{
  foreach my $wrong_path ( 'wrong path', 'wrong#path', '1', '1tag', '///tag', 'tag/')
    { eval {XML::Twig->new( twig_handlers => { $wrong_path => sub {}});};
      matches( $@, "unrecognized expression in handler: '$wrong_path'", "wrong handler ($wrong_path)");
    }

  eval {XML::Twig->new( input_filter => 'dummy')};
  matches( $@, "invalid input filter:", "input filter");
  eval {XML::Twig->new( input_filter => {})};
  matches( $@, "invalid input filter:", "input filter");
}

{ foreach my $bad_tag ( 'toto', '<1toto', '<foo:bar:baz', '< foo::bar', '<_toto', '<-toto', '<totoatt=', '<#toto', '<toto')
    { eval {XML::Twig::_parse_start_tag( qq{$bad_tag})};
      matches( $@, "error parsing tag '$bad_tag'", "bad tag '$bad_tag'");
      eval {XML::Twig::Elt::_match_expr( qq{$bad_tag})};
      matches( $@, "error parsing tag '$bad_tag'", "bad tag '$bad_tag'");
    }
}

{ my $t= XML::Twig->new( twig_handlers => { sax => sub { $_[0]->toSAX1 } });
  eval {$t->parse( '<doc><sax/></doc>')};
  matches( $@, "cannot use toSAX1 while parsing", "toSAX1 during parsing");
}

{ my $t= XML::Twig->new( twig_handlers => { sax => sub { $_[0]->toSAX2 } });
  eval {$t->parse( '<doc><sax/></doc>')};
  matches( $@, "cannot use toSAX2 while parsing", "toSAX2 during parsing");
}

{ my $t= XML::Twig->new->parse( '<doc/>');
  foreach my $bad_cond ( 'foo bar', 'foo:bar:baz', '.', '..', '...', '**', 'con[@to:ta:ti]')
    { eval { $t->root->first_child( qq{$bad_cond})};
      matches( $@, "wrong navigation condition '\Q$bad_cond\E'", "bad navigation condition '$bad_cond'");
    }
}

{ my $t= XML::Twig->new->parse( '<doc><field/></doc>');
  eval { $t->root->set_field( '*[2]'); };
  matches( $@, "can't create a field name from", 'set_field');
}

{ my $t= XML::Twig->new( twig_handlers => { erase => sub { $_->parent->erase } });
  eval { $t->parse( '<doc><p><erase>toto</erase></p></doc>'); };
  matches( $@, "trying to erase an element before it has been completely parsed", 'erase current element');
}

{ my $t= XML::Twig->new->parse( '<doc><erase><e1/><e2/></erase></doc>');
  my $e= $t->first_elt( 'erase')->cut;
  eval { $e->erase };
  matches( $@, "can only erase an element with no parent if it has a single child", 'erase cut element');
  $e->paste( $t->root);
  eval { $e->paste( first_child => $t->root); };
  matches( $@, "cannot paste an element that belongs to a tree", 'paste uncut element');
  $e->cut;
  eval { $e->paste( $t->root => 'first_child' ); };
  matches( $@, "wrong argument order in paste, should be", 'paste uncut element');
  eval { $e->paste( first_child  => {} ); };
  matches( $@, "wrong target type in paste: 'HASH', should be XML::Twig::Elt", 'paste with wrong ref');
  eval { $e->paste( 'first_child' ); };
  matches( $@, "missing target in paste", 'paste with no target');
  eval { $e->paste( 'first_child', 1 ); };
  matches( $@, 'wrong target type in paste \(not a reference\)', 'paste with no ref');
  eval { $e->paste( 'first_child', bless( {}, 'foo') ); };
  matches( $@, "wrong target type in paste: 'foo'", 'paste with wrong object type');
  eval { $e->paste( wrong => $t->root ); };
  matches( $@, "tried to paste in wrong position 'wrong'", 'paste in wrong position');
  eval { $e->paste( before => $t->root); };
  matches( $@, "cannot paste before root", 'paste before root');
  eval { $e->paste( after => $t->root); };
  matches( $@, "cannot paste after root", 'paste after root');
  eval { $e->paste_before( $t->root); };
  matches( $@, "cannot paste before root", 'paste before root');
  eval { $e->paste_after( $t->root); };
  matches( $@, "cannot paste after root", 'paste after root');
  
}

{ my $t= XML::Twig->new->parse( '<doc><p>text1</p><p>text2</p></doc>');
  my $p1= $t->root->first_child( 'p');
  my $p2= $t->root->first_child( 'p[2]');
  eval { $p1->merge_text( 'toto'); } ;
  matches( $@, "invalid merge: can only merge 2 elements", 'merge elt and string');
  eval { $p1->merge_text( $p2); } ;
  matches( $@, "invalid merge: can only merge 2 text elements", 'merge non text elts');
  $p1->first_child->merge_text( $p2->first_child);
  is( $t->sprint, '<doc><p>text1text2</p><p></p></doc>', 'merge_text');
  my $p3= XML::Twig::Elt->new( '#CDATA' => 'foo');
  eval { $p1->first_child->merge_text( $p3); };
  matches( $@, "invalid merge: can only merge 2 text elements", 'merge cdata and pcdata elts');
  
}

{ my $t= XML::Twig->new;
  $t->save_global_state;
  eval { $t->set_pretty_print( 'foo'); };
  matches( $@, "invalid pretty print style 'foo'", 'invalid pretty_print style');
  eval { $t->set_pretty_print( 987); };
  matches( $@, "invalid pretty print style 987", 'invalid pretty_print style');
  eval { $t->set_empty_tag_style( 'foo'); };
  matches( $@, "invalid empty tag style 'foo'", 'invalid empty_tag style');
  eval { $t->set_empty_tag_style( '987'); };
  matches( $@, "invalid empty tag style 987", 'invalid empty_tag style');
  eval { $t->set_quote( 'foo'); };
  matches( $@, "invalid quote 'foo'", 'invalid quote style');
  eval { $t->set_output_filter( 'foo'); };
  matches( $@, "invalid output filter 'foo'", 'invalid output filter style');
  eval { $t->set_output_text_filter( 'foo'); };
  matches( $@, "invalid output text filter 'foo'", 'invalid output text filter style');
}
  
{ my $t= XML::Twig->new->parse( '<doc/>');
  my @methods= qw( depth in_element within_element context current_line current_column current_byte
                   recognized_string original_string xpcroak xpcarp xml_escape base current_element 
                   element_index position_in_context
                 );
  my $method;
  foreach $method ( @methods)
    { eval "\$t->$method"; 
      matches( $@, "calling $method after parsing is finished", $method);
    }
  $SIG{__WARN__}= $init_warn;
}

{ my $t= XML::Twig->new->parse( '<doc><elt/></doc>');
  my $elt= $t->root->first_child( 'elt')->cut;
  foreach my $pos ( qw( before after))
    { eval { $elt->paste( $pos => $t->root); };
      matches( $@, "cannot paste $pos root", "paste( $pos => root)");
    }
}

{  my $t= XML::Twig->new->parse( '<doc><a><f1>f1</f1><f2>f2</f2></a></doc>');
   eval { $t->root->simplify( group_tags => { a => 'f1' }); };
   matches( $@, "error in grouped tag a", "grouped tag error f1");
   eval { $t->root->simplify( group_tags => { a => 'f2' }); };
   matches( $@, "error in grouped tag a", "grouped tag error f2");
   eval { $t->root->simplify( group_tags => { a => 'f3' }); };
   matches( $@, "error in grouped tag a", "grouped tag error f3");
}

{  eval { XML::Twig::Elt->parse( '<e>foo</e>')->subs_text( "foo", '&elt( 0/0)'); };
   matches( $@, "(invalid replacement expression |Illegal division by zero)", "invalid replacement expression in subs_text");
}

{ eval { my $t=XML::Twig->new( twig_handlers => { e => sub { $_[0]->parse( "<doc/>") } });
            $t->parse( "<d><e/></d>");
       };
  matches( $@, "cannot reuse a twig that is already parsing", "error re-using a twig during parsing");
}

{ ok( XML::Twig->new( twig_handlers => { 'elt[string()="foo"]' => sub {}} ), 'twig_handlers with string condition' );
  eval { XML::Twig->new( twig_roots => { 'elt[string()="foo"]' => sub {}} ) };
  matches( $@, "string.. condition not supported on twig_roots option", 'twig_roots with string condition' );
  ok( XML::Twig->new( twig_handlers => { 'elt[string()=~ /foo/]' => sub {}} ), 'twig_handlers with regexp' );
  eval { XML::Twig->new( twig_roots => { 'elt[string()=~ /foo/]' => sub {}} ) };
  matches( $@, "string.. condition not supported on twig_roots option", 'twig_roots with regexp condition' );

  #ok( XML::Twig->new( twig_handlers => { 'elt[string()!="foo"]' => sub {}} ), 'twig_handlers with !string condition' );
  #eval { XML::Twig->new( twig_roots => { 'elt[string()!="foo"]' => sub {}} ) };
  #matches( $@, "string.. condition not supported on twig_roots option", 'twig_roots with !string condition' );
  #ok( XML::Twig->new( twig_handlers => { 'elt[string()!~ /foo/]' => sub {}} ), 'twig_handlers with !regexp' );
  #eval { XML::Twig->new( twig_roots => { 'elt[string()!~ /foo/]' => sub {}} ) };
  #matches( $@, "regexp condition not supported on twig_roots option", 'twig_roots with !regexp condition' );

}

{ XML::Twig::_disallow_use( "XML::Parser");
  nok( XML::Twig::_use( "XML::Parser"), '_use XML::Parser (disallowed)');
  XML::Twig::_allow_use( "XML::Parser");
  ok( XML::Twig::_use( "XML::Parser"), '_use XML::Parser (allowed)');
  ok( XML::Twig::_use( "XML::Parser"), '_use XML::Parser (allowed, 2cd try)');
  nok( XML::Twig::_use( "XML::Parser::foo::nonexistent"), '_use XML::Parser::foo::nonexistent');
}

{ XML::Twig::_disallow_use( "Tie::IxHash");
  eval { XML::Twig->new( keep_atts_order => 1); };
  matches( $@, "Tie::IxHash not available, option keep_atts_order not allowed", 'no Tie::IxHash' );
}

{ eval { XML::Twig::_first_n { $_ } 0, 1, 2, 3; }; 
  matches( $@, "illegal position number 0", 'null argument to _first_n' );
}

{ if( ( $] <= 5.008) || ($^O eq 'VMS') )
    { skip(1, 'test perl -CSDAL'); }
  elsif( ! can_check_for_pipes() )
    { skip( 1, 'your perl cannot check for pipes'); }
  else
    { 
      my $infile= File::Spec->catfile('t','test_new_features_3_22.xml');
      my $script= File::Spec->catfile('t','test_error_with_unicode_layer');
      my $error=File::Spec->catfile('t','error.log');
      
      my $perl = used_perl();

    
      my $cmd= qq{$perl $q-CSDAL$q $script $infile 2>$error};
      system $cmd;

      matches( slurp( $error), "cannot parse the output of a pipe", 'parse a pipe with perlIO layer set to UTF8 (RT #17500)');
    }
}

exit 0;

sub can_check_for_pipes
  { my $perl = used_perl();
    open( FH, qq{$perl -e$q print 1$q |}) or die "error opening pipe: $!";
    return -p FH;
  }
