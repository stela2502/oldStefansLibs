#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'lib::stefans_libs::file_readers::CoExpressionDescription' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs::file_readers::CoExpressionDescription -> new();
is_deeply ( ref($test_object) , 'stefans_libs::file_readers::CoExpressionDescription', 'simple test of function stefans_libs::file_readers::CoExpressionDescription -> new()' );

$value = $test_object->AddDataset ( {             'r_cutoff' => 0,
            'gene list type' => 1,
            'phenotype list' => 2,
            'phenotype count' => 3,
            'KEGG results table' => 4, } );
is_deeply( $value, 1, "we could add a sample dataset");

## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
