#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'lib::stefans_libs::database::array_dataset::array_values' }

my $array_values = array_values -> new();
is_deeply ( ref($array_values) , 'array_values', 'simple test of function array_values -> new()' );

## test for new

