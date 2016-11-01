#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok 'stefans_libs::file_readers::stat_results' }
my ( $value, @values, $exp, $test_obj );

my $stat_results = stat_results->new();
is_deeply( ref($stat_results), 'stat_results',
	'simple test of function stat_results -> new()' );

my $test_file = 't/data/KruskalWallisTest_result.txt';
$test_file = 'data/KruskalWallisTest_result.txt' unless ( -f $test_file );
Carp::confess("Oops - I could not find the test data file #1 -> $test_file")
  unless ( -f $test_file );

$test_obj = $stat_results->read_file($test_file);
is_deeply( ref($test_obj),
	"stefansibs::file_readers::stat_results::KruskalWallisTest_result",
	"KruskalWallisTest_result" );
$exp = [
	{
		'samples' => [
			'ISL0004', 'ISL0006', 'ISL0007', 'ISL0008', 'ISL0010', 'ISL0014',
			'ISL0019', 'ISL0020', 'ISL0023', 'ISL0027', 'ISL0028', 'ISL0030',
			'ISL0032', 'ISL0033', 'ISL0034', 'ISL0036', 'ISL0040', 'ISL0042',
			'ISL0044', 'ISL0046', 'ISL0047', 'ISL0049', 'ISL0052', 'ISL0053',
			'ISL0056', 'ISL0059', 'ISL0064', 'ISL0065', 'ISL0066'
		],
		'tag' => 'AG'
	},
	{
		'samples' => [
			'ISL0003', 'ISL0009', 'ISL0015', 'ISL0022', 'ISL0026', 'ISL0043',
			'ISL0055', 'ISL0058', 'ISL0062'
		],
		'tag' => 'AA'
	},
	{
		'samples' => [
			'ISL0001', 'ISL0002', 'ISL0011', 'ISL0012', 'ISL0013', 'ISL0016',
			'ISL0021', 'ISL0024', 'ISL0025', 'ISL0029', 'ISL0031', 'ISL0035',
			'ISL0037', 'ISL0038', 'ISL0039', 'ISL0041', 'ISL0045', 'ISL0048',
			'ISL0050', 'ISL0051', 'ISL0054', 'ISL0057', 'ISL0063'
		],
		'tag' => 'GG'
	}
];

is_deeply( $test_obj->{'sample_ids'}, $exp, "samples were grouped" );

@values = $test_obj->plot("/home/stefan/temp/simply_removeable/");
$exp    = [
	[
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_8023710_CDH19.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_8173148_FAM104B.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_8017867_FAM20A.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7918913_IGSF3.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_8138145_LOC441453.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7954012_LOH12CR1.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7939942_OR5D14.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7904433_PHGDH.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7976826_SNORD114-26.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7980438_SPTLC2.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_8120004_TMEM151B.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_8005839_TMEM97.svg',
		'/home/stefan/temp/simply_removeable//KruskalWallisTest_result_7918936_VTCN1.svg'
	]
];

is_deeply( [@values], $exp, "plot" );
foreach ( @{ $values[0] } ) {
	#unlink($_);
}

$test_obj = stefans_libs_file_readers_stat_results_base_class->new();
$test_obj -> Add_2_Header ( 'Gene Symbol' );

use stefans_libs::Latex_Document;
my $LaTeX_doc = stefans_libs::Latex_Document -> new();
my @genes = qw(ATP5B ATP5G3 NDUFA8 NDUFA9 NDUFS3 NDUFS5 OR10Q1 OR4P4 OR51B5 OR52N4 OR56B4 OR5B21 OR5M1 OR6C68 OR8H3 POLR2B TBPL1 UQCRC2 VDAC3);
foreach ( @genes ) {
	$test_obj -> AddDataset ( { 'Gene Symbol' => $_ } );
}

my @huntigton = qw(ATP5B ATP5G3 VDAC3 NDUFA8 NDUFA9 NDUFS3 NDUFS5 TBPL1 UQCRC2 POLR2B );
my $huntigton ; 
foreach (@huntigton ){
	$huntigton->{$_} = 1;
}
my @Olfactory_transduction = qw( OR10Q1 OR4P4 OR51B5 OR52N4 OR56B4 OR5B21 OR5M1 OR6C68 OR8H3 );
my $Olfactory_transduction;
foreach ( @Olfactory_transduction ){
	$Olfactory_transduction -> {$_} = 1;
}

$LaTeX_doc -> Section ( "Test Analysis") -> AddText ( 'We are going to analyze the genes '.join(", ", @genes ));

$value = $test_obj->Add_KEGG_Pathway_for_settings(
			{
				'LaTeX_obj' => $LaTeX_doc -> Section ( "Test Analysis")->Section('All'),
				'phenotype'       => "Just a test",
				'exclusionists' => {
					'huntigton'  => $Olfactory_transduction,
					'Olfactory_transduction' => $huntigton,
				},
				'outpath' => "/home/stefan/temp/simply_removable/"
				  . "/add_geneist_"
				  . join( "_", split( /\s/,  "Just a test" ) ) . "/",
				'min_genes'              => 5,
				'kegg_reference_geneset' => 'HUGene_v1'
			}
		);

$exp = $value->{'all'}->AsString();
is_deeply ( 1, $exp =~ m/Huntington s disease/, "all matches to Huntington s disease");
is_deeply ( 1, $exp =~ m/Olfactory transduction/, "all matches to Olfactory transduction");

$exp = $value->{'huntigton'}->AsString();
is_deeply ( 1, $exp =~ m/Huntington s disease/, "huntigton matches to Huntington s disease");
is_deeply ( 1, !($exp =~ m/Olfactory transduction/), "huntigton does NOT match to Olfactory transduction");

$exp = $value->{'Olfactory_transduction'}->AsString();
is_deeply ( 1, ! ($exp =~ m/Huntington s disease/), "Olfactory_transduction does NOT match to Huntington s disease");
is_deeply ( 1, $exp =~ m/Olfactory transduction/, "Olfactory_transduction matches to Olfactory transduction");


#print root::get_hashEntries_as_string ($value, 5, "The result values");
#print "\$exp = " . root->print_perl_var_def($value) . ";\n";
