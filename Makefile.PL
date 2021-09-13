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
elsif( $ENV{AUTOMATED_TESTING} || $ENV{NONINTERACTIVE_TESTING})
  { @programs=(); }
else
  { print "run 'perl Makefile.PL -y' to install all tools,\n",
          "    'perl Makefile.PL -n' to skip installation\n";
    foreach my $prompt (@prompts)
      { my ($program, $default, $description) = @$prompt;
        if( prompt("Do you want to install '$program' ($description)?", $default) =~ /^y/i)
          { push(@programs, $program); }
      }
  }

MyWriteMakefile(
    META_MERGE => {
      resources => {
        repository => 'http://github.com/mirod/xmltwig',
      },
    },
    META_ADD => {
      prereqs => {
        build => {
         requires => {
            'ExtUtils::MakeMaker' => "0",
         }
      },
      configure => {
         requires => {
            'ExtUtils::MakeMaker' => "0",
         }
      },

          test => {
            recommends => {
              'Test'                     =>    '1.25_02',
              'IO::Scalar'               =>    '2.110',
              'IO::CaptureOutput'        =>    '1.1102',
            },
            suggests => {
              'Test::Pod'                =>    '1.45',
              'XML::Simple'              =>    '2.18',
              'XML::Handler::YAWriter'   =>    '0.23',
              'XML::SAX::Writer'         =>    '0.53',
              'XML::Filter::BufferText'  =>    '1.01',
            },
          },
          runtime => {
            requires => {
              'XML::Parser'              =>    '2.23',
            },
            recommends => {
              'Scalar::Util'             =>    '1.23',
              'Encode'                   =>    '2.42_01',
              'XML::XPathEngine'         =>    '0.13',
            },
            suggests => {
              'LWP'                      =>    '6.04',
              'HTML::TreeBuilder'        =>    '4.2',
              'HTML::Entities::Numbered' =>    '0.04',
              'HTML::Tidy'               =>    '1.50',
              'HTML::Entities'           =>    '3.69',
              'Tie::IxHash'              =>    '1.22',
              'Text::Wrap'               => '2009.0305',
            },
          }
        }
    },
    #BUILD_REQUIRES => {
    #},

    NAME	 => 'XML::Twig',
    ABSTRACT     => 'XML, The Perl Way',
    AUTHOR       => 'Michel Rodriguez <mirod@cpan.org>',
    LICENSE      => 'perl',
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


sub MyWriteMakefile {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);

  add_prereqs_to_mymeta( $params{META_ADD}->{prereqs});
}

sub add_prereqs_to_mymeta
  { my $prereqs= shift;

    my $MYJSON= 'MYMETA.json';
    my $MYYAML= 'MYMETA.yml';
    my $JSON  = 'META.json';
    my $YAML  = 'META.yml';

    rename $MYYAML, $YAML;
    if( eval { require JSON; })
      { my $json= JSON->new()->pretty->canonical;
        if( my $meta= eval { $json->decode( slurp( -s $MYJSON ?  $MYJSON : $JSON )); })
          { $meta->{prereqs}= $prereqs;
            spit( $JSON, $json->encode( $meta));
            warn "updated prereqs in $JSON\n";
          }
      }

  }

sub slurp
  { my( $file)= @_;
    my $in;
    open( $in, "<$file") or return ''; # can't use fancy open so this works in 5.005
    local undef $/;
    return <$in>;
  }

sub spit
  { my $file= shift;
    my $out;
    open( $out, ">$file") or ( warn "cannot update $file: $!" && return);
    print {$out} @_;
  }
