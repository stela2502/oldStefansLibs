#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::database::fulfilledTask' }

my $fulfilledTask = fulfilledTask -> new( root::getDBH('root', "geneexpress" ), "just_a_test" );
is_deeply ( ref($fulfilledTask) , 'fulfilledTask', 'simple test of function fulfilledTask -> new()' );

$fulfilledTask -> create('fulfilledTask');

## test for new
my ( $value, $data );
$data = { 'program_id' => "we are the test script", 'description' => 'performing a simple test'};

$value = $fulfilledTask->AddDataset ($data );
is_deeply ( $value, 1, "AddDataset");

$value = $fulfilledTask->get_fulfilled_for_program_id ($data->{'program_id'} );
is_deeply ( @$value[0]->{'description'}, $data->{'description'}, "get_fulfilled_for_program_id");

$value = $fulfilledTask->hasBeenDone ( $data );
is_deeply ( $value, 1, "hasBeenDone" );

$data ={'program_id' => "crap", 'description' => 'performing a simple test'};
$value = $fulfilledTask->hasBeenDone ( $data );
is_deeply ( $value, 0, "hasBeenDone with no result" );