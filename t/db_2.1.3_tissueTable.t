#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::tissueTable' }

my $tissueTable = tissueTable -> new(root::getDBH( 'root', "geneexpress" ));
is_deeply ( ref($tissueTable) , 'tissueTable', 'simple test of function tissueTable -> new()' );

$tissueTable -> create();

## we first need a protocol table entry!

$tissueTable -> AddDataset ( {
	
});
