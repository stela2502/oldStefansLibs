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

=head1 add_NCBI_SNP_chr_rpts_files.pl

A script that can import NCBI chr_rpts SNP tables into the databse. 
The files need to be downloaded by the user. Take care to download 
the right files for the most actual genome version, that is stored in the databse.

To get further help use 'add_NCBI_SNP_chr_rpts_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::genomeDB;
use strict;
use warnings;

my ( $help, $debug, $genome, @files, $database );

Getopt::Long::GetOptions(
	"-help"                => \$help,
	"-debug"               => \$debug,
	"-database=s"          => \$database,
	"-genome_string=s"     => \$genome,
	"-chr_rpts_files=s{,}" => \@files
);

if ($help) {
	print helpString();
	exit;
}
unless ( defined $genome ) {
	print helpString("We need the genome identifer to import the SNP data");
	exit;
}
unless ( defined $files[0] ) {
	print helpString("We need at least one NCBI chr_rpts file do import data");
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for add_NCBI_SNP_chr_rpts_files.pl
 
   -help           :print this help
   -debug          :verbose output
   -database       :the name of the database to use (default = 'genomeDB')
   -genome_string  :the genome string (i.a. H_sapiens as used by the NCBI to describe the genome)
   -chr_rpts_files :a list of files to add
   
";
}

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad, $loggingEntries );

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );

## and add a working entry

$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'add_NCBI_SNP_chr_rpts_files.pl',
		'description' => "Add the files @files to genome $genome"
	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description(
	"Add the files @files to genome $genome");
unless ( defined @$loggingEntries[0] ) {

	my ( $genomeDB, $genomeInterface, $rv, $gbFile_accs, $lineArray, $SNP_table,
		@line );
	## 1. select the genome interface
	$genomeDB = genomeDB->new( $database, $debug );
	$genomeInterface =
	  $genomeDB->getGenomeHandle_for_dataset( { 'organism_tag' => $genome } );
	$genomeInterface = $genomeInterface->get_rooted_to("gbFilesTable");

	## 2. select all usable accs
	#my $sql = "select id, acc from ". $genomeInterface->TableName();
	$rv = $genomeInterface->getArray_of_Array_for_search({
 	'search_columns' => ['gbFilesTable.id', 'gbFilesTable.acc'],
 	'order_by' => ['gbFilesTable.id'],
 	});
#	print "we use this sql statement: '$sql;'\n" if ( $debug);
#	my $sth;
#	unless ( $sth = $genomeInterface->{'dbh'} ->prepare( $sql) ) {
#		die "we could not execute sql statement '$sql;'\n". $genomeInterface->{'dbh'}->errstr();
#	}
#	$rv = $sth -> execute();
	unless ( scalar(@$rv) > 0 ){
		die "Sorry, but we got no data for query '$genomeInterface->{'complex_search'};'\n";
	}

	foreach $lineArray (@$rv) {
		$gbFile_accs->{ @$lineArray[1] } = @$lineArray[0];
		print "we got an acc from the database: '@$lineArray[1]', @$lineArray[0]\n" if ($debug);
	}

	## 3. get me the SNP_Table interface
	$SNP_table = $genomeInterface->get_SNP_Table_interface();
	
	## THIS CHECK is done in this class - might speed up the whole process!!
	my $saveStorage = @{$SNP_table ->{ 'table_definition' }->{'variables'}}[1]->{'data_handler'};
	@{$SNP_table ->{ 'table_definition' }->{'variables'}}[1]->{'data_handler'} = undef;
	## THIS CHECK is done in this class - might speed up the whole process!!
	
	## 4. insert all the rsIDs...
	foreach my $SNP_file (@files) {
		print "I will open the file $SNP_file\n" if ($debug);
		open( IN, "<$SNP_file" );
		while (<IN>) {
			chop($_);
			@line = split( "\t", $_ );
			if ( defined $gbFile_accs->{"$line[7].$line[8]"} ) {
				$SNP_table->AddDataset(
					{
						'rsID'      => "rs$line[0]",
						'gbFile_id' => $gbFile_accs->{"$line[7].$line[8]"},
						'position'  => $line[10],
						'withdrawn' => $line[2],
						'validationStatus' => $line[16],
						'minorAllele' => '',
						'majorAllele' => ''
					}
				);
			}
		}
	}

## work is finfished - we add a log entry and remove the workload entry!

	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

}

$workingTable->delete_workload_for_PID($$);

