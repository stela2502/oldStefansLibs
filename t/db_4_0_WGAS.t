#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::database::WGAS' }

my ( $value, $exp, @values );
my $WGAS = WGAS->new( root->getDBH() );
$WGAS->create();

is_deeply( $WGAS->Create_rsID_2_SNP_table(&test_RS),
	1, "we might have been able to create a RS_table" );

is_deeply(
	$WGAS->AddDataset(
		{
			'sample' => {
				'extraction_protocol' => {
					'name' => 'DNA extraction',
					'description' =>
					  'TEST - standard DNA extraction protocol - TEST',
					'version'      => '1.0',
					'working_copy' => "just follow the kit description",
					'original_protocol_description' => {
						'file'     => 'Just_a_test_file.txt',
						'filetype' => 'text_document'
					},
					'materialList' => { 'list_id' => 1 }
				},
				'sample_lable' => 'WGAS_test_1',
				'tissue'       => {
					'organism'            => { 'id' => 1 },
					'name'                => 'bone marrow',
					'extraction_protocol' => {
						'name'        => 'my test extraction_protocol',
						'version'     => "1.0",
						'description' => "a test protocol entry",
						'working_copy' =>
"1. get up in the morning\n2. eat breakfast\n3. go to work\n4. go home\n5. eat diner\n6. go to bed\n",
						'original_protocol_description' => {
							'file'     => 'Just_a_test_file.txt',
							'filetype' => 'text_document'
						},
						'materialList' => { 'list_id' => 1 }
					}
				},
				'subject' => {
					'identifier'  => 'test_1',
					'organism_id' => 1,
					'project_id'  => 1
				},
				'storage' => {
					'temperature' => "-20",
					'building'    => "60",
					'floor'       => "3",
					'room'        => '62',
					'description' => 'the fidge on the right side',
					'box_label'   => 'Stefan\'s test samples'
				},
				'initial_amount' => 1,
				'name' => 'WGAS'
			},
			'rsID_2_SNP_table' => 'test_table_rsID_2_SNP',
			'SNP_call_data'    => [ 1, 2 ],
			'study_name' => 'DGI_test'
		}
	),
	1,
	"we have added a dataset"
);

## And now lets see if we can get something from that interface!

my ($interface, $samples) = $WGAS -> GetDatabaseInterface_for_dataset ( { 'study_name' => 'DGI_test'} );
is_deeply( ref($interface), 'rsID_2_SNP', "we get the right interface class");

## check some internals
is_deeply ( ( defined $interface->{'data_handler'}->{'SNP_calls'} ), 1, "the data structure was updated" );

$exp = {
  'SNP_calls.value' => '1',
  'rsID_2_SNP.rsID' => 'rs00001'
};
#print root::get_hashEntries_as_string ($interface, 10, "the interface " , 100);
$value = $interface-> get_data_table_4_search ({
 	'search_columns' => ["rsID_2_SNP.rsID", "SNP_calls.value" ],
 	'where' => [["rsID_2_SNP.rsID", '=' ,'my_value']]
	}, 'rs00001' )->get_line_asHash(0);

is_deeply( $value, $exp ,"we did get the right entry back!");
	
#print "\$exp = ".root->print_perl_var_def($value).";\n";

sub test_sample_data {
	return {};
}

sub test_RS {
	return {
		'rsID_2_SNP_table' => 'test_table',
		'rsID_2_SNP_data'  => [
			{ 'rsID' => 'rs00001', 'minorAllele' => 'A', 'majorAllele' => 'U' },
			{ 'rsID' => 'rs00002', 'minorAllele' => 'T', 'majorAllele' => 'G' }
		]
	};
}


