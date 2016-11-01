#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
BEGIN { use_ok 'stefans_libs::database::subjectTable' }

my ( $value, @values, $expected, $tables );

my $phenotype_registration = phenotype_registration->new();
$phenotype_registration->create();

## now we will create some phenotypes....

$phenotype_registration->AddDataset ( {
	'name' => 'age',
	'protocol' => {
		'name' => 'simple_question',
		'description' => 'you simply ask the patient',
		'version' => "1.0",
		'working_copy' => 'you simply ask the patient'
	},
	'description' => 'the age of the subjects',
	'perl_module_name' => 'age',
	'connection_type' => 'local',
	'min_val' => '1900-01-01',
	'max_val' => '',
	'unit' => 'DATE'
});
$phenotype_registration->AddDataset ( {
	'name' => 'familyHistory',
	'protocol' => {
		'name' => 'simple_question'
	},
	'description' => 'a descriptive information about the desease state of families',
	'perl_module_name' => 'familyHistory',
	'connection_type' => 'local',
	'module_spec_restr' => 'mom dad mommom momdad dadmom daddad sibling\d*',
	'unit' => 'binary'
});
$phenotype_registration->AddDataset ( {
	'name' => 'gender',
	'protocol' => {
		'name' => 'simple_question'
	},
	'description' => 'the gender of the subject',
	'perl_module_name' => 'binary_mono',
	'connection_type' => 'local',
	'min_val' => 'm',
	'max_val' => 'w',
	'unit' => 'binary'
});
$phenotype_registration->AddDataset ( {
	'name' => 'body_length',
	'protocol' => {
		'name' => 'simple_question'
	},
	'description' => 'the body size of the subject',
	'perl_module_name' => 'continuose_mono',
	'connection_type' => 'local',
	'min_val' => 30,
	'max_val' => 260,
	'unit' => "cm"
});
$phenotype_registration->AddDataset ( {
	'name' => 'BMI',
	'protocol' => {
		'name' => 'BMI_calculation',
		'description' => 'simple calculation of body_weight [kg] / body_length [m]',
		'version' => "1.0",
		'working_copy' => 'calculate body_weight [kg] / (body_length * body_length)[m2]'
	},
	'description' => 'the body size of the subject',
	'perl_module_name' => 'continuose_multi',
	'connection_type' => 'local',
	'min_val' => 12,
	'max_val' => 80,
	'unit' => "kg/m2"
});

my $subjectTable = subjectTable->new( root::getDBH('root') );
$tables = {};

## can we check for all supported phenotyoes?
$expected = [ sort ( 'age', 'BMI', 'body_length','familyHistory', 'gender' ) ];
$value = $subjectTable->{'phenotype_registration'}->supports();
is_deeply( $value, $expected, "We can check all supported phenotype tables" );

foreach my $phenotype ( @$expected ){
	$tables->{$phenotype} = $subjectTable->connect_2_phenotype($phenotype);
	is_deeply( $tables->{$phenotype}->{'name'},$phenotype
	, "we can connect to the phenotype '$phenotype'" );
}

## can we get the age table object?
$tables->{'age'} = $subjectTable->connect_2_phenotype('age');
is_deeply( ref( $tables->{'age'} ),
	"ph_age", "we can connect to the phenotype 'age'" );

## AddDataset?
$value = $tables->{'age'}->AddDataset(
	{
		'subject_id' => 1,
		'birth'      => '1946-09-19',
		'death'      => '2008-10-10'
	}
);
is_deeply( $value, 1, "we can add a age dataset" );

## can we connect to the family_history table object
$tables->{'familyHistory'} =
  $subjectTable->connect_2_phenotype('familyHistory');
is_deeply( ref( $tables->{'familyHistory'} ),
	"familyHistory", "we can connect to the phenotype 'familyHistory'" );

## AddDataset?
$value = $tables->{'familyHistory'}->AddDataset(
	{
		'subject_id'     => 1,
		'family_member'  => 'mom',
		'affection_type' => 'T2D',
		'affected'       => 0
	}
);
$value = $tables->{'familyHistory'}->AddDataset(
	{
		'subject_id'     => 1,
		'family_member'  => 'dad',
		'affection_type' => 'T2D',
		'affected'       => 1
	}
);
$value = $tables->{'familyHistory'}->AddDataset(
	{
		'subject_id'     => 1,
		'family_member'  => 'mommom',
		'affection_type' => 'T2D',
		'affected'       => 0
	}
);
$value = $tables->{'familyHistory'}->AddDataset(
	{
		'subject_id'     => 1,
		'family_member'  => 'momdad',
		'affection_type' => 'T2D',
		'affected'       => 1
	}
);
$value = $tables->{'familyHistory'}->AddDataset(
	{
		'subject_id'     => 1,
		'family_member'  => 'sibling1',
		'affection_type' => 'T2D',
		'affected'       => 0
	}
);
is_deeply( $value, 5, "we can add a familyHistory dataset" );

$value = $subjectTable->getArray_of_Array_for_search(
	{
		'search_columns' => [ ref($subjectTable) . '.id' ],
		'where'          => [
			[ 'familyHistory' . '.affected',      '=', 'my_value' ],
			[ 'familyHistory' . '.family_member', '=', 'my_value' ]
		],
	},
	1,
	[ 'mom', 'dad', 'sibling1' ]
);

is_deeply( $value, [ [1] ],
	"we can get a binary result from the familyHistory table" );

$value = $subjectTable->getArray_of_Array_for_search(
	{
		'search_columns' => [ ref($subjectTable) . '.id' ],
		'where'          => [
			[ 'familyHistory' . '.affected',      '=', 'my_value' ],
			[ 'familyHistory' . '.family_member', '=', 'my_value' ]
		],
	},
	1,
	[ 'mom', 'dad', 'momdad' ]
);

print "we executed $subjectTable->{'complex_search'}\n";
print "and got the result:\n"
  . root::get_hashEntries_as_string( $value, 3, "" );
is_deeply(
	$value,
	[ [1], [1] ],
"but we get multiple reports for one individual if multiple family members are affected"
);

$value = $tables->{'gender'}->AddDataset(
	{
		'subject_id' => '1',
		'value'        => 'w'
	}
);
is_deeply( 1, 1, "we can add to the sex table" );

$value = $subjectTable->getArray_of_Array_for_search(
	{
		'search_columns' => [ ref($subjectTable) . '.id' ],
		'where'          => [
			[ 'familyHistory' . '.affected',      '=', 'my_value' ],
			[ 'familyHistory' . '.family_member', '=', 'my_value' ],
			[ 'gender' . '.value', '=', 'my_value' ]
		],
	},
	1,
	[ 'mom', 'dad', 'momdad' ],
	'w'
);

$value = $subjectTable->getArray_of_Array_for_search(
	{
		'search_columns' => [ ref($subjectTable) . '.id' ],
		'where'          => [
			[ 'familyHistory' . '.affected',      '=', 'my_value' ],
			[ 'familyHistory' . '.family_member', '=', 'my_value' ],
			[ 'gender' . '.value', '=', 'my_value' ]
		],
	},
	1,
	[ 'mom', 'dad', 'momdad' ],
	'm'
);

is_deeply( $value, [], "we can create the complex sql \n$subjectTable->{'complex_search'}\nexecute and get the right values (nothing)\n" );

$subjectTable->printReport( undef, "subjectTable_with_links_to_phenotypes" );
