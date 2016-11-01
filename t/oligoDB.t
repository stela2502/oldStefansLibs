#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::nucleotide_array::oligoDB' }

my $oligoDB = oligoDB -> new();
is_deeply ( ref($oligoDB) , 'oligoDB', 'simple test of function oligoDB -> new()' );

## test for new

