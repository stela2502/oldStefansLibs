#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::Section' }

my $Section = Section -> new();
is_deeply ( ref($Section) , 'Section', 'simple test of function Section -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


## test for new

