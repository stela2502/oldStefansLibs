#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 22;
use FindBin;
my $plugin_path = "$FindBin::Bin";

BEGIN { use_ok 'stefans_libs::file_readers::MeDIP_results' }

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs_file_readers_MeDIP_results->new();
is_deeply( ref($test_object), 'stefans_libs_file_readers_MeDIP_results',
	'simple test of function stefans_libs_file_readers_MeDIP_results -> new()'
);

$value = $test_object->AddDataset(
	{
		'Oligo_id'          => 0,
		'p value'           => 1,
		'meanA'             => 2,
		'meanB'             => 3,
		'fold_change [A/B]' => 4,
	}
);
is_deeply( $value, 1, "we could add a sample dataset" );

my ( $file, $path );
$path = $plugin_path . "/data";
$path = "t/$path" unless ( -d $path );
$file = "$path/small_FH_p_before_ex_vs_after_ex.xls";

die
"Sorry I could not find the test data file small_FH_p_before_ex_vs_after_ex.xls"
  unless ( -f $file );

$test_object = stefans_libs_file_readers_MeDIP_results->new();
$test_object->read_file($file);
$test_object->{'debug'} = 1;
is_deeply( scalar( @{ $test_object->{'data'} } ), 4999, "read the data" );

is_deeply(
	$test_object->get_line_asHash(0),
	{
		'Oligo_id'          => 'CHR10FS114700200',
		'p value'           => 0.173860382064085,
		'meanA'             => 0.00888395062184651,
		'meanB'             => 0.0519002085023254,
		'fold_change [A/B]' => 0.171173698106597
	},
	'got the right data'
);

#print "\$exp = ".root->print_perl_var_def(  $test_object->Samples_GroupA() ).";\n";
$exp = [
	'34885_1', '34893_1', '34894_1', '34895_1', '34896_1', '34898_1',
	'34900_1', '34906_1', '34910_1', '34912_1', '34919_1', '34901_1',
	'34927_1', '34928_1', '34932_1'
];
is_deeply( $test_object->Samples_GroupA(), $exp, 'samples group A' );

#print "\$exp = ".root->print_perl_var_def(  $test_object->Samples_GroupB() ).";\n";
$exp = [
	'34885_2', '34893_2', '34894_2', '34895_2', '34896_2', '34898_2',
	'34900_2', '34906_2', '34910_2', '34912_2', '34919_2', '34901_2',
	'34927_2', '34928_2', '34932_2'
];
is_deeply( $test_object->Samples_GroupB(),$exp , 'samples group B' );

$test_object->Add_Olig_Infos( $path . "/smal_nimble_gene_ndf_file.ndf" );

#is_deeply ( $test_object->get_line_asHash(1)->{'seq'}, '', 'No seq for an not existing oligo');
$value = $test_object->get_line_asHash(2);

#print "\$exp = ".root->print_perl_var_def( $value ) .";\n";

$exp = {
	'p value' => '0.0744816418225699',

	#  'location' => '1442..1492',
	'CpG content [n]' => '2',

	#  'chr' => 'chr1',
	#  'end' => '923891',
	'meanA'             => '0.282489270756739',
	'fold_change [A/B]' => '0.66666369030763',
	'Oligo_id'          => 'CHR01FS000923841',
	'meanB'             => '0.423735797919915',
	'seq'               => 'TTCCAGCACCGGGAAGATTCTGGGCACTCAGGGACGTTGAGCTTCCCACC',

	#  'Gene Symbol' => 'HES4',
	#  'start' => '923841'
};

is_deeply( $value, $exp, 'I got the right oligo info added' );

$test_object->parse_oligo_id_2_position();

is_deeply(
	$test_object->get_line_asHash(0),
	{
		'Oligo_id'          => 'CHR10FS114700200',
		'seq'               => 'GTCACGTAACCCTAGGGAAGAGTAAACCTCAATAGTTAAAACAG',
		'CpG content [n]'   => '1',
		'p value'           => 0.173860382064085,
		'meanA'             => 0.00888395062184651,
		'meanB'             => 0.0519002085023254,
		'fold_change [A/B]' => 0.171173698106597,
		'chr'               => 'chr10',
		'start'             => 114700200,
		'end'               => ( 114700200 + 44 )
	},
	'oligo was parsed into position'
);

## now I need to add the gene information!
$test_object->Add_Genes_Using_this_GFF( $path . "/test_array_description.gff" );
$value = $test_object->getAsArray('Gene Symbol');
is_deeply( scalar(@$value),        4999, "All oligos got a gene name" );
is_deeply( &has_undefined($value), 0,    "all gene names werde defined" );
is_deeply( $test_object->get_line_asHash(0)->{'Gene Symbol'},
	'TCF7L2', "the first oligo was matched as expected" );
is_deeply( $test_object->get_line_asHash(0)->{'location'},
	'0..44', "the first got the right location" );
is_deeply( $test_object->get_line_asHash(1)->{'Gene Symbol'},
	'SMG5', "the second oligo was matched as expected" );
is_deeply( $test_object->get_line_asHash(1)->{'location'},
	'-50..0', "the second got the right location" );

## OH I also need the 'old' oligo sequence!

is_deeply( scalar( @{ $test_object->{'data'} } ),
	4999, "we have not lost any data" );
$test_object = $test_object -> restrict_to_p_value ( 0.05 );
is_deeply( scalar( @{ $test_object->{'data'} } ),
	158, "can select based on the p_value" );

## OK and now I need to add the expression data

$test_object->Add_GeneExpression_File ( $path."/rma_expression.txt", 'rma');

is_deeply( scalar( @{ $test_object->{'data'} } ),
	160, "no adding of lines to add the gene expression apart from additional probesets" );
#print "\$exp = ".root->print_perl_var_def( $test_object ->get_line_asHash(0) ).";\n";
$exp = {
  'rma std expression A' => '14.3600573415495',
  'rma expression p value' => '0.945',
  'CpG content [n]' => '1',
  'rma mean expression A' => '98.4235402005428',
  'rma difference A-B' => '-4.84237947066195',
  'meanA' => '0.212069658513915',
  'fold_change [A/B]' => '-0.566644109802974',
  'Oligo_id' => 'CHR01FS002152727',
  'Gene Symbol' => 'SKI',
  'seq' => 'GCCCATTGGAGTGGCCAGTGGGGCCTCGTTGTCACAGCTGACACAGAGCA',
  'p value' => '2.30697693207631',
  'location' => '2734..2784',
  'chr' => 'chr1',
  'rma std expression B' => '26.0252961415021',
  'end' => '2152777',
  'meanB' => '-0.374255471547482',
  'rma mean expression B' => '103.265919671205',
  'start' => '2152727'
};
is_deeply ($test_object ->get_line_asHash(0), $exp, "the expression was added as expected" );

$test_object -> Check_MeDIP_Hypothesis ();

$value = $test_object -> get_best_oligo_per_gene ();
is_deeply(scalar ( @{$value->{'data'}}), 62 ,"right number of genes");

$value = $test_object -> get_all_supportive_oligos ();

$value->write_file( '/home/stefan_l/test_MeDIP_Analysis_supp_oligos.xls');
$test_object ->write_file ( '/home/stefan_l/test_MeDIP_Analysis_all.xls');

my $test_object_2 = stefans_libs_file_readers_MeDIP_results->new();

$test_object_2->read_file('/home/stefan_l/test_MeDIP_Analysis_all.xls');

my $value_2 = $test_object_2-> get_all_supportive_oligos ();

is_deeply ( $value->{'data'}, $value_2->{'data'}, 're-selecting supportive oligos from a partial result OK');

$value = $test_object -> get_best_oligo_per_gene ();
$value_2 = $test_object_2-> get_best_oligo_per_gene ();
is_deeply ( $value->{'data'}, $value_2->{'data'}, 're-selecting best oligo per gene from a partial result OK');



#print "\$exp = ".root->print_perl_var_def( $test_object ->get_line_asHash(0) ).";\n";
## A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def( $test_object ->getAsArray( 'Gene Symbol') ).";\n";

sub has_undefined {
	my $array_ref = @_;
	return 0 unless ( ref($array_ref) eq "ARRAY" );
	foreach (@$array_ref) {
		return 1 unless ( defined $_ );
		return 1 if ( $_ eq "" );
	}
	return 0;
}

