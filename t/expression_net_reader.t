#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::file_readers::expression_net_reader' }

my $expression_net_reader = expression_net_reader->new();

## I want to check the __get_gene_symbol function

is_deeply(['PGD', 1], [$expression_net_reader->__get_gene_symbol('7897620_PGD', '8031992_tcag7.907')], "OK __get_gene_symbol 1");
is_deeply(['tcag7.907',1], [$expression_net_reader->__get_gene_symbol('8031992_tcag7.907', '7897620_PGD')], "OK __get_gene_symbol 1");
