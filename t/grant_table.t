#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::grant_table' }

my $grant_table = grant_table -> new();
is_deeply ( ref($grant_table) , 'grant_table', 'simple test of function grant_table -> new()' );

## test for new

