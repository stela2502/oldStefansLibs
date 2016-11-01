#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::affymerix_snp_data' }

my $affymerix_snp_data = affymerix_snp_data -> new();
is_deeply ( ref($affymerix_snp_data) , 'affymerix_snp_data', 'simple test of function affymerix_snp_data -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


## test for new

