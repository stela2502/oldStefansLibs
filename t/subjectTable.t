#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::subjectTable' }

my $subjectTable = subjectTable -> new();
is_deeply ( ref($subjectTable) , 'subjectTable', 'simple test of function subjectTable -> new()' );

## test for new

