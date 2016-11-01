#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::genomeDB::genomeSearchResult' }

my $genomeSearchResult = genomeSearchResult -> new();
is_deeply ( ref($genomeSearchResult) , 'genomeSearchResult', 'simple test of function genomeSearchResult -> new()' );

## test for new

