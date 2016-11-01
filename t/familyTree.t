#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::creaturesTable::familyTree' }

my $familyTree = familyTree -> new();
is_deeply ( ref($familyTree) , 'familyTree', 'simple test of function familyTree -> new()' );

## test for new

