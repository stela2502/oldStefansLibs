#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::gbFile;
use Test::More tests => 5;
BEGIN { use_ok 'stefans_libs::database::genomeDB::gbFilesTable' }


my $gbFilesTable = gbFilesTable -> new(root::getDBH('root', "geneexpress" ));
is_deeply ( ref($gbFilesTable) , 'gbFilesTable', 'simple test of function gbFilesTable -> new()' );

## test for new

my ( $value, @values);

## test for new

## test for TableName

$value = $gbFilesTable->TableName( "make.a.test" );
is_deeply ( $value, "make_a_test_gbFilesTable", "table base name is created correctly");

$value = $gbFilesTable ->create();

is_deeply ( $value, 1, "we created a table ".$gbFilesTable->TableName() );

my $filename = "../t/data/hu_genome/originals/NT_113968.1.gb";
$filename = "t/data/hu_genome/originals/NT_113968.1.gb" if ( -f "t/data/hu_genome/originals/NT_113968.1.gb" );
unless ( -f $filename) { system ( "ls -lh" ); }

my $gbFile = gbFile->new($filename);
$gbFilesTable->AddDataset( { 'gbFile' => $gbFile, 'chromosome' => {'tax_id' => 1,
	'chromosome' => 'Y',
	'chr_start' => 1,
	'chr_stop' => $gbFile->Length(),
	'orientation' => '+',
	'feature_name' => $gbFile->Version(),
	'feature_id' => 'k.a.',
	'feature_type' => 'k.a.',
	'group_label' => 'k.a.'
} } );





