#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::file_readers::SNP_2_gene_expression_reader' }

my $SNP_2_gene_expression_reader = SNP_2_gene_expression_reader -> new();
is_deeply ( ref($SNP_2_gene_expression_reader) , 'SNP_2_gene_expression_reader', 'simple test of function SNP_2_gene_expression_reader -> new()' );

my $datafile = 'data/VAMP8-SNARE_interactions_in_vesicle_transport.txt';
$datafile = 't/data/VAMP8-SNARE_interactions_in_vesicle_transport.txt' if ( -f 't/data/VAMP8-SNARE_interactions_in_vesicle_transport.txt');

my ($value, @values ) = @_;

is_deeply ($SNP_2_gene_expression_reader->read_file( $datafile ), 4, "we can read all entries");
$SNP_2_gene_expression_reader = SNP_2_gene_expression_reader -> new();
is_deeply ($SNP_2_gene_expression_reader->read_file( $datafile,  0.0006), 1, "we can restrict the input");
$SNP_2_gene_expression_reader = SNP_2_gene_expression_reader -> new();
is_deeply ($SNP_2_gene_expression_reader->read_file( $datafile,  0.0001), 0, "and we get nothing if there is nothing");


## test for new

