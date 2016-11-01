#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
BEGIN { use_ok 'stefans_libs::database::Protein_Expression' }

my ( $value, @values, $exp, $data_table );

my $stefans_libs_database_Protein_Expression =
  stefans_libs_database_Protein_Expression->new( root->getDBH() );
is_deeply(
	ref($stefans_libs_database_Protein_Expression),
	'stefans_libs_database_Protein_Expression',
	'simple test of function stefans_libs_database_Protein_Expression -> new()'
);
$stefans_libs_database_Protein_Expression->create();
$data_table = &get_data_table();

## now I expect the database object to be able to utilize this data table.
my $ENS_2_GS = data_table->new();
$ENS_2_GS->Add_header_Array( [ 'GeneSymbol', 'ENSEMBL_ID' ] );
$ENS_2_GS->AddDataset(
	{ 'ENSEMBL_ID' => 'ENSG00000000003', 'GeneSymbol' => 'pure_crap' } );
$stefans_libs_database_Protein_Expression->process_ENSEMBLE_ID_2_GeneSymbols(
	$ENS_2_GS);
is_deeply(
	$stefans_libs_database_Protein_Expression->{'data_handler'}
	  ->{'stefans_libs_database_Protein_Expression_gene_ids'}
	  ->get_data_table_4_search(
		{
			'search_columns' => [ 'id', 'GeneSymbol', 'ENSEMBL_ID' ],
			'where' => [ [ 'ENSEMBL_ID', '=', 'my_value' ] ]
		},
		'ENSG00000000003'
	  )->get_line_asHash(0),
	{
		'id'         => 1,
		'ENSEMBL_ID' => 'ENSG00000000003',
		'GeneSymbol' => 'pure_crap'
	},
	'we can add an ENSEMBL_id 2 Gene Symblo entry.'
);

$ENS_2_GS = data_table->new();
$ENS_2_GS->Add_header_Array( [ 'GeneSymbol', 'ENSEMBL_ID' ] );
$ENS_2_GS->AddDataset(
	{ 'ENSEMBL_ID' => 'ENSG00000000003', 'GeneSymbol' => 'TSPAN6' } );
$stefans_libs_database_Protein_Expression->process_ENSEMBLE_ID_2_GeneSymbols(
	$ENS_2_GS);
is_deeply(
	$stefans_libs_database_Protein_Expression->{'data_handler'}
	  ->{'stefans_libs_database_Protein_Expression_gene_ids'}
	  ->get_data_table_4_search(
		{
			'search_columns' => [ 'id', 'GeneSymbol', 'ENSEMBL_ID' ],
			'where' => [ [ 'ENSEMBL_ID', '=', 'my_value' ] ]
		},
		'ENSG00000000003'
	  )->get_line_asHash(0),
	{ 'id' => 1, 'ENSEMBL_ID' => 'ENSG00000000003', 'GeneSymbol' => 'TSPAN6' },
	'we can update an ENSEMBL_id 2 Gene Symblo entry.'
);

$stefans_libs_database_Protein_Expression->Add_Human_Protein_Atlas_Data(
	$data_table);

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

$value = $stefans_libs_database_Protein_Expression->get_data_table_4_search(
	{
		'search_columns' => [ 'exp_level', 'tissue.name' ],
		'where' => [ [ 'reliability', '=', 'my_value' ] ],
	},
	'Supportive'
)->AsString;
$exp = '#exp_level	tissue.name
0	adrenal gland - glandular cells
2	appendix - glandular cells
0	appendix - lymphoid tissue
0	bone marrow - hematopoietic cells
3	breast - glandular cells
3	bronchus - respiratory epithelial cells
0	cerebellum - cells in granular layer
0	cerebellum - cells in molecular layer
0	cerebellum - Purkinje cells
';

is_deeply( $value, $exp, "Data is accessible" );

$value =
  $stefans_libs_database_Protein_Expression
  ->expression_difference_between_2_cell_types_4_genes(
	{
		'cell_1' => 'appendix - glandular cells',
		'cell_2' => 'appendix - lymphoid tissue',
		'genes'  => 'TSPAN6'
	}
  );

is_deeply(
	$value->AsString(),
	'# A=appendix - glandular cells; B= appendix - lymphoid tissue
#Gene Symbol	difference A vs B	numeric
TSPAN6	>	1
', 'A more than B'
);

$value =
  $stefans_libs_database_Protein_Expression
  ->expression_difference_between_2_cell_types_4_genes(
	{
		'cell_2' => 'appendix - glandular cells',
		'cell_1' => 'appendix - lymphoid tissue',
		'genes'  => 'TSPAN6'
	}
  );

is_deeply(
	$value->AsString(),
	'# A=appendix - lymphoid tissue; B= appendix - glandular cells
#Gene Symbol	difference A vs B	numeric
TSPAN6	<	-1
', 'A less than B'
);

$value =
  $stefans_libs_database_Protein_Expression
  ->expression_difference_between_2_cell_types_4_genes(
	{
		'cell_1' => 'cerebellum - cells in granular layer',
		'cell_2' => 'cerebellum - cells in molecular layer',
		'genes'  => 'TSPAN6'
	}
  );

is_deeply(
	$value->AsString(),
	'# A=cerebellum - cells in granular layer; B= cerebellum - cells in molecular layer
#Gene Symbol	difference A vs B	numeric
TSPAN6	=	0
', 'A equals B'
);

$value =
  $stefans_libs_database_Protein_Expression
  ->expression_difference_between_2_cell_types(
	{
		'cell_1' => 'cerebellum - cells in granular layer',
		'cell_2' => 'cerebellum - cells in molecular layer',
		'genes'  => 'TSPAN6'
	}
  );

is_deeply(
	$value->AsString(),
	'# A=cerebellum - cells in granular layer; B= cerebellum - cells in molecular layer
#Gene Symbol	ENSEMBL_ID	difference A vs B	numeric
TSPAN6	ENSG00000000003	=	0
', 'A equals B all genes'
);

#print "\$value = '" . $value->AsString() . "';\n";

sub get_data_table {
	my $data_table = data_table->new();
	$data_table->parse_from_string(
		"Ensembl_ID	Tissue	Cell type	Level	Expression type	Reliability
ENSG00000000003	adrenal gland	glandular cells	Negative	Staining	Supportive
ENSG00000000003	appendix	glandular cells	Moderate	Staining	Supportive
ENSG00000000003	appendix	lymphoid tissue	Negative	Staining	Supportive
ENSG00000000003	bone marrow	hematopoietic cells	Negative	Staining	Supportive
ENSG00000000003	breast	glandular cells	Strong	Staining	Supportive
ENSG00000000003	bronchus	respiratory epithelial cells	Strong	Staining	Supportive
ENSG00000000003	cerebellum	cells in granular layer	Negative	Staining	Supportive
ENSG00000000003	cerebellum	cells in molecular layer	Negative	Staining	Supportive
ENSG00000000003	cerebellum	Purkinje cells	Negative	Staining	Supportive"
	);
	$data_table->line_separator(";;");
	return $data_table;
}
