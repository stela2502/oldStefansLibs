#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::hypothesis_table' }

my $hypothesis_table = hypothesis_table -> new();
is_deeply ( ref($hypothesis_table) , 'hypothesis_table', 'simple test of function hypothesis_table -> new()' );

## test for new

