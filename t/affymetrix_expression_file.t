#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
BEGIN { use_ok 'stefans_libs::file_readers::affymetrix_expression_result'};

my ( $test_obj, @values, $value, $exp, $infile );
$test_obj = stefans_libs_file_readers_affymetrix_expression_result -> new();
is_deeply ( ref($test_obj) , 'stefans_libs_file_readers_affymetrix_expression_result', 'new()' );

$infile = "t/affymetrix_expression_file.xls";
$infile = "../t/affymetrix_expression_file.xls" if ( -f"../t/affymetrix_expression_file.xls" );

is_deeply ( -f $infile, 1, "I have the infile");
$test_obj->p4cS( 'ARPE-\\d+');
$test_obj->read_file( $infile );
is_deeply ( $test_obj->get_column_entries('Probe Set ID'), [ 7945663, 8008885, 7986446, 8141150, 7982757 ,8086880, 8046488 ,8040712 ,7990391], "read_data OK" );
$exp = [ 'ARPE-10', 'ARPE-125', 'ARPE-126', 'ARPE-127', 'ARPE-128', 'ARPE-132', 'ARPE-133', 'ARPE-134', 'ARPE-135', 'ARPE-22', 'ARPE-24', 'ARPE-25', 'ARPE-26', 'ARPE-28', 'ARPE-29', 'ARPE-32', 'ARPE-33', 'ARPE-37', 'ARPE-39', 'ARPE-48', 'ARPE-49', 'ARPE-4', 'ARPE-50', 'ARPE-51', 'ARPE-52', 'ARPE-53', 'ARPE-54', 'ARPE-55', 'ARPE-57', 'ARPE-58', 'ARPE-60', 'ARPE-67', 'ARPE-68', 'ARPE-79', 'ARPE-7', 'ARPE-80', 'ARPE-81', 'ARPE-82', 'ARPE-83', 'ARPE-84', 'ARPE-86', 'ARPE-88', 'ARPE-89', 'ARPE-8', 'ARPE-90', 'ARPE-93', 'ARPE-94', 'ARPE-95', 'ARPE-96', 'ARPE-97', 'ARPE-99', 'ARPE-9' ];
is_deeply ($test_obj->Samples(), $exp, "sample identification");

## so now I want to test my NEW plotting feature
## lets start with the groupings:
$exp = [ {
  'color' => 'blue',
  'border_color' => 'blue',
  'name' => 'A',
  'data' => {
  'medium' => [ '8.155273', '7.760552', '7.420182', '7.778951' ],
  'young' => [ '7.500555', '7.92252', '8.356277', '8.120697' ],
  'old' => [ '7.562115', '8.5895', '8.477027', '8.764832' ]
},
  'order_array' => [ 'young', 'medium', 'old' ]
}, {
  'color' => 'green',
  'border_color' => 'green',
  'name' => 'B',
  'data' => {
  'medium' => [ '8.658142', '8.53313', '8.423612', '8.720793' ],
  'young' => [ '8.493458', '8.137424', '8.515308', '8.763663' ],
  'old' => [ '8.845812', '8.702066', '9.098486', '8.995623' ]
},
  'order_array' => [ 'young', 'medium', 'old' ]
} ];
$test_obj->Add_2_Description ("x_values\tyoung\tmedium\told");
$test_obj->Sample_Groups ( 'blue young A', [ 'ARPE-10', 'ARPE-125', 'ARPE-126', 'ARPE-127'], 'x=young;color=blue;label=A' );
$test_obj->Sample_Groups ( 'blue medium A', [ 'ARPE-128', 'ARPE-132', 'ARPE-133', 'ARPE-134'], 'x=medium;color=blue;label=A' );
$test_obj->Sample_Groups ( 'blue old A', [ 'ARPE-135', 'ARPE-22', 'ARPE-24', 'ARPE-25'], 'x=old;color=blue;label=A' );
$test_obj->Sample_Groups ( 'green young B', [ 'ARPE-26', 'ARPE-28', 'ARPE-29', 'ARPE-32'], 'x=young;color=green;label=B' );
$test_obj->Sample_Groups ( 'green medium B', [ 'ARPE-33', 'ARPE-37', 'ARPE-39', 'ARPE-48'], 'x=medium;color=green;label=B' );
$test_obj->Sample_Groups ( 'green old B', [ 'ARPE-49', 'ARPE-4', 'ARPE-50', 'ARPE-51'], 'x=old;color=green;label=B' );
is_deeply ( [$test_obj->process_plotting_variables( 'Probe Set ID', 8008885)], $exp, "get the plot data");

is_deeply ( scalar($test_obj->plot( {
	'outfile' => "/home/stefan/tmp/affy_plotting_device", 
	'select_column' => 'Probe Set ID',
	'values' => [ 7945663, 8008885, 7986446],
	'title_column' => "Gene Symbol",
})),3,"plot three figures" );

$test_obj->write_file ( $infile.".out");
my $test_obj_2 = stefans_libs_file_readers_affymetrix_expression_result -> new();
$test_obj_2 -> read_file ( $infile.".out.xls" );
is_deeply ( $test_obj_2 ->Description(), $test_obj -> Description(), "read the file");

is_deeply ( [$test_obj->process_plotting_variables( 'Probe Set ID', 8008885)], [$test_obj_2->process_plotting_variables( 'Probe Set ID', 8008885)], 'Write and read');

#print "\$exp = ".root->print_perl_var_def([$test_obj->process_plotting_variables( 'Probe Set ID', 8008885)] ).";\n";


#print "\$exp = ".root->print_perl_var_def($value ).";\n";


## test for new