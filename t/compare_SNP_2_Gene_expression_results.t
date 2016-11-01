#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::MyProject::compare_SNP_2_Gene_expression_results' }

my $compare_SNP_2_Gene_expression_results = compare_SNP_2_Gene_expression_results -> new();
is_deeply ( ref($compare_SNP_2_Gene_expression_results) , 'compare_SNP_2_Gene_expression_results', 'simple test of function compare_SNP_2_Gene_expression_results -> new()' );

## test for new

