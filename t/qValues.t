#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok '::home::stefan_l::Link_2_My_Libs::lib::stefans_libs::array_analysis::correlatingData::qValues' }

my $qValues = qValues -> new();
is_deeply ( ref($qValues) , 'qValues', 'simple test of function qValues -> new()' );

## test for new

