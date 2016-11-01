#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::dataset_registaration' }

my $dataset_registaration = dataset_registaration -> new('geneexpress');
is_deeply ( ref($dataset_registaration) , 'dataset_registaration', 'simple test of function dataset_registaration -> new()' );

## test for new

