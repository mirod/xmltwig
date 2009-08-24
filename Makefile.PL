# $Id: /xmltwig/trunk/Makefile.PL 33 2008-04-30T08:03:41.004487Z mrodrigu  $
# tool installation part shamelessly lifted from YAML's Makefile.PL

use ExtUtils::MakeMaker;

my @prompts=(
 [ xml_pp         => y => "XML pretty printer"                                          ],
 [ xml_grep       => y => "XML grep - grep XML files using XML::Twig's subset of XPath" ],
 [ xml_split      => y => "split big XML files"                                         ],
 [ xml_merge      => y => "merge back files created by xml_split"                       ],
 [ xml_spellcheck => y => "spellcheck XML files skipping tags"                          ],
);

my @programs;

my $opt= $ARGV[0] ? $ARGV[0] : '';

if(    $opt eq "-n")
  { @programs=(); }
elsif( $opt eq "-y")
  { @programs= map { $_->[0] } @prompts; }
elsif( $opt eq "-d")
  { @programs= map { $_->[0] if( $_->[1] eq 'y') } @prompts; }
elsif( $ENV{AUTOMATED_TESTING})
  { @programs=(); }
else
  { print "run 'perl Makefile.PL -y' to install all tools,\n",
          "    'perl Makefile.PL -n' to skip installation\n";
    foreach my $prompt (@prompts)
      { my ($program, $default, $description) = @$prompt;
        if( prompt("Do you want to install '$program' ($description)?", $default) =~ /^y/)
          { push(@programs, $program); }
      }
  }

(my $EUMM= $ExtUtils::MakeMaker::VERSION)=~ tr/_//d;
my @license = $EUMM > 6.30 ? qw(LICENSE perl) : ();

WriteMakefile(
    NAME	 => 'XML::Twig',
    ABSTRACT     => 'XML, The Perl Way',
    AUTHOR       => 'Michel Rodriguez <mirod@xmltwig.com>',
     @license,
    EXE_FILES    => [ map {"tools/$_/$_"} @programs],
    VERSION_FROM => 'Twig.pm', 
    PREREQ_PM    => { 'XML::Parser' => '2.23' },
    dist         => { COMPRESS    => 'gzip -9f',
                      SUFFIX	     => 'gz',
                    },
    depend       => { 'Twig.pm' => "FORCE\n\t\$(PERL) speedup Twig_pm.slow > Twig.pm\n\t\$(PERL) -i_bak -p filter_for_5.005 Twig.pm Twig/XPath.pm\n\t\$(PERL) check_optional_modules",
    'FORCE'   => '',
									  },
);

