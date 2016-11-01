#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use File::HomeDir;
BEGIN { use_ok 'stefans_libs::exec_helper::XML_handler' }

my $XML_handler = XML_handler->new();
is_deeply( ref($XML_handler), 'XML_handler',
	'simple test of function XML_handler -> new()' );

my $homeDir = File::HomeDir->home();
$homeDir .= "/temp";

## test for new

use stefans_libs::root;
my ( $value, @values, $expected );

my $hash = {
	'executable' => {
		'SCRIPT_NAME' => 'calculateNucleosomePositionings.pl',
		'DESCRIPTION' =>
'a maintainance script to calculate the nucleosome positioning for a whole genome and stores those values in the database',
		'ENCAPSULATED' => 0,
		'RUN_NICE'     => 1,
		'JOB_ID'       => 1,
		'THREAD_PROVE' => 1,
	},
	'arguments' => [
		{
			'ARGUMENT_NAME'  => 'organism',
			'IS_NECESSARY'   => 1,
			'CONFLICTS_WITH' => [ 1, 2, 3, 4, 5 ],
			'VALUE'          => 'H_sapiens'
		},
		{
			'ARGUMENT_NAME' => 'executable',
			'IS_NECESSARY'  => 1,
			'VALUE' =>
'/home/stefan_l/Downloads/prgramme/nucleosomePrediction/nucleosome_prediction.pl'
		},
		{
			'ARGUMENT_NAME' => 'max_seq_length',
			'IS_NECESSARY'  => 0,
			'VALUE'         => 1000000
		},
	]
};
$expected = "<opt>
  <arguments ARGUMENT_NAME=\"organism\"
             IS_NECESSARY=\"1\"
             VALUE=\"H_sapiens\">
    <CONFLICTS_WITH>1</CONFLICTS_WITH>
    <CONFLICTS_WITH>2</CONFLICTS_WITH>
    <CONFLICTS_WITH>3</CONFLICTS_WITH>
    <CONFLICTS_WITH>4</CONFLICTS_WITH>
    <CONFLICTS_WITH>5</CONFLICTS_WITH>
  </arguments>
  <arguments ARGUMENT_NAME=\"executable\"
             IS_NECESSARY=\"1\"
             VALUE=\"/home/stefan_l/Downloads/prgramme/nucleosomePrediction/nucleosome_prediction.pl\" />
  <arguments ARGUMENT_NAME=\"max_seq_length\"
             IS_NECESSARY=\"0\"
             VALUE=\"1000000\" />
  <executable DESCRIPTION=\"a maintainance script to calculate the nucleosome positioning for a whole genome and stores those values in the database\"
              ENCAPSULATED=\"0\"
              JOB_ID=\"1\"
              RUN_NICE=\"1\"
              SCRIPT_NAME=\"calculateNucleosomePositionings.pl\"
              THREAD_PROVE=\"1\" />
</opt>";

$value =
  $XML_handler->print_XML_job_description_2_file( $hash,
	$homeDir . "/test2.xml" );

#warn $value;
is_deeply(
	[ split( "\n", $value ) ],
	[ split( "\n", $expected ) ],
	"we got the right XML structure"
);

$value =
  $XML_handler->read_XML_job_description_from_file( $homeDir . "/test2.xml" );
is_deeply( $value, $hash, "we can get our original hash again" );

