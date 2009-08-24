#!/usr/bin/perl -w
use strict; 

use XML::Twig;

foreach my $module ( qw( XML::Simple Test::More Data::Dumper YAML) )
  { if( eval "require $module")
      { import $module; }
    else
      { print "1..1\nok 1\n";
        warn "skipping: $module is not installed\n";
        exit;
      }
  }

if( $XML::Simple::VERSION < 2.09) 
  { print "1..1\nok 1\n";
    warn "skipping: need XML::Simple 2.09 or above\n";
    exit;
  }

undef $XML::Simple::PREFERRED_PARSER;
$XML::Simple::PREFERRED_PARSER= 'XML::Parser';  

$/="\n\n";
my @doc= <DATA>;

my @options= ( { },
               { content_key => 'foo' },
               { group_tags => { templates => 'template'} },
               { group_tags => { dirs => 'dir', templates => 'template'} },
               { forcearray => 1 },
               { forcearray => [ qw(server) ] },
               { noattr => 1, },
               { noattr => 0, },
               { content_key => 'mycontent' },
               { content_key => '-mycontent' },
               { var_attr => 'var' },
               { var_attr => 'var', var_regexp => qr/\$\{?(\w+)\}?/ },
               { variables => { var => 'foo' } },
               { keyattr => [ qw(name)] },
               { keyattr => [ 'name' ] },
               { keyattr => [ qw(foo bar)] },
               { keyattr => {server => 'name' } },
               { keyattr => {server => '+name' } },
               { keyattr => {server => '-name' } },
               { normalize_space => 1 },
               { normalise_space => 2 },
               { group_tags => { f1_ar => 'f1' } },
               { group_tags => { f1_ar => 'f1', f2_ar => 'f2'} },
             );

plan( tests => @options * @doc);

$SIG{__WARN__} = sub { };

foreach my $doc (@doc)
  { foreach my $options (@options)
      { (my $options_text= Dumper( $options))=~ s{\s*\n\s*}{ }g;
        $options_text=~ s{^\$VAR1 = }{};

        my( $options_twig, $options_simple)= UNIVERSAL::isa( $options, 'ARRAY') ?
                                             @$options : ($options, $options);
        
        my $t        = XML::Twig->new->parse( $doc);
        my $twig     = $t->root->simplify( %$options_twig);
        my $doc_name = $t->root->att( 'doc');
        delete $options_simple->{var_regexp};
        my $simple   = XMLin( $doc, %$options_simple); 
        my $res=is_deeply( $twig, $simple, "doc: $doc_name - options: $options_text" ); #. Dump( {twig => $twig, simple => $simple}));
        exit unless( $res);
      }
  } 

exit 0;

__DATA__
<config doc="XML::Simple example" logdir="/var/log/foo/" debugfile="/tmp/foo.debug">
  <server name="sahara" osname="solaris" osversion="2.6">
    <address>10.0.0.101</address>
    <address>10.0.1.101</address>
  </server>
  <server name="gobi" osname="irix" osversion="6.5">
    <address>10.0.0.102</address>
  </server>
  <server name="kalahari" osname="linux" osversion="2.0.34">
    <address>10.0.0.103</address>
    <address>10.0.1.103</address>
  </server>
</config>

<config doc="example from XML::Twig" host="laptop.xmltwig.com">
  <server>localhost</server>
  <dirs>
    <dir name="base">/home/mrodrigu/standards</dir>
    <dir name="tools">${base}/tools</dir>
  </dirs>
  <templates>
    <template name="std_def">std_def.templ</template>
    <template name="dummy">dummy</template>
  </templates>
</config>

<doc doc="simple example with variables"><var var="var">foo</var><string>var is ${var}</string></doc>

<doc doc=" val  with spaces ">
  <item name="n1">text with spaces </item>
  <item name="n2 "> text with spaces</item>
  <item name=" n3 ">text  with  spaces</item>
  <item name="n  4 "> text  with spaces 
  </item>
</doc>

<doc doc="minimal">
  <f1_ar><f1>f1 1</f1><f1>f1 2</f1></f1_ar>
  <f2_ar><f2>f2 1</f2><f2>f2 2</f2></f2_ar>
</doc>
