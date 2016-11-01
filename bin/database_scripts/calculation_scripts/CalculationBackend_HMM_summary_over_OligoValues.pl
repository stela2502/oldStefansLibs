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

=head1 CalculationBackend_HMM_summary_over_OligoValues.pl

A script, that calculates the summary over different ChIP on chip array oligo values as described in PMID 16046496. To get the datasets from the databse it need two sql query strings that can be used to fetch the datasets.

To get further help use 'CalculationBackend_HMM_summary_over_OligoValues.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::statistics::statisticItemList;
use stefans_libs::database::array_calculation_results;

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,
	$debug,
	$database_name,
	$resorce_path,
	$array_calculation_results_name,
	$array_calculation_results_scientist_id,
	$scientistTable_name,
	$scientistTable_workgroup,
	$scientistTable_position,
	$array_calculation_results_work_description,
	$array_calculation_results_program_name,
	$array_calculation_results_program_version,
	$array_calculation_results_access_right,
	$array_calculation_results_array_id,
	$nucleotide_array_identifier,
	$array_calculation_results_experiment_id,
	$experiment_name,
	$sql_input,
	$sql_ip
);

Getopt::Long::GetOptions(
	"-array_calculation_results_name=s" => \$array_calculation_results_name,
	"-array_calculation_results_scientist_id=s" =>
	  \$array_calculation_results_scientist_id,
	"-scientistTable_name=s"      => \$scientistTable_name,
	"-scientistTable_workgroup=s" => \$scientistTable_workgroup,
	"-scientistTable_position=s"  => \$scientistTable_position,
	"-array_calculation_results_access_right=s" =>
	  \$array_calculation_results_access_right,
	"-array_calculation_results_array_id=s" =>
	  \$array_calculation_results_array_id,
	"-nucleotide_array_identifier=s" => \$nucleotide_array_identifier,
	"-array_calculation_results_experiment_id=s" =>
	  \$array_calculation_results_experiment_id,
	"-sql_input=s"            => \$sql_input,
	'-sql_ip=s'               => \$sql_ip,
	"-experiment_name=s"      => \$experiment_name,
	"-jobid=s"                => \$resorce_path,
	"-database_name=s"        => \$database_name,
	"-help"                   => \$help,
	"-debug"                  => \$debug
) or die( helpString() );

if ($help) {
	print helpString();
	exit;
}

if ( defined $resorce_path ) {

	if ( -f "$resorce_path/array_calculation_results_name.dta" ) {
		open( IN, "<$resorce_path/array_calculation_results_name.dta" );
		foreach (<IN>) {
			chomp($_);
			$array_calculation_results_name = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sql_input.dta" ) {
		open( IN, "<$resorce_path/sql_input.dta" );
		foreach (<IN>) {
			chomp($_);
			$sql_input = $_ ;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sql_ip.dta" ) {
		open( IN, "<$resorce_path/sql_ip.dta" );
		foreach (<IN>) {
			chomp($_);
			$sql_ip = $_ ;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/array_calculation_results_scientist_id.dta" ) {
		open( IN, "<$resorce_path/array_calculation_results_scientist_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$array_calculation_results_scientist_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/scientistTable_name.dta" ) {
		open( IN, "<$resorce_path/scientistTable_name.dta" );
		foreach (<IN>) {
			chomp($_);
			$scientistTable_name = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/scientistTable_workgroup.dta" ) {
		open( IN, "<$resorce_path/scientistTable_workgroup.dta" );
		foreach (<IN>) {
			chomp($_);
			$scientistTable_workgroup = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/scientistTable_position.dta" ) {
		open( IN, "<$resorce_path/scientistTable_position.dta" );
		foreach (<IN>) {
			chomp($_);
			$scientistTable_position = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/array_calculation_results_access_right.dta" ) {
		open( IN, "<$resorce_path/array_calculation_results_access_right.dta" );
		foreach (<IN>) {
			chomp($_);
			$array_calculation_results_access_right = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/array_calculation_results_array_id.dta" ) {
		open( IN, "<$resorce_path/array_calculation_results_array_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$array_calculation_results_array_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/nucleotide_array_identifier.dta" ) {
		open( IN, "<$resorce_path/nucleotide_array_identifier.dta" );
		foreach (<IN>) {
			chomp($_);
			$nucleotide_array_identifier = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/array_calculation_results_experiment_id.dta" ) {
		open( IN,
			"<$resorce_path/array_calculation_results_experiment_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$array_calculation_results_experiment_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/experiment_name.dta" ) {
		open( IN, "<$resorce_path/experiment_name.dta" );
		foreach (<IN>) {
			chomp($_);
			$experiment_name = $_;
			last;
		}
		close(IN);
	}

}

my @progName = split ( "/",$0);

$array_calculation_results_work_description =
"calculation HMM summary statiustics for IP values '$sql_ip' and input values '$sql_input'";
$array_calculation_results_program_name    = @progName[@progName-1];
$array_calculation_results_program_version = $VERSION;

my $dataset = {
	'name'         => $array_calculation_results_name,
	'scientist_id' => $array_calculation_results_scientist_id,
	'scientist'    => {
		'id'        => $array_calculation_results_scientist_id,
		'name'      => $scientistTable_name,
		'workgroup' => $scientistTable_workgroup,
		'position'  => $scientistTable_position,
	},
	'work_description' => $array_calculation_results_work_description,
	'program_name'     => $array_calculation_results_program_name,
	'program_version'  => $array_calculation_results_program_version,
	'access_right'     => $array_calculation_results_access_right,
	'array_id'         => $array_calculation_results_array_id,
	'array'            => {
		'id'         => $array_calculation_results_array_id,
		'identifier' => $nucleotide_array_identifier,
	},
	'experiment_id' => $array_calculation_results_experiment_id,
	'experiment'    => {
		'id'   => $array_calculation_results_experiment_id,
		'name' => $experiment_name,
	}
};

my ( $error, $dataStr ) = check_dataset($dataset);


if ($help) {
	print helpString();
	exit;
}

unless ( defined $sql_input ) {
	print helpString(
		"Sorry, but we need to know how to get the input values ('-sql_input')"
	);
	exit;
}
unless ( defined $sql_ip ) {
	print helpString(
		"Sorry, but we need to know how to get the ip values ('-sql_ip')");
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );

	return "

$errorMessage

    command line switches for CalculationBackend_HMM_summary_over_OligoValues.pl
 
    this script takes either a <TAB> separated table_file 
    containing all neccessary variable names as table header (-table_file) 
    or a list values as descibed:

    There are three possible variable types:
    1. the NEEDED variables 
       those have to be defined to add to the table
    2. the OPTIONAL values
       those might be ommitted
    3. the LINKAGE values
       those might drastically reduce the amount of variables needed
       as the render the downstream variables obsolete 
       if those downstream values are already defined in the database

    The level of indention indicates the stucture:
    the first level is needed -
        the second level is obsolete if you have added all LINKAGE 
        values of the upper level. Each LINKAGE value skipps another set of variables.
    This info applies for all other indention levels.
    
 command line switches for EXECUTABLE

 NEEDED values:
 -array_calculation_results_name
       a name for this calculation - has to be unique with the version of the program
 -array_dataset_ids
       the ids of the dataset we should include into the evaluation
 -array_calculation_results_access_right
       a access right (scientis, group, all)
 LINKAGE variables:
 -array_calculation_results_scientist_id
       a link to the scientists table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -scientistTable_name
          the name of the scientif (you)
    -scientistTable_workgroup
          the name of your group leader
    -scientistTable_position
          your position (PhD student, postdoc, .. )
 -array_calculation_results_array_id
       a link to the nucleotides array
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -nucleotide_array_identifier
          a identifier for this particular array design
 -array_calculation_results_experiment_id
       a link to the experiment table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -experiment_name
          The name for the experiment. This name has to be uniwue over all the emperiments.

   -help           :print this help
   -debug          :verbose output

";
}


## now we set up the logging functions....

my (
	$task_description, $workingTable, $loggingTable,
	$workLoad,         $loggingEntries
);

$workingTable = workingTable->new( $database_name, $debug );
$loggingTable = loggingTable->new( $database_name, $debug );

## and add a working entry

$task_description =
"calculate Tilemap summary statistics from IP values '$sql_ip' and INPUT values '$sql_input'";

$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'CalculationBackend_HMM_summary_over_OligoValues.pl',
		'description' => $task_description
	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description($task_description);
unless ( defined @$loggingEntries[0] ) {
	my ( $sth, $rv, $statisticItemList );
	$statisticItemList = statisticItemList->new($debug);
	## 1. the IP values
	$sql_ip .= " limit 100 " if ( $debug);
	unless ($sth = $workingTable->{'dbh'}->prepare( $sql_ip )){
		die "we could not prepare '$sql_ip;' due to this sql error:\n".$workingTable->{'dbh'}->errstr();
	}
	$rv = $sth->execute();
	unless ( $rv > 0 ){
		die "sorry, but the query '$sql_ip' did not result in a dataset! (rv = '$rv')\n";
	}
	$rv =  $sth->fetchall_arrayref();
	$statisticItemList->AddData( $rv , 'IP' );
	
	## 2. the INPUT data
	$sql_input .= " limit 100 " if ( $debug);
	unless ($sth = $workingTable->{'dbh'}->prepare( $sql_input )){
		die "we could not prepare '$sql_input;' due to this sql error:\n".$workingTable->{'dbh'}->errstr();
	}
	$rv = $sth->execute();
	unless ( $rv > 0 ){
		die "sorry, but the query '$sql_input' did not result in a dataset! (rv = '$rv')\n";
	}
	$rv =  $sth->fetchall_arrayref();
	$statisticItemList->AddData( $rv , 'control' );
	
	$rv = $statisticItemList->CalculateTStatistics();
	my ( $oligo_name );
	
	$dataset->{'data'} = $rv;
	my $array_calculation_results = array_calculation_results->new( $database_name, $debug );
	$array_calculation_results -> AddDataset ( $dataset ) ;


	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

}

$workingTable->delete_workload_for_PID($$);

sub check_dataset {
	my ( $dataset, $variable_name ) = @_;
	my $error   = '';
	my $dataStr = '';
	my ( $temp, $temp_data );
	foreach my $value_tag ( keys %$dataset ) {
		next if ( $value_tag eq "array_calculation_results_work_description" );
		$dataStr .= "-$value_tag => $dataset->{$value_tag}, "
		  if ( defined $dataset->{$value_tag}
			&& !( ref( $dataset->{$value_tag} ) eq "HASH" ) );

		#next if ( ref( $dataset->{$value_tag} ) eq "HASH" );
		next if ( $value_tag eq "id" );
		unless ( defined $dataset->{$value_tag} ) {
			$temp = $value_tag;
			$temp =~ s/_id//;
			if ( ref( $dataset->{$temp} ) eq "HASH" ) {
				( $temp, $temp_data ) = check_dataset( $dataset->{$temp} );
				$dataStr .= $temp_data;
				$error .=
"we miss the data for value $value_tag and the downstream table:\n"
				  . $temp
				  if ( $temp =~ m/\w/ );
			}
			else {
				$error .= "we miss the data for value $value_tag\n";
			}
		}
	}

	return ( $error, $dataStr );
}
