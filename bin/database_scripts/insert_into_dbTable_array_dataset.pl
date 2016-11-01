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

=head1 insert_into_dbTable_array_dataset.pl

INFO_STR

To get further help use 'insert_into_dbTable_array_dataset.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::array_dataset;
use stefans_libs::root;
use Digest::MD5 qw(md5_hex);
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my ( $help, $debug, $IP, $INPUT, $GFF, $database_name, $resorce_path, $array_dataset_scientist_id, $scientistTable_name, $scientistTable_workgroup, $scientistTable_position, $array_dataset_sample_id, $sampleTable_sample_lable, $sampleTable_subject_id, $sampleTable_tissue_id, $array_dataset_access_right, $array_dataset_array_id, $nucleotide_array_identifier, $array_dataset_experiment_id, $experiment_name, $array_dataset_array_type, $array_dataset_table_baseString );

Getopt::Long::GetOptions(
	 "-resource_path=s"  => \$resorce_path,
	 "-database_name=s"  => \$database_name,
         "-array_dataset_scientist_id=s"  => \$array_dataset_scientist_id,
         "-scientistTable_name=s"  => \$scientistTable_name,
	 "-IP=s" => \$IP,
	 "-INPUT=s" => \$INPUT,
	 "-GFF=s" => \$GFF,
         "-scientistTable_workgroup=s"  => \$scientistTable_workgroup,
         "-scientistTable_position=s"  => \$scientistTable_position,
         "-array_dataset_sample_id=s"  => \$array_dataset_sample_id,
         "-sampleTable_sample_lable=s"  => \$sampleTable_sample_lable,
         "-sampleTable_subject_id=s"  => \$sampleTable_subject_id,
         "-sampleTable_tissue_id=s"  => \$sampleTable_tissue_id,
         "-array_dataset_access_right=s"  => \$array_dataset_access_right,
         "-array_dataset_array_id=s"  => \$array_dataset_array_id,
         "-nucleotide_array_identifier=s"  => \$nucleotide_array_identifier,
         "-array_dataset_experiment_id=s"  => \$array_dataset_experiment_id,
         "-experiment_name=s"  => \$experiment_name,
         "-array_dataset_array_type=s"  => \$array_dataset_array_type,
         "-array_dataset_table_baseString=s"  => \$array_dataset_table_baseString,

	 "-help"             => \$help,
	 "-debug"            => \$debug
) or die (helpString());

if ( $help ){
	print helpString( ) ;
	exit;
}

if ( -f "$resorce_path/array_dataset_scientist_id.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_scientist_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_scientist_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/GFF.dta" ) {
	$GFF =  "$resorce_path/GFF.dta";
}
if ( -f "$resorce_path/IP.dta" ) {
        $GFF =  "$resorce_path/GFF.dta";
}
if ( -f "$resorce_path/INPUT.dta" ) {
        $GFF =  "$resorce_path/GFF.dta";
}
if ( -f "$resorce_path/scientistTable_name.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable_workgroup.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable_workgroup.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable_workgroup = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable_position.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable_position.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable_position = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/array_dataset_sample_id.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_sample_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_sample_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/sampleTable_sample_lable.dta" ) { 
       open ( IN , "<$resorce_path/sampleTable_sample_lable.dta" );
       foreach ( <IN> ){
              chomp($_);
              $sampleTable_sample_lable = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/sampleTable_subject_id.dta" ) { 
       open ( IN , "<$resorce_path/sampleTable_subject_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $sampleTable_subject_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/sampleTable_tissue_id.dta" ) { 
       open ( IN , "<$resorce_path/sampleTable_tissue_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $sampleTable_tissue_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/array_dataset_access_right.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_access_right.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_access_right = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/array_dataset_array_id.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_array_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_array_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/nucleotide_array_identifier.dta" ) { 
       open ( IN , "<$resorce_path/nucleotide_array_identifier.dta" );
       foreach ( <IN> ){
              chomp($_);
              $nucleotide_array_identifier = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/array_dataset_experiment_id.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_experiment_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_experiment_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/experiment_name.dta" ) { 
       open ( IN , "<$resorce_path/experiment_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $experiment_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/array_dataset_array_type.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_array_type.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_array_type = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/array_dataset_table_baseString.dta" ) { 
       open ( IN , "<$resorce_path/array_dataset_table_baseString.dta" );
       foreach ( <IN> ){
              chomp($_);
              $array_dataset_table_baseString = $_;
              last;
       }
       close ( IN );
 }


my $dataset = { 
'scientist_id' => $array_dataset_scientist_id,
'scientist' => { 'name' => $scientistTable_name,
'workgroup' => $scientistTable_workgroup,
'position' => $scientistTable_position,
},
'sample_id' => $array_dataset_sample_id,
'sample' => { 'sample_lable' => $sampleTable_sample_lable,
'subject_id' => $sampleTable_subject_id,
'tissue_id' => $sampleTable_tissue_id,
},
'access_right' => $array_dataset_access_right,
'array_id' => $array_dataset_array_id,
'array' => { 'identifier' => $nucleotide_array_identifier,
},
'experiment_id' => $array_dataset_experiment_id,
'experiment' => { 'name' => $experiment_name,
},
'array_type' => $array_dataset_array_type,
'table_baseString' => $array_dataset_table_baseString,
};

$dataset->{'task'} = 'add nimblegene Chip on chip data';
$dataset->{'data'} = {};
$dataset->{'data'} ->{'IP'} = $IP;
$dataset->{'data'} ->{'INPUT'} = $INPUT;
$dataset->{'data'} ->{'GFF'} = $GFF; 

my ( $error, $dataStr) = check_dataset ( $dataset );

if ( $error =~ m/\w/){
	print helpString( $error ) ;
	exit;
}

my $array_dataset = array_dataset->new (  $database_name );

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad , $loggingEntries );

$workingTable = workingTable->new($database_name, $debug);
$loggingTable = loggingTable->new($database_name, $debug);

## and add a working entry

my $rv = $workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'insert_into_dbTable_array_dataset.pl',
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

$array_dataset->AddDataset( $dataset );

## work is finfished - we add a log entry and remove the workload entry!

$loggingTable->set_log ( {
	'start_time' => @$workLoad[0]->{'timeStamp'},
	'evaluation_string' => @$workLoad[0]->{'programID'},
	'description' => @$workLoad[0]->{'description'}
}
);

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
		$dataStr .= "-$value_tag => $dataset->{$value_tag}, " if ( defined $dataset->{$value_tag});
		#next if ( ref( $dataset->{$value_tag} ) eq "HASH" );
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

    command line switches for insert_into_dbTable_array_dataset.pl
 
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
 -array_dataset_access_right
       a access right (scientis, group, all)
 -array_dataset_array_type
       the same as in nucleotide_array_libs.array_type
 -array_dataset_table_baseString
       the table name (!!) containing the data values
 LINKAGE variables:
 -array_dataset_scientist_id
       a link to the scientists table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -scientistTable_name
          the name of the scientif (you)
    -scientistTable_workgroup
          the name of your group leader
    -scientistTable_position
          your position (PhD student, postdoc, .. )
 -array_dataset_sample_id
       a link to the samples table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -sampleTable_sample_lable
          the lable of the storage tubes
    -sampleTable_subject_id
          the link to the subjects table
    -sampleTable_tissue_id
          the link to the tissues table
 -array_dataset_array_id
       a link to the nucleotides array
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -nucleotide_array_identifier
          a identifier for this particular array design
 -array_dataset_experiment_id
       a link to the experiment table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -experiment_name
          The name for the experiment. This name has to be uniwue over all the emperiments.

   -help           :print this help
   -debug          :verbose output

"; 
}
