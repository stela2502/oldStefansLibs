#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::personTable' }

my $personTable = peopleDB -> new();
is_deeply ( ref($personTable) , 'peopleDB', 'simple test of function peopleDB -> new()' );

## test for new

