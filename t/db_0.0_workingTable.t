#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::system_tables::workingTable' }

my $workingTable = workingTable -> new('geneexpress');
is_deeply ( ref($workingTable) , 'workingTable', 'simple test of function workingTable -> new()' );

## test for new

$workingTable->create();

## test for new

for ( my $ i = 0; $i <2 ; $i ++){
my $dataset = {
		'programID'          => 'data_insert.pl',
		'description'   => 'this is just a test for this table!!',
		'PID' => $$
	};
	
my $value;

$dataset ->{'id'} = $workingTable->set_workload(
	$dataset
);

my $expected = {
		'id' => $dataset ->{'id'},
		'programID'          => 'data_insert.pl',
		'description'   => 'this is just a test for this table!!',
		'PID' => $$,
		'start_time' => $dataset -> { 'start_time'}. ".000000",
		'md5_sum' => $dataset ->{'md5_sum'}
};

$value = $workingTable->Select_by_ID ( $expected ->{ 'id'} );
is_deeply( $value, [$expected], "we can Select_by_ID");

$value = $workingTable->select_workloads_for_program ( $expected ->{ 'programID'} );
is_deeply( $value, [$expected], "we can select_workloads_for_program");

$value = $workingTable->select_workloads_for_description ( $expected ->{ 'description'} );
is_deeply( $value, [$expected], "we can programID");

$workingTable -> delete_workload_for_PID ( $expected ->{ 'PID'} );
}