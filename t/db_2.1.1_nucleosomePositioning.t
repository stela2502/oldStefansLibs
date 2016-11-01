#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 14;
use stefans_libs::database::genomeDB;
BEGIN { use_ok 'stefans_libs::database::genomeDB::nucleosomePositioning' }

my ( $value, @values, $expected );
my $database =
  genomeDB->new("geneexpress")
  ->GetDatabaseInterface_for_Organism('hu_genome');
  
my $nucleosomePositioning = $database->getNucleosomePositioning_Table();

is_deeply( ref($nucleosomePositioning),
	'nucleosomePositioning',
	'simple test of function nucleosomePositioning -> new()' );

my $filename = "t/data/nucleosomePositioningTest.txt";
$filename = "data/nucleosomePositioningTest.txt"
  if ( -f "data/nucleosomePositioningTest.txt" );

$nucleosomePositioning->create( $database->{'tableBaseName'}, my $force = 1 );

$nucleosomePositioning->{dataLength} = 100;

$nucleosomePositioning->readInDataFile(
	{
		'baseName' => $database->{'tableBaseName'},
		'gbFile_id'     => 1,
		'datafile' => $filename,
		'start'    => 1
	}
);

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 1, 'start' => 1, 'end' => 5 } );
$expected = [ 0.00186, 0.00103, 0.00095, 0.00122, 0.00181 ];
is_deeply( $value, $expected, "we get the right values Get_prob_start_for_region 1-5 (gbFileID 1)" );

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 1, 'start' => 1000, 'end' => 1013 } );
$expected = [
	0.00122, 0.000892, 0.000818, 0.00114, 0.00116,  0.00114,
	0.000721, 0.000654, 0.00062,  0.00065, 0.000718, 0.000732,
	0.000825, 0.00103
];
is_deeply( $value, $expected, "we get the right values Get_prob_start_for_region 1000 - 1013 (gbFileID 1)" );

$value = $nucleosomePositioning->Get_prob_overall_for_region(
	{ 'gbFile_id' => 1, 'start' => 1000, 'end' => 1019 } );
	
$expected = [
    0.832, 0.832,0.832, 0.832, 0.832, 0.831,
    '0.830', 0.828, 0.826, 0.825, 0.823, 0.822,
    0.821, '0.820', '0.820', '0.820', '0.820', 0.819, 
    0.819, 0.819 
];

is_deeply( $value, $expected, "we get the right values Get_prob_overall_for_region 1000- 1019 (gbFileID 1)" );


$nucleosomePositioning->readInDataFile(
	{
		'baseName' => $database->{'tableBaseName'},
		'gbFile_id'     => 2,
		'datafile' => $filename,
		'start'    => 1
	}
);

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 2, 'start' => 1, 'end' => 5 } );
$expected = [ 0.00186, 0.00103, 0.00095, 0.00122, 0.00181 ];
is_deeply( $value, $expected, "we get the right values Get_prob_start_for_region 1-5 (gbFileID 2)" );

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 2, 'start' => 1000, 'end' => 1013 } );
$expected = [
	0.00122, 0.000892, 0.000818, 0.00114, 0.00116,  0.00114,
	0.000721, 0.000654, 0.00062,  0.00065, 0.000718, 0.000732,
	0.000825, 0.00103
];
is_deeply( $value, $expected, "we get the right values Get_prob_start_for_region 1000- 1013 (gbFileID 2)" );

$value = $nucleosomePositioning->Get_prob_overall_for_region(
	{ 'gbFile_id' => 2, 'start' => 1000, 'end' => 1019 } );
	
$expected = [
    0.832, 0.832, 0.832, 0.832, 0.832, 0.831,
    '0.830', 0.828, 0.826, 0.825, 0.823, 0.822,
    0.821, '0.820', '0.820', '0.820', '0.820', 0.819, 
    0.819, 0.819 
];

is_deeply( $value, $expected, "we get the right values Get_prob_overall_for_region 1000- 1019 (gbFileID 2)" );

$value = $nucleosomePositioning->Get_prob_start_for_gbFile_id ( { 'gbFile_id' => 1 });

$expected = [ 
0.00186, 0.00103, 0.00095, 0.00122, 0.00181, 
0.00301, 0.00249, 0.00114, 0.000632, 0.00036, 
0.000985, 0.00188, 0.00402, 0.0057, 0.00516,
0.00923, 0.0136, 0.0122, 0.00898, 0.00349
 ];

@values = ();
for ( my $i = 0; $i < 5; $i++ ){
	#print "test script : select values from overall arrays: $i -> @$value[$i]\n";
	push ( @values ,@$value[$i]);
}
for ( my $i = 100; $i < 105; $i++ ){
	#print "test script : select values from overall arrays: $i -> @$value[$i]\n";
	push ( @values ,@$value[$i]);
}

for ( my $i = 200; $i < 205; $i++ ){
	#print "test script : select values from overall arrays: $i -> @$value[$i]\n";
	push ( @values ,@$value[$i]);
}

for ( my $i = 40000; $i < 40005; $i++ ){
	#print "test script : select values from overall arrays: $i -> @$value[$i]\n";
	push ( @values ,@$value[$i]);
}

is_deeply ( \@values, $expected, "we get the right values using Get_prob_start_for_gbFile_id ");


## and now we test the advanced features...

$nucleosomePositioning->readInDataFile(
	{
		'baseName' => $database->{'tableBaseName'},
		'gbFile_id'     => 3,
		'datafile' => $filename,
		'start'    => 1,
		'skipp_last' => 1103
	}
);

## we should not see anything bejond 1100 bp!

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 3, 'start' => 1000, 'end' => 1013 } );
$expected = [
	0.00122, 0.000892, 0.000818, 0.00114, 0.00116,  0.00114,
	0.000721, 0.000654, 0.00062,  0.00065, 0.000718, 0.000732,
	0.000825, 0.00103
];
is_deeply( $value, $expected, "we get the right values Get_prob_start_for_region 1000- 1013 (gbFileID 3)" );

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 3, 'start' => 1100, 'end' => 1105 } );
$expected = [
	0.00795 , 0, 0, 0, 0, 0
];
is_deeply( $value, $expected, "we get the right values Get_prob_start_for_region 1100- 1105 (gbFileID 3)" );

## and now one out of bounds...

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 3, 'start' => 1200, 'end' => 1213 } );
$expected = [ undef , undef, undef, undef , undef, undef,undef , undef, undef,undef , undef, undef, undef, undef];
is_deeply( $value, $expected, "we get use readInDataFile with the 'skipp_last' value" );

## now we want to add some entries....

$nucleosomePositioning->readInDataFile(
	{
		'baseName' => $database->{'tableBaseName'},
		'gbFile_id'     => 3,
		'datafile' => $filename,
		'start'    => 1101,
		'skipp_last' => 1103
	}
);

print $nucleosomePositioning->{error};

## we would expect that the first entries in the file are now placed on after the old entries.

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 3, 'start' => 1200, 'end' => 1205 } );
$expected = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 3, 'start' => 100, 'end' => 105 } );

is_deeply( $value, $expected, "we can use readInDataFile with the 'start' value changed" );

## and now we need to test the insertion starting at a certain position of the input file...

$nucleosomePositioning->readInDataFile(
	{
		'baseName' => $database->{'tableBaseName'},
		'gbFile_id'     => 3,
		'datafile' => $filename,
		'start'    => 2201,
		'skipp_first' => 300,
		'skipp_last' => 1103
	}
);

## ok - what would we expect?
## starting at 2201 we have the same values as starting at 301, but before that we would expect the same values as before 1100
@$expected = ();
push ( @$expected , @{$nucleosomePositioning->Get_prob_start_for_region({ 'gbFile_id' => 3, 'start' => 1000, 'end' => 1100 } ) } );
push ( @$expected , @{$nucleosomePositioning->Get_prob_start_for_region({ 'gbFile_id' => 3, 'start' => 2201, 'end' => 2300 } ) } );

$value = $nucleosomePositioning->Get_prob_start_for_region(
	{ 'gbFile_id' => 3, 'start' => 2100, 'end' => 2300 } );
	
is_deeply( $value, $expected, "we can use readInDataFile with the 'skipp_first' value" );
