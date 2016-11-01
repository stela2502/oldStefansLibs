#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::file_readers::phenotypes' }

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs_file_readers_phenotypes -> new();
is_deeply ( ref($test_object) , 'stefans_libs_file_readers_phenotypes', 'simple test of function stefans_libs_file_readers_phenotypes -> new()' );

my $file;
$file = "data/phenotypes.txt" if ( -f "data/phenotypes.txt");
$file = "t/data/phenotypes.txt" if ( -f "t/data/phenotypes.txt");
die "Sorry I could not find the test data file phenotypes.txt" unless (-f $file);

$test_object ->read_file ( $file );
is_deeply ( scalar( @{$test_object->{'data'}}), 3, "we could read the file" );

is_deeply ( $test_object->get_column_entries( 'phenotype'), [ 'rs1', 'rs2', 'rs3'], "we got the column 'phenotype'");

$value = $test_object->As_CLS_file_str( 'rs1', [ 'ISL0065',  'ISL0001', 'ISL0002', 'ISL0003', 'ISL0004','ISL0005' ] );
## rs1	AG	GG	AA	AG	AG

$exp = {
  'samples' => [ 'ISL0001', 'ISL0002', 'ISL0003', 'ISL0004', 'ISL0005' ],
  'str' => '5 3 1
# AA GG AG
AA -> 2;AG -> 0;GG -> 1;
0 1 2 0 0
'
};
is_deeply ($value, $exp, "As_CLS_file_str" );

$value = $test_object->As_CLS_file_str( 'rs1', [ 'ISL0065',  'ISL0001', 'ISL0002', 'ISL0003', 'ISL0005' ] );
## rs1	AG	GG	AA	AG	AG

$exp = {
  'samples' => [ 'ISL0001', 'ISL0002', 'ISL0003',  'ISL0005' ],
  'str' => '4 3 1
# AA GG AG
AA -> 2;AG -> 0;GG -> 1;
0 1 2 0
'
};
is_deeply ($value, $exp, "As_CLS_file_str one Sample was not queried" );

$value = $test_object->As_CLS_file_str( 'rs3', [ 'ISL0065', 'ISL0003', 'ISL0001', 'ISL0002', 'ISL0004', 'ISL0005' ] );
$exp = {
  'samples' => [ 'ISL0001', 'ISL0002', 'ISL0003', 'ISL0005' ],
  'str' => '4 3 1
# TT AT AA
AA -> 0;TT -> 2;AT -> 1;
0 1 1 2
'
};
is_deeply ($value, $exp, "As_CLS_file_str one empty column" );


## A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
