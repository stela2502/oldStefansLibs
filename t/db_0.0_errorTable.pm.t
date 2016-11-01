#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::system_tables::errorTable' }

my $errorTable = errorTable->new('geneexpress');
is_deeply( ref($errorTable), 'errorTable',
	'simple test of function errorTable -> new()' );

## test for new

$errorTable->create();

for ( my $i = 0 ; $i < 2 ; $i++ ) {
	my $dataset = {
		'evaluation_string' => 'data_insert.pl',
		'description'       => 'this is just a test for this table!!',
		'time'              => '2009-07-03 12:07:49'
	};

	my $value;

	$dataset->{'id'} = $errorTable->set_error_log( $dataset );

	my $expected = {
		'id'                => $dataset->{'id'},
		'evaluation_string' => 'data_insert.pl',
		'description'       => 'this is just a test for this table!!',
		'time'              => '2009-07-03 12:07:49',
		'md5_sum'           => $dataset->{'md5_sum'}
	};

	$value = $errorTable->Select_by_ID( $expected->{'id'} );
	is_deeply( $value, [$expected], "we can Select_by_ID" );

	$value = $errorTable->select_errors_for_program( $expected->{'evaluation_string'} );
	is_deeply( $value, [$expected], "we can select_errors_for_program" );

	$value =
	  $errorTable->select_errors_for_description( $expected->{'description'} );
	is_deeply( $value, [$expected], "we can select_errors_for_description" );
}