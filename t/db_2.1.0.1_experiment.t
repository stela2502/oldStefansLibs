#! /usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::database::experiment' }

my $home = File::HomeDir->my_home();
## we need an picture file - and we have one in our t/data folder
## therefore we copy that!
$home .= "/temp";
my $picture = "t/data/test_pic.png";
$picture = "data/test_pic.png" if ( -f "data/test_pic.png" );
system("cp $picture $home/hypothesis_test_pic.png");

my $experiment = experiment->new('geneexpress');
is_deeply( ref($experiment), 'experiment',
	'simple test of function experiment -> new()' );

## test for new
$experiment->create();

my ( $value, $expected, $data );

$data = {
	'project' => {
		'aim'   => "set up the database",
		'name'  => "Database_Setup",
		'grant' => {
			'id'   => 1,
			'name' => 'the unsecure',
			'description' =>
"this grant indicates, that the databse is not in a stable working condition, but under development. Use at your own risk.",
			'application_file' => "$home/A_initial_grant_description.txt"
		}
	},
	'name'        => "experiment_from_scratch",
	'description' => "set up the experiment table using a single hash of data",
	'hypothesis'  => {
		'picture' => {
			'file'     => "$home/hypothesis_test_pic.png",
			'filetype' => 'picture'
		},
		'hypothesis_name' => 'just a test hypothesis',
		'description' =>
		  "not really a picture that could describe a hypothesis, but a test!",
		'hypothesis' =>
		  "The database is the only way to handle biological data",
		'access_right' => "scientist"
	},
	'aim'  => "nnix",
	'PMID' => ""
};

$value = $experiment->AddDataset($data);

is_deeply( $value, 1, "we could insert a experiment" );

$value =
  $experiment->_select_all_for_DATAFIELD( "experiment_from_scratch", 'name' );

#print root::get_hashEntries_as_string( $value, 3, "see what we got!" );

#print "the internal structure of the emperiment tables\n"
#  . $experiment->printReport();

$expected = {
	'id'          => 1,
	'PMID'        => '',
	'name'        => "experiment_from_scratch",
	'description' => "set up the experiment table using a single hash of data",
	'conclusion'  => '',
	'aim'         => "nnix",
	'md5_sum'     => '6b3f44a6ec94a59789c91fb261fa9374',
	'project_id'  => 1,
	'hypothesis_id' => 1
};

is_deeply( $value, [$expected], "access the data using the name" );
$value = 0;
$value = $experiment->AddDataset( { 'name' => "experiment_from_scratch" } );

is_deeply( $value, 1,
	"the experiment could be retrieved using the 'name' tag" );
$value = 0;

$value = $experiment->_select_all_for_DATAFIELD( "1", 'id' );
is_deeply( $value, [$expected], "access the data using the id" );

$experiment->Update_Conclusion_for_experiment_id(
	"we have found no errrors in the script (so far...)", 1 );

$value = $experiment->_select_all_for_DATAFIELD( "1", 'id' );
$expected = {
	'id'          => 1,
	'PMID'        => '',
	'name'        => "experiment_from_scratch",
	'description' => "set up the experiment table using a single hash of data",
	'conclusion'  => "we have found no errrors in the script (so far...)",
	'aim'         => "nnix",
	'md5_sum'     => '6b3f44a6ec94a59789c91fb261fa9374',
	'project_id'  => 1,
	'hypothesis_id' => 1
};
is_deeply( $value, [$expected], "we can add a conclusion" );

$value = $experiment->get_data_table_4_search(
	{
		'search_columns' => [
			'hypothesis_table.hypothesis', 'experiment.name',
			'experiment.description',      'experiment.aim'
		],
		'limit' => "limit 1"
	}
);

is_deeply(
	$value->AsString(),
"#hypothesis_table.hypothesis\texperiment.name\texperiment.description\texperiment.aim\n"
	  . "The database is the only way to handle biological data\texperiment_from_scratch\tset up the experiment table using a single hash of data\tnnix\n",
	"we can get a data_table object\n"
);

