#!/usr/bin/perl -w
use strict;

use XML::Twig;

$|=1;

my $i=0;
my $failed=0;

my $TMAX=4; # do not forget to update!

print "1..$TMAX\n";

$i++;
print "ok $i\n"; # loading

my $t= XML::Twig->new( 
         twig_handlers => 
	   { 'elt[@att=~/^v/]' => sub { $i++;
	                                if( $_->att( 'ok') eq "ok")
	                                  { print "ok $i\n"; 
					  }
					else
					  { print "NOK $i\n";
					    # print STDERR "id: ", $_->att( 'id'), "\n";
					  }
				      },
	     'elt[@change=~/^now$/]' => sub { $_[0]->setTwigHandler( 
	                                       'elt[@att=~/^new/]' =>
					           sub { $i++;
						         if( $_->att( 'ok') eq "ok")
						           { print "ok $i\n"; }
                                                         else
							   { print "NOK $i\n"; 
					                     # print STDERR "id: ", $_->att( 'id'), "\n";
							   }
                                                        });
                                            },
                      },
	            );
$t->parse( \*DATA);

exit 0;

__DATA__
<doc id="doc" >
  <elt id="elt1" att="val" ok="ok">foo<elt id="elt2" att="no val" ok="nok"/></elt>
  <elt id="elt3" att="v" ok="ok"/>
  <elt id="elt4" ok="nok"/>q
  <elt id="elt5" change="now"/>
  <elt id="elt6" att="new_val" ok="ok"/>
  <elt id="elt7" att="val" ok="nok"/>
</doc>
