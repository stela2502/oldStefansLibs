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

=head1 batch_insert_phenotypes.pl

A script to insert tab separated table documents containing phenotypic data into the database.

To get further help use 'batch_insert_phenotypes.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::tableHandling;
use stefans_libs::database::subjectTable;
use strict;
use warnings;

my ( $help, $debug, $database, $organism_tag, $pattern, $infile);

Getopt::Long::GetOptions(
	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 '-phenotypeFile=s'  => \$infile,
	 '-organism_tag=s'   => \$organism_tag,
	 "-p4cS=s"           => \$pattern
);

my $error = '';
if ( $help ){
	print helpString( ) ;
	exit;
}
unless ( defined $pattern){
	$error .= "  we need a -p4cS\n";
}

unless ( defined $infile ){
	$error .= "  we need a -phenotypeFile\n";
}
elsif ( ! (-f $infile) ){
	$error .= "  we can not access the file $infile\n";
}
unless ( defined $organism_tag){
	warn "  we do not have an organism_tag - that might (ONLY) work if the subjects are known to the database\n";
}

if ( $error =~ m/\w+/){
	print &helpString( $error );
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
$errorMessage
 command line switches for batch_insert_phenotypes.pl
 
   -phenotypeFile  :a tab separated file with phenotype informations.
                    The phenotypes have to be known to the database and
                    the first line has to contain the subject_identifiers
   -p4cS           :A pattern that can be used to identify the comumns containing 
                    the subject_identififers
   -organism_tag   :the name of the organism, the subjects come from
   -help           :print this help
   -debug          :verbose output

"; 
}

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad, $loggingEntries, $subjectTable );

$workingTable = workingTable->new($database, $debug);
$loggingTable = loggingTable->new($database, $debug);

## and add a working entry

$workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'batch_insert_phenotypes.pl',

			'description' =>
			  "DESCRIBE THIS TASK!"
		}
);
$workLoad = $workingTable->select_workloads_for_PID ( $$ );
$loggingEntries = $loggingTable->select_logs_for_description ( "DESCRIBE THIS TASK!"."-> WITH SOME DETAILS?" );
unless ( defined @$loggingEntries[0]){

my ( $tableHandling, $lineCount, @dataColumnHeaders, 
@subjectIDs, $infoPositions, @dataset, $dataPositions, $interface, $phenotype_name, @report_header );

$tableHandling = tableHandling->new();
$subjectTable = subjectTable->new(root::getDBH('root'),$debug);

open( IN, "<$infile" )
  or die "could not open array data file '$infile' in batchStatistic.pl\n";
print "opened the expression array dataset $infile\n";
$lineCount = 0;

while (<IN>) {
	$lineCount++;
	chomp $_;
	$_ =~ s/,/\./g;  ## change from european decimal separator',' to english '.'

	if ( $lineCount == 1 ) {
		## we have to create groups for each test type
		print
"\nwe try to select the data containing columns using the pattern $pattern\n"
		  if ($debug);
		$dataPositions = $tableHandling->identify_columns_of_interest_patternMatch(
				$_, $pattern );
			@dataset = $tableHandling->get_column_entries_4_columns(
			$_,$dataPositions );
		$infoPositions = [0];
		die
"we got no data to evaluate! ( @dataColumnHeaders )\nheader line\n$_\n"
		  unless ( defined $dataset[0] );
		foreach my $ident( @dataset ){
			push ( @subjectIDs, $subjectTable->AddDataset( {'identifier' => $ident, 'organism' => { 'organism_tag' => $organism_tag }}));
		}
		print "we have some subject ids:\nidentifier -> id\n";
		for (my $i = 0; $i < @subjectIDs;$i++){
			print "$dataset[$i] -> $subjectIDs[$i]\n";
		}
		push( @report_header , 'subject_identifier');
		next;
	}
	($phenotype_name) =  $tableHandling->get_column_entries_4_columns(
			$_, $infoPositions);
	$interface = $subjectTable->connect_2_phenotype( $phenotype_name );
	if ( ref($interface) eq ""){
		warn "$interface" ;
		next;
	}
	print "we try to insert into ".$interface->TableName()."\n";
	push( @report_header , $phenotype_name);
	@dataset = $tableHandling->get_column_entries_4_columns(
			$_, $dataPositions);
	for (my $i = 0; $i < @subjectIDs;$i++){
		$interface->AddDataset( { 'subject_id' => $subjectIDs[$i], 'value' => $dataset[$i]}) if ( $dataset[$i] =~ m/\w/ );
	}
	
}
my $value;
my $data = $subjectTable->getArray_of_Array_for_search({
 	'search_columns' => ['subjectTable.identifier','value'],
 	'where' => [['subjectTable.id', "=", "my_value"]],
 	}, \@subjectIDs);
 	print "the data in the database:\n".join("\t",@report_header)."\n";
 	foreach my $array ( @$data ){
 		for(my $i = 0; $i < @$array; $i++){
 			@$array[$i] = '' unless ( defined @$array[$i]);
 		}
 		print join("\t",@$array)."\n";
 	}

$loggingTable->set_log ( {
	'start_time' => @$workLoad[0]->{'timeStamp'},
	'programID' => @$workLoad[0]->{'programID'},
	'description' => @$workLoad[0]->{'description'}."-> WITH SOME DETAILS?"
});

}

$workingTable->delete_workload_for_PID($$);

