#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::statistics::HMM::state_values;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::statistics::HMM::marcowChain' }
## test for new

my $C = state_values->new("C");
my $H = state_values->new("H");

$C->import_from_line_array(
	[
		split(
			"\n", 'name	C
log_state	1
startProbability	-0.693147180559945
endProbability	-2.30258509299405
probability_for_change_to_state
H	-2.30258509299405
C	-0.22314355131421
probability distribution
logged	1
min	1
max	3
category_steps	3
scale21	1
noNull	1
data
1	1	1	-2.48223928400802
2	2	2	-0.975423855522189
3	3	3	-0.617276405601344'
		)
	]
);
$H->import_from_line_array(
	[
		split(
			"\n", 'name	H
log_state	1
startProbability	-0.693147180559945
endProbability	-2.30258509299405
probability_for_change_to_state
H	-0.22314355131421
C	-2.30258509299405
probability distribution
logged	1
min	1
max	3
category_steps	3
scale21	1
noNull	1
data
1	1	1	-0.617276405601344
2	2	2	-0.975423855522189
3	3	3	-2.48223928400802'
		)
	]
);

my $chain = marcowChain->new( [ $C, $H ] );

is_deeply( ref($chain), "marcowChain", "simple test  for new" );

my ( $value, @values );
@values = ( log(5), log(8) );

$value = $chain->Add2Logs(@values);

is_deeply( exp($value), 13, "Add2Logs" );

my @states = ( 'Rainy', 'Sunny' );

my @observations = ( 'walk', 'shop', 'clean' );

my $start_probability = { 'Rainy' => 0.6, 'Sunny' => 0.4 };

my $transition_probability = {
	'Rainy' => { 'Rainy' => 0.7, 'Sunny' => 0.3 },
	'Sunny' => { 'Rainy' => 0.4, 'Sunny' => 0.6 },
};

my $emission_probability = {
	'Rainy' => { 'walk' => 0.1, 'shop' => 0.4, 'clean' => 0.5 },
	'Sunny' => { 'walk' => 0.6, 'shop' => 0.3, 'clean' => 0.1 },
};

## test for addValue

## test for addValueArray

## test for getProbabilityHash

## test for getProbabilityHash_H0

## test for getValuesHash

## test for getProbability4ID

## test for first_pH0

## test for last_pH0

## test for first_pH1

## test for last_pH1

## test for addProbabilityFunction_F0

## test for addProbabilityFunction_F1

## test for Add2Logs

## test for CalculateForwardProbability

## test for CalculateBackwardProbability

## test for CalculateTotalProbabilityFromStartToEnd

## test for CalculateProbOfTransitions

## test for ReestimateProbabilityFunctions

## test for SumOf

## test for print_enriched_regions

## test for Print

