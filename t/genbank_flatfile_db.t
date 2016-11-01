#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok 'stefans_libs::database::genomeDB::genbank_flatfile_db' }

my $flatfiles = genbank_flatfile_db -> new();
is_deeply ( ref($flatfiles) , 'genbank_flatfile_db', 'simple test of function genbank_flatfile_db -> new()' );

my ($value, @values, $filename);

$filename = "../t/data/hu_genome/part.ref_ChrY.gbk.gz";
$filename = "t/data/hu_genome/part.ref_ChrY.gbk.gz" if ( -f "t/data/hu_genome/part.ref_ChrY.gbk.gz");

$flatfiles->loadFlatFile($filename);


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