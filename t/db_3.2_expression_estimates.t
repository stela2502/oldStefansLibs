#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::database::expression_estimate' }

use stefans_libs::tableHandling;

my (
	$value,    @values,  $exp,   $expression_estimate,
	$dataFile, $dataset, $error, $tableHandling,
	$header,   $probeID, $Data_Column
);
$expression_estimate = expression_estimate->new( root::getDBH('root'), 0 );

$dataFile = "data/expression_dataset.txt"
  if ( -f "data/expression_dataset.txt" );
$dataFile = "t/data/expression_dataset.txt"
  if ( -f "t/data/expression_dataset.txt" );

$tableHandling = tableHandling->new();

open( IN, "<$dataFile" ) or die "I could not open the data file '$dataFile'\n";

#print "we have opened the data file $dataFile\n";
$error = '';
my $i = 0;
while (<IN>) {
	$i++;
	unless ( ref($probeID) eq "ARRAY" ) {
		$probeID =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			{ 'Probe Set ID' => 1 } );
		$Data_Column =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			{ 'ISL0001' => 1 } );
		unless ( @$probeID[0] >= 0 ) {
			$error .=
'We have not identifed the column that corresponds to the "Probe Set ID"'
			  . "\n";
		}
		Carp::confess(
			"we could not identify the important header columns\n$error")
		  if ( $error =~ m/\w/ );
		next;
	}
	$_ =~ s/,/./g;
	($exp) = $tableHandling->get_column_entries_4_columns( $_, $probeID );
	( $dataset->{$exp} ) =
	  $tableHandling->get_column_entries_4_columns( $_, $Data_Column );
	$dataset->{$exp} = $1 if ( $dataset->{$exp} =~ m/^ *([\w\-\d\.]+) */ );
#	print
#	  "we got the expression_value $dataset->{$exp} for the probe_id $exp on "
#	  . ( @$Data_Column[0] + 1 ) . "\n";
}
close(IN);
$value = $expression_estimate->{'data_handler'}->{'sample_table'}->AddDataset(
	{
		'sample_lable'           => 'ISL0001',
		'name' => 'test',
		'subject_id'             => 1,
		'storage_id'             => 1,
		'initial_amount'         => 1,
		'tissue_id'              => 1,
		'aliquots'               => 1,
		'extraction_protocol_id' => 1
	}
);
is_deeply( $value, 3, "we could insert the sample for 'ISL0001'" );

$value = $expression_estimate->AddDataset(
	{
		'sample_id'    => $value,
		'sample'       => { 'id' => $value },
		'program_call' => "just a test call",
		'affy_desc_id' => 1,
		'affy_desc'    => { 'id' => 1 },
		'program_call' => "just a test call",
		'affy_desc_id' => 1,
		'affy_desc'    => { 'id' => 1 },
		'estimates'    => $dataset
	}
);

is_deeply( $value, 1, "we could insert the dataset for 'ISL0001'" );

open( IN, "<$dataFile" )
  or die "I could not open the data file '$dataFile'\n";

#print "we have opened the data file $dataFile\n";
$error = '';
$i     = 0;
while (<IN>) {
	$i++;
	unless ( ref($probeID) eq "ARRAY" ) {
		$probeID =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			{ 'Probe Set ID' => 1 } );
		$Data_Column =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			{ 'ISL0010' => 1 } );
		unless ( @$probeID[0] >= 0 ) {
			$error .=
'We have not identifed the column that corresponds to the "Probe Set ID"'
			  . "\n";
		}
		Carp::confess(
			"we could not identify the important header columns\n$error")
		  if ( $error =~ m/\w/ );
		next;
	}
	$_ =~ s/,/./g;
	($exp) = $tableHandling->get_column_entries_4_columns( $_, $probeID );
	( $dataset->{$exp} ) =
	  $tableHandling->get_column_entries_4_columns( $_, $Data_Column );
	$dataset->{$exp} = $1 if ( $dataset->{$exp} =~ m/^ *([\w\-\d\.]+) */ );
#	print
#	  "we got the expression_value $dataset->{$exp} for the probe_id $exp on "
#	  . ( @$Data_Column[0] + 1 ) . "\n";
}
close(IN);

$value = $expression_estimate->{'data_handler'}->{'sample_table'}->AddDataset(
	{
		'sample_lable'           => 'ISL0010',
		'subject_id'             => 1,
		'storage_id'             => 1,
		'initial_amount'         => 1,
		'tissue_id'              => 1,
		'aliquots'               => 1,
		'extraction_protocol_id' => 1
	}
);
is_deeply($value, 1, "Added a sample");
$value = $expression_estimate->AddDataset(
	{
		'sample_id'    => $value,
		'sample'       => { 'id' => $value },
		'program_call' => "just a test call",
		'affy_desc_id' => 1,
		'affy_desc'    => { 'id' => 1 },
		'estimates'    => $dataset
	}
);

is_deeply( $value, 2, "we could insert the dataset for 'ISL0010'" );

$value = $expression_estimate->GetInterface(
	1,
	[ [ 'sample_lable', '=', 'my_value' ] ],
	[ [ 'ISL0001', 'ISL0010' ] ]
);

is_deeply( ref($value), "probesets_table",
	"we can get a probsets_table database interface using this internal search \n$expression_estimate->{'complex_search'}" );

## and now do some queries!!

$exp = $value->getArray_of_Array_for_search(
	{
		'search_columns' => [ 'probesets_table.gene_symbol', 'expr_est.value' ],
		'where' => [ [ 'probesets_table.id', '<', 'my_value' ] ],
	},
	4
);

#print root::get_hashEntries_as_string ($exp, 3, "we expect a dataset consisting of three rows woth three entries each using this search:\n$value->{'complex_search'} ");
#print root::get_hashEntries_as_string ($value, 5, "we would expect to see some exp_est data entries");

foreach my $array ( @$exp){
	@$array[1] =~ s/,/./;
	@$array[1] = sprintf("%.5f",scalar(@$array[1]));
	@$array[2] =~ s/,/./;
	@$array[2] = sprintf("%.5f",scalar(@$array[1]));
}

is_deeply(
	$exp,
	[
		[ 'OR4F17', 2.63946,  2.63946 ],
		[ 'SEPT14', 5.80204, 5.80204 ],
		[ 'OR4F16', 3.55898, 3.55898 ]
	],
	"we can get the right data!\n"
);

