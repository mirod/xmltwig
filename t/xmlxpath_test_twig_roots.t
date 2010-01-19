#!/usr/bin/perl -w
use strict;
#use diagnostics;


use strict;
use Carp;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;
use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

my $DEBUG=0;

print "1..12\n";

$|=1;

$/= "\n\n";

my $t= XML::Twig::XPath->new( twig_roots => { },
                       twig_print_outside_roots => \*RESULT,
                       error_context => 1,
		     );
test_twig( $t, 1);

$t= XML::Twig::XPath->new( twig_roots => { elt2 => sub { } },
                    twig_print_outside_roots => \*RESULT,
                    error_context => 1,
                  );
test_twig( $t, 2);

$t= XML::Twig::XPath->new( twig_roots => { elt3 => sub { } },
                    twig_print_outside_roots => \*RESULT,
                    error_context => 1,
                  );
test_twig( $t, 3);

$t= XML::Twig::XPath->new( twig_roots => { },
                       twig_print_outside_roots => \*RESULT,
                       error_context => 1,
		     );
test_twig( $t, 4);

$t= XML::Twig::XPath->new( twig_roots => { elt2 => sub { } },
                    twig_print_outside_roots => \*RESULT,
                    error_context => 1,
                  );
test_twig( $t, 5);

$t= XML::Twig::XPath->new( twig_roots => { elt3 => sub { } },
                    twig_print_outside_roots => \*RESULT,
                    error_context => 1,
                  );
test_twig( $t, 6);


$t= XML::Twig::XPath->new( twig_roots => { },
                       twig_print_outside_roots => \*RESULT,
                       error_context => 1,
		     );
test_twig( $t, 7);

$t= XML::Twig::XPath->new( twig_roots => { elt2 => sub { } },
                    twig_print_outside_roots => \*RESULT,
                    error_context => 1,
                  );
test_twig( $t, 8);

$t= XML::Twig::XPath->new( twig_roots => { elt3 => sub { } },
                    twig_print_outside_roots => \*RESULT,
                    error_context => 1,
                  );
test_twig( $t, 9);

$t= XML::Twig::XPath->new( twig_roots =>         { elt => sub { print RESULT "elt handler called on ", $_->gi, "\n";   }, },
                    start_tag_handlers => { doc => sub { print RESULT "start tag handler called on ", $_->gi, "\n"; }, },
                    end_tag_handlers   => { doc => sub { print RESULT "end tag handler called on $_[1]\n";   }, },
                  );
test_twig( $t, 10);

# test with doc root as root
$t= XML::Twig::XPath->new( twig_roots => { doc => sub { $_->print( \*RESULT); } });
test_twig( $t, 11);

# test with elt as root
$t= XML::Twig::XPath->new( twig_roots => { elt => sub { $_->print( \*RESULT); } });
test_twig( $t, 12);


exit 0;

sub test_twig
  { my( $t, $test_nb)= @_;
    my $doc= read_doc();
    my $expected_result=  read_expected_result();

    my $result_file= "test_twig_roots.res1";
    open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

    $t->parse( $doc);
    check_result( $result_file, $test_nb, $expected_result);
    close RESULT;
  }


sub check_result
  { my( $result_file, $test_no, $expected_result)= @_;
    # now check result
    my $result= read_result( $result_file);
    if( $result eq $expected_result)
      { print "ok $test_no\n"; }
    else
      { print "nok $test_no\n"; 
        print STDERR "\ntest $test_no:\n",
	             "expected: \n$expected_result\n",
                     "real: \n$result\n";
      }
  }

{ my $last_doc;
  my $buffered_result;
  sub read_doc
    { local $/="\n\n";
      my $doc= <DATA>;
      # if the data starts with #doc then it's a doc, otherwise use the previous one
      if( $doc=~ /^\s*#\s*doc/) 
        { $doc= clean_data( $doc);
          $last_doc= $doc;
          $buffered_result='';
          return $doc;
        }
      else
        { $buffered_result= clean_data( $doc);
          return $last_doc;
        }
    }

  sub read_expected_result
    { if( $buffered_result) 
        { return $buffered_result; }
      else
        { local $/="\n\n";
          my $expected_result= <DATA>;
          $expected_result= clean_data( $expected_result);
          return $expected_result;
        }
    }

  }

sub clean_data
  { my $data= shift;
    $data=~ s{^\s*#.*\n}{}m;           # get rid of comments
    $data=~ s{\s*$}{}s;                # remove trailing spaces (and \n)
    $data=~  s{(^|\n)\s*(\n|$)}{}g;    # remove empty lines
    return $data;
  }

 
sub read_result
  { my $file= shift;
    local $/="\n";
    open( RESULT, "<$file") or die "cannot read $file: $!";
    my @result= grep {m/\S/} <RESULT>;
    my $result= join( '', @result);
    $result=~  s{(^|\n)\s*(\n|$)}{}g;    # remove empty lines
    close RESULT;
    unlink $file;
    return $result;
  }

__DATA__
# doc 1
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 1
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 2
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 3
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
</doc>

# doc 2
<?xml version="1.0"?>
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 4
<?xml version="1.0"?>
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 5
<?xml version="1.0"?>
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 6
<?xml version="1.0"?>
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
</doc>

# doc 3
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 7
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 8
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt3>
    <!-- a comment -->
    <subelt> text of subelt</subelt>
  </elt3>
</doc>

# expected_res 9
<doc>
  <!-- a comment -->
  <elt> text <subelt> subelt text</subelt></elt>
  <?pi a pi?>
  <elt>another elt text</elt>
  <elt2>an other type of element</elt2>
</doc>

# doc 4
<doc>
  <elt/>
</doc>

# expected_res 10
start tag handler called on doc
elt handler called on elt
end tag handler called on doc

# expected_res 11
<doc><elt/></doc>

# expected_res 12
<elt/>

