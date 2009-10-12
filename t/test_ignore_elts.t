#!/usr/bin/perl -w
use strict;

use XML::Twig;

$|=1;

my $TMAX=1; # do not forget to update!
print "1..$TMAX\n";

my $doc= read_data();

my $t= XML::Twig->new( ignore_elts => { ignore => 1 },
                       keep_spaces => 1,
		     );
my $result_file= "test_ignore_elt.res1";
open( RESULT, ">$result_file") or die "cannot create $result_file: $!";
select RESULT;
$t->parse( $doc);
$t->print;
select STDOUT;
close RESULT;
check_result( $result_file, 1);

exit 0;

# Not yet implemented

# test 2
$doc= read_data();

$t= XML::Twig->new( ignore_elts =>   { ignore => 'print' },
                    twig_handlers => { elt    => sub { $_->print; } },
                    keep_spaces => 1,
                  );
$result_file= "test_ignore_elt.res2";
open( RESULT, ">$result_file") or die "cannot create $result_file: $!";
select RESULT;
$t->parse( $doc);
$t->print;
select STDOUT;
close RESULT;
check_result( $result_file, 2);



sub read_data
  { local $/="\n\n";
    my $data= <DATA>;
    $data=~ s{^\s*#.*\n}{}m; # get rid of comments
    $data=~ s{\s*$}{}s;     # remove trailing spaces (and \n)
    $data=~  s{(^|\n)\s*(\n|$)}{}g;    # remove empty lines
    return $data;
  };

  
sub check_result
  { my( $result_file, $test_no)= @_;
    # now check result
    my $expected_result= read_data();
    my $result= read_result( $result_file);
    if( $result eq $expected_result)
      { print "ok $test_no\n"; }
    else
      { print "not ok $test_no\n"; 
        print STDERR "\ntest $test_no:\n",
	             "expected: \n$expected_result\n",
                     "real: \n$result\n";
      }
  }


sub read_result
  { my $file= shift;
    local $/="\n";
    open( RESULT, "<$file") or die "cannot read $file: $!";
    my @result= grep {m/\S/} <RESULT>;
    close RESULT;
    unlink $file;
    return join '', @result;
  }


  
__DATA__
# doc 1
<doc>
  <ignore>text<child ok="no"/></ignore>
  <elt>
    <child ok="yes"/>
    <ignore>text<child ok="no"/></ignore>
  </elt>
</doc>

# expected result 1
<doc>
  <elt>
    <child ok="yes"/>
  </elt>
</doc>

#doc 2
<doc>
  <ignore>text<child ok="no"/></ignore>
  <elt>
    <child ok="yes"/>
  </elt>
  <ignore>text<child ok="no"/></ignore>
</doc>

# expected result 2
  <ignore att="val">text<child ok="no"/></ignore>
  <elt>
    <child ok="yes"/>
  </elt>
  <ignore>text<child ok="no"/></ignore>
