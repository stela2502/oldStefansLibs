#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use stefans_libs::database::nucleotide_array;
BEGIN { use_ok 'stefans_libs::database::array_dataset' }

my $dataset = array_dataset->new( "geneexpress", 0 );
is_deeply( ref($dataset), 'array_dataset',
	'simple test of function dataset -> new()' );
my ( $value, @values );
## test for new

## this class is used to handle LARGE datasets, e.g. array results.
## at the moment, only array results are in the pipeline

$value = $dataset->create();

is_deeply( $value, 1, 'create');

my ( $INPUT, $IP, $INPUT_2, $IP_2 );

$INPUT = 'data/GSM304524_145252_532.pair.zip';
$INPUT_2 = 'data/GSM304524_145252_532_2.pair.zip';
if ( -f 't/data/GSM304524_145252_532.pair.zip' ){
	$INPUT = 't/data/GSM304524_145252_532.pair.zip';
	$INPUT_2 = 't/data/GSM304524_145252_532_2.pair.zip';
}

$IP = 'data/GSM304524_145252_635.pair.zip';
$IP_2 = 'data/GSM304524_145252_635_2.pair.zip';
if ( -f 't/data/GSM304524_145252_635.pair.zip' ){
	$IP = 't/data/GSM304524_145252_635.pair.zip';
	$IP_2 = 't/data/GSM304524_145252_635_2.pair.zip';
}



$value = $dataset->AddDataset(
	{
		'task'         => 'add nimblegene Chip on chip data',
		'access_right' => 'scientist',
		'scientist'    => {
			'name'      => 'Stefan Lang',
			'username' => 'med_sal',
			'position'  => 'postdoc',
			'workgroup' => 'Leif Groop',
			'email'     => 'Stefan.Lang@med.lu.se'
		},
		'sample' => {
			'name'         => 'some additional tag',
			'tissue' => {
				'organism'            => { 'id' => 1 },
				'name'         => 'bone marrow',
				'extraction_protocol' => {
					'name'        => 'my test extraction_protocol',
					'version'     => "1.0",
					'description' => "a test protocol entry",
					'working_copy' =>
"1. get up in the morning\n2. eat breakfast\n3. go to work\n4. go home\n5. eat diner\n6. go to bed\n",
					'original_protocol_description' => {
						'file' => 'Just_a_test_file.txt',
						'filetype' => 'text_document'
					},
					'materialList' => { 'list_id' => 1}
				}
			},
			'subject' => {
				'identifier' => 'cryptic_0021',
				'organism'   => { 'organism_tag' => 'hu_genome' },
				'project_id'  => 1
			  },
			'storage' => {
				'temperature' => "-20",
				'building' => "60",
				'floor' => "3",
				'room' => '62',
				'description' => 'the fidge on the right side',
				'box_label' => 'Stefan\'s test samples'
			},
			'extraction_protocol' => {
				'name' => 'DNA extraction',
				'description' => 'TEST - standard DNA extraction protocol - TEST',
				'version' => '1.0',
				'working_copy' => "just follow the kit description",
				'original_protocol_description' => {
					'file' => 'Just_a_test_file.txt',
					'filetype' => 'text_document'
				},
				'materialList' => { 'list_id' => 1}
			},
			'sample_lable' => 'my test sample',
			'initial_amount' => '100',
			'aliquots' => 1
		},
		'array' => {
			'manufacturer' => 'nimblegene',
			'array_type' => "Chip on chip",
			'identifier'   => 'test'
		},
		'data' => {
			'INPUT'        => $INPUT,
			'IP'           => $IP,
			'GFF'          => undef
		},
		'experiment' => { 'id' => 1 }
	}
);

is_deeply ($value, 3, "may be we could insert the datasets (3x)!");

$value = $dataset->AddDataset(
	{
		'task'         => 'add nimblegene Chip on chip data',
		'access_right' => 'scientist',
		'scientist'    => {
			'id' => 1
		},
		'sample' => {
			'tissue' => {
				'organism'            => { 'id' => 1 },
				'name'         => 'bone marrow',
				'extraction_protocol' => {
					'name'        => 'my test extraction_protocol',
					'version'     => "1.0",
					'description' => "a test protocol entry",
					'working_copy' =>
"1. get up in the morning\n2. eat breakfast\n3. go to work\n4. go home\n5. eat diner\n6. go to bed\n",
					'original_protocol_description' => {
						'file' => 'Just_a_test_file.txt',
						'filetype' => 'text_document'
					},
					'materialList' => { 'list_id' => 1}
				}
			},
			'subject' => {
				'identifier' => 'test_001',
				'organism'   => { 'organism_tag' => 'hu_genome' }
			  },
			'storage' => {
				'temperature' => "-20",
				'building' => "60",
				'floor' => "3",
				'room' => '62',
				'description' => 'the fidge on the right side',
				'box_label' => 'Stefan\'s test samples'
			},
			'extraction_protocol' => {
				'name' => 'DNA extraction',
				'description' => 'TEST - standard DNA extraction protocol - TEST',
				'version' => '1.0',
				'working_copy' => "just follow the kit description",
				'original_protocol_description' => {
					'file' => 'Just_a_test_file.txt',
					'filetype' => 'text_document'
				},
				'materialList' => { 'list_id' => 1}
			},
			'sample_lable' => 'my test sample #2',
			'initial_amount' => '100',
			'aliquots' => 1
		}, 
		'array' => {
			'manufacturer' => 'nimblegene',
			'array_type' => "Chip on chip",
			'identifier'   => 'test'
		},
		'data' => {
			'INPUT'        => $INPUT_2,
			'IP'           => $IP_2,
			'GFF'          => undef
		},
		'experiment' => { 'id' => 1 }
	}
);

$dataset->printReport();

my $nucleotide_array = nucleotide_array->new( "geneexpress", 0 );
is_deeply( ref($nucleotide_array), 'nucleotide_array' , "nucleotide_array->new");
my $oligoDB = $nucleotide_array -> Get_OligoDB_for_ID ( 1 );
is_deeply( ref($oligoDB), 'oligoDB' , "Get_OligoDB_for_ID");
$value = $dataset -> getArray_of_Array_for_search ( { 'search_columns' => [ 'oligoDB.oligo_name', 'array_dataset.table_baseString'] , 'where' => [ ['array_dataset.sample_id', '=', 'my_value'] ] }, 1 );
foreach my $table_name ( @$value ){
	$oligoDB->Add_oligo_array_values_Table ( @$table_name[0]);
}

$oligoDB->printReport(undef, "oligo_values_array_data_interface");

$value = $oligoDB -> getArray_of_Array_for_search ( { 'search_columns' => [ 'oligo_array_values.value'], 'where' => [ [ 'oligoDB.id', '<', 'my value' ] ]}, 2);

@values = ( 318, 413, -1);
for ( my $i = 0; $i < @{@$value[0]}; $i++ ){
	@{@$value[0]}[$i] = int(@{@$value[0]}[$i]);
}
is_deeply ( $value, [\@values ], "we can access the data");
print  $oligoDB -> {'complex_search'}."\n";
#root::print_hashEntries( $value, 3, "the results from $oligoDB -> getArray_of_Array_for_search ()");
