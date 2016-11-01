#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::plot::plottable_gbFile' }

my $plottable_gbFile = plottable_gbFile -> new();
is_deeply ( ref($plottable_gbFile) , 'plottable_gbFile', 'simple test of function plottable_gbFile -> new()' );

## test for new

