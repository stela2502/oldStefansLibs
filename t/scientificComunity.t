#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::scientistTable::scientificComunity' }

my $scientificComunity = scientificComunity -> new();
is_deeply ( ref($scientificComunity) , 'scientificComunity', 'simple test of function scientificComunity -> new()' );

## test for new

