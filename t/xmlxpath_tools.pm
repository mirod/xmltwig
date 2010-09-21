use strict;
use Config;

BEGIN 
  { if( eval( 'require XML::Twig::XPath'))
      { import XML::Twig::XPath; }
    elsif( $@ =~ m{^cannot use XML::Twig::XPath})
      { print "1..1\nok 1\n"; $@=~s{ at.*}{}s; warn "$@\n";
        exit;
      }
    else
      { die $@; }
  }

1;

__END__

=head1 SYNOPSYS

use FindBin qw($Bin); BEGIN { unshift @INC, $Bin; } use xmlxpath_tools;

