#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::variable_table::queryInterface' }

my $queryInterface = queryInterface -> new();
is_deeply ( ref($queryInterface) , 'queryInterface', 'simple test of function queryInterface -> new()' );

## test for new

