#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
BEGIN { use_ok 'stefans_libs::statistics::new_histogram' }
use Digest::MD5 qw(md5_hex);

## test for new

my $histogram = new_histogram->new("test");
my ( $value, @values );

is_deeply( ref($histogram), "new_histogram", "new_histogram new" );

$value = $histogram->Category_steps(11);
is_deeply( $value, 11, "new_histogram Category_steps works" );

$value = $histogram->Max(10);
is_deeply( $value, 10, "new_histogram Max works" );

$value = $histogram->Min(-1);
is_deeply( $value, -1, "new_histogram Min works" );

## now we create $histogram->{data} and $histogram->{bins}
@values = $histogram->initialize();

is_deeply(
	$values[0],
	{
		-0.5 => 0,
		0.5  => 0,
		1.5  => 0,
		2.5  => 0,
		3.5  => 0,
		4.5  => 0,
		5.5  => 0,
		6.5  => 0,
		7.5  => 0,
		8.5  => 0,
		9.5  => 0,
	},
	"histogram -> {data} was created as expected"
);

is_deeply(
	$values[1],
	[
		{ category => -0.5, max => 0,  min => -1 },
		{ category => 0.5,  max => 1,  min => 0 },
		{ category => 1.5,  max => 2,  min => 1 },
		{ category => 2.5,  max => 3,  min => 2 },
		{ category => 3.5,  max => 4,  min => 3 },
		{ category => 4.5,  max => 5,  min => 4 },
		{ category => 5.5,  max => 6,  min => 5 },
		{ category => 6.5,  max => 7,  min => 6 },
		{ category => 7.5,  max => 8,  min => 7 },
		{ category => 8.5,  max => 9,  min => 8 },
		{ category => 9.5,  max => 10, min => 9 }
	],
	"histogram -> {bins} was created as expected"
);

my @data = (
	0, 0, -1, -1, -1, 1, 2, 2, 2, 3, 3, 4, 5,  5, 5, 5,
	5, 6, 6,  7,  7,  7, 8, 8, 8, 9, 9, 9, 10, 10
);

$value = $histogram->CreateHistogram( \@data, undef, 11 );

is_deeply(
	$value,
	{
		-0.5 => 5,
		0.5  => 1,
		1.5  => 3,
		2.5  => 2,
		3.5  => 1,
		4.5  => 5,
		5.5  => 2,
		6.5  => 3,
		7.5  => 3,
		8.5  => 3,
		9.5  => 2
	},
	"histogram -> {data} was inserted as expected (simple array)"
);

my $data = {
	A1  => { X => 0 },
	A2  => { X => 0 },
	A3  => { X => -1 },
	A4  => { X => -1 },
	A5  => { X => -1 },
	A6  => { X => 1 },
	A7  => { X => 2 },
	A8  => { X => 2 },
	A9  => { X => 2 },
	A10 => { X => 3 },
	A11 => { X => 3 },
	A12 => { X => 4 },
	A13 => { X => 5 },
	A14 => { X => 5 },
	A15 => { X => 5 },
	A16 => { X => 5 },
	A17 => { X => 5 },
	A18 => { X => 6 },
	A19 => { X => 6 },
	A20 => { X => 7 },
	A21 => { X => 7 },
	A22 => { X => 7 },
	A23 => { X => 8 },
	A24 => { X => 8 },
	A25 => { X => 8 },
	A26 => { X => 9 },
	A27 => { X => 9 },
	A28 => { X => 9 },
	A29 => { X => 10 },
	A30 => { X => 10 }
};

$value = $histogram->CreateHistogram( $data, "X", 11 );

is_deeply(
	$value,
	{
		-0.5 => 5,
		0.5  => 1,
		1.5  => 3,
		2.5  => 2,
		3.5  => 1,
		4.5  => 5,
		5.5  => 2,
		6.5  => 3,
		7.5  => 3,
		8.5  => 3,
		9.5  => 2
	},
	"histogram -> {data} was inserted as expected (hash of hashes)"
);

@data = (
	{ X => 0 }, { X => 0 }, { X => -1 }, { X => -1 }, { X => -1 }, { X => 1 },
	{ X => 2 }, { X => 2 }, { X => 2 },  { X => 3 },  { X => 3 },  { X => 4 },
	{ X => 5 }, { X => 5 }, { X => 5 },  { X => 5 },  { X => 5 },  { X => 6 },
	{ X => 6 }, { X => 7 }, { X => 7 },  { X => 7 },  { X => 8 },  { X => 8 },
	{ X => 8 }, { X => 9 }, { X => 9 },  { X => 9 },  { X => 10 },
	{ X => 10 }
);

$value = $histogram->CreateHistogram( \@data, "X", 11 );

is_deeply(
	$value,
	{
		-0.5 => 5,
		0.5  => 1,
		1.5  => 3,
		2.5  => 2,
		3.5  => 1,
		4.5  => 5,
		5.5  => 2,
		6.5  => 3,
		7.5  => 3,
		8.5  => 3,
		9.5  => 2
	},
	"histogram -> {data} was inserted as expected (hash of hashes)"
);

## test for maxAmount

$value = $histogram -> maxAmount();
is_deeply( $value , 5 , "histogram - maxAmount");

## test for minAmount

$value = $histogram -> minAmount();
is_deeply( $value , 1 , "histogram - minAmount");

@values = $histogram ->export();

@values = ( split ("\n", $values[0]));

my $newHistogram = new_histogram->new();
$newHistogram->import_from_line_array(\@values);

@values = $newHistogram ->export();

is_deeply ( $histogram, $newHistogram , "import/export");

$value = $newHistogram->LogTheHash();
is_deeply( $value , 1 , "the hash was transformed into a log hash");

$value = $newHistogram -> getHistoValue( 1.5 );

is_deeply( $value , 1.09861228866811 , "histogram (logscale) - getHistoValue ( 1.5 ) == 3");

$value = $newHistogram -> plot ( {'outfile' => "/home/stefan_l/temp/text.svg"} );

