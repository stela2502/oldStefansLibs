#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'lib::stefans_libs::database::variable_table::linkage_info::table_script_generator' }

my $table_script_generator = table_script_generator -> new();
is_deeply ( ref($table_script_generator) , 'table_script_generator', 'simple test of function table_script_generator -> new()' );

## test for new

