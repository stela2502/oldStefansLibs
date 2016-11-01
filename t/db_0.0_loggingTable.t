#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::database::system_tables::loggingTable' }

my $loggingTable = loggingTable -> new('geneexpress');
is_deeply ( ref($loggingTable) , 'loggingTable', 'simple test of function loggingTable -> new()' );

$loggingTable->create();

## test for new

for ( my $ i = 0; $i <2 ; $i ++){
my $dataset = {
		'programID'          => 'data_insert.pl',
		'description'   => 'this is just a test for this table!!',
		'start_time' => '2009-07-03 12:07:49',
	};
	
my $value;

$dataset ->{'id'} = $loggingTable->set_log(
	$dataset
);

my $expected = {
		'id' => $dataset ->{'id'},
		'programID'          => 'data_insert.pl',
		'description'   => 'this is just a test for this table!!',
		'start_time' => '2009-07-03 12:07:49',
		'end_time' => $dataset -> { 'end_time'},
		'md5_sum' => $dataset ->{'md5_sum'}
};

$value = $loggingTable->Select_by_ID ( $expected ->{ 'id'} );
is_deeply( $value, [$expected], "we can Select_by_ID");

$value = $loggingTable->select_logs_for_program ( $expected ->{ 'evaluation_string'} );
is_deeply( $value, [$expected], "we can select_logs_for_program");

$value = $loggingTable->select_logs_for_description ( $expected ->{ 'description'} );
is_deeply( $value, [$expected], "we can Select_by_Description");

$loggingTable -> delete_log_for_ID ( $expected ->{ 'id'} );
}
