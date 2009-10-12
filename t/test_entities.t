#!/usr/bin/perl -w
use strict;
#use diagnostics;

use XML::Twig;

$|=1;

my $TMAX=6; # do not forget to update!
print "1..$TMAX\n";

my $doc= read_data();

# test 1 : roots and twig_print_outside_roots
my $result_file= "test_entities.res1";

open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

my $t= XML::Twig->new( twig_roots => { elt2 => sub { $_->print}  },
                       twig_print_outside_roots => 1,
                       #load_DTD => 1,
                       error_context => 2,
		     );
select RESULT;
$t->safe_parse( $doc) or die "This error is probably due to an incompatibility between
XML::Twig and the version of libexpat that you are using\n See the README and the
XML::Twig FAQ for more information\n";;

close RESULT;
select STDOUT;

check_result( $result_file, 1);

# test 2 : roots only, test during parsing 
$result_file= "test_entities.res2";

open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

$t= XML::Twig->new( twig_roots => { elt2 => sub { $_->print}  },
                    error_context => 1,
                  );
select RESULT;
$t->parse( $doc);
close RESULT;
select STDOUT;

check_result( $result_file, 2);


# test 3 : roots only, test parse result
$result_file= "test_entities.res3";

open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

$t= XML::Twig->new( twig_roots => { elt2 => 1 },
                    pretty_print => 'indented',
                    error_context => 1,
		  );
$t->parse( $doc);
$t->print( \*RESULT);
close RESULT;

check_result( $result_file, 3);


# test 4 : roots and twig_print_outside_roots
$result_file= "test_entities.res4";

open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

$t= XML::Twig->new( twig_roots => { elt2 => sub { $_->print}  },
                    twig_print_outside_roots => 1,
                    keep_encoding => 1,
                    error_context => 1,
                  );
select RESULT;
$t->parse( $doc);
close RESULT;
select STDOUT;

check_result( $result_file, 4);

# test 5 : roots only, test during parsing 
$result_file= "test_entities.res5";

open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

$t= XML::Twig->new( twig_roots => { elt2 => sub { $_->print}  },
		    keep_encoding => 1,
                    error_context => 1,
                  );
select RESULT;
$t->parse( $doc);
close RESULT;
select STDOUT;

check_result( $result_file, 5);


# test 6 : roots only, test parse result
$result_file= "test_entities.res6";

open( RESULT, ">$result_file") or die "cannot create $result_file: $!";

$t= XML::Twig->new( twig_roots => { elt2 => 1 },
                    pretty_print => 'indented',
		                keep_encoding => 1,
                    error_context => 1,
		  );
$t->parse( $doc);
$t->print( \*RESULT);
close RESULT;

check_result( $result_file, 6);


exit 0;



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

sub read_data
  { local $/="\n\n";
    my $data= <DATA>;
    $data=~ s{^\s*#.*\n}{}m; # get rid of comments
    $data=~ s{\s*$}{}s;     # remove trailing spaces (and \n)
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
  <elt1>toto &ent1;</elt1>
  <elt2>tata &ent2;</elt2>
  <elt3>tutu &ent3;</elt3>
  <elt2>tutu &ent4;</elt2>
  <elt3>tutu &ent5;</elt3>
</doc>

# expected_res 1
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <elt1>toto &ent1;</elt1>
  <elt2>tata &ent2;</elt2>
  <elt3>tutu &ent3;</elt3>
  <elt2>tutu &ent4;</elt2>
  <elt3>tutu &ent5;</elt3>
</doc>

# expected_res 2
<elt2>tata &ent2;</elt2><elt2>tutu &ent4;</elt2>

# expected_res 3
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <elt2>tata &ent2;</elt2>
  <elt2>tutu &ent4;</elt2>
</doc>

# expected_res 4
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <elt1>toto &ent1;</elt1>
  <elt2>tata &ent2;</elt2>
  <elt3>tutu &ent3;</elt3>
  <elt2>tutu &ent4;</elt2>
  <elt3>tutu &ent5;</elt3>
</doc>

# expected_res 5
  <elt2>tata &ent2;</elt2>
  <elt2>tutu &ent4;</elt2>

# expected_res 6
<?xml version="1.0"?>
<!DOCTYPE doc SYSTEM "t/dummy.dtd">
<doc>
  <elt2>tata &ent2;</elt2>
  <elt2>tutu &ent4;</elt2>
</doc>

