#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::project_table' }

my $project_table = project_table -> new();
is_deeply ( ref($project_table) , 'project_table', 'simple test of function project_table -> new()' );

## test for new

