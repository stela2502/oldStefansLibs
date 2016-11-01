#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::plot::Chromosomes_plot::chromosomal_histogram' }

my $chromosomal_histogram = chromosomal_histogram -> new();
is_deeply ( ref($chromosomal_histogram) , 'chromosomal_histogram', 'simple test of function chromosomal_histogram -> new()' );

## test for new

