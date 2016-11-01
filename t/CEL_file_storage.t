#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok '::home::stefan_l::Link_2_My_Libs::lib::stefans_libs::database::expression_estimate::CEL_file_storage' }

my $CEL_file_storage = CEL_file_storage -> new();
is_deeply ( ref($CEL_file_storage) , 'CEL_file_storage', 'simple test of function CEL_file_storage -> new()' );

## test for new

