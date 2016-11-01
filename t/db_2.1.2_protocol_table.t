#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use stefans_libs::root;
BEGIN { use_ok 'stefans_libs::database::protocol_table' }

my $protocol_table =
  protocol_table->new( root::getDBH( 'root', "geneexpress" ) );
is_deeply( ref($protocol_table), 'protocol_table',
	'simple test of function protocol_table -> new()' );

## test for new
my ( $value, @values, $expected );

open ( T, ">Just_a_test_file.txt");
print T "Just a test!\n";
close ( T );

$value = $protocol_table->AddDataset(
	{
		'name'         => 'A new protocol',
		'description'  => 'TEST - standard DNA extraction protocol - TEST',
		'version'      => '1.0',
		'working_copy' => "just follow the kit description",
		'original_protocol_description' => {
			'file'     => 'Just_a_test_file.txt',
			'filetype' => 'text_document'
		},
		'materialList' => { 'list_id' => 1}
	}
);
##   ( name, description, version, working_copy, 
##     original_protocol_description_id, PMID, materialList_id, md5_sum )
if (unlink( "Just_a_test_file.txt") ){
	print "temp file deleted!\n";
}
is_deeply( $value, 1, "we could add a dataset" );

## honestly - I would like to read the protocol description file!
 $value = $protocol_table -> getArray_of_Array_for_search({
 	'search_columns' => ['external_files.file'],
 	'where' => [[ref($protocol_table).".name", '=', 'ma_value']],
 },
 'A new protocol'
 );
open ( T , "<@{@$value[0]}[0]") or die "could not open the protocol description file @{@$value[0]}[0]\n";
while ( <T> ){
	is_deeply( $_, "Just a test!\n", "we could acces the data file" );
}
close ( T );

## OK next - can we get our protocol querying for a materialsTable entry?
 $value = $protocol_table -> getArray_of_Array_for_search({
 	'search_columns' => ['external_files.file'],
 	'where' => [["materialsTable.id", '=', 'my_value']],
 },
 1
 );
 open ( T , "<@{@$value[0]}[0]") or die "could not open the protocol description file @{@$value[0]}[0]\n";
while ( <T> ){
	is_deeply( $_, "Just a test!\n", "we could acces the data file searching for a materialsTable.id!!" );
}
close ( T );

print $protocol_table -> {complex_search};

