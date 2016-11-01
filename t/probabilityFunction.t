#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 20;
BEGIN { use_ok 'stefans_libs::statistics::HMM::probabilityFunction' }

sub ScaleSumToOne {
	my ($data) = @_;

	my ($i);

	die "test ScaleSumToOne no data present!" unless ( defined $data );

	$i = 0;

	while ( my ( $key, $value ) = each %$data ) {
		$i += $value unless ( $key =~ m/ARRAY/ );
	}
	foreach my $value ( values %$data ) {
		$value = $value / $i;
	}
	$i = 0;
	while ( my ( $key, $value ) = each %$data ) {
		$i += $value unless ( $key =~ m/ARRAY/ );
	}
	$i = &ScaleSumToOne() unless ( $i > 0.99999 && $i < 1.000001 );
	return $data;
}

sub logTheHash {
	my ($hash) = @_;
	foreach my $key ( keys %$hash ) {
		$hash->{$key} = log( $hash->{$key} );
	}
	return $hash;
}



my $probabilityFunction = probabilityFunction->new( " ", 1);
is_deeply( ref($probabilityFunction),
	'probabilityFunction',
	'simple test of function probabilityFunction -> new()' );

is_deeply ( $probabilityFunction->isa( 'new_histogram' ), 1,"we inherit from new_histogram" );

my ( $value, @values );

$value = $probabilityFunction->Category_steps(11);
is_deeply( $value, 11, "new_histogram Category_steps works" );

$value = $probabilityFunction->Max(10);
is_deeply( $value, 10, "new_histogram Max works" );

$value = $probabilityFunction->Min(-1);
is_deeply( $value, -1, "new_histogram Min works" );

## now we create $probabilityFunction->{data} and $probabilityFunction->{bins}
@values = $probabilityFunction->initialize();

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

$value = $probabilityFunction->CreateHistogram( \@data, undef, 11 );

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

$value = $probabilityFunction->CreateHistogram( $data, "X", 11 );

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
	{ X => 0 },
	{ X => 0 },
	{ X => -1 },
	{ X => -1 },
	{ X => -1 },
	{ X => 1 },
	{ X => 2 },
	{ X => 2 },
	{ X => 2 },
	{ X => 3 },
	{ X => 3 },
	{ X => 4 },
	{ X => 5 },
	{ X => 5 },
	{ X => 5 },
	{ X => 5 },
	{ X => 5 },
	{ X => 6 },
	{ X => 6 },
	{ X => 7 },
	{ X => 7 },
	{ X => 7 },
	{ X => 8 },
	{ X => 8 },
	{ X => 8 },
	{ X => 9 },
	{ X => 9 },
	{ X => 9 },
	{ X => 10 },
	{ X => 10 }
);

$value = $probabilityFunction->CreateHistogram( \@data, "X", 11 );

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

$value = $probabilityFunction->maxAmount();
is_deeply( $value, 5, "histogram - maxAmount" );

## test for minAmount

$value = $probabilityFunction->minAmount();
is_deeply( $value, 1, "histogram - minAmount" );

@values = $probabilityFunction->export();

@values = ( split( "\n", $values[0] ) );

my $newHistogram = probabilityFunction->new( " ", 1);
$newHistogram->import_from_line_array( \@values );

@values = $newHistogram->export();

is_deeply( $probabilityFunction, $newHistogram, "import/export" );

## test the reestimation thing!
## first with non logged data

$probabilityFunction = probabilityFunction->new();

@data = (
	0, 0, -1, -1, -1, 1, 2, 2, 2, 3, 3, 4, 5,  5, 5, 5,
	5, 6, 6,  7,  7,  7, 8, 8, 8, 9, 9, 9, 10, 10
);

$value = $probabilityFunction->CreateHistogram( \@data, undef, 11 );

@data = (
	0, -1, -1, 1, 2, 2, 3, 4, 5, 5, 5, 5, 5, 5,
	5, 5,  5,  5, 5, 6, 7, 7, 8, 8, 9, 9, 10
);
$probabilityFunction->initReestimation();
foreach $value (@data) {
	$probabilityFunction->Reestimate( $value, 1 );
}

$value = $probabilityFunction->finalizeReestimation();

is_deeply(
	$value,
	ScaleSumToOne(
		{
			-0.5 => 3,
			0.5  => 1,
			1.5  => 2,
			2.5  => 1,
			3.5  => 1,
			4.5  => 11,
			5.5  => 1,
			6.5  => 2,
			7.5  => 2,
			8.5  => 2,
			9.5  => 1
		}
	),
	"probabilityFunction: reestimation"
);

## and now the logged thing!

$probabilityFunction = undef;
$probabilityFunction = probabilityFunction->new();

$value = $probabilityFunction->CreateHistogram( \@data, undef, 11 );

$value = $probabilityFunction->LogTheHash();

is_deeply( $value, 1, "LogTheHash returns 1" );

is_deeply(
	$probabilityFunction->{data},
	{
		-0.5 => log(3),
		0.5  => log(1),
		1.5  => log(2),
		2.5  => log(1),
		3.5  => log(1),
		4.5  => log(11),
		5.5  => log(1),
		6.5  => log(2),
		7.5  => log(2),
		8.5  => log(2),
		9.5  => log(1)
	},
	"probabilityFunction: LogTheHash (log) function"
);

#and now - reestimate!

@data = ( 0, -1, -1, 1, 2, 2, 3, 5, 5, 5, 5, 6, 7, 7, 8, 8, 9, 9, 10, 4 );

$probabilityFunction->initReestimation();

foreach $value (@data) {
	$probabilityFunction->Reestimate( $value, log(1) );
}

is_deeply(
	$probabilityFunction->{new_data},
	{
		-0.5 => 3,
		0.5  => 1,
		1.5  => 2,
		2.5  => 1,
		3.5  => 1,
		4.5  => 4,
		5.5  => 1,
		6.5  => 2,
		7.5  => 2,
		8.5  => 2,
		9.5  => 1
	},
	"probabilityFunction: reestimation (log) the data is entered correctly"
);


$value = $probabilityFunction->finalizeReestimation();

my $hash = {
	-0.5 => 3,
	0.5  => 1,
	1.5  => 2,
	2.5  => 1,
	3.5  => 1,
	4.5  => 4,
	5.5  => 1,
	6.5  => 2,
	7.5  => 2,
	8.5  => 2,
	9.5  => 1
};

$hash = ScaleSumToOne($hash);
$hash = logTheHash ( $hash) ;

is_deeply(
	$value,
	$hash,
	"probabilityFunction: reestimation with log values!!"
);

$probabilityFunction = undef;
$probabilityFunction = probabilityFunction->new();

$probabilityFunction->createFixedDataset(
	{
		-0.5 => 3,
		0.5  => 1,
		1.5  => 2,
		2.5  => 1,
		3.5  => 1,
		4.5  => 4,
		5.5  => 1,
		6.5  => 2,
		7.5  => 2,
		8.5  => 2,
		9.5  => 1
	}
);

$value = $probabilityFunction->getAsDataMatrix();

#print $probabilityFunction-> export();

$hash = {
	-0.5 => 3,
	0.5  => 1,
	1.5  => 2,
	2.5  => 1,
	3.5  => 1,
	4.5  => 4,
	5.5  => 1,
	6.5  => 2,
	7.5  => 2,
	8.5  => 2,
	9.5  => 1
};

$hash = ScaleSumToOne($hash);

my $array = [];

foreach my $key ( sort { $a <=> $b } keys %$hash ) {
	push( @$array, [ $key, $key, $hash->{$key} ] );
}

is_deeply( [ sort { @$a[0] <=> @$b[0] } @$value ],
	$array, "probabilityFunction createFixedDataset" );
