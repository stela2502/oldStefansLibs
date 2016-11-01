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

=head1 Wilcox_over_two_search_results.pl

This script needs to have two sql queries to get data from the database. I expect you to give me some selection queries from the array_datasets which I will perform and correlate the resulting comlumns according to there occurrance in the results. The datasets will be stored in a calculation results table, so be absolutely shure, that you add a order by id to the query for the datasets

To get further help use 'Wilcox_over_two_search_results.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::array_calculation_results;
use stefans_libs::array_analysis::correlatingData::Wilcox_Test;
use stefans_libs::database::nucleotide_array;
use stefans_libs::database::array_dataset;
#use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;

use strict;
use warnings;

my $VERSION = "1.00";

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
	@array_dataset_ids_A,$oldGFF_file,
	@array_dataset_ids_B, $outpath
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
	"-experiment_name=s"      => \$experiment_name,
	'-array_dataset_ids_groupA=s{,}' => \@array_dataset_ids_A,
	'-array_dataset_ids_groupB=s{,}' => \@array_dataset_ids_B,
	"-jobid=s"                => \$resorce_path,
	"-database_name=s"        => \$database_name,
	"-sampleGFF_File=s"       => \$oldGFF_file,
	"-outpath=s" => \$outpath,
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
	if ( -f "$resorce_path/array_dataset_ids_A.dta" ) {
		open( IN, "<$resorce_path/array_dataset_ids_A.dta" );
		foreach (<IN>) {
			chomp($_);
			push( @array_dataset_ids_A, $_ );
		}
		close(IN);
	}
	if ( -f "$resorce_path/array_dataset_ids_B.dta" ) {
		open( IN, "<$resorce_path/array_dataset_ids_B.dta" );
		foreach (<IN>) {
			chomp($_);
			push( @array_dataset_ids_B, $_ );
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
'comparison between the array_dataset ('
  . join( ", ", @array_dataset_ids_A ) . ')'.
  " and the array_datasets (". join( ", ", @array_dataset_ids_B ) . ')';

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
	},
};

my ( $error, $dataStr ) = check_dataset($dataset);

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

my ( $db_1, $db_2, $interface_A, $interface_B,$temp, $result, @temp );
my $array_calculation_results = array_calculation_results->new($database_name);
my ( $workingTable, $loggingTable, $workLoad, $loggingEntries, $errorTable, $array_dataset, $subjectIDs );

$workingTable = workingTable->new( $database_name, $debug );
$loggingTable = loggingTable->new( $database_name, $debug );
$errorTable = errorTable->new( $database_name, $debug );

my $rv = $workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => @progName[@progName-1],
		'description' => "the dataset: $dataStr"
	}
);

unless ( defined $rv ) {
	print
"OOPS - we have a stuck process that wants to do the task - please mention that to your database administrator!\n";
	exit;
}

$workLoad = $workingTable->select_workloads_for_PID($$);
$loggingEntries =
  $loggingTable->select_logs_for_description("the dataset: $dataStr");
unless ( defined @$loggingEntries[0] ) {
	$dataset->{'work_description'} .= $dataStr;
	my $nucleotide_array_lib = nucleotide_array->new( $database_name, $debug );
	$array_dataset = array_dataset->new(root::getDBH('root'),0);
	
	my $oligoDB =
	  $nucleotide_array_lib->Get_OligoDB_for_ID( $dataset->{'array_id'} );
	## 2. get the table names for the array_dataset ids
	
	$rv = $array_dataset->getArray_of_Array_for_search({
 	'search_columns' => ["array_datasets.table_baseString", "samples.subject_id"],
 	'where' => [["array_datasets.id", '=', 'my_value']],
 	'order_by' => ['samples.subject_id']
 	}, [@array_dataset_ids_A]);
 	## 3. create the oligo_array_values entries inside the oligoDB
 	$subjectIDs->{'A'} = '';
 	$subjectIDs->{'B'} = '';
	push(
		@{ $oligoDB->{'table_definition'}->{'variables'} },
		{
			'name'         => 'id',
			'data_handler' => 'oligo_array_values',
			'type'         => 'INTEGER',
			'description'  => "this is an artefact of @progName[@progName-1]",
			'NULL'         => 0
		}
	);
	print "we have gotten the relevant data tables using the search $array_dataset->{'complex_search'}\n";
	;
	$oligoDB->{'data_handler'}->{'oligo_array_values'} = [];
	foreach my $dataRow (@$rv) {
		my $oligo_array_values =
		  oligo_array_values->new( $workingTable->{'dbh'}, $debug );
		$oligo_array_values->{'_tableName'} = @$dataRow[0];
		$subjectIDs->{'A'} .= @$dataRow[1].";";
		push(
			@{ $oligoDB->{'data_handler'}->{'oligo_array_values'} },
			$oligo_array_values
		);
	}

	my $sqlA = $oligoDB->create_SQL_statement(
		{
			'search_columns' => [ 'oligo_name', 'oligo_array_values.value' ],
			'order_by' => [ $oligoDB->TableName().".id"],
			#'limit' => 'limit 100'
		}
	);
	print "we select the data values using this sql statement '$sqlA;'\n";

	$rv = $array_dataset->getArray_of_Array_for_search({
 	'search_columns' => ["array_datasets.table_baseString", "samples.subject_id"],
 	'where' => [["array_datasets.id", '=', 'my_value']],
 	'order_by' => ['samples.subject_id']
 	}, [@array_dataset_ids_B]);
 	
	$oligoDB->{'data_handler'}->{'oligo_array_values'} = [];
	foreach my $dataRow (@$rv) {
		my $oligo_array_values =
		  oligo_array_values->new( $workingTable->{'dbh'}, $debug );
		$oligo_array_values->{'_tableName'} = @$dataRow[0];
		$subjectIDs->{'B'} .= @$dataRow[1].";";
		push(
			@{ $oligoDB->{'data_handler'}->{'oligo_array_values'} },
			$oligo_array_values
		);
	}
	my $sqlB = $oligoDB->create_SQL_statement(
		{
			'search_columns' => [ 'oligo_name', 'oligo_array_values.value' ],
			'order_by' => [ $oligoDB->TableName().".id"],
			#'limit' => 'limit 100'
		}
	);
	if ( $subjectIDs->{'A'} eq $subjectIDs->{'B'}){
		## we can do a paired test!!!
		print "We will calculate a paired Wilcox signed rank test!\n";
	}
	else {
		print "the subject_ids \n$subjectIDs->{'A'} \ndo not match the subjct_ids $subjectIDs->{'B'}\n";
	}
	print "we select the other data values using this sql statement '$sqlB;'\n";
	my ( $dataA, $dataB,$sth);
	$sth = $workingTable->{'dbh'}->prepare($sqlA);
	$rv = $sth->execute();
	$rv = $sth ->fetchall_arrayref();
	foreach my $data ( @$rv ){
		$temp = shift (@$data);
		$dataA ->{ $temp } = $data;
	}
	$sth = $workingTable->{'dbh'}->prepare($sqlB);
	$rv = $sth->execute();
	$rv = $sth ->fetchall_arrayref();
	foreach my $data ( @$rv ){
		$temp = shift (@$data);
		$dataB ->{ $temp } = $data;
	}
	
	my $Wilcox_Test = Wilcox_Test->new();
	if ( $subjectIDs->{'A'} eq $subjectIDs->{'B'}){
		## we can do a paired test!!!
		$Wilcox_Test->SET_pairedTest(1);
	}
	
	my $i = 0;
	foreach my $oligoName ( keys %$dataA ){
		$rv = $Wilcox_Test -> _calculate_wilcox_statistics ( $dataA->{$oligoName}, $dataB->{$oligoName});
		unless ( defined $rv){
			@temp = ( 1 );
		}
		else{
			@temp = split("\t",$rv);
		}
		$i ++;
		if ( $i % 5000 == 0){
			print "we have done $i calculations - still alive! (oligo_name = $oligoName)\n";
		}
		$result-> { $oligoName } = -(&log10($temp[0])) ;
		#print "$oligoName  => $temp[0] -> $result->{$oligoName} values A = ". join( "; ",@{$dataA->{$oligoName}})." B = ".join( "; ",@{$dataB->{$oligoName}})." p_value = $temp[0]\n";
	}
	
	&export2gffFile ($oldGFF_file, $result, $oligoDB) if ( defined $oldGFF_file);
	
	if ( $debug ){
		print "and we will not import the data into the database!\n";
		exit;
	}
	$dataset->{'data'} = $result;
	$dataset->{'oligoDB'} = $oligoDB;
	my $id =
	  $array_calculation_results->_return_unique_ID_for_dataset($dataset);

## work is finfished - we add a log entry and remove the workload entry!
	if ( defined $id && $id > 0 ) {
		$loggingTable->set_log(
			{
				'start_time'  => @$workLoad[0]->{'timeStamp'},
				'programID'   => @$workLoad[0]->{'programID'},
				'description' => @$workLoad[0]->{'description'}
			}
		);
	}
	else {
		warn
"insert_into_dbTable_array_calculation_results.pl -> we could not add the data $dataStr\n";
		$errorTable->AddDataset(
			{
				'name' => 'insert_into_dbTable_array_calculation_results.pl',
				'description' => $dataStr
			}
		);
	}
}


sub export2gffFile{
	my ( $gffFile, $dataHash, $oligoDB) = @_;
	my $oligoData = $oligoDB->getArray_of_Array_for_search({
 	'search_columns' => ["oligoDB.oligo_name", "oligoDB.sequence"]
 	});
 	my $data;
 	my $gffFileOBJ = gffFile->new( $debug );
	my $dataset = $gffFileOBJ->GetData( $gffFile, 'preserve_structure');
 	foreach my $oligoData_array ( @$oligoData ){
 		$data->{@$oligoData_array[0]} = @$oligoData_array[1];
 	}
 	$oligoData = undef;
 	open ( LOG ,">/home/stefan_l/log.txt" ) or die "could not open log file /home/stefan_l/log.txt\n";
 	foreach my $dataRow ( @$dataset ){
 		print LOG "$dataRow->{'oligoID'} = $dataHash->{$dataRow->{'oligoID'}}" if ( defined $dataHash->{$dataRow->{'oligoID'}});
 		$dataRow->{'value'} = $dataHash->{$dataRow->{'oligoID'}};
 		$dataRow->{'description'} = "seq=".$data->{$dataRow->{'oligoID'}}.";oligoID=$dataRow->{'oligoID'}";
 	}
 	print "log written to /home/stefan_l/log.txt\n";
 	unless ( defined $outpath){
 		$outpath = "./";
 	}
 	close (LOG);
 	$gffFileOBJ->{'data_handler'} = "Wilcox_over_two_search_results";
 	$gffFileOBJ->{'data_label'} = $array_calculation_results_name;
 	$gffFileOBJ->writeData ( $dataset, "$outpath/$array_calculation_results_name.gff" );
 	print "GFF file written to $outpath/$array_calculation_results_name.gff\n";
 	return 1;
}

sub log10 {
  my $n = shift;
  return log($n)/log(10);
}
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

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );

	return "

$errorMessage

    command line switches for insert_into_dbTable_array_calculation_results.pl
 
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
 -array_dataset_ids_groupA
 -array_dataset_ids_groupB
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

   -outpath        :if you use a sampleGFF_File you MUST give me that otherwise you will get NO output!
   -sampleGFF_File :a signalmap gff file to take as a template to store the -log10(p_value) from this analysis in
   -help           :print this help
   -debug          :verbose output and we do not import the data into the database

";
}
