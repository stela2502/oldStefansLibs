#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::lists::list_using_table' }

my $list_using_table = list_using_table -> new();
is_deeply ( ref($list_using_table) , 'list_using_table', 'simple test of function list_using_table -> new()' );

## test for new

