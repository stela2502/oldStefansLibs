#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::organismDB' }

my $organismDB = organismDB -> new();
is_deeply ( ref($organismDB) , 'organismDB', 'simple test of function organismDB -> new()' );

## test for new

