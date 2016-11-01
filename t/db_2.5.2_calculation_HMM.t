#! /usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use Test::More tests => 40;
BEGIN { use_ok 'stefans_libs::statistics::HMM' }
## test for new
use stefans_libs::statistics::HMM::HMM_hypothesis;
use stefans_libs::database::array_calculation_results;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::statistics::HMM::UMS;

my $home = File::HomeDir->my_home();
my $array_calculation_results =
  array_calculation_results->new( 'geneexpress', 0 );

sub log2 {
	my ($value) = @_;
	return log($value) / log(2);
}

sub ScaleSumToOne {
	my ( $data, $logscale ) = @_;

	my ($i);

	die "test ScaleSumToOne no data present!" unless ( defined $data );

	$i = 0;
	if ( !defined $logscale ) {
		while ( my ( $key, $value ) = each %$data ) {
			$i += $value unless ( $key =~ m/ARRAY/ );
		}
		foreach my $value ( values %$data ) {
			$value = $value / $i;
		}
		$i = 0;
		while ( my ( $key, $value ) = each %$data ) {
			$i += $value unless ( $key =~ m/ARRAY/ );
		}
	}
	else {
		while ( my ( $key, $value ) = each %$data ) {
			$i += exp($value) unless ( $key =~ m/ARRAY/ );
		}
		foreach my $value ( values %$data ) {
			$value = log( exp($value) / $i );
		}
		$i = 0;
		while ( my ( $key, $value ) = each %$data ) {
			$i += exp($value) unless ( $key =~ m/ARRAY/ );
		}
	}
	$i = &ScaleSumToOne() unless ( $i > 0.99999 && $i < 1.000001 );
	return $data;
}

sub formatValue {
	my ( $value, $digits ) = @_;
	$digits = 2 unless ( defined $digits );
	if ( ref($value) eq "HASH" ) {
		foreach my $val ( values %$value ) {
			$val = formatValue( $val, $digits );
		}
		return $value;
	}
	elsif ( ref($value) eq "ARRAY" ) {
		for ( my $i = 0 ; $i < @$value ; $i++ ) {
			@$value[$i] = formatValue( @$value[$i], $digits );
		}
		return $value;
	}
	else {
		$value = 0 unless ( defined $value );
		return sprintf( "%." . $digits . "e", $value );
		return sprintf( "%.1e", $value ) if ( $digits == 1 );
		return sprintf( "%.2e", $value ) if ( $digits == 2 );
		die "use either 1 or 2 digits at HMM.t formatValue $!\n";
	}
}
my $hmm = HMM->new();

is_deeply( ref($hmm), "HMM", "simple test for object name eq 'HMM'" );

my ( $value, @values, $oligo2dnaDB, @expected );
@values = ( log(5), log(8) );

$value = $hmm->Add2Logs(@values);

is_deeply( exp($value), 13, "Add2Logs" );

## OK NOW we need to get the data from the database

$oligo2dnaDB =
  $array_calculation_results->get_Array_Lib_Interface( my $array_id = 1 );
is_deeply( ref($oligo2dnaDB), 'oligo2dnaDB',
"array_calculation_results->get_Array_Lib_Interface (1) returned an oligo2dnaDB"
);

## most probably, there is only one entry in that database!
## -> We have to add some more entries ( 194 ) if that is right!

$value = $oligo2dnaDB->getArray_of_Array_for_search(
	{
		'search_columns' => [
			'oligo_name',                  'oligo2dnaDB.start',
			'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start',
			'oligo2dnaDB.gbFile_id'
		]
	}
);

if ( scalar(@$value) == 1 ) {
	## we have to add some data to this table!
	&populate_oligoDB_table($oligo2dnaDB);
}

## NOW we start the HMM calculation:

# get the data
$value = $array_calculation_results->getArray_of_Array_for_search(
	{
		'search_columns' => ['array_calculation_results.table_baseString'],
		'where' => [ [ 'array_calculation_results.id', '=', 'my_value' ] ]
	},
	1
);

is_deeply(
	@{ @$value[0] }[0],
	'summary_stat_testSetup_vers_v1_0_oligo_array_values',
	"we got the right table base name from array_calculation_results!"
);
$oligo2dnaDB->Add_oligo_array_values_Table( @{ @$value[0] }[0] );

$value = $oligo2dnaDB->getArray_of_Array_for_search(
	{
		'search_columns' => [
			'oligo2dnaDB.id',              'oligo2dnaDB.start',
			'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start',
			'oligo_array_values.value'
		],
		'where' => [['oligo2dnaDB.OligoHitCount', '=', 'my_value' ]],
		'order_by' => [ 'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start' ]
	},
	1
);

print $oligo2dnaDB->{'complex_search'}."\n";

#create the marcow chains
my ( $acutual_id, $last_chr, $last_location, $marcow_chains, @hypos );
$acutual_id                         = -1;
$marcow_chains->{'data'}            = [];
$marcow_chains->{'oligo2dnaDB_ids'} = [];
$last_chr                           = $last_location = 0;
unshift (@$value, [1000, 500, 'X', '500000', 0.54] );
foreach my $table_line (@$value) {
	if (
		!(
			   $last_chr eq @$table_line[2]
			&& $last_location + 500 >= @$table_line[1]
		)
	  )
	{
		print
"we create a new array  $acutual_id + 1 as ! ( $last_chr eq @$table_line[2] && "
		  . ( $last_location + 500 )
		  . " >= @$table_line[1] ) is true\n'"
		  . join( "'\t'", @$table_line ) . "\n";
		$acutual_id++;
		
		if ( $acutual_id > 0 ){
			print "but it may be possible, that ".scalar(@{@{ $marcow_chains->{'data'} }[$acutual_id-1]}).
		" has less that 2 entries - we should not considder that!\n";
			if ( scalar(@{@{$marcow_chains->{'data'}}[$acutual_id-1]}) < 2 ){
				$acutual_id--;
				print "and therefore we have ste the counter back to $acutual_id\n";
			}
			
		}
		@{ $marcow_chains->{'data'} }[$acutual_id]            = [];
		@{ $marcow_chains->{'oligo2dnaDB_ids'} }[$acutual_id] = [];
		$last_chr = @$table_line[2];
	}
	push( @{ @{ $marcow_chains->{'data'} }[$acutual_id] }, @$table_line[4] );
	push(
		@{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$acutual_id] },
		@$table_line[0]
	);
	print "we are at position $last_location\n";
	$last_location = @$table_line[1];
}

@expected = ( [], [] );
for ( my $i = 1 ; $i < 101 ; $i++ ) {
	push( @{ $expected[0] }, $i );
}
for ( my $i = 101 ; $i < 195 ; $i++ ) {
	push( @{ $expected[1] }, $i );
}

is_deeply( $marcow_chains->{'oligo2dnaDB_ids'},
	\@expected, "we got the oligo2dnaDB_ids in the right order" );

#print "\$expected[0] = (".join( ", ",@{@{$marcow_chains->{'data'}}[0]}).");\n";
#print "\$expected[1] = (".join( ", ",@{@{$marcow_chains->{'data'}}[1]}).");\n";
$expected[0] = [
	-510.289, -1424.93, -3396.66, -2354.82, -3339.4,  -1767.97,
	-2551.66, -3534.76, -2529.66, -3005.58, -3167.96, -3094.16,
	-2548.59, -1167.27, -1282.64, -1469.79, -3147,    -2351.66,
	-2750.44, -3052.6,  -6955.79, -6763.08, -2128.38, -3021.84,
	-3179.16, -5034.54, -3708.12, -3726.46, -4410.55, -3171.69,
	-3898.08, -3061.68, -1575.34, -2296.61, -3077.45, -3540.32,
	-4121.28, -3580.34, -2978.12, -2826.05, -2752.97, -1348.71,
	-5158.83, -3245.1,  -1941.36, -4726.38, -1935.83, 204.041,
	-2576.73, -3371.69, -3619.85, -1417.95, -47.9441, -3672.44,
	-2878.6,  -3796.58, -5021.4,  -70.6401, -2651.54, -2379.14,
	-5729.77, -3226.51, -2029.51, -1031.51, -2929.91, -4948.98,
	-1713.67, -1880.98, -4309.31, -652.168, -3393.77, -922.273,
	-4541.04, -2701.27, -2510.87, -2879.47, -4486.15, -2484.35,
	-2039.06, -4882.67, -1366.99, -5142.62, -3933.5,  -1240.02,
	-2180.27, -3420.87, -1934.75, -2507.18, -2223.99, -2846.56,
	-3197.83, -3002.75, -3573.96, -3417.33, -2397.43, -1765.95,
	-1446.64, -4488.5,  -3738.7,  -5840.5
];
$expected[1] = [
	-3509.39, -766.984, -5201.04, -2592.47, -1918.41, -3128.35,
	-2870.64, -2813.61, -2361.48, -5051.62, -2945.23, -475.062,
	-3243.82, -2393.87, -2125.81, -6122.22, -2931.43, -2450.89,
	-3508.42, -5166.59, -2583.98, -3235.32, -2814.82, -2770.52,
	-4537.49, -3146.58, -3890.56, -1048.45, -3254.08, 131.174,
	-4160.48, -2173.87, -2509.34, -3720.75, -5721.58, -4355.43,
	-2704.62, -173.172, -2834.57, -1236.38, -3145.14, -3137.01,
	-4713.09, -2337.35, -2071.61, -3430.54, -1989.65, -4289.89,
	-3918.81, -1285.39, -237.951, -2300.51, -3008.47, -2547.51,
	-218.491, -2218.86, -898.471, -4158.95, -1488.82, -761.271,
	-4723.15, -2206.06, -3865.35, -3535.68, -2741.49, -3024.65,
	-3212.55, -2387.84, -2742.2,  -1059.7,  -1620.17, -1711.39,
	-3348.9,  -3223.78, -1081.82, -1995.49, -4394,    -3504.58,
	-3949.41, -1758.1,  -3985.4,  -2751.8,  -3043.84, -2422.88,
	-3644.18, -3456.91, -3670.34, -4615.46, -2111.73, -3289.54,
	-4351.74, -1178.92, -2941.42, -3115.15
];

#print root::get_hashEntries_as_string( $marcow_chains->{'data'}, 2, "the oligo_data");
is_deeply( $marcow_chains->{'data'},
	\@expected, "we got the right oligo data!" );

# create the HMM_states

push( @hypos, ( HMM_hypothesis->new(), HMM_hypothesis->new() ) );

$hypos[0]->add_internalState_hypotheis(
	{ 'name' => 'not_enriched', 'hypothesis' => { 'more_than' => 0.8 } } );
$hypos[1]->add_internalState_hypotheis(
	{ 'name' => 'enriched', 'hypothesis' => { 'less_than' => 0.2 } } );

my $UMS = UMS->new();

my $probDistributions = $UMS->get_stateValues_for_dataset(
	{ data => $marcow_chains->{'data'}, hypothesies => \@hypos } );

my $influence_of_not_enriched = $UMS->calculate_components($probDistributions);

$UMS->plot_states( $probDistributions, "$home/temp/ums_testScript_output" );

## now we have to estimate the transition probabilities
#  we have a 'chip' with 100 bp spacing => in 1kb of DNA we would have 10 matches

	@$probDistributions[1]
	  ->probability_for_change_to_state( 'not_enriched', 0.9 );
	@$probDistributions[1]->probability_for_change_to_state( 'enriched', 0.1 );
	@$probDistributions[1]->{'startProbability'} =
	  log($influence_of_not_enriched);
	@$probDistributions[1]->{'endProbability'} =
	  log($influence_of_not_enriched);

	print
	  "we have an influence of none enriched = $influence_of_not_enriched\n";
	print "that translates to a probability to change to enriched = "
	  . ( 0.1 * ( 1 - $influence_of_not_enriched ) ) /
	  $influence_of_not_enriched . "\n";

	@$probDistributions[0]->probability_for_change_to_state( 'enriched',
		( 0.1 * ( 1 - $influence_of_not_enriched ) ) /
		  $influence_of_not_enriched );
	@$probDistributions[0]->probability_for_change_to_state( 'not_enriched',
		1 -
		  ( 0.1 * ( 1 - $influence_of_not_enriched ) ) /
		  $influence_of_not_enriched );
	@$probDistributions[0]->{'startProbability'} =
	  log( 1 - $influence_of_not_enriched );
	@$probDistributions[0]->{'endProbability'} =
	  log( 1 - $influence_of_not_enriched );


$value = $hmm->_check_and_prepareStates($probDistributions);

is_deeply(
	[ $value, $hmm->{error} ],
	[ undef,  undef ],
	"finally everything went well (no errors)"
);

$hmm->CalculateHMM(
	{
		states       => $probDistributions,
		'values'     => $marcow_chains->{'data'},
		'path'       => "$home/temp",
		'file_base'  => "test_HMM_InternalStates_2",
		'iterations' => 100
	}
);

my $state_values = $hmm->get_hiddenState_as_array('enriched');
my ( $regionsOfInterst, $start_id, $end_id, $gbFeature, $gbFile_id );

$regionsOfInterst->{'gbFeatures'} = [];
$regionsOfInterst->{'gbFile_ids'} = [];
for ( my $chain = 0 ; $chain < @$state_values ; $chain++ ) {

	for ( my $id = 0 ; $id < @{ @$state_values[$chain] } ; $id++ ) {
		## now I need to create the enriched regions!!!!!
			$start_id =
			  @{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$chain] }[$id]
			  unless ( defined $start_id );
			$end_id =
			  @{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$chain] }[$id];
	}
	if ( defined $start_id && ( $start_id != $end_id ) ) {
		print "we create a gbFeature between $start_id and $end_id\n";
		( $gbFeature, $gbFile_id ) =
		  $oligo2dnaDB->get_gbFeature_for_id_pair( $start_id, $end_id );
		if ( ref($gbFeature) eq "gbFeature" ) {
			push( @{ $regionsOfInterst->{'gbFeatures'} }, $gbFeature );
			push( @{ $regionsOfInterst->{'gbFile_ids'} }, $gbFile_id );
		}
		else{
			print "but we have got no gbFeature!\n";
		}
		$start_id = $end_id = undef;
	}
}
my $loggingTable = loggingTable->new( 'geneexpress', 0 );
my $lodID = $loggingTable->set_log(
	{
		'programID'   => 'db_calculation_HMM.t',
		'description' => "we do a test setup"
	}
);
my @dataset = ();

for ( my $i = 0 ; $i < @{ $regionsOfInterst->{'gbFeatures'} } ; $i++ ) {
	push(
		@dataset,
		{
			'gbFile_id' => @{ $regionsOfInterst->{'gbFile_ids'} }[$i],
			'tag'       => @{ $regionsOfInterst->{'gbFeatures'} }[$i]->Tag("array_calc_id_$array_id"),
			'name'     => "id_$i",
			'start'    => @{ $regionsOfInterst->{'gbFeatures'} }[$i]->Start(),
			'end'      => @{ $regionsOfInterst->{'gbFeatures'} }[$i]->End(),
			'gbString' => @{ $regionsOfInterst->{'gbFeatures'} }[$i]->getAsGB(),
			'loggingTable' => { 'id' => $lodID }
		}
	);
}

$oligo2dnaDB->Add_2_result_ROIs( 'geneexpress', \@dataset );

sub populate_oligoDB_table {
	my ($oligo2dnaDB) = @_;
	my $dataset = {
		'oligo_id'        => 0,
		'start'           => 0,
		'length'          => 50,
		'chromosome_name' => 'Y',
		'chr_start'       => 207885,
		'sameOrientation' => 1,
		'gbFile_id'       => 3,
		'OligoHitCount'   => 1
	};
	## Oligo_id 1 and 2
	for ( my $i = 1 ; $i < 3 ; $i++ ) {
		$dataset->{'oligo_id'}     = $i;
		$dataset->{'search_array'} = undef;
		$dataset->{'start'}        = 6500 + $i * 100;
		$oligo2dnaDB->AddDataset($dataset);
	}
	## Oligo_id 4 - 100
	for ( my $i = 4 ; $i < 101 ; $i++ ) {
		$dataset->{'oligo_id'}     = $i;
		$dataset->{'search_array'} = undef;
		$dataset->{'start'}        = 6500 + $i * 100;
		$oligo2dnaDB->AddDataset($dataset);
	}
	## Oligo_id 101 - 194
	for ( my $i = 101 ; $i < 195 ; $i++ ) {
		$dataset->{'oligo_id'}     = $i;
		$dataset->{'search_array'} = undef;
		$dataset->{'start'}        = 26000 + $i * 100;
		$oligo2dnaDB->AddDataset($dataset);
	}
	## OK - we should be ready!
}

package SORTER;

sub new {
	my $self = {};
	bless $self, 'SORTER';
	return $self;
}

sub Sort {
	my ( $self, $old_value1, $value1 ) = @_;

	return 1 unless ( defined $old_value1 );
	return 1 unless ( defined $value1 );
	return 1 if ( !( $old_value1 eq $value1 ) );
	return 0;
}
1;
