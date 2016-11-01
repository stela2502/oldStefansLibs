#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::fulfilledTask::fulfilledTask_handler' }

my $fulfilledTask_handler = fulfilledTask_handler -> new();
is_deeply ( ref($fulfilledTask_handler) , 'fulfilledTask_handler', 'simple test of function fulfilledTask_handler -> new()' );

## test for new

