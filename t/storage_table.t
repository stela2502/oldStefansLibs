#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::storage_table' }

my $storage_table = storage_table -> new();
is_deeply ( ref($storage_table) , 'storage_table', 'simple test of function storage_table -> new()' );

## test for new

