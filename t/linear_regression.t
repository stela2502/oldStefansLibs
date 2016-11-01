#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;

BEGIN {
	use_ok 'stefans_libs::array_analysis::regression_models::linear_regression';
}
use stefans_libs::flexible_data_structures::data_table;

my $linear_regression = linear_regression->new();
my ( $samples_hash, $var_hash, $value, @values, $exp, $data );

$value = $linear_regression->_get_fitted_values(
	{
		'normalizing_values' => {
			'a' => [
				8.51,
				8.59, 8.81,
				8.93, 7.74,
				8.98, 8.45,
				8.51, 9.07,
				8.94, 9.02,
				9.28, 7.99,
				8.95
			]
		},
		'data_values' => [
			24.7,
			23.9,
			27.7,
			17.6,
			28.4,
			21.1,
			27,
			29,
			26.1,
			26.1,
			29.4,
			26.8,
			26.2,
			28.4
		]
	}
);
$exp = [ '26.17357', '26.05099', '25.71387', '25.52999', '27.35347', '25.45338', '26.26551', '26.17357', '25.31547', '25.51467', '25.39208', '24.99368', '26.97039', '25.49935' ];

is_deeply ( $value, $exp, "fitted values");
is_deeply( ref($linear_regression), 'linear_regression',
	'simple test of function linear_regression -> new()' );

## test __process_single_vars_hash
$samples_hash = { 'A' => 1,   'B' => 1,   'C' => 1,   'X' => 1 };
$exp          = { 'A' => 1,   'B' => 1,   'C' => 1,   'X' => 1 };
$var_hash     = { 'A' => 0.2, 'B' => 0.3, 'C' => 0.1, 'X' => '' };
$value =
  $linear_regression->__process_single_vars_hash( $var_hash, $samples_hash );
is_deeply( $value, $var_hash,
	'__process_single_vars_hash return linear value' );
is_deeply( $samples_hash, $exp, 'the sample_hash was unchanged' );
$data->{'linear_vars'} = $value;
my $var_hash2 = { 'A' => 'no', 'B' => 'yes', 'C' => 'no', 'X' => 'yes' };
$exp = { 'A' => 1, 'B' => 2, 'C' => 1, 'X' => 2 };
$value =
  $linear_regression->__process_single_vars_hash( $var_hash2, $samples_hash );
is_deeply( $value, $exp,
	'__process_single_vars_hash return sring values converted to integers' );
$data->{'string_vars'} = $value;

## test __process_vars_hash_array

$value = $linear_regression->__process_vars_hash_array( $data, $samples_hash );
$exp = {
	'string_vars' => [ '1',   '2',   '1' ],
	'linear_vars' => [ '0.2', '0.3', '0.1' ]
};
is_deeply(
	[ sort keys %$value ],
	[ 'conditional_vars', 'dropped_samples', 'used_sample_order' ],
	'simple test for the right return keys of __process_vars_hash_array'
);
is_deeply(
	$value->{'used_sample_order'},
	[ 'A', 'B', 'C' ],
	"selection of informative vars"
);
is_deeply( $value->{'dropped_samples'}, ['X'], 'selection of drpooed vars' );
is_deeply( $value->{'conditional_vars'}, $exp,
	'the data structure looks good' );

$data = $linear_regression->_normalize_dataset(
	{
		'data_values'        => [ 0.5, 0.3, 0.9 ],
		'normalizing_values' => $value->{'conditional_vars'}
	}
);
is_deeply( $data, [ 0, 0, 0 ], "a crappy, but the right result" );

# print $linear_regression->{'last_command'}."\n";
## test the main remove_influence_from_dataset function

my ($hash);
$hash->{'influence_data_table'}   = data_table->new();
$hash->{'variables_data_table'}   = data_table->new();
$hash->{'list_of_vars_to_remove'} = [];
$hash->{'vars_to_keep'}           = [];

$hash->{'variables_data_table'}->Add_db_result(
	[
		'Gene Symbol',
		'kept column',
		'dropped column',
		qw/SA01 SA02 SA03 SA04 SA05 SA06 SA07 SA08 SA09 SA10 SA11 SA12 SA13 SA14/
	],
	[
		[
			'TCF7L2',
			'important gene',
			'useless information',
			7.4, 7.4, 7.48, 7.51, 7.55, 7.62, 7.64, 7.69, 7.92, 7.93, 7.93,
			7.99, 7.2, 7.61
		],
		[
			'TP53INP1',               'not important locus',
			'useless information #2', 8.51,
			8.59,                     8.81,
			8.93,                     7.74,
			8.98,                     8.45,
			8.51,                     9.07,
			8.94,                     9.02,
			9.28,                     7.99,
			8.95
		]
	]
);
$hash->{'influence_data_table'}->Add_db_result(
	[
		'KEY',
		qw/SA01 SA02 SA03 SA04 SA05 SA06 SA07 SA08 SA09 SA10 SA11 SA12 SA13 SA14/
	],
	[
		[
			'HbA1c', 5.8, '', 5.4, '',  '', 5.5, '',
			4.3,     '',  '', 7.8, 6.9, '', 5.4
		],
		[
			'BMI', 24.7, 24.7, 23.9, 27.7, 17.6, 28.4, 21.1,
			27,    29,   26.1, 26.1, 29.4, 26.8, 26.2, 28.4,
			26,    24.7, 23.9, 22.5, 26.2, 29.1
		]
	]
);
$hash->{'influence_data_table'}->define_subset( 'samples',
	[qw/SA01 SA02 SA03 SA04 SA05 SA06 SA07 SA08 SA09 SA10 SA11 SA12 SA13 SA14/]
);
$hash->{'list_of_vars_to_remove'} = ['HbA1c'];
$hash->{'vars_to_keep'} = [ 'Gene Symbol', 'kept column' ];

#$linear_regression->{'debug'} = 1;
$value = $linear_regression->remove_influence_from_dataset($hash);

is_deeply(
	$value->{'header'},
	[ 'Gene Symbol', 'kept column', qw/SA01 SA03 SA06 SA08 SA11 SA12 SA14/ ],
	"the column selection went well"
);
is_deeply(
	$value->AsString(),
	'#Gene Symbol	kept column	SA01	SA03	SA06	SA08	SA11	SA12	SA14
TCF7L2	important gene	-0.265579869	-0.136827133	-0.009015317	0.207242888	0.020656455	0.190350109	-0.006827133
TP53INP1	not important locus	-0.34429796	0.01963348	0.17365062	-0.10455507	-0.15395514	0.24989059	0.15963348
', 'the results are are OK'
);

#print "\$exp = ".root->print_perl_var_def($value->{'conditional_vars'} ).";\n";

#print "\$exp = " . root->print_perl_var_def($value) . ";\n";

## test for new

