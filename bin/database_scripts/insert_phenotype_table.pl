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

=head1 insert_phenotype_table.pl

A script to insert tab separated table files containing at least 
one phenotype column and one column named either subject_id or subject_identifier. 
Remember, that the subject_id is the db internal subject_id, not the subject id you have in your lab book. 
This would be the subject_identifier

To get further help use 'insert_phenotype_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::array_analysis::tableHandling;
use stefans_libs::database::subjectTable;
use strict;
use warnings;

my ( $help, $debug, $database, $table_file, $tab, $pheno_name );

Getopt::Long::GetOptions(
	"-help"            => \$help,
	"-debug"           => \$debug,
	"-infile=s"        => \$table_file,
	"-phenotype_name=s" => \$pheno_name,
	"-tab_separator=s" => \$tab,
	"-database=s"      => \$database
);
my $error = '';
if ($help) {
	print &helpString();
	exit;
}
unless ( -f $table_file ) {
	$error .= "we can not acces the -infile '$table_file'\n";
}
unless ( defined $pheno_name ){
	$error .= "we need a -phenotype_name so we know where to store the phenotype data in!\n";
}

if ( $error =~ m/\w/ ){
	print &helpString ( $error);
	exit;
}
$tab = "\t" unless ( defined $tab );

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for insert_phenotype_table.pl
   -phenotype_name :if you do not know the id of the phenotype you at least need to know the name of the phenotype!
   -infile         :a file containing phenotype information. 
                    The first line in that file has to contain the column headers where we expect either 
                    a subject_id (the database internal subject_id) or
                    a subject_identifier that is the subject_id used in your lab book.
                    To add this dataset to the database the phenotypes have to be previously defined
                    in the databse using the 'insert_into_dbTable_phenotype_registration.pl'
   -tab_separator  :an optional sting used to separate the columns in the infile (default = <TAB>)
   -help           :print this help
   -debug          :verbose output

";
}

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad, $loggingEntries, $description, $subjectTable );

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );

## and add a working entry

$description =
  "Add some phenotypes to the database using the infile $table_file";

$workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'insert_phenotype_table.pl',
		'description' => $description
	}
);

$workLoad       = $workingTable->select_workloads_for_PID($$);
$loggingEntries = $loggingTable->select_logs_for_description($description);
unless ( defined @$loggingEntries[0] ) {

	my ( $tableHandling, @data, $header, $error, $dataset, $necessary_columns, $phenotypeTable, $necessary_column );

	$tableHandling = tableHandling->new($tab);
	unless ( open( IN, "<$table_file" ) ) {
		$workingTable->delete_workload_for_PID($$);
		die "we could not open the file '$table_file'\n" . $!;
	}
	$subjectTable = subjectTable->new(root::getDBH('root'));
	$phenotypeTable = $subjectTable->connect_2_phenotype ( $pheno_name );
	## NOW WE WILL POISON THE $subjectTable - DO NOT USE THAT FOR ANY QUERY IN THIS SCRIPT
	$phenotypeTable -> InsertMode ( $subjectTable );
	#$phenotypeTable -> printReport ( 'An_Insertable_Phenotype_Table');
	#die;
	unless ( ref($phenotypeTable) =~ m/\w/ ){
		$workingTable->delete_workload_for_PID($$);
		die "Sorry, but we could not identify the phenotype table for the phenotype_name $pheno_name\n";
	}
	$necessary_columns = $phenotypeTable->Get_neededColumns();
	
	while (<IN>) {
		unless ( defined $header){
			@data = $tableHandling->_split_line($_);
			for( my $i = 0; $i< @data; $i++ ){
				next unless ( $necessary_columns->{$data[$i]});
				$header->{$data[$i]} = $i;
			}
			foreach $necessary_column ( keys %$necessary_columns ){
				unless ( defined $header->{$necessary_column} ){
					$error .= "We miss a vital column for the phenotype $pheno_name in the data file $table_file: '$necessary_column'\n";
				}
			}
			if ( $error =~ m/\w/){
				$workingTable->delete_workload_for_PID($$);
				die $error;
			}
			next;
		}
		## AND now we need to do some work - HURAY!
		@data = $tableHandling->_split_line($_);
		$dataset = {};
		foreach $necessary_column ( keys %$necessary_columns ){
			if ( $necessary_column eq "subject_identifier"){
				$dataset->{'subject'} = { 'identifier' => $data[$header->{$necessary_column}]};
			}
			else{
				$dataset->{$necessary_column} = $data[$header->{$necessary_column}];
			}
		}
		print root::get_hashEntries_as_string ($dataset , 3, "we try to inster this dataset into table ".$phenotypeTable->TableName());
		$phenotypeTable->AddDataset( $dataset );
	}
	close(IN);

	$loggingTable->set_log(
		{
			'start_time'  => @$workLoad[0]->{'timeStamp'},
			'programID'   => @$workLoad[0]->{'programID'},
			'description' => @$workLoad[0]->{'description'}
		}
	);

}

$workingTable->delete_workload_for_PID($$);

