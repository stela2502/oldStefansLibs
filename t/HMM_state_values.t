#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;
BEGIN { use_ok 'stefans_libs::statistics::HMM::state_values;' }

my $state_values = state_values -> new("important");
is_deeply ( ref($state_values) , 'state_values', 'simple test of function state_values -> new()' );

use stefans_libs::statistics::HMM::probabilityFunction;

my $histogram = $state_values-> ProbabilityDistribution( probabilityFunction->new("first") );
my ( $value, @values);

my @data = (
	0, 0, -1, -1, -1, 1, 2, 2, 2, 3, 3, 4, 5,  5, 5, 5,
	5, 6, 6,  7,  7,  7, 8, 8, 8, 9, 9, 9, 10, 10
);

$value = $histogram->CreateHistogram( \@data, undef, 11 );

#my $histo2 = probabilityFunction->new("last");
#@data = (
#	0, 0, -1, -1,-1, -1 -1, 1, 2, 2, 2, 3, 3, 4, 5,  5, 5, 5,
#	5, 6, 6, 6, 6, 4, 4, 4, 4, 7,  7,  7, 8, 8, 8, 9, 9, 9, 10, 10
#);
#
#$value = $histo2->CreateHistogram( \@data, undef, 11 );

#$state_values-> ProbabilityDistribution($histogram);

$value = $state_values-> ProbabilityDistribution();

is_deeply ( $value, $histogram, "simple storage of a histogram works");

$value = $state_values-> prob_for_observed ( -0.3 );

is_deeply ( $value, 5 , "prob_for_observed gives the right value back ( -0.3 )");

$value = $state_values-> prob_for_observed ( 0.000001 );

is_deeply ( $value, 1 , "prob_for_observed gives the right value back ( 0.00001 )");

$value = $state_values->probability_for_change_to_state( "nix" , 0.3 );

is_deeply ( $value, 0.3 , "probability_for_change_to_state gives the right value back ( 0.3 )");

$value = $state_values->probability_for_change_to_state( "allex" , 0.99999 );

is_deeply ( $value, 0.99999 , "probability_for_change_to_state gives the right value back ( 0.99999 )");

$value = $state_values->probability_for_change_to_state( "questionable" , 0 );

is_deeply ( $value, undef , "probability_for_change_to_state gives the right value back ( 0 )");

$value = $state_values->probability_for_change_to_state( "questionable" , 1 );

is_deeply ( $value, undef , "probability_for_change_to_state gives the right value back ( 1 )");

$value = $state_values->probability_for_change_to_state( "nix" );

is_deeply ( $value , 0.3 , "probability_for_change_to_state can get stored infos");


$value = $state_values->probability_for_change_to_state( "nix", 0.4 );

is_deeply ( $value , 0.4, "probability_for_change_to_state datasets can be changed");

$state_values->Log_state(1);

$value = $state_values->probability_for_change_to_state( "nix" );

is_deeply ( $value , log(0.4), "the log was applied for the probability_for_change_to_state datasets");


$value = $state_values-> prob_for_observed ( -0.3 );

is_deeply ( $value , log(0.166666666666667), "the log was applied for the probability function");

$state_values->Log_state(0);

$value = $state_values->probability_for_change_to_state( "nix" );

is_deeply ( $value , 0.4, "the log was removed for the probability_for_change_to_state datasets");

$value = $state_values-> prob_for_observed ( -0.3 );

is_deeply ( $value , 0.166666666666667, "the log was removed for the probability function");

$value = $state_values->export();

@values = split("\n",$value);

my $new_state = state_values->new("nothing");

$new_state->import_from_line_array(\@values);
$new_state->{error} = undef;

is_deeply ( $state_values, $new_state, "import/export");


