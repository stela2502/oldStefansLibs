#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::MyProject::Gene_SNP_descritpion_table' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs_MyProject_Gene_SNP_descritpion_table -> new();
is_deeply ( ref($test_object) , 'stefans_libs_MyProject_Gene_SNP_descritpion_table', 'simple test of function stefans_libs_MyProject_Gene_SNP_descritpion_table -> new()' );

$value = $test_object->AddDataset ( {             'rsID' => 0,
            'Probe Set ID' => 1,
            'Gene Symbol' => 2,
            'p_value' => 3,
            'rho' => 4,
            'Gene Symbol (p_value)' => 5, } );
is_deeply( $value, 1, "we could add a sample dataset");

## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
