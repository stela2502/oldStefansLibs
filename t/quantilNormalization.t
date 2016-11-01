#! /usr/bin/perl

use stefans_libs::normalize::quantilNormalization;
use Test::More;
use warnings;
use strict;

plan tests => 7;

my $quantilNormalization = quantilNormalization->new();

my ( $hash1, $hash2, $result_hash1, $result_hash2, $array1, $array2,
	$result_array1, $result_array2 );

## test if the function _create_quantil_matrix works properly

$hash1 = {
	"a" => 1,
	"b" => 2,
	"c" => 3
};

$hash2 = {
	"a" => 5,
	"b" => 6,
	"c" => 2
};

my $expect = [
	[ "a", 1, "c", 2 ],
	[ "c", 3, "b", 6 ],
	[ "b", 2, "a", 5 ]

];
my $result = $quantilNormalization->_create_quantil_matrix( $hash1, $hash2 );

is_deeply(
	[ sort { @$a[0] cmp @$b[0] } @$result ],
	[ sort { @$a[0] cmp @$b[0] } @$expect ],
	"_create_quantil_matrix concatenates two hashes"
);

$hash2 = $quantilNormalization->_setLineValuesTo_mean($result);

is_deeply(
	$hash2,
	[  [ "a", 1.5, "c", 1.5 ],  [ "b", 3.5, "a", 3.5 ], [ "c", 4.5, "b", 4.5 ] ],
	"_setLineValuesTo_mean calculation of line means"
);

## _createHashfromArray

$array1 = [ split( ",", "1,2,3,4,5,6,7" ) ];
$array2 = [ split( ",", "7,6,5,4,3,2,1" ) ];
$hash1 = $quantilNormalization->_createHashfromArray( $array1, $array2 );
is_deeply(
	$hash1,
	[
		{ 0 => 1, 1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 7 },
		{ 6 => 1, 5 => 2, 4 => 3, 3 => 4, 2 => 5, 1 => 6, 0 => 7 }
	],
	"_createHashfromArray conversion of array to hash!"
);

#_quantilNormalize_hash

$hash1 = {
	"1" => 1,
	"2" => 2,
	"3" => 3,
	"4" => 8
};

$hash2 = {
	"1" => 5,
	"2" => 6,
	"3" => 2,
	"4" => 10
};

$result_hash1 = {
	"1" => 1.5,
	"2" => 3.5,
	"3" => 4.5,
	"4" => 9
};

$result_hash2 = {
	"1" => 3.5,
	"2" => 4.5,
	"3" => 1.5,
	"4" => 9
};

$quantilNormalization->_quantilNormalize_hash( $hash1, $hash2 );

is_deeply(
	[ $hash1,        $hash2 ],
	[ $result_hash1, $result_hash2 ],
	"_quantilNormalize_hash using two hashes"
);

# quantil normalize using hashes

$array1 = [ split( ",", "1,2,3,4,5,6,7" ) ];
$array2 = [ split( ",", "7,8,9,3,4,5,6" ) ];

$hash1         = {};
$hash2         = {};
$result_hash1  = {};
$result_hash2  = {};
$result_array1 = [ split( ",", "2,3,4,5,6,7,8" ) ];
$result_array2 = [ split( ",", "6,7,8,2,3,4,5" ) ];

for ( my $i = 0 ; $i < @$array1 ; $i++ ) {
	$hash1->{$i}        = @$array1[$i];
	$hash2->{$i}        = @$array2[$i];
	$result_hash1->{$i} = @$result_array1[$i];
	$result_hash2->{$i} = @$result_array2[$i];
}

$quantilNormalization->quantilNormalize( $hash1, $hash2 );

is_deeply(
	[ $hash1,        $hash2 ],
	[ $result_hash1, $result_hash2 ],
	"quantilNormalization using hashes"
);


# quantilNormalize using arrays

$array1 = [ split( ",", "1,2,3,4,5,6,7" ) ];
$array2 = [ split( ",", "7,8,9,3,4,5,6" ) ];

$result_array1 = [ split( ",", "2,3,4,5,6,7,8" ) ];
$result_array2 = [ split( ",", "6,7,8,2,3,4,5" ) ];

$quantilNormalization->quantilNormalize( $array1, $array2 );

is_deeply(
	[ $array1,        $array2 ],
	[ $result_array1, $result_array2 ],
	"quantilNormalization using arrays"
);

## test for log2_calculation

$quantilNormalization->{log2_data} = 1;

$array1 = [ 1,2,3,4,5,6,7 ];
$array2 = [ 7,8,9,3,4,5,6 ];

$result_array1 = [ 2,3,4,5,6,7,8 ];
$result_array2 = [ 6,7,8,2,3,4,5 ];

logTheArray($array1);
logTheArray($array2);

logTheArray($result_array1);
logTheArray($result_array2);

$quantilNormalization->quantilNormalize( $array1, $array2 );

is_deeply(
	[ $array1,        $array2 ],
	[ $result_array1, $result_array2 ],
	"quantilNormalization using arrays"
);

sub logTheArray{
	my ( $array) = @_;
	for ( my $i = 0; $i < @$array ; $i++){
		@$array[$i] = log2(@$array[$i]);
	}
	return 1;
}

sub log2 {
	my ($value ) = @_;
	return log($value) / log(2);
}
