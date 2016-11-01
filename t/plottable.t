#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'lib::stefans_libs::plot::plottable' }

my $plottable = plottable -> new();
is_deeply ( ref($plottable) , 'plottable', 'simple test of function plottable -> new()' );

## test for new

