#! /usr/bin/perl

use strict;
use warnings;

use stefans_libs::database::scientistTable;

my $word = $ARGV[0];

print scientistTable->encrypt ( $word ) ."\n"; 
