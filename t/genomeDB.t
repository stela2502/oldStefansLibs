#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::database::genomeDB::genbank_flatfile_db;

use Test::More tests => 7;
BEGIN { use_ok 'stefans_libs::database::genomeDB' }

open( DB, ">create_test.db" ) or die "could not craete file create_test.db\n";
print DB "create database geneexpress;\n";
close(DB);
open( DB, ">drop_test.db" ) or die "could not drop file create_test.db\n";
print DB "drop database geneexpress;\n";
close(DB);

system("mysql -uroot -palmdiR < drop_test.db");
system("mysql -uroot -palmdiR < create_test.db");

my $genomeDB = genomeDB->new( "geneexpress" );

is_deeply( ref($genomeDB), 'genomeDB',
	'simple test of function genomeDB -> new()' );

## now we have to add data... two gbFiles would be nice....

my ( $value, @values, $gbFile_location );

$gbFile_location = "../t/data/hu_genome/part.ref_ChrY.gbk.gz";
$gbFile_location = "t/data/hu_genome/part.ref_ChrY.gbk.gz" if ( -f "t/data/hu_genome/part.ref_ChrY.gbk.gz");

$value = $genomeDB->create();

is_deeply( $value, 1, "we can create the table" );

## the data for the first kb of human chr Y are stored in path /t/data/hu_genome/
## most probably we only need the data/hu_genome part....

## we try to import the reference sequence Y chromosome version 36.3
## this will only work if the data is available!
die "the datasets are not available!\n"
  unless ( -f $gbFile_location );

my $flatfiles = genbank_flatfile_db->new();

$flatfiles->loadFlatFile($gbFile_location);

@values = ('NT_113819.1', 'NT_113967.1', 'NT_113968.1', 'NT_113969.1', 'NT_113970.1');
$value = [ ( sort keys %{ $flatfiles->{files} } ) ];

is_deeply(
	$value,
	[ sort @values ],
	"all gbFiles were parsed by genbank_flatfile_db"
);

$value = $flatfiles -> get_gbFile_obj_for_version ('NT_113819.1');

is_deeply(
	ref($value),
	"gbFile",
	"we can access the gbFiles via genbank_flatfile_db"
);

is_deeply( [$value->Length, $value->Name(), $value->Version() ], [554624, 'NT_113819', 'NT_113819.1' ], "and the contents are as expected");

unless ($value->Version() eq 'NT_113819.1' ){
	system("mysql -uroot -palmdiR < drop_test.db");
	die "we have to chancle all other tests - fix genbank_flatfile_db first!\n";
}
## ok - that looks good!

$value = $genomeDB->insert( "1.0", "H_sapiens", "data/hu_genome" );

is_deeply( $value, "H_sapiens_1_0", "and it looks like we managed to create an entry!" );

$genomeDB->

$genomeDB = undef;



