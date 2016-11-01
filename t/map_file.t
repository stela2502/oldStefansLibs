#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::plink::map_file' }

my $map_file = map_file -> new();
is_deeply ( ref($map_file) , 'map_file', 'simple test of function map_file -> new()' );

## test for new

