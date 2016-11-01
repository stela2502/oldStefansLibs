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

=head1 insert_into_dbTable_experiment.pl

INFO_STR

To get further help use 'insert_into_dbTable_experiment.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::experiment;
use stefans_libs::root;
use Digest::MD5 qw(md5_hex);
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my ( $help, $debug, $database_name, $resorce_path, $experiment_name, $experiment_project_id, $project_table_name, $experiment_hypothesis_id, $hypothesis_table_hypothesis_name, $experiment_description, $experiment_aim, $experiment_conclusion, $experiment_PMID );

Getopt::Long::GetOptions(
         "-experiment_name=s"  => \$experiment_name,
         "-experiment_project_id=s"  => \$experiment_project_id,
         "-project_table_name=s"  => \$project_table_name,
         "-experiment_hypothesis_id=s"  => \$experiment_hypothesis_id,
         "-hypothesis_table_hypothesis_name=s"  => \$hypothesis_table_hypothesis_name,
         "-experiment_description=s"  => \$experiment_description,
         "-experiment_aim=s"  => \$experiment_aim,
         "-experiment_conclusion=s"  => \$experiment_conclusion,
         "-experiment_PMID=s"  => \$experiment_PMID,

	 "-jobid=s"          => \$resorce_path,
	 "-database_name=s"  => \$database_name,
	 "-help"             => \$help,
	 "-debug"            => \$debug
) or die (helpString());

if ( $help ){
	print helpString( ) ;
	exit;
}

if ( defined $resorce_path ){

if ( -f "$resorce_path/experiment_name.dta" ) { 
       open ( IN , "<$resorce_path/experiment_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_project_id.dta" ) { 
       open ( IN , "<$resorce_path/experiment_project_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_project_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/project_table_name.dta" ) { 
       open ( IN , "<$resorce_path/project_table_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $project_table_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_hypothesis_id.dta" ) { 
       open ( IN , "<$resorce_path/experiment_hypothesis_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_hypothesis_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/hypothesis_table_hypothesis_name.dta" ) { 
       open ( IN , "<$resorce_path/hypothesis_table_hypothesis_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $hypothesis_table_hypothesis_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_description.dta" ) { 
       open ( IN , "<$resorce_path/experiment_description.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_description = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_aim.dta" ) { 
       open ( IN , "<$resorce_path/experiment_aim.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_aim = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_conclusion.dta" ) { 
       open ( IN , "<$resorce_path/experiment_conclusion.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_conclusion = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_PMID.dta" ) { 
       open ( IN , "<$resorce_path/experiment_PMID.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_PMID = $_;
              last;
       }
       close ( IN );
 }


}

my $dataset = { 
'name' => $experiment_name,
'project_id' => $experiment_project_id,
'project' => { 
'id' => $experiment_project_id,
'name' => $project_table_name,
},
'hypothesis_id' => $experiment_hypothesis_id,
'hypothesis' => { 
'id' => $experiment_hypothesis_id,
'hypothesis_name' => $hypothesis_table_hypothesis_name,
},
'description' => $experiment_description,
'aim' => $experiment_aim,
'conclusion' => $experiment_conclusion,
'PMID' => $experiment_PMID,
};


my ( $error, $dataStr) = check_dataset ( $dataset );

if ( $error =~ m/\w/){
	print helpString( $error ) ;
	exit;
}

my $experiment = experiment->new (  $database_name );

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad , $loggingEntries,  $errorTable);

$workingTable = workingTable->new($database_name, $debug);
$loggingTable = loggingTable->new($database_name, $debug);
$errorTable = errorTable->new($database_name, $debug);

## and add a working entry

my $rv = $workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'insert_into_dbTable_experiment.pl',
			'description' =>
			  "the dataset: $dataStr"
		}
);

unless ( defined $rv) {
	print "OOPS - we have a stuck process that wants to do the task - please mention that to your database administrator!\n";
	exit;
}

$workLoad = $workingTable->select_workloads_for_PID ( $$ );
$loggingEntries = $loggingTable->select_logs_for_description ( "the dataset: $dataStr" );
unless ( defined @$loggingEntries[0]){

$experiment->AddDataset( $dataset );

my $id =$experiment->_return_unique_ID_for_dataset( $dataset );

## work is finfished - we add a log entry and remove the workload entry!
if ( defined $id && $id > 0 ){
	$loggingTable->set_log ( {
		'start_time' => @$workLoad[0]->{'timeStamp'},
		'programID' => @$workLoad[0]->{'programID'},
		'description' => @$workLoad[0]->{'description'}
	} );
}
else {
	warn "insert_into_dbTable_experiment.pl -> we could not add the data $dataStr\n";
	$errorTable -> AddDataset ( { 'name' => 'insert_into_dbTable_experiment.pl', 'description' => $dataStr } );
}

}
else{
	print 'OOPS - the dataset was already present in the database!
';
} 

$workingTable->delete_workload_for_PID($$);


sub check_dataset{
	my ( $dataset, $variable_name ) = @_;
	my $error = '';
	my $dataStr = '';
	my ($temp, $temp_data);
	foreach my $value_tag ( keys %$dataset ){
		$dataStr .= "-$value_tag => $dataset->{$value_tag}, " 
			if ( defined $dataset->{$value_tag} 
				&& ! (ref( $dataset->{$value_tag} ) eq "HASH") );
		#next if ( ref( $dataset->{$value_tag} ) eq "HASH" );
		next if ( $value_tag eq "id" );
		unless (defined $dataset->{$value_tag} ){
			$temp = $value_tag;
			$temp =~ s/_id//;
			if (  ref( $dataset->{$temp} ) eq "HASH" ){
				($temp, $temp_data) = check_dataset ( $dataset->{$temp} );
				$dataStr .= $temp_data;
				$error .= "we miss the data for value $value_tag and the downstream table:\n".$temp if ( $temp =~ m/\w/) ;
			}
			else {
				$error .= "we miss the data for value $value_tag\n";
			}
		}
	}
	
	return ($error, $dataStr);
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	
 	return "

$errorMessage

    command line switches for insert_into_dbTable_experiment.pl
 
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
 -experiment_name
       The name for the experiment. This name has to be uniwue over all the emperiments.
 -experiment_description
       a informative description of the experiment - please!
 -experiment_aim
       the aim of this experiment
 -experiment_conclusion
       the final conclusion that can be drawn from this experiment
 -experiment_PMID
       
 LINKAGE variables:
 -experiment_project_id
       the id of the project the experiment belongs to
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -project_table_name
          the name of the project
 -experiment_hypothesis_id
       the id of the main hypothesis of this experiment
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -hypothesis_table_hypothesis_name
          a name for the hypothesis unique in the whole database

   -help           :print this help
   -debug          :verbose output

"; 
}
