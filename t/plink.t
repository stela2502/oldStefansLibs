#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;
use stefans_libs::database::WGAS;
BEGIN { use_ok 'stefans_libs::file_readers::plink' }

my ( $bim_file, $ped_file, $value, $exp, @values );
if ( -d 'data' ) {
	$bim_file = "data/test.bim";
	$ped_file = "data/test.ped";
}
if ( -d 't/data' ) {
	$bim_file = "t/data/test.bim";
	$ped_file = "t/data/test.ped";
}
die "Sorry, but we could not find our datafiles\n" unless ( -f $bim_file );

my $plink = plink->new();
is_deeply( ref($plink), 'plink', 'simple test of function plink -> new()' );

## test for new
my $WGAS = WGAS->new( root->getDBH() );
is_deeply( ref($WGAS), "WGAS", "WGAS new" );
$WGAS->create();
my $rsID_2_SNP_table = $WGAS->store_bim_file( $bim_file, "DGI" );
is_deeply( ref($rsID_2_SNP_table), 'rsID_2_SNP', 'rsID_2_SNP new' );

$value = $rsID_2_SNP_table->get_data_table_4_search(
	{
		'search_columns' => [ 'id', 'rsID', 'majorAllele', 'minorAllele' ],
		'where' => [ [ 'rsID', '=', 'my_value' ] ]
	},
	[ 'rs3094315', 'rs2980300' ]
)->print();

$exp = '#id	rsID	majorAllele	minorAllele
4	rs2980300	T	C
1	rs3094315	G	A
';
is_deeply( $value, $exp, "we can get the values back" );

$WGAS->store_ped_file(
	{
		'WGAS_name'  => "DGI",
		'ped_file'   => $ped_file,
		'rsID_2_SNP' => $rsID_2_SNP_table
	}
);
my $samples;
($rsID_2_SNP_table, $samples) =
  $WGAS->GetDatabaseInterface_for_dataset( { 'study_name' => 'DGI' } );
is_deeply( ref($rsID_2_SNP_table), 'rsID_2_SNP',
	'GetDatabaseInterface_for_dataset' );
is_deeply( $rsID_2_SNP_table->TableName(),
	'DGI_rsID_2_SNP', 'right initial table name' );
$rsID_2_SNP_table->Organism_name('hu_genome');
$value = $rsID_2_SNP_table->get_data_table_4_search(
	{
		'search_columns' => [ 'rsID', 'value' ],
		'where'          => []
	}
);

$exp = '#DGI_rsID_2_SNP.rsID	DGI_2.value	DGI_3.value	DGI_4.value	DGI_5.value
rs3094315	2	1	2	1
rs6672353	2	1	2	2
rs4040617	2	1	2	1
rs2980300	2	1	2	0
';
is_deeply( $value->print(), $exp, 'data looks good' );

$value = $rsID_2_SNP_table->get_data_table_4_search(
	{
		'search_columns' => [ 'rsID', 'value' ],
		'where' => [ [ 'rsID', '=', 'my_value' ] ]
	},
	[ 'rs3094315', 'rs2980300' ]
);

$exp = '#DGI_rsID_2_SNP.rsID	DGI_2.value	DGI_3.value	DGI_4.value	DGI_5.value
rs2980300	2	1	2	0
rs3094315	2	1	2	1
';
is_deeply( $value->print(), $exp, 'data looks good 2' );

$value = $rsID_2_SNP_table->__get_SNP_dataset( [ 'rs2980300', 'rs3094315' ] );

#    rs3094315   rs2980300
#8   A A ok       C C ok
#24  G A ok       T C ok
#28  A A ok       C C ok
#42  G A ok       T C ok
#id	rsID	majorAllele	minorAllele
#4	rs2980300	T	C
#1	rs3094315	G	A

$exp = {
	'info' => {},
	'data' => {
		'42' => {
			'rs3094315' => {
				'AlleleB' => 'A',
				'AlleleA' => 'G'
			},
			'rs2980300' => {
				'AlleleB' => 'T',
				'AlleleA' => 'T'
			}
		},
		'8' => {
			'rs3094315' => {
				'AlleleB' => 'A',
				'AlleleA' => 'A'
			},
			'rs2980300' => {
				'AlleleB' => 'C',
				'AlleleA' => 'C'
			}
		},
		'28' => {
			'rs3094315' => {
				'AlleleB' => 'A',
				'AlleleA' => 'A'
			},
			'rs2980300' => {
				'AlleleB' => 'C',
				'AlleleA' => 'C'
			}
		},
		'24' => {
			'rs3094315' => {
				'AlleleB' => 'A',
				'AlleleA' => 'G'
			},
			'rs2980300' => {
				'AlleleB' => 'C',
				'AlleleA' => 'T'
			}
		}
	}
};
is_deeply( $value, $exp, '__get_SNP_dataset');

## now lets see if I can create a PHASE input file!
$exp->{'info'} = {'rs3094315' => { 'position' => 1000, 'Chr' => 1}, 'rs2980300' => { 'position' => 2300, 'Chr' => 1}};

($value, $samples) = $rsID_2_SNP_table->__convert_dataset_2_PHASE_string ( $exp );
$exp = "4\n2\nP 1000 2300\nSS\n#8\nA C\nA C\n#42\nG T\nA T\n#28\nA C\nA C\n#24\nG T\nA C\n";

is_deeply( $value, $exp, '__convert_dataset_2_PHASE_string');

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";
