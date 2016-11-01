#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::file_readers::UCSC_ens_Gene' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs_file_readers_UCSC_ens_Gene -> new();
is_deeply ( ref($test_object) , 'stefans_libs_file_readers_UCSC_ens_Gene', 'simple test of function stefans_libs_file_readers_UCSC_ens_Gene -> new()' );

$value = $test_object->AddDataset ( {             'test' => 0, } );
is_deeply( $value, 1, "we could add a sample dataset");

## A handy help if you do not know what you should expect
#print "$exp = ".root->print_perl_var_def($value ).";\n";
