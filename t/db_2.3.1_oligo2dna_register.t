#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::database::oligo2dna_register' }

my $oligo2dna_register = oligo2dna_register->new("geneexpress");

is_deeply( ref($oligo2dna_register),
	'oligo2dna_register',
	'simple test of function oligo2dna_register -> new()' );

## test for new

my $oligo2dnaDB =
  $oligo2dna_register->Get_Query_Interface_4_dataset( { 'id' => 1 } );
is_deeply( ref($oligo2dnaDB), 'oligo2dnaDB', "we got a query interface" );

$oligo2dnaDB->printReport();

my $value = "#1, #2, #3, #3 - #2, #4 ";

$value = $oligo2dnaDB->getArray_of_Array_for_search(
	{
		'search_columns' => [
			'oligoDB.oligo_name',  'gbFeaturesTable.start',
			'gbFeaturesTable.end', 'chromosome'
		],
		'where' => [
			[ 'oligoDB.id', '=', 'my value' ],
			[ 'gbFile_id',  '=', 'my value' ]
		],
		'complex_select' => \$value
	},
	1, 1
);

my $expected = [ [ 'CHR100P000404691', 1, 34821, 34820, 'Y' ] ];
is_deeply( $value, $expected,
	    "we can generate and execute quite complex searches like '"
	  . join( " ", split( "\n", $oligo2dnaDB->{'complex_search'} ) )
	  . "'" )
