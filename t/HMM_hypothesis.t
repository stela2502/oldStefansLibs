#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;
use stefans_libs::gbFile::gbRegion;

BEGIN { use_ok 'stefans_libs::statistics::HMM::HMM_hypothesis' }

my $HMM_hypothesis = HMM_hypothesis -> new();
is_deeply ( ref($HMM_hypothesis) , 'HMM_hypothesis', 'simple test of function HMM_hypothesis -> new()' );

## test for new

$HMM_hypothesis -> add_internalState_hypotheis ( { 'name' => 'higher' , 'hypothesis' => { 'more_than' => 0.7 }});
is_deeply($HMM_hypothesis -> getStateName() ,"higher", "simple test more_than" );
is_deeply($HMM_hypothesis -> getHypType(), "more_than" , "more_than name");
is_deeply($HMM_hypothesis -> getHypEntry(), 0.7  , "more_than value");

$HMM_hypothesis = HMM_hypothesis -> new();
$HMM_hypothesis -> add_internalState_hypotheis ( { 'name' => 'higher' , 'hypothesis' => { 'less_than' => 0.2 }});
is_deeply($HMM_hypothesis -> getStateName() ,"higher", "simple test less_than" );
is_deeply($HMM_hypothesis -> getHypType(), "less_than" , "less_than name");
is_deeply($HMM_hypothesis -> getHypEntry(), 0.2  , "less_than value");

$HMM_hypothesis = HMM_hypothesis -> new();
$HMM_hypothesis -> add_internalState_hypotheis ( { 'name' => 'higher' , 'hypothesis' => { 'region' => [gbRegion->new( "1..100"), gbRegion->new("300..800")] }});
is_deeply($HMM_hypothesis -> getStateName() ,"higher", "simple test region" );
is_deeply($HMM_hypothesis -> getHypType(), "region" , "region was inserted ok");
is_deeply($HMM_hypothesis -> getHypEntry(), [gbRegion->new( "1..100"), gbRegion->new("300..800")]  , "region value");

my $value = $HMM_hypothesis -> getStateValues_obj ();
my $second = $HMM_hypothesis -> getStateValues_obj ();
is_deeply ( $value, $second , "state values creation");
