#!/usr/bin/perl 

use 5.010;

my $FIELD     = join( '|', qw( parent first_child last_child prev_sibling next_sibling pcdata cdata ent data target cdata pcdata comment flushed));
my $PRIVATE   = join( '|', qw( parent first_child last_child prev_sibling next_sibling pcdata cdata comment 
                               extra_data_in_pcdata extra_data_before_end_tag
                             )
                    ); # _$private is inlined
my $FORMER    = join( '|', qw( parent prev_sibling next_sibling)); # former_$former is inlined
my $SET_FIELD = join( '|', qw( first_child next_sibling ent data pctarget comment flushed));
my $SET_NOT_EMPTY= join( '|', qw( pcdata cdata comment)); # set the field

my $var= '(\$[a-z_]+(?:\[\d\])?|\$t(?:wig)?->root|\$t(?:wig)?->twig_current|\$t(?:wig)?->\{\'?twig_root\'?\}|\$t(?:wig)?->\{\'?twig_current\'?\})';

my $set_to = '(?:undef|\$\w+|\$\w+->\{\w+\}|\$\w+->\w+|\$\w+->\w+\([^)]+\))';
my $elt    = '\$(?:elt|new_elt|child|cdata|ent|_?parent|twig_current|next_sibling|first_child|prev_sibling|last_child|ref|elt->_parent)';


my %gi2index=( '', 0, PCDATA =>  1, CDATA =>  2, PI => 3, COMMENT => 4, ENT => 5);

(my $version= $])=~ s{\.}{}g;

my $in_pod = 0; # do not change the POD!

while( <>)
  {
    $in_pod = 1 if m{^__END__};
    # do not fix the pod
    if ($in_pod) {
        print $_;
        next;
    }

    if( /=/)
      { s/$var->_children/do { my \$elt= $1; my \@children=(); my \$child= \$elt->_first_child; while( \$child) { push \@children, \$child; \$child= \$child->_next_sibling; } \@children; }/; }

    s/$var->set_gi\(\s*(PCDATA|CDATA|PI|COMMENT|ENT)\s*\)/$1\->{gi}= $gi2index{$2}/;

    s/$var->del_(twig_current)/delete $1\->{'$2'}/g;
    s/$var->set_(twig_current)/$1\->{'$2'}=1/g;
    s/$var->_del_(flushed)/delete $1\->{'$2'}/g;
    s/$var->_set_(flushed)/$1\->{'$2'}=1/g;
    s/$var->_(flushed)/$1\->{'$2'}/g;

    s/$var->set_($SET_FIELD)\(([^)]*)\)/$1\->\{$2\}= $3/g;
    s/$var->($FIELD)\b(?!\()/$1\->\{$2\}/g;
    s/$var->_($PRIVATE)\b(\s*\(\s*\))?(?!\s*\()/$1\->\{$2\}/g;

    s{($elt)->former_($FORMER)}{($1\->{former} && $1\->{former}\->{$2})}g;

    s{($elt)->set_(parent|prev_sibling)\(\s*($set_to)\s*\)}{$1\->\{$2\}=$3; weaken( $1\->\{$2\}); }g;
    s{($elt)->set_(first_child)\(\s*($set_to)\s*\)}{ $1\->set_not_empty; $1\->\{$2\}=$3; }g;
    s{($elt)->set_(next_sibling)\(\s*($set_to)\s*\)}{ $1\->\{$2\}=$3; }g;
    s{($elt)->set_(last_child)\(\s*($set_to)\s*\)}{ $1\->set_not_empty; $1\->\{$2\}=$3; weaken( $1\->\{$2\}); }g;

    s/$var->atts/$1\->{att}/g;

    s/$var->append_(pcdata|cdata)\(([^)]*)\)/$1\->\{$2\}.= $3/g;
    s/$var->set_($SET_NOT_EMPTY)\(([^)]*)\)/$1\->\{$2\}= (delete $1->\{empty\} || 1) && $3/g;
    s/$var->_set_($SET_NOT_EMPTY)\s*\(([^)]*)\)/$1\->{$2}= $3/g;

    s/(\$[a-z][a-z_]*(?:\[\d\])?)->gi/\$XML::Twig::index2gi\[$1\->{'gi'}\]/g;

    s/$var->id/$1\->{'att'}->{\$ID}/g;
    s/$var->att\(\s*([^)]+)\)/$1\->{'att'}->\{$2\}/g;

    s/(\$[a-z][a-z_]*(?:\[\d\])?)->is_pcdata/(exists $1\->{'pcdata'})/g; 
    s/(\$[a-z][a-z_]*(?:\[\d\])?)->is_cdata/(exists $1\->{'cdata'})/g; 
    s/$var->is_pi/(exists $1\->{'target'})/g; 
    s/$var->is_comment/(exists $1\->{'comment'})/g; 
    s/$var->is_ent/(exists $1\->{'ent'})/g; 
    s/(\$,a-z][a-z_]*(?:\[\d\])?)->is_text/((exists $1\->{'pcdata'}) || (exists $1\->{'cdata'}))/g; 

    s/$var->is_empty/$1\->{'empty'}/g;
    s/$var->set_empty(?:\(([^)]*)\))?(?!_)/"$1\->{empty}= " . ($2 || 1)/ge;
    s/$var->set_not_empty/delete $1\->{empty}/g;

    s/$var->_is_private/( (substr( \$XML::Twig::index2gi\[$1\->{'gi'}\], 0, 1) eq '#') && (substr( \$XML::Twig::index2gi\[$1\->{'gi'}\], 0, 9) ne '#default:') )/g;
    s/_is_private_name\(\s*$var\s*\)/( $1=~ m{^#(?!default:)} )/g;

    s{_is_fh\(\s*$var\)}{isa( $1, 'GLOB') || isa( $1, 'IO::Scalar')}g;

    s/$var->set_gi\s*\(\s*([^)]*)\s*\)/$1\->{gi}=\$XML::Twig::gi2index{$2} or $1->set_gi( $2)/g;

    s/$var->xml_string/$1->sprint( 1)/g;

    print $_ ;
  }

