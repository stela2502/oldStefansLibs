#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::sampleTable' }

my $sampleTable = sampleTable -> new();
is_deeply ( ref($sampleTable) , 'sampleTable', 'simple test of function sampleTable -> new()' );

## test for new

