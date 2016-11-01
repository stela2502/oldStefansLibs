#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::file_readers::stat_results::KruskalWallisTest_result' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs::file_readers::stat_results::KruskalWallisTest_result -> new();
is_deeply ( ref($test_object) , 'stefans_libs::file_readers::stat_results::KruskalWallisTest_result', 'simple test of function stefans_libs::file_readers::stat_results::KruskalWallisTest_result -> new()' );

$value = $test_object->AddDataset ( {             'Probe Set ID' => 0,
            'Gene Symbol' => 1,
            'p-value' => 2,
            'chi-squared' => 3,
            'degrees of freedom' => 4,
            'group nr. 0 (AG)' => 5, } );
is_deeply( $value, 1, "we could add a sample dataset");

## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
