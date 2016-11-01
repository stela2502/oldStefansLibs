#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo' }

my $Nimblegene_GeneInfo = Nimblegene_GeneInfo -> new();
is_deeply ( ref($Nimblegene_GeneInfo) , 'Nimblegene_GeneInfo', 'simple test of function Nimblegene_GeneInfo -> new()' );

## test for new

