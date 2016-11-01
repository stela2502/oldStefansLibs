#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use stefans_libs::database::genomeDB;
use stefans_libs::database::oligo2dna_register;
BEGIN { use_ok 'stefans_libs::database::nucleotide_array' }

## test for new
my ( $value, @values, $temp, $expected );

my $genomeDB        = genomeDB->new("geneexpress");
my $chromsomesTable = $genomeDB->GetDatabaseInterface_for_Organism("hu_genome");

### we have to check, whether everything works fine...
($value) = $chromsomesTable->ID( undef, 'Y', 1, 821 );
is_deeply( $value, [1], "we can access the genomesDB" );

my $nucleotide_array = nucleotide_array->new( "geneexpress", 0 );

$nucleotide_array->Match_NucleotideArray_to_Genome( { 'identifier' => 'test' },
	{ 'id' => 1 } );

## The database table :
## +----+------------------+-------+-----------------+-----------+---------------+
## | id | oligo_name       | start | sameOrientation | gbFile_id | OligoHitCount |
## +----+------------------+-------+-----------------+-----------+---------------+
## |  3 | CHR100P000404691 |  1201 |               1 |         1 |             1 |
## |  1 | CHR700P000745846 |  6241 |               1 |         1 |             2 |
## |  2 | CHR700P000745846 |   799 |               1 |         2 |             2 |
## +----+------------------+-------+-----------------+-----------+---------------+

is_deeply( 1, 1,
	    "at least we did not die during the "
	  . ref($nucleotide_array)
	  . "->Match_NucleotideArray_to_Genome() function call!" );

my $nucl_array_interface = $nucleotide_array->get_Array_Lib_Interface( { 'id' => 1 } );

is_deeply( ref($nucl_array_interface),
	'oligo2dnaDB', "we got a oligo2dnaDB interface!" );

$value = $nucl_array_interface->get_oligos(
	{ 'chromosome' => 'Y', 'start' => 12000, 'end' => 207885 }, "SignalMap" );

$expected = [
	[
		'Y', 201385, 'CHR100P000721173',
		'GAATTACAGGCATGCTCCACCACTACCCAGCTAGTATTTGTAGTTTTAGT', 6500
	]
];

#root::print_hashEntries( $value, 5,
#	"we got the following values for the 'select one oligo' search" );

#root::print_hashEntries( $value->{1}[1], 5, "and here we expect NOTHING!!");

is_deeply( $value, $expected, "select one oligo" );

