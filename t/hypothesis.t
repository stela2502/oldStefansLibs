#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::experiment::hypothesis' }

my $hypothesis = hypothesis -> new();
is_deeply ( ref($hypothesis) , 'hypothesis', 'simple test of function hypothesis -> new()' );

## test for new

