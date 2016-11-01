#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use stefans_libs::root;
BEGIN { use_ok 'stefans_libs::database::experiment::partizipatingSubjects' }

my $partizipatingSubjects = partizipatingSubjects->new('geneexpress');
is_deeply( ref($partizipatingSubjects),
	'partizipatingSubjects',
	'simple test of function partizipatingSubjects -> new()' );

## test for new
my ( $value, @values );

$value = $partizipatingSubjects->AddDataset(
	{
		'experiment' => { 'id' => 1 },
		'subject' =>
		  { 'id' => 1, 'identifier' => "3CPO", 'organism' => { 'organism_tag' => 'android' } }
	}
);
is_deeply( $value, 1, "we added a dataset!" );

$value = $partizipatingSubjects->_select_all_for_DATAFIELD( 1, "id" );
is_deeply(
	$value,
	[ { 'id' => 1, 'experiment_id' => 1, 'subject_id' => 1 } ],
	"and we can get the values out again!"
);
