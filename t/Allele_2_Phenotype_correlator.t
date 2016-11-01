#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use stefans_libs::MyProject::PHASE_outfile;
BEGIN { use_ok 'stefans_libs::MyProject::Allele_2_Phenotype_correlator' }

my ( $datafile, $datafile2, $value, $exp, @values );

$datafile  = "/home/stefan_l/Link_2_My_Libs/t/data/phenotype_file.txt";
$datafile2 = "/home/stefan_l/Link_2_My_Libs/t/data/PHASE_outfile.txt";

my $Allele_2_Phenotype_correlator = Allele_2_Phenotype_correlator->new();
is_deeply(
	ref($Allele_2_Phenotype_correlator),
	'Allele_2_Phenotype_correlator',
	'simple test of function Allele_2_Phenotype_correlator -> new()'
);

$Allele_2_Phenotype_correlator->read_file($datafile);

my $PHASE_outfile = PHASE_outfile->new();
$PHASE_outfile->read_file($datafile2);

my @array =
  $Allele_2_Phenotype_correlator->__get_sample_id_groups(
	$PHASE_outfile->get_sample_id_groups('recessive') );
$exp = [
	[
		'-9', '-2.091356', '-9',       '0.581846',
		'-9', '-9',        '-9',       '-9',
		'-9', '0.577148',  '0.589178', '-9',
		'-9', '0.179953',  '-9',       '-0.409038',
		'-9', '-9',        '-9',       '-9',
		'-9', '-9',        '-9',       '-9',
		'-9', '-9',        '-9',       '-9',
		'-9', '-9'
	],
	[ '-9', '0.224670', '-9', '-9' ],
	[
		'-9',        '-9',        '-9',        '1.874594',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-9',        '-9',        '0.351343',
		'-0.423441', '-9',        '0.044912',  '-9',
		'-1.319290', '-9',        '-9',        '0.391164',
		'-0.154597', '-9',        '-0.824937', '-0.922635',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-0.260599', '-9',        '-9',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-9',        '-9',        '-9',
		'3.095310',  '-9',        '-9',        '1.298865',
		'-9',        '-9',        '-9',        '-9',
		'-0.353466', '-9',        '-9',        '-9',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-9',        '-9',        '-9',
		'-9',        '-0.171857', '-9',        '-0.373714',
		'-9',        '-9',        '1.094321',  '-9',
		'-9',        '0.064568',  '-9',        '-9',
		'0.490690',  '-9',        '-9',        '-9'
	],
	[ '-9', '-9', '-0.764434', '-9' ]
];
is_deeply( \@array, $exp, "__get_sample_id_groups" );

$exp = {
	'combination' => '0.759	6.6385	10',
	'dominant'    => '0.5481	5.9288	7',
	'recessive'   => '0.995	0.0713	3'
};
is_deeply ( $Allele_2_Phenotype_correlator->create_plots( "/home/stefan_l/temp/"),1, "creat_plots");
@values =
  $Allele_2_Phenotype_correlator->calculate_4_grouping_hash($PHASE_outfile);
is_deeply( $values[0], $exp, "we got the right results for the statistcs" );
$Allele_2_Phenotype_correlator->plot();

my $data_table = $Allele_2_Phenotype_correlator->getChi_square_table();
is_deeply( ref($data_table), "data_table", "get a data table") ;

#print "\$exp = ".root->print_perl_var_def( \@array ).";\n";
