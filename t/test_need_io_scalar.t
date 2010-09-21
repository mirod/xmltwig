#!/usr/bin/perl -w


# tests that require IO::String to run
use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

#$|=1;
my $DEBUG=0;

use XML::Twig;

BEGIN 
  { eval "require IO::String";
    if( $@) 
      { print "1..1\nok 1\n"; 
        warn "skipping, need IO::String\n";
        exit;
      } 
    else
      { import IO::String; }
  }

print "1..1778\n";

{ my $out1='';
  my $fh1= IO::String->new( \$out1);
  my $out2='';
  my $fh2= IO::String->new( \$out2);
  my $doc='<d><e><m>main</m><i>ignored<i2>completely</i2></i><m>in</m></e><i>ignored<i2>completely</i2></i></d>';
  my $out= select $fh1;
  my $t= XML::Twig->new( ignore_elts => { i => 'print' })->parse( $doc);
  $t->print( $fh2);
  select $out;
  is( $out1,'<i>ignored<i2>completely</i2></i><i>ignored<i2>completely</i2></i>', 'ignored with print option'); 
  is( $out2,'<d><e><m>main</m><m>in</m></e></d>', 'print after ignored_elts');
}
   
{ my $doc='<d><e><m>main</m><i>ignored<i2>completely</i2></i><m>in</m></e><i>ignored<i2>completely</i2></i></d>';
  my $t= XML::Twig->new( ignore_elts => { i => 'string' })->parse( $doc);
  is( $t->{twig_buffered_string} || '','<i>ignored<i2>completely</i2></i><i>ignored<i2>completely</i2></i>', 'ignored with string option'); 
  is( $t->sprint,'<d><e><m>main</m><m>in</m></e></d>', 'string after ignored_elts (to string)');
}
      
{ my $string='';
  my $doc='<d><e><m>main</m><i>ignored<i2>completely</i2></i><m>in</m></e><i>ignored<i2>completely</i2></i></d>';
  my $t= XML::Twig->new( ignore_elts => { i => \$string })->parse( $doc);
  is( $string,'<i>ignored<i2>completely</i2></i><i>ignored<i2>completely</i2></i>', 'ignored with string reference option'); 
  is( $t->sprint,'<d><e><m>main</m><m>in</m></e></d>', 'string after ignored_elts (to string reference)');
}
                      
                
{ # test autoflush
  my $out=''; 
  my $fh= IO::String->new( \$out);  
  my $doc= "<doc><elt/></doc>";
  my $t= XML::Twig->nparse( twig_handlers => { elt => sub { $_->flush( $fh) } }, $doc);
  is( $out, $doc, "autoflush, no args");
}

{ my $out=''; 
  my $fh= IO::String->new( \$out);
  my $doc= "<doc><elt/></doc>";
  my $t= XML::Twig->nparse( twig_handlers => { elt => sub { $_->flush( $fh, empty_tags => "expand") } }, $doc);
  is( $out, "<doc><elt></elt></doc>", "autoflush, no args, expand empty tags");
}

{ # test bug on comments after the root element RT #17064
  my $out=''; 
  my $fh= IO::String->new( \$out);
  my $doc= q{<doc/><!-- comment1 --><?t pi?><!--comment2 -->};
  XML::Twig->nparse( $doc)->print( $fh);
  is( $out, $doc, 'comment after root element');
}

{ # more tests, with flush this time
  my $c= '<!--c#-->';
  my $pi= '<?t pi #?>';
  my @simple_docs= ('<doc/>', '<doc><!--c--></doc>', '<doc><elt>foo</elt></doc>');
  my $i=0;
  my @docs= map { $i++; (my $l= $_)=~ s{#}{$i}g;
                  $i++; (my $t= $_)=~ s{#}{$i}g;
                  map { ("$l$_", "$_$t", "$l$_$t") } @simple_docs;
                 }
                 ( $c, $pi, $c.$pi, $pi.$c, $c.$c, $pi.$pi, $c.$pi.$c, $pi.$c.$pi, $c.$pi.$c.$pi, $pi.$c.$pi.$c, $c.$c.$pi, $c.$pi.$pi)
                ;
  foreach my $doc (@docs)
    { foreach my $options ( { comments => "keep",    pi => "keep"    },
                            { comments => "process", pi => "keep"    },
                            { comments => "keep",    pi => "process" },
                            { comments => "process", pi => "process" },
                          )
        { my $options_text= join( ', ', map { "$_ => $options->{$_}" } sort keys %$options);
          is( XML::Twig->nparse( %$options, $doc)->sprint, $doc, "sprint cpi $options_text $doc");
          is( XML::Twig->nparse( %$options, keep_encoding => 1, $doc)->sprint, $doc, "sprint cpi keep_encoding $options_text $doc");
          { my $out='';
            my $fh= IO::String->new( \$out);
            XML::Twig->nparse( %$options, $doc)->flush( $fh);
            is( $out, $doc, "flush cpi $options_text $doc");
          }
          { my $out='';
            my $fh= IO::String->new( \$out);
            XML::Twig->nparse( keep_encoding => 1, %$options, $doc)->flush( $fh);
            is( $out, $doc, "flush cpi keep_encoding $options_text $doc");
          }
        }
    }
}


{ my $out=''; 
  my $fh= IO::String->new( \$out);
  my $doc=q{<doc><link/><link></link><script/><script></script><elt>foo</elt><elt /><elt2/><link/><link></link><script/><script></script></doc>};
  my $t= XML::Twig->new( pretty_print => 'indented', empty_tags => 'expand',
                         twig_handlers => { elt => sub { $_[0]->flush( $fh, pretty_print => 'none',
                                                                            empty_tags => 'html'
                                                                      );
                                                       },
                                          },
                       );
  $t->{twig_autoflush}=0;
  $t->parse( $doc);
  is( $out => q{<doc><link /><link /><script></script><script></script><elt>foo</elt><elt></elt>}, 'flush with a pretty_print arg');
  is( $t->sprint => qq{<doc>\n  <elt2></elt2>\n  <link></link>\n  <link></link>\n  <script></script>\n  <script></script>\n</doc>\n},
      'flush with a pretty_print arg (checking that option values are properly restored)'
    );
}
  
{ my $out=''; 
  my $fh= IO::String->new( \$out);
  select $fh;
  my $doc=q{<doc><link/><link></link><script/><script></script><elt>foo</elt><elt /><elt2/><link/><link></link><script/><script></script></doc>};
  my $t= XML::Twig->new( pretty_print => 'indented', empty_tags => 'expand',
                         twig_handlers => { elt => sub { $_[0]->flush( pretty_print => 'none',
                                                                       empty_tags => 'html'
                                                                      );
                                                       },
                                          },
                       );
  $t->{twig_autoflush}=0;
  $t->parse( $doc);
  select STDOUT;
  is( $out => q{<doc><link /><link /><script></script><script></script><elt>foo</elt><elt></elt>}, 'flush with a pretty_print arg (default fh)');
  is( $t->sprint => qq{<doc>\n  <elt2></elt2>\n  <link></link>\n  <link></link>\n  <script></script>\n  <script></script>\n</doc>\n},
      'flush with a pretty_print arg (checking that option values are properly restored) (default fh)'
    );
}
  
{ my $out=''; 
  my $fh= IO::String->new( \$out);
  select $fh;
  my $doc=q{<doc><elt>foo</elt><elt /><elt2/></doc>};
  my $t= XML::Twig->new( pretty_print => 'indented', empty_tags => 'expand',
                         twig_handlers => { elt => sub { $_[0]->flush_up_to( $_, pretty_print => 'none',
                                                                       empty_tags => 'html'
                                                                      );
                                                       },
                                          },
                       );
  $t->{twig_autoflush}=0;
  $t->parse( $doc);
  select STDOUT;
  is( $out => q{<doc><elt>foo</elt><elt></elt>}, 'flush with a pretty_print arg (default fh)');
  is( $t->sprint => qq{<doc>\n  <elt2></elt2>\n</doc>\n},
      'flush with a pretty_print arg (checking that option values are properly restored)'
    );
}
  

{ my $out=''; my $out2=''; my $out3=''; my $out4='';
  my $fh=  IO::String->new( \$out);
  my $fh2= IO::String->new( \$out2);
  my $fh3= IO::String->new( \$out3);
  my $fh4= IO::String->new( \$out4);
  my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none')->parse( '<doc><elt/></doc>');
  $t->print( $fh);
  is( $out, "<doc><elt></elt></doc>", "empty_tags expand"); 
  $t->print( $fh2, empty_tags => 'normal', pretty_print => 'indented' );
  is( $out2, "<doc>\n  <elt/>\n</doc>\n", "print with args"); 

  $t->print( $fh3);
  is( $out3, "<doc><elt></elt></doc>", "print without args"); 
  is( $t->sprint( empty_tags => 'normal'), "<doc><elt/></doc>", "empty_tags normal"); 
  $t->print( $fh4);
  is( $t->sprint( pretty_print => 'indented', empty_tags => 'normal'), "<doc>\n  <elt/>\n</doc>\n", "empty_tags expand"); 
  $t->set_pretty_print( 'none');
  $t->set_empty_tag_style( 'normal');
}

{ my $out=''; my $out2='';
  my $fh= IO::String->new( \$out);
  my $fh2= IO::String->new( \$out2);
  my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none')->parse( '<doc><elt/></doc>');
  $t->root->print( $fh);
  is( $out, "<doc><elt></elt></doc>", "empty_tags expand"); 
  $t->root->print( $fh2, { pretty_print => 'indented' } );
  is( $out2, "<doc>\n  <elt></elt>\n</doc>\n", "print elt indented"); 
  $out=''; $fh= IO::String->new( \$out); $t->root->print( $fh);
  is( $out, "<doc><elt></elt></doc>", "back to default"); 
  $t->set_pretty_print( 'none');
  $t->set_empty_tag_style( 'normal');
}



{ my $out=''; my $out2='';
  my $fh= IO::String->new( \$out);
  my $fh2= IO::String->new( \$out2);
  my $t= XML::Twig->new( empty_tags => 'expand', pretty_print => 'none');
  $t->parse( '<doc><elt/></doc>')->flush( $fh);
  is( $out, "<doc><elt></elt></doc>", "empty_tags expand"); 
  $t->parse( '<doc><elt/></doc>')->flush( $fh2);
  is( $t->sprint( empty_tags => 'normal'), "<doc><elt/></doc>", "empty_tags normal"); 
  $out=''; $t->parse( '<doc><elt/></doc>')->flush( $fh);
  is( $t->sprint( pretty_print => 'indented', empty_tags => 'normal'), "<doc>\n  <elt/>\n</doc>\n", "empty_tags expand"); 
  $t->set_pretty_print( 'none');
  $t->set_empty_tag_style( 'normal');
}

{ my $out='';
  my $fh= IO::String->new( \$out);
  my $doc= q{<doc><sect><p>p1</p><p>p2</p><flush/></sect></doc>};
  my $t= XML::Twig->new( twig_handlers => { flush => sub { $_->flush( $fh) } } );
  $t->{twig_autoflush}=0;
  $t->parse( $doc);
  is( $out, q{<doc><sect><p>p1</p><p>p2</p><flush/>}, "flush"); 
  close $fh;

  $out="";
  $fh= IO::String->new( \$out);
  $t= XML::Twig->new( twig_handlers => { flush => sub { $_[0]->flush_up_to( $_->prev_sibling, $fh) } } );
  $t->{twig_autoflush}=0;
  $t->parse( $doc);
  is( $out, q{<doc><sect><p>p1</p><p>p2</p>}, "flush_up_to"); 

  $t= XML::Twig->new( twig_handlers => { purge => sub { $_[0]->purge_up_to( $_->prev_sibling->prev_sibling, $fh) } } )
                  ->parse( q{<doc><sect2/><sect><p>p1</p><p><sp>sp 1</sp></p><purge/></sect></doc>});
  is( $t->sprint, q{<doc><sect><p><sp>sp 1</sp></p><purge/></sect></doc>}, "purge_up_to"); 
}

{ my $out='';
  my $fh= IO::String->new( \$out);
  my $t= XML::Twig->new()->parse( q{<!DOCTYPE doc [<!ELEMENT doc (#PCDATA)*>]><doc>toto</doc>});
  $t->dtd_print( $fh);
  is( $out, "<!DOCTYPE doc [\n<!ELEMENT doc (#PCDATA)*>\n\n]>\n", "dtd_print"); 
  close $fh;
}

{ my $out="";
  my $fh= IO::String->new( \$out);
  my $t= XML::Twig->new( twig_handlers => { stop => sub { print $fh "[X]"; $_->set_text( '[Y]'); $_[0]->flush( $fh); $_[0]->finish_print( $fh); } });
  $t->{twig_autoflush}=0;
  $t->parse( q{<doc>before<stop/>finish</doc>});
  select STDOUT;
  is( $out, q{[X]<doc>before<stop>[Y]</stop>finish</doc>}, "finish_print"); 
}


package test_handlers;
sub new { bless { } }
sub recognized_string { return 'recognized_string'; }
sub original_string { return 'original_string'; }
package main;


{ 
  my $out='';
  my $fh= IO::String->new( \$out);
  my $stdout= select $fh;
  XML::Twig::_twig_print_original_default( test_handlers->new);
  select $stdout;
  close $fh;
  is( $out, 'original_string', 'twig_print_original_default'); 

  $out='';
  $fh= IO::String->new( \$out);
  select $fh;
  XML::Twig::_twig_print( test_handlers->new);
  select $stdout;
  close $fh;
  is( $out, 'recognized_string', 'twig_print_default'); 

  $out='';
  $fh= IO::String->new( \$out);
  select $fh;
  XML::Twig::_twig_print_end_original( test_handlers->new);
  select $stdout;
  close $fh;
  is( $out, 'original_string', 'twig_print_end_original'); 

  $out='';
  $fh= IO::String->new( \$out);
  select $fh;
  XML::Twig::_twig_print( test_handlers->new);
  select $stdout;
  close $fh;
  is( $out, 'recognized_string', 'twig_print_end'); 
}

XML::Twig::_twig_print_entity(); # does nothing!


{ 
  my %ents= ( foo => '"toto"', pile => 'SYSTEM "file.bar" NDATA bar');
  my %ent_text = hash_ent_text( %ents);
  my $ent_text = string_ent_text( %ents); 

  my $doc= "<!DOCTYPE doc [$ent_text]><doc/>";

  my $t= XML::Twig->new->parse( $doc);
  is( normalize_xml( $t->entity_list->text), $ent_text, 'entity_list'); 
  my @entities= $t->entity_list->list;
  is( scalar @entities, scalar keys %ents, 'entity_list'); 

      foreach my $ent (@entities)
        { my $out='';
          my $fh= IO::String->new( \$out);
          my $stdout= select $fh;
          $ent->print;
          close $fh;
          select $stdout;
          is( normalize_xml( $out), $ent_text{$ent->name}, "print $ent->{name}"); 
        }
      my $out='';
      my $fh= IO::String->new( \$out);
      my $stdout= select $fh;
      $t->entity_list->print;
      close $fh;
      select $stdout;
      is( normalize_xml( $out), $ent_text, 'print entity_list'); 

}

{ my( $out1, $out2, $out3);
  my $fh1= IO::String->new( \$out1);
  my $fh2= IO::String->new( \$out2);
  my $fh3= IO::String->new( \$out3);

  my $stdout= select $fh3; 
  my $t= XML::Twig->new( twig_handlers => { e => sub { $_->print( $fh2); 
                                                       print $fh1 "X"; 
                                                       $_[0]->finish_print( $fh1);
                                                     },
                                          },
                       )
                  ->parse( '<doc>text<e>e <p>text</p></e>more text <p>foo</p></doc>');
  print 'should be in $out3';
  select $stdout;
  is( $out1, 'Xmore text <p>foo</p></doc>', 'finish_print'); 
  is( $out2, '<e>e <p>text</p></e>', 'print to fh'); 
  is( $out3, 'should be in $out3', 'restoring initial fh'); 

}


{ my $doc= '<doc><![CDATA[toto]]>tata<!-- comment -->t<?pi data?> more</doc>';
  my $out;
  my $fh= IO::String->new( \$out);
  my $t= XML::Twig->new( comments => 'process', pi => 'process')->parse( $doc);
  $t->flush( $fh);
  is( $out, $doc, 'flush with cdata');
}

{ my $out=''; 

  my $fh= IO::String->new( \$out);
  my $doc='<doc><elt>text</elt><elt1/><elt2/><elt3>text</elt3></doc>';
  my $t= XML::Twig->new( twig_roots=> { elt2 => 1 },
                          start_tag_handlers => { elt  => sub { print $fh '<e1/>'; } },  
                          end_tag_handlers   => { elt3 => sub { print $fh '<e2/>'; } },  
                          twig_print_outside_roots => $fh,
                          keep_encoding => 1
                        )
                   ->parse( $doc);
  is( $out, '<doc><e1/><elt>text</elt><elt1/><elt3>text<e2/></elt3></doc>', 
            'twig_print_outside_roots, start/end_tag_handlers, keep_encoding');
  close $fh;
  $out='';
  $fh= IO::String->new( \$out);
  $t= XML::Twig->new( twig_roots=> { elt2 => 1 },
                      start_tag_handlers => { elt  => sub { print $fh '<e1/>'; } },  
                      end_tag_handlers   => { elt3 => sub { print $fh '<e2/>'; } },  
                      twig_print_outside_roots => $fh,
                    )
               ->parse( $doc);
  is( $out, '<doc><e1/><elt>text</elt><elt1/><elt3>text<e2/></elt3></doc>', 
         'twig_print_outside_roots and start_tag_handlers');
}

{ my $t= XML::Twig->new->parse( '<doc/>');
  eval( '$t->set_output_encoding( "ISO-8859-1");');
  if( $@) 
    { skip( 1 => "your system does not seem to support conversions to ISO-8859-1: $@\n"); }
  else
    { is( $t->sprint, qq{<?xml version="1.0" encoding="ISO-8859-1"?><doc/>}, 
          'creating an output encoding'
        );
    }
}

{ my $out=''; 
  my $fh= IO::String->new( \$out);
  select $fh;
  my $doc='<?xml version="1.0"?><!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)> <!ENTITY foo "bar">]><doc/>';
  my( $expected)= $doc=~ m{(<!DOCTYPE.*?\]>)};
  XML::Twig->new->parse( $doc)->dtd_print;
  select STDOUT;
  is_like( $out, $expected, "dtd_print to STDOUT");
}

{ my $out=''; 
  my $fh= IO::String->new( \$out);
  select $fh;
  my $doc='<doc><elt1/><elt2/></doc>';
  XML::Twig->new( twig_handlers => { elt1 => sub { $_[0]->finish_print; } })->parse( $doc);
  select STDOUT;
  is( $out, '<elt2/></doc>', "finish_print to STDOUT");
}

{ my $out=''; 
  my $fh= IO::String->new( \$out);
  select $fh;
  my $doc='<doc><elt1/><elt2/></doc>';
  XML::Twig->new( keep_encoding => 1, twig_handlers => { elt1 => sub { $_[0]->finish_print; } })->parse( $doc);
  select STDOUT;
  is( $out, '<elt2/></doc>', "finish_print to STDOUT");
}

  


exit 0;
