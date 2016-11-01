#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::nucleotide_array::nimbleGeneArrays' }

my $nimbleGeneArrays = nimbleGeneArrays -> new();
is_deeply ( ref($nimbleGeneArrays) , 'nimbleGeneArrays', 'simple test of function nimbleGeneArrays -> new()' );

## test for new

