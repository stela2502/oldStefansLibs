#! /usr/bin/perl -w

#  Copyright (C) 2008 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 calculate_HMM_for_id.pl

use an HMM to identify peaks in an summary statistics dataset. Make shure, the oligo_id you present here is a summary_statistics dataset and the oligo2dnaDB dataset for this array has been calculated.

To get further help use 'calculate_HMM_for_id.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;

use stefans_libs::statistics::HMM;
use stefans_libs::statistics::HMM::HMM_hypothesis;
use stefans_libs::database::array_calculation_results;
use stefans_libs::statistics::HMM::UMS;

use strict;
use warnings;

my ( $help, $debug, $database, $array_id, $reiterations, $positive_quantil );

Getopt::Long::GetOptions(
	"-help"       => \$help,
	"-debug"      => \$debug,
	"-database=s" => \$database,
	'-array_id=s' => \$array_id,
	'-reiterations=s' => \$reiterations,
	'-positive_quantil=s' => \$positive_quantil
);

if ($help) {
	print helpString();
	exit;
}
unless ( defined $array_id ) {
	print helpString(
"we need the array_id of the array_calculation dataset you want to evaluate!"
	);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for calculate_HMM_for_id.pl
 
   -help           :print this help
   -debug          :verbose output
   -database       :the database you want to use
   -array_id       :the array_id of the array_calculation_results you wnt to use
   -reiterations    :the amount of reiteration the HMM algorythm should perform (default 10)
   -positive_quantil : the quantile below which a value should be considered enriched ( default 0.2)
   
   
";
}

## now we set up the logging functions....

$positive_quantil = 0.2 unless ( defined $positive_quantil);
$reiterations = 10 unless ( defined $reiterations);

my (
	$workingTable,   $loggingTable, $workLoad,
	$loggingEntries, $work_description
);

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );

$database = $workingTable -> {'database'};
## and add a working entry

$work_description =
  "calculate_HMM_for_id.pl -database $database -array_id $array_id -reiterations $reiterations -positive_quantil $positive_quantil";

$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'calculate_HMM_for_id.pl',
		'description' => $work_description

	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description($work_description);
unless ( ref( @$workLoad[0] ) eq "HASH" ) {
	die
"Sorry, but we could not get a propper workload lock for this task ($work_description)\nContact your system administrator with including the above error message\n";
}
unless ( defined @$loggingEntries[0] ) {

	my ( $hmm, $array_calculation_results, $value, $marcow_chains, @hypos );

	$hmm = HMM->new();
	$array_calculation_results = array_calculation_results->new( $database, 0 );

	my $array_calculation_result_table =
	  $array_calculation_results->getArray_of_Array_for_search(
		{
			'search_columns' => [
				'array_calculation_results.array_id',
				'array_calculation_results.table_baseString'
			],
			'where' => [ [ 'array_calculation_results.id', '=', 'my_value' ] ]
		},
		$array_id
	  );
	my ($oligo2dnaDB);
	$oligo2dnaDB = $array_calculation_results->get_Array_Lib_Interface(
		@{ @$array_calculation_result_table[0] }[0] );

	$value = $oligo2dnaDB->getArray_of_Array_for_search(
		{
			'search_columns' => [
				'oligo_name',                  'oligo2dnaDB.start',
				'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start',
				'oligo2dnaDB.gbFile_id'
			],
			'limit' => 'limit 10'
		}
	);
	if ( scalar(@$value) != 10 ) {
		die
"It seams, as if you have not matched the oligoDB against the genome\nSorry, but I can not calculate the peaks!\n";
	}

	$oligo2dnaDB->Add_oligo_array_values_Table(
		@{ @$array_calculation_result_table[0] }[1] );

	$value = $oligo2dnaDB->getArray_of_Array_for_search(
		{
			'search_columns' => [
				'oligo2dnaDB.id',              'oligo2dnaDB.start',
				'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start',
				'oligo_array_values.value'
			],
			'where' => [ [ 'oligo2dnaDB.OligoHitCount', '=', 'my_value' ] ],
			'order_by' =>
			  [ 'oligo2dnaDB.chromosome_name', 'oligo2dnaDB.chr_start' ]
		},
		1
	);
	$marcow_chains = &craete_marcow_chains($value);
	## create the probability distributions

	push( @hypos, ( HMM_hypothesis->new(), HMM_hypothesis->new() ) );

	$hypos[0]->add_internalState_hypotheis(
		{ 'name' => 'not_enriched', 'hypothesis' => { 'more_than' => 0.5 } } );
	$hypos[1]->add_internalState_hypotheis(
		{ 'name' => 'enriched', 'hypothesis' => { 'less_than' => $positive_quantil } } );

	my $UMS = UMS->new();

	my $probDistributions = $UMS->get_stateValues_for_dataset(
		{ data => $marcow_chains->{'data'}, hypothesies => \@hypos } );

	$UMS->plot_states( $probDistributions,
		"/home/stefan_l/temp/ums_start_model_output_array_id_$array_id" );

	my $influence_of_not_enriched =
	  $UMS->calculate_components($probDistributions);

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

	$hmm->CalculateHMM(
		{
			'states'       => $probDistributions,
			'values'     => $marcow_chains->{'data'},
			'path'       => "/tmp/calculate_HMM_for_id$array_id/",
			'file_base'  => "HMM_InternalStates_id$array_id",
			'iterations' => $reiterations
		}
	);

	## and now - create the regions of interest - they are in gbFeature format and could be added quite easyly to a new table!

	my $state_values = $hmm->get_hiddenState_as_array('enriched');
	my ( $regionsOfInterst, $start_id, $end_id, $gbFeature, $gbFile_id );

	$regionsOfInterst->{'gbFeatures'} = [];
	$regionsOfInterst->{'gbFile_ids'} = [];

	open( OUT,
		">/home/stefan_l/temp/HMM_results/HMM_data_array_id_$array_id"."_it_$reiterations.csv" )
	  or die
"could not create /home/stefan_l/temp/HMM_results/HMM_data_array_id_$array_id"."_it_$reiterations.csv\n";
	print OUT "oligo2dnaDB.id\tp_value enriched\n";
	for ( my $chain = 0 ; $chain < @$state_values ; $chain++ ) {

		#print OUT "marcow chain $chain\n";
		for ( my $id = 0 ; $id < @{ @$state_values[$chain] } ; $id++ ) {
			## now I need to create the enriched regions!!!!!
			if ( exp( @{ @$state_values[$chain] }[$id] ) > 0.99 ) {
				$start_id =
				  @{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$chain] }[$id]
				  unless ( defined $start_id );
				$end_id =
				  @{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$chain] }[$id];
			}
			elsif ( defined $start_id ) {
				if ( ( defined $end_id ) && ( $start_id != $end_id ) ) {
					( $gbFeature, $gbFile_id ) =
					  $oligo2dnaDB->get_gbFeature_for_id_pair( $start_id,
						$end_id );
					if ( ref($gbFeature) eq "gbFeature" ) {
						push(
							@{ $regionsOfInterst->{'gbFeatures'} },
							$gbFeature
						);
						push(
							@{ $regionsOfInterst->{'gbFile_ids'} },
							$gbFile_id
						);
					}
				}
				$start_id = $end_id = undef;
			}

			print OUT @{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$chain] }[$id]
			  . "\t"
			  . exp( @{ @$state_values[$chain] }[$id] ) . "\n";
		}
		if ( defined $start_id && ( $start_id != $end_id ) ) {
			( $gbFeature, $gbFile_id ) =
			  $oligo2dnaDB->get_gbFeature_for_id_pair( $start_id, $end_id );
			if ( ref($gbFeature) eq "gbFeature" ) {
				push( @{ $regionsOfInterst->{'gbFeatures'} }, $gbFeature );
				push( @{ $regionsOfInterst->{'gbFile_ids'} }, $gbFile_id );
			}
			$start_id = $end_id = undef;
		}
	}
	print "we got "
	  . scalar( @{ $regionsOfInterst->{'gbFeatures'} } )
	  . " gbFeatures that should represent enriched regions!\n";
	close(OUT);
	open( OUT,
		">/home/stefan_l/temp/HMM_results/HMM_report_for_id_$array_id.txt" )
	  or die
"could not craete file /home/stefan_l/temp/HMM_results/HMM_report_for_id_$array_id.txt\n"
	  . $!;
	for ( my $i = 0 ; $i < @{ $regionsOfInterst->{'gbFeatures'} } ; $i++ ) {
		print OUT "gbFile_id="
		  . @{ $regionsOfInterst->{'gbFile_ids'} }[$i] . "\n"
		  . @{ $regionsOfInterst->{'gbFeatures'} }[$i]->getAsGB()
		  if (
			ref( @{ $regionsOfInterst->{'gbFeatures'} }[$i] ) eq "gbFeature" );

	}
	close(OUT);

	my $lodID = $loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

	my @dataset = ();

	for ( my $i = 0 ; $i < @{ $regionsOfInterst->{'gbFeatures'} } ; $i++ ) {
		push(
			@dataset,
			{
				'gbFile_id' => @{ $regionsOfInterst->{'gbFile_ids'} }[$i],
				'tag'       => @{ $regionsOfInterst->{'gbFeatures'} }[$i]
				  ->Tag("array_calc_id_$array_id"."_it_$reiterations"),
				'name'  => "id_$i",
				'start' => @{ $regionsOfInterst->{'gbFeatures'} }[$i]->Start(),
				'end'   => @{ $regionsOfInterst->{'gbFeatures'} }[$i]->End(),
				'gbString' =>
				  @{ $regionsOfInterst->{'gbFeatures'} }[$i]->getAsGB(),
				'loggingTable'    => { 'id' => $lodID },
				'loggingTable_id' => $lodID
			}
		);
	}

	$oligo2dnaDB->Add_2_result_ROIs( $database, \@dataset );

}

$workingTable->delete_workload_for_PID($$);

sub craete_marcow_chains {
	my ($value) = @_;

	my ( $acutual_id, $last_chr, $last_location, $marcow_chains, @hypos );
	$acutual_id                         = -1;
	$marcow_chains->{'data'}            = [];
	$marcow_chains->{'oligo2dnaDB_ids'} = [];
	$last_chr                           = $last_location = 0;
	my $i = 0;
	foreach my $table_line (@$value) {
		if (
			!(
				   $last_chr eq @$table_line[2]
				&& $last_location + 500 >= @$table_line[1]
			)
		  )
		{

			$acutual_id++;

			if ( $acutual_id > 0 ) {
				if (
					scalar(
						@{ @{ $marcow_chains->{'data'} }[ $acutual_id - 1 ] }
					) < 2
				  )
				{
					$acutual_id--;
				}

			}
			@{ $marcow_chains->{'data'} }[$acutual_id]            = [];
			@{ $marcow_chains->{'oligo2dnaDB_ids'} }[$acutual_id] = [];
			$i++;
			$last_chr = @$table_line[2];
		}
		push( @{ @{ $marcow_chains->{'data'} }[$acutual_id] },
			@$table_line[4] );
		push(
			@{ @{ $marcow_chains->{'oligo2dnaDB_ids'} }[$acutual_id] },
			@$table_line[0]
		);

		$last_location = @$table_line[1];
	}
	print "we created $i marcow chains\n";
	return $marcow_chains;
}
