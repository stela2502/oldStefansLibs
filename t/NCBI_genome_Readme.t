#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok 'stefans_libs::database::genomeDB::genomeImporter::NCBI_genome_Readme' }

my $NCBI_genome_Readme = NCBI_genome_Readme -> new();
is_deeply ( ref($NCBI_genome_Readme) , 'NCBI_genome_Readme', 'simple test of function NCBI_genome_Readme -> new()' );

my ( $value, @values);

## test for new

my $filename = "../t/data/hu_genome/README_CURRENT_BUILD";
$filename = "t/data/hu_genome/README_CURRENT_BUILD" if ( -f "t/data/hu_genome/README_CURRENT_BUILD");
$NCBI_genome_Readme->readFile($filename);

$value = $NCBI_genome_Readme->Version();
is_deeply( $value, "36.3", "read the version of the build");

$value = $NCBI_genome_Readme->ReleaseDate();
is_deeply( $value, "2008-03-24", "read the release date");

$value = $NCBI_genome_Readme->ReferenceTag();
is_deeply($value, "reference" , "we can access the referrence tag");

$value = $NCBI_genome_Readme->convert_NCBI_date_to_mysql('24 December 2008');
is_deeply( $value, "2008-12-24", "read the release date #2");

$value = $NCBI_genome_Readme->convert_NCBI_date_to_mysql('24 uuuggs 2008');
is_deeply( $value, undef , "read the release date #3");