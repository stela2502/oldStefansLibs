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

=head1 match_nucleotideArray_to_genome.pl

do what the name may indicate

To get further help use 'match_nucleotideArray_to_genome.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::genomeDB;
use stefans_libs::database::nucleotide_array;
use strict;
use warnings;

my ( $help, $debug, $organism, $database, $identifier);

Getopt::Long::GetOptions(
	 '-organism=s'         => \$organism,
	 '-database_name=s'    => \$database,
	 '-array_identifier=s' => \$identifier,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

unless ( defined $organism ){
	print helpString( "we need the -organism") ;
	exit;
}

unless ( defined $identifier ){
	print helpString( "we need the -identifier" ) ;
	exit;
}

if ( $help ){
	print helpString( ) ;
	exit;
}



sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for match_nucleotideArray_to_genome.pl
   -organism         :the organism you want to match the oligos to
   -array_identifier :the array identifier for the array oligos you want to use
   -database         :the database you want to use (if not the default one)
   -help             :print this help
   -debug            :verbose output

"; 
}

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad  );
my $genomeDB        = genomeDB->new($database);
$database = $genomeDB->{'database_name'};
$workingTable = workingTable->new($database, $debug);
$loggingTable = loggingTable->new($database, $debug);

## and add a working entry


my $chromsomesTable = $genomeDB->GetDatabaseInterface_for_Organism($organism);

my $task_description = " organism = $organism, identifier = $identifier";

$workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'match_nucleotideArray_to_genome.pl',
			'description' => $task_description
		}
);
$workLoad = $workingTable->select_workloads_for_PID ( $$ );
my $loggingEntries = $loggingTable->select_logs_for_description ( $task_description );
unless ( defined @$loggingEntries[0]){


my $nucleotide_array = nucleotide_array->new( $database );

$nucleotide_array->Match_NucleotideArray_to_Genome( { 'identifier' => $identifier },
	{ 'id' =>  $chromsomesTable->{'genomeID'}} );

## work is finfished - we add a log entry and remove the workload entry!

$loggingTable->set_log ( {
	'start_time' => @$workLoad[0]->{'timeStamp'},
	'programID' => @$workLoad[0]->{'evaluation_string'},
	'description' => @$workLoad[0]->{'description'}
});

}

$workingTable->delete_workload_for_PID($$);

