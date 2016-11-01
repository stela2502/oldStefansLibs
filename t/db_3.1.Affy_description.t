#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::database::expression_estimate::Affy_description' }
use stefans_libs::tableHandling;

my ( $value, @values, $exp, $Affy_description, $dataFile, $dataset, $error, $tableHandling, $header, $probeID, $GeneSymbol);
$Affy_description = Affy_description->new(root::getDBH('root'),0);

$dataFile = "data/expression_dataset.txt"   if ( -f "data/expression_dataset.txt" );
$dataFile = "t/data/expression_dataset.txt" if ( -f "t/data/expression_dataset.txt" );

$tableHandling = tableHandling->new();

open ( IN, "<$dataFile") or die "I could not open the data file '$dataFile'\n";
#print "we have opened the data file $dataFile\n";
$error = '';
my $i = 0;
while ( <IN> ){
	$i++;
	unless ( ref($probeID) eq "ARRAY" ){
		$probeID = $tableHandling->identify_columns_of_interest_bySearchHash($_, {'Probe Set ID' => 1});
		$GeneSymbol = $tableHandling->identify_columns_of_interest_bySearchHash($_, {'Gene Symbol' => 1});
		unless ( @$probeID[0] >= 0){
			$error .= 'We have not identifed the column that corresponds to the "Probe Set ID"'."\n";
		}
		unless ( @$GeneSymbol[0] > 0 ){
			$error .= 'We have not identifed the column that corresponds to the "Gene Symbol"'."\n";
		}
		Carp::confess( "we could not identify the important header columns\n$error") if ( $error =~ m/\w/ );
		next;
	}
	($exp) = $tableHandling->get_column_entries_4_columns( $_, $probeID);
	( $dataset->{ $exp } ) = $tableHandling->get_column_entries_4_columns( $_, $GeneSymbol);
	$dataset->{$exp} = $1 if ( $dataset->{$exp} =~ m/^ *([\w\-\d]+) */ );
	#print "we got the gene symbol $dataset->{$exp} for the probe_id $exp\n";
}

print "we got ".scalar( keys %$dataset)." in $i lines\n";

$value = $Affy_description -> AddDataset( {
	'identifier' => 'test',
	'array_type' => 'expression',
	'manufacturer' => 'affymetrix',
	'description_data' => $dataset
});

is_deeply( $value , 1, "We have inserted the dataset" );

$value = $Affy_description->GetLibInterface( $value );

is_deeply( ref($value) , "probesets_table" );

$exp = $value->getArray_of_Array_for_search({
 	'search_columns' => ["probesets_table.probeSet_id", "probesets_table.gene_symbol"]
});

is_deeply( scalar(@$exp), scalar( keys %$dataset),"we got as manny datasets from the database as we have pushed into it - sounds good!");
unless ( scalar(@$exp) == scalar( keys %$dataset)){
	print "the deleterious sql query was\n$value->{'complex_search'}\n";
}