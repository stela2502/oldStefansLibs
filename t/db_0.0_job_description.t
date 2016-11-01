#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::database::system_tables::jobTable' }

my $job_description = jobTable->new(root::getDBH('root'));

is_deeply( ref($job_description), 'jobTable',
	'simple test of function job_description -> new()' );

## test for new


my $dataset = {
		'job_type'          => 'data_insert',
		'description'   => 'this is just a test for this table!!',
		'cmd' => 'just_a_test _ command',
		'state' => 1,
		'executable' => 'just_a_test'
	};
	
my $value;



$dataset ->{'id'} = $job_description->AddDataset(
	$dataset
);

my $expected = {
		'id' => $dataset ->{'id'},
		'job_type'          => 'data_insert',
		'description'   => 'this is just a test for this table!!',
		'cmd' => 'just_a_test _ command',
		'state' => 1,
		'executable' => 'just_a_test',
		'md5_sum' => $dataset ->{'md5_sum'}
};

$value = $job_description->Select_by_ID ( $expected ->{ 'id'} );
is_deeply( $value, [$expected], "we can Select_by_ID");

$value = $job_description->Select_by_Job_Type ( $expected ->{ 'job_type'} );
is_deeply( $value, [$expected], "we can Select_by_Job_Type");

