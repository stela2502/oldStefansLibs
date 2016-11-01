#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'stefans_libs::database::LabBook' }

my $LabBook = LabBook->new( root->getDBH(), 0 );

$LabBook->create();

is_deeply(
	$LabBook->AddDataset(
		{
			'scientist_id' => 1,
			'project_id'   => 1,
		}
	),
	1,
	"we can create a new labbook entry"
);

my $labInst = $LabBook->get_LabBook_Instance(1);
$labInst->create();

my $labBook_inst = $LabBook->get_LabBook_Instance(1);
is_deeply( ref($labBook_inst), 'LabBook_instance',
	"And we can get an instance for the created LabBook" );
is_deeply(
	$labBook_inst->AddDataset(
		{
			'header1' => 'test the labbook instance',
			'header2' => 'start',
			'header3' => 'needed',
			'text'    => "We insert the first entry into the database!"
		}
	),
	1,
	"we can add an entry into the LabBook_instance"
);

is_deeply(
	$labBook_inst->UpdateDataset(
		{
			'id' => 1,
			'text' =>
"We insert the first entry into the database! And we have added a small extension!"
		}
	),
	1,
	"we can update the entry"
);

is_deeply(
	$labBook_inst->get_data_table_4_search(
		{ 'search_columns' => [ ref($labBook_inst) . '.text' ], }
	  )->get_line_asHash(0)->{ ref($labBook_inst) . '.text' },
"We insert the first entry into the database! And we have added a small extension!",
	"And the text is stored as expected"
);

is_deeply(
	$labBook_inst->get_data_table_4_search(
		{ 'search_columns' => [ ref($labBook_inst) . '.md5_sum' ], }
	  )->get_line_asHash(0)->{ ref($labBook_inst) . '.md5_sum' },
	"2cbd976caa888da88d9ed3854a5d7d0d",
	"And we have automatically changed the md5 sum!\n"
);
my $value =  $LabBook->createChapter_array(1);
is_deeply(
	$value->{'chapter_order'},
	[
		{
			'name' => 'test the labbook instance',
			'subchapter' => [
				{
					'name' => 'start',
					'subchapter' =>
					  [ { 'name' => 'needed', 'id' => 1, 'subchapter' => [] } ]
				}
			]
		}
	],
	"get a chapter dataset"
);

is_deeply(
	$labBook_inst->AddDataset(
		{
			'header1' => 'test the labbook instance',
			'header2' => '',
			'header3' => '',
			'text'    => "This is the chapter 1"
		}
	),
	2,
	"we can add an entry into the LabBook_instance#2"
);
$value = root::Today() +1;

is_deeply(
	$labBook_inst->AddDataset(
		{
			'header1' => 'test the labbook instance',
			'header2' => '',
			'header3' => '',
			'text'    => "And now I wanted to add a little other thing!",
			'creation_date' => "$value"
		}
	),
	3,
	"we can add an entry into the LabBook_instance#3"
);

is_deeply(($labBook_inst->get_data_table_4_search(
		{ 'search_columns' => [ ref($labBook_inst) . '.*' ], }
	  )->GetAsHTML() =~ m/<table.*<\/table>/) , 1, 1,"we can export as html table");
	  
print $value = $LabBook->write_LaTeX_File_4_LabBook_id_to_path(1, '/home/stefan_l/temp/simply_removeable/');

#open ( OUT , ">./latex_test_source.tex") or die "could not create file '~/latex_test_source.tex'\n";
#print OUT $value;
#close OUT;
#print "Please try to crreate a pdf from the file ./latex_test_source.tex\n";

