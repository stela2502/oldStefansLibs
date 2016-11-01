#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip' }

my $NimbleGene_Chip_on_chip = NimbleGene_Chip_on_chip -> new();
is_deeply ( ref($NimbleGene_Chip_on_chip) , 'NimbleGene_Chip_on_chip', 'simple test of function NimbleGene_Chip_on_chip -> new()' );

## test for new

