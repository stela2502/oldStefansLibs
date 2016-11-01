#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::scientistTable::PW_table' }

my $PW_table = PW_table -> new();
is_deeply ( ref($PW_table) , 'PW_table', 'simple test of function PW_table -> new()' );

## test for new

