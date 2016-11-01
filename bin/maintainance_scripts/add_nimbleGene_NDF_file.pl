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

=head1 add_nimblegene_NDF_file.pl

Add a nimblegene array definition file to the database.

To get further help use 'add_nimblegene_NDF_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::experiment;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::nucleotide_array;
use stefans_libs::database::genomeDB;

my (
	$help,     $debug,      $cleanUP,            $killall,
	$organism, $array_name, $exp_id,             $exp_hyp,
	$exp_aim,  $exp_descr,  $patientID,          $exp_PMID,
	$sci_id,   $sci_group,  $sci_email,          $sci_action_gr,
	$sci_pos,  $database,   $nimbleGene_ndf_file, $maufacturer,
	$sci_name, $array_type
);

Getopt::Long::GetOptions(
	'-organism=s'            => \$organism,
	'-array_name=s'          => \$array_name,
	'-nimbleGene_ndf_file=s' => \$nimbleGene_ndf_file,
	'-database=s'            => \$database,
	'-array_type=s'          => \$array_type,
	"-help"       => \$help,
	"-debug"      => \$debug,
	"-clean_up=s" => \$cleanUP,
	"-killall"    => \$killall
);

if ($help) {
	print helpString();
	exit;
}

if ( defined $cleanUP ) {
	## Ups - we need to clean up behind an old instance....
	&remove_ThreadProblem($cleanUP);
	exit;
}

unless ( defined $organism){
	print helpString("we need the organism information!");
	exit;
}

unless ( defined $array_name){
	print helpString("we can not add to the database without an 'array_name'!");
	exit;
}

unless ( defined $nimbleGene_ndf_file){
	print helpString("we do need a array description file '$nimbleGene_ndf_file'!");
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for add_nimblegene_NDF_file.pl
 
   -organism       :the organism that was used to designe this array
   -array_name     :the array identifier as provided by nimblegene
   -nimbleGene_ndf_file
                   :the ndf file provided by nimblegene, that contains the oligo information
   -array_type
   -database       :the database, that should be used to store the data in (if not set fall back to package default)
   -help           :print this help
   -debug          :verbose output


";
}

my (
	$nucleotide_array, $workingTable, $loggingTable,
	$workLoad,         $loggingEntries
);

$workingTable = workingTable->new($database, $debug);
$loggingTable = loggingTable->new($database, $debug);

$nucleotide_array = nucleotide_array->new( $database, $debug );

my $rv = $workingTable->set_workload(
	{
		'PID'       => $$,
		'programID' => 'add_nimblegene_NDF_file',
		'description' =>
"manufacturer=nimblegene identifier=$array_name organism=$organism ndf_file=$nimbleGene_ndf_file"
	}
);
unless ( defined $rv ) {
	print
"OOPS - we have a stuck process that wants to do the task - please mention that to your database administrator!\n";
	exit;
}

$workLoad = $workingTable->select_workloads_for_PID($$);
$loggingEntries =
  $loggingTable->select_logs_for_description( @$workLoad[0]->{'description'}
	  . "-> oligos have been added to the database" );
unless ( defined @$loggingEntries[0] ) {

## ok we have not done that task - good then we will do it!
	$nucleotide_array->AddDataset(
		{
			'manufacturer' => 'nimblegene',
			'identifier'   => $array_name,
			'array_type'   => $array_type,
			'organism'     => $organism,
			'ndf_file'     => $nimbleGene_ndf_file
		}
	);

	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
			  . "-> oligos have been added to the database"
		}
	);
}
$loggingEntries =
  $loggingTable->select_logs_for_description( @$workLoad[0]->{'description'}
	  . "-> and the entries have been matched to the genome" );
unless ( defined @$loggingEntries[0] ) {
	my $genomeDB = genomeDB->new($database);
	my $chromsomesTable =
	  $genomeDB->GetDatabaseInterface_for_Organism($organism);

	$nucleotide_array->_match_to_genome( $chromsomesTable, $array_name );

	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
			  . "-> and the entries have been matched to the genome"
		}
	);
}

$workingTable->delete_workload_for_PID($$);
