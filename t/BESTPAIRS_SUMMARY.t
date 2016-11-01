#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::MyProject::PHASE_outfile::BESTPAIRS_SUMMARY' }

my $BESTPAIRS_SUMMARY = BESTPAIRS_SUMMARY -> new();
is_deeply ( ref($BESTPAIRS_SUMMARY) , 'BESTPAIRS_SUMMARY', 'simple test of function BESTPAIRS_SUMMARY -> new()' );

## test for new

