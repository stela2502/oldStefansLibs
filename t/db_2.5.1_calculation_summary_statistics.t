#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { use_ok 'stefans_libs::statistics::statisticItemList' }

use stefans_libs::database::array_dataset;
use stefans_libs::database::nucleotide_array;
use stefans_libs::database::array_calculation_results;

my $statisticItemList = statisticItemList->new();
my ( $value, @values );
my $nucleotide_array = nucleotide_array->new( "geneexpress", 0 );
my $oligoDB          = $nucleotide_array->Get_OligoDB_for_ID(1);
my $array_dataset    = array_dataset->new( "geneexpress", 0 );

$value = $array_dataset->getArray_of_Array_for_search(
	{
		'search_columns' => ['array_dataset.table_baseString'],
		'where'          => [ [ 'array_dataset.array_type', '=', 'my_value' ] ]
	},
	"IP"
);
foreach my $table_name (@$value) {
	print "one dataset for the IP data is stored in table @$table_name[0]\n";
	$oligoDB->Add_oligo_array_values_Table( @$table_name[0] );
}
$statisticItemList->AddData(
	$oligoDB->getArray_of_Array_for_search(
		{
			'search_columns' =>
			  [ 'oligoDB.oligo_name', 'oligo_array_values.value' ]
		}
	),
	"IP"
);

$oligoDB->remove_all_oligo_array_values_Tables();

$value = $array_dataset->getArray_of_Array_for_search(
	{
		'search_columns' => ['array_dataset.table_baseString'],
		'where'          => [ [ 'array_dataset.array_type', '=', 'my_value' ] ]
	},
	"INPUT"
);
foreach my $table_name (@$value) {
	print "one dataset for the INPUT data is stored in table @$table_name[0]\n";
	$oligoDB->Add_oligo_array_values_Table( @$table_name[0] );
}


$statisticItemList->AddData(
	$oligoDB->getArray_of_Array_for_search(
		{
			'search_columns' =>
			  [ 'oligoDB.oligo_name', 'oligo_array_values.value' ]
		}
	),
	"control"
);

#print root::get_hashEntries_as_string($value, 3, "the result from $oligoDB->getArray_of_Array_for_search" );

$value = $statisticItemList->CalculateTStatistics();

my $array_calculation_results =
  array_calculation_results->new( "geneexpress", 0 );

print root::get_hashEntries_as_string($value, 3, "the results from \$statisticItemList->CalculateTStatistics()" );

$value = $array_calculation_results->AddDataset(
	{
		'name'         => 'summary_stat_testSetup',
		'scientist_id' => 1,
		'work_description' =>
		  "we set up the summary statistics described in PMID 16046496",
		'program_name' => 'db_calculation_summary_statistics.t',
		'program_version' => "v1.0",
		'access_right' => 'all',
		'array_id' => 1,
		'experiment_id' => 1,
		'data' => $value
	}
);

is_deeply ( $value, 1, "we have inserted data into array_calculation_results!");

## value = {<oligoID> => [ <T_stat> ]}

