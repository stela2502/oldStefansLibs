#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use stefans_libs::database::genomeDB::genomeImporter;
BEGIN { use_ok 'stefans_libs::database::nucleotide_array' }

## test for new
my ( $value, @values, $temp, $expected );

my $nucleotide_array = nucleotide_array->new( "geneexpress", 0 );

$nucleotide_array-> create();

is_deeply( ref($nucleotide_array), 'nucleotide_array',
	'simple test of function nucleotide_array -> new()' );

## is it possible to import the array definition file of a nimblegene Array?

my $filename = "t/data/nimbleGene_ndfFile.ndf";
$filename = "data/nimbleGene_ndfFile.ndf" if ( -f "data/nimbleGene_ndfFile.ndf");
my $interface = genomeDB ->new("geneexpress", 0 )-> GetDatabaseInterface_for_Organism( 'hu_genome' );

$value = $nucleotide_array->AddDataset(
	{
		'manufacturer' => 'nimblegene',
		'identifier' => 'test',
		'genome'   => { 'id' => $interface->{'genomeID'} },
		'array_type' => 'Chip on chip',
		'ndf_file' => $filename
	}
);



$value = $nucleotide_array->AddDataset(
	{
		'manufacturer' => 'nimblegene',
		'identifier' => 'test_2',
		'genome'   => { 'id' => $interface->{'genomeID'} },
		'array_type' => 'Chip on chip',
		'ndf_file' => $filename
	}
);

is_deeply ( $value, 2 ,"we get the database 'id' from AddDataset" );

$value = $nucleotide_array -> get_array_oligos_as_fastaDB ( 'test');

is_deeply ( ref($value), "oligoDB" , "get the data as oligoDB");

$temp = $value -> getAsFasta( 'CHR1P224186' );

is_deeply ( $temp, ">CHR1P224186\nGGAGGCGGGAGGGAGACCTCGCCAACGGGAGGCGGGAGGGAGACCTCGCC", "position 2");

$nucleotide_array->printReport();


