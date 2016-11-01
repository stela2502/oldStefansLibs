#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::MyProject::PHASE_outfile::LIST_SUMMARY' }

my $LIST_SUMMARY = LIST_SUMMARY -> new();
is_deeply ( ref($LIST_SUMMARY) , 'LIST_SUMMARY', 'simple test of function LIST_SUMMARY -> new()' );

## test for new

