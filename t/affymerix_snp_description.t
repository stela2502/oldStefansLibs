#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::affymerix_snp_description' }

my $affymerix_snp_description = affymerix_snp_description -> new();
is_deeply ( ref($affymerix_snp_description) , 'affymerix_snp_description', 'simple test of function affymerix_snp_description -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


## test for new

