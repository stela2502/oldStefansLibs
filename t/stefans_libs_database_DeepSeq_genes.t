#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::database::DeepSeq::genes' }

my $db = stefans_libs_database_DeepSeq_genes->new(root->getDBH());
my ( $value, @values, $exp );
$db->create();
$db->{'linked_list'} -> create();
$db->{'linked_list'} -> {'data_handler'}->{'otherTable'} ->create();

$value = $db->AddDataset(
	{
		'name'  => 'TCF7L2',
		'organism'   => 'H_Sapiens',
		'type' => 'Gene Symbol'
	}
);

is_deeply( $value, 1, "TCF7L2 got id 1" );

$value = $db->AddDataset(
	{
		'name'  => 'TCF7L2',
		'organism'   => 'H_Sapiens'
	}
);

is_deeply( $value, 1, "get the right ID" );

$value = $db->AddDataset(
	{
		'name'  => 'TCF4',
		'gene_list_id' => 1,
		'organism'   => 'H_Sapiens',
		'type' => 'Gene Symbol'
	}
);

is_deeply( $value, 1, "by setting the 'gene_list_id' I can add to the list" );
$value = $db->get_data_table_4_search ({
 	'search_columns' => ['GENE_IDs.name'],
 	'where' => [[ref($db).'.id','=','my_value']]}, 1 );
#print $db->{'complex_search'};

is_deeply ( $value->getAsArray( 'GENE_IDs.name'), ['TCF7L2','TCF4'], "get all gene names for one gene_id");


$value = $db->get_gene_id_4_gene_name('TCF4');
 	
is_deeply ( $value , 1, "get the gene id for a gene name");
 	