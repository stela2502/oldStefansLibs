#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::subjectTable::phenotype_table::unifiedDataHandler' }

my $unifiedDataHandler = unifiedDataHandler -> new();
is_deeply ( ref($unifiedDataHandler) , 'unifiedDataHandler', 'simple test of function unifiedDataHandler -> new()' );

## test for new

