#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::array_analysis::correlatingData::chi_square' }

my $chi_square = chi_square -> new();
is_deeply ( ref($chi_square) , 'chi_square', 'simple test of function chi_square -> new()' );

## test for new

