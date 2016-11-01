#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 7;
BEGIN { use_ok 'stefans_libs::database::genomeDB::genomeImporter::seq_contig' }

my $seq_contig = seq_contig -> new();
is_deeply ( ref($seq_contig) , 'seq_contig', 'simple test of function seq_contig -> new()' );
my ( $value, @values);
## test for new
my $filename = "../t/data/hu_genome/seq_contig.md.gz";
$filename = "t/data/hu_genome/seq_contig.md.gz" if ( -f "t/data/hu_genome/seq_contig.md.gz");
$seq_contig->readFile($filename);

my $refHash_line3 = {
	tax_id => 9606,
	chromosome => 'Y',
	chr_start => 1,
	chr_stop => 3043,
	orientation => '+',
	feature_name => 'NW_927734.1',
	feature_id => '-',
	feature_type => 'CONTIG',
	group_label =>  'Celera',
	weight => 3
};

my $refHash_line4 = {
	tax_id => 9606,
	chromosome => 'Y',
	chr_start => 1,
	chr_stop => 34821,
	orientation => '+',
	feature_name => 'NT_113967.1',
	feature_id => 'CONTIG:111686',
	feature_type => 'CONTIG',
	group_label =>  'reference',
	weight => 1
};

$value = $seq_contig->getPrevious();
is_deeply( $value, undef, "getNext line -1");

$seq_contig->getNext(); ## line 0
$seq_contig->getNext(); ## line 1
$seq_contig->getNext(); ## line 2

$value = $seq_contig->getNext(); ## line 3
is_deeply( $value, $refHash_line3, "getNext line 3");

$value = $seq_contig->getNext(); ## line 4
is_deeply( $value, $refHash_line4, "getNext line 4");

$value = $seq_contig->getPrevious(); ## line 3
is_deeply( $value, $refHash_line3, "getPrevious line 3");

$seq_contig->getNext(); ## line 4
$seq_contig->getNext(); ## line 5
$seq_contig->getNext(); ## line 6
$seq_contig->getNext(); ## line 7
$seq_contig->getNext(); ## line 8
$seq_contig->getNext(); ## line 9 & last!
$value = $seq_contig->getNext(); ## line 2
is_deeply( $value, undef, "getNext line 9 (not existant!)");

