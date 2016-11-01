#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok '::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::database::LabBook::ChapterStructure' }

my $ChapterStructure = ChapterStructure -> new();
is_deeply ( ref($ChapterStructure) , 'ChapterStructure', 'simple test of function ChapterStructure -> new()' );

## test for new

