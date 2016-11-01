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

=head1 export4SignalMap_using_knownGFF_fileStructure.pl

A script that can change the data label and the data values of a given SignalMap GFF file to export a calculated dataset in order to visualize it with SignalMap.

To get further help use 'export4SignalMap_using_knownGFF_fileStructure.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::array_calculation_results;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;

use strict;
use warnings;

my ( $help, $debug, $database, $old_gff_file, $new_gff_file, $table_id );

Getopt::Long::GetOptions(
	"-help"                             => \$help,
	"-debug"                            => \$debug,
	"-database=s"                       => \$database,
	'-old_gff_file=s'                   => \$old_gff_file,
	'-new_gff_file=s'                   => \$new_gff_file,
	'-calculated_datasets_table_id=s' => \$table_id
);
my $error = '';
if ($help) {
	print helpString();
	exit;
}
unless ( defined $old_gff_file ){
	$error .= 
"we need the old GFF file - please take care, that the array_id matches!!";
}
unless ( -f $old_gff_file ) {
	$error .= 
"we need the old GFF file - please take care, that the array_id matches!!";
}
if ( ! ( defined $new_gff_file ) ){
	$error .= 
"we need the 'new_gff_file'";
}
if ( (-f $new_gff_file ) ) {
	$error .= 
"Sorry, but the new file '$new_gff_file' already exists - "
."please specify another file or delete this file";
}
unless ( defined $table_id ) {
	$error .= 
"Sorry, but we definitely need to know the calculated_datasets_table_id!";
}

if ( $error =~ m/\w/){
	print helpString($error);
	exit;
}
my ( $array_calculation_results, $dataset );
$array_calculation_results =
  array_calculation_results->new( $database, $debug );
my ( $oligoDB, $dataDescription ) =
  $array_calculation_results->GetSearchInterface( [$table_id] );
unless ( defined $oligoDB ) {
	print helpString(
		"Sorry, but we have no calculated array dataset for id '$table_id'".
		"we used the search $array_calculation_results->{'complex_search'}\n");
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for export4SignalMap_using_knownGFF_fileStructure.pl
 
   -help           :print this help
   -debug          :verbose output
   -database       :the name of the database (default = genomeDB)
   -old_gff_file   :the source gff file containing the genomic positions of the oligos
   -new_gff_file   :a new file that will contain the old genomic positions together with the new values
   -calculated_datasets_table_id:
                    the id of the calculated dataset you want to export to the gff file

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
		'programID'   => 'export4SignalMap_using_knownGFF_fileStructure.pl',
		'description' => "export calculation results for array_calculation_results.id=$table_id into gff file $old_gff_file and save the results to $new_gff_file"
	}
);
$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description(
	"export calculation results for array_calculation_results.id=$table_id into gff file $old_gff_file and save the results to $new_gff_file" );
unless ( defined @$loggingEntries[0] ) {
	
	## 1. read in the GFF file data structure
	my $gffFile = gffFile->new( $debug );
	my $dataset = $gffFile->GetData( $old_gff_file, 'preserve_structure');

	my ( $root, $id, $mean, $var, $stddev, $data, $sql, $rv, $sth, $new_oligo_data, $dataRow );
	
	$sql = $oligoDB->create_SQL_statement(
		{
			'search_columns' => [ 'oligo_name', 'oligo_array_values.value', 'oligoDB.sequence' ]
		}
	);
	print "we select the data values using this sql statement '$sql;'\n";
	
	$root = root->new();
	## 4. get the data
	$sth = $workingTable->{'dbh'}->prepare($sql);
	$rv = $sth->execute();
	$rv = $sth ->fetchall_arrayref();
	foreach $dataRow (@$rv) {
		$new_oligo_data->{@$dataRow[0]} = [ @$dataRow[1], @$dataRow[2] ] ;
	}
	foreach $dataRow ( @$dataset ){
		$dataRow->{'value'} = @{$new_oligo_data->{$dataRow->{'oligoID'}}}[0];
		$dataRow->{'description'} = "seq=".@{$new_oligo_data->{$dataRow->{'oligoID'}}}[1].";oligoID=$dataRow->{'oligoID'}";
	}
	$gffFile->{'data_handler'} = @$dataDescription[0]->{'summary_program_name'};
	$gffFile->{'data_label'} = @$dataDescription[0]->{'name'};
	$gffFile->writeData ( $dataset, $new_gff_file );


}

$workingTable->delete_workload_for_PID($$);

