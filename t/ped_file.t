#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::plink::ped_file' }

my $ped_file = ped_file -> new();
is_deeply ( ref($ped_file) , 'ped_file', 'simple test of function ped_file -> new()' );

## test for new

