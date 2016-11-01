#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::creaturesTable' }

my $creaturesTable = creaturesTable -> new( root::getDBH('root',"geneexpress") );
is_deeply ( ref($creaturesTable) , 'creaturesTable', 'simple test of function creaturesTable -> new()' );

## test for new

