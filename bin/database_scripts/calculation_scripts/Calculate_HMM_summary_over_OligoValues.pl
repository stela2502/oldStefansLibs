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

=head1 Calculate_HMM_summary_over_OligoValues.pl

This script can be used to generate the sql querys to run the CalculationBackend_HMM_summary_over_OligoValues.pl.
This is kind of a developmental tool, as the user needs to know the table structures by hart and the use of 
stefans_libs::database::variable_table->create_SQL_statement(). Almost the same sql statement will be used to
select the IP and INPUT values.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use stefans_libs::database::array_dataset;
use stefans_libs::database::nucleotide_array;
use Carp;

use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @whereStatements, $dataset_name, $scientist_id,
	$access_right, $experiment_id );

Getopt::Long::GetOptions(
	"-help"                  => \$help,
	"-debug"                 => \$debug,
	"-database=s"            => \$database,
	"-where_statements=s{,}" => \@whereStatements,
	"-dataset_name=s"        => \$dataset_name,
	'-scientist_id=s'        => \$scientist_id,
	'-access_right=s'        => \$access_right,
	'-experiment_id=s'       => \$experiment_id
);

if ($help) {
	print helpString();
	exit;
}
unless ( defined $whereStatements[0] ) {
	print helpString(
"No - we will NOT get ALL the data from the database - please give me some where statements!"
	);
	exit;
}
unless ( defined $dataset_name ) {
	print helpString(
		"we definitely need a name for the new dataset (-dataset_name)" );
	exit;
}
unless ( defined $scientist_id ) {
	print helpString(
		"we definitely need a scientist id for the new dataset (-scientist_id)" );
	exit;
}
unless ( defined $access_right ) {
	print helpString(
		"we definitely need an access_right for the new dataset (-access_right)" );
	exit;
}


my ( @where_statements, $temp, @bindValues );
foreach my $where (@whereStatements) {
	$temp = [ split( ";", $where ) ];
	unless ( scalar(@$temp) == 3 ) {
		print helpString(
"sorry, but the where statement '$where' did not look like that 'column_A;[=<><=>=];STRING'"
		);
		exit;
	}
	push( @bindValues, @$temp[2] );
	@$temp[2] = "my_value";
	push( @where_statements, $temp );
}

## get the data sql string:
## select * from array_datasets left join (samples, tissue ) ON array_datasets.sample_id = samples.id && samples.tissue_id = tissue.id  where tissue.id = 1 && samples.extraction_protocol_id = 3 && array_type = 'IP';

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for Calculate_HMM_summary_over_OligoValues.pl
 
   -help             :print this help
   -debug            :verbose output
   -database         :the database name (default='genomeDB')
   -dataset_name     :the name the new dataset should get
   -scientist_id     :the id of the executing scientist (this scientis will own the dataset)
   -access_right     :the acces right for this dataset (scientist, group, all) 
   -where_statements :a list of where stements that look like that 'column_A;[=<><=>=];STRING'.
                      the STRING will alwas be used as a string - so please do not use it as a second column name!
   -experiment_id    :an optional experiment_id, if you do not whish to use the experiment denoted in the array_datasets table

";
}
my @progName = split( "/", $0 );
my ( $oligoDB, $rv, $sql, $sth, $array_dataset, $actual_sql, $nucleotide_array,
	$use_experiment_id );

$array_dataset = array_dataset->new( $database, $debug );
$database = $array_dataset->{'database_name'};

$nucleotide_array = nucleotide_array->new( $database, $debug );

$sql = $array_dataset->create_SQL_statement(
	{
		'search_columns' => [
			'array_datasets.array_id', 'array_datasets.experiment_id',
			'array_datasets.table_baseString'
		],
		'where' => [
			@where_statements, [ 'array_datasets.array_type', '=', 'my_value' ]
		]
	}
);
foreach (@bindValues) {
	$sql =~ s/\?/$_/;
}
my ( $array_id, $stored_experiment_id );
$use_experiment_id = 1;
my $sql_ip = Get_data_query_sql_for_array_type( 'IP', $sql );
my $sql_input = Get_data_query_sql_for_array_type( 'INPUT', $sql );

print
"we got the sql statements:\n   ---->IP<---- \n$sql_ip;\n   ---->INPUT<----\n$sql_input;\n";

my $cmd = "CalculationBackend_HMM_summary_over_OligoValues.pl -database '$database' -array_calculation_results_scientist_id $scientist_id  "
  . "-array_calculation_results_access_right $access_right -sql_input '$sql_input' -sql_ip '$sql_ip' -array_calculation_results_name $dataset_name".
  " -array_calculation_results_array_id $array_id ";
if ( defined $experiment_id ) {
	$cmd .= " -array_calculation_results_experiment_id $experiment_id ";
}
elsif ($use_experiment_id) {
	$cmd .= " -array_calculation_results_experiment_id $stored_experiment_id ";
}
else {
	die
"Sorry, but we need a experiment_id value to execute CalculationBackend_HMM_summary_over_OligoValues.pl\n";
}  

print "the working command:\n'"
  . "$cmd\n";





sub Get_data_query_sql_for_array_type {
	my ( $array_type, $actual_sql ) = @_;
	$actual_sql =~ s/\?/'$array_type'/;

	my ($oligoDB);
	print
"we will execute this sql statement: '$actual_sql' to get the $array_type table_names"
	  if ($debug);
	$sth = $array_dataset->{'dbh'}->prepare($actual_sql)
	  or die "Sorry, but we got a database error for query '$actual_sql;':\n",
	  $array_dataset->{'dbh'}->errstr();
	$rv = $sth->execute();
	die "We got no datasets for quers '$actual_sql;' -> this will NOT work!\n"
	  if ( $rv == 0 );
	foreach my $dataLine ( @{ $sth->fetchall_arrayref() } ) {

		unless ( defined $array_id ) {
			$array_id      = @$dataLine[0];
			$stored_experiment_id = @$dataLine[1];
		}
		die
"Sorry, but we can not handle an array_id mismatch! ( last array_id = $array_id; this array_id = @$dataLine[0] )\n"
		  unless ( $array_id == @$dataLine[0] );
		$use_experiment_id = 0 unless ( $stored_experiment_id == @$dataLine[1] );

		unless ( ref($oligoDB) eq "oligoDB" ) {
			print "we have a database interface of type '"
			  . ref($oligoDB) . "'\n";
			$oligoDB = $nucleotide_array->Get_OligoDB_for_ID( @$dataLine[0] );
			push(
				@{ $oligoDB->{'table_definition'}->{'variables'} },
				{
					'name'         => 'id',
					'data_handler' => 'oligo_array_values',
					'type'         => 'INTEGER',
					'description' =>
					  "this is an artefact of @progName[@progName-1]",
					'NULL' => 0
				}
			);
			$oligoDB->{'data_handler'}->{'oligo_array_values'} = [];
		}
		print
"we create a new oligo_array_values object with the table base name '@$dataLine[2]'\n";
		my $oligo_array_values =
		  oligo_array_values->new( $array_dataset->{'dbh'}, $debug );
		$oligo_array_values->{'_tableName'} = @$dataLine[2];
		push(
			@{ $oligoDB->{'data_handler'}->{'oligo_array_values'} },
			$oligo_array_values
		);
	}

	return 
		$oligoDB->create_SQL_statement(
			{
				'search_columns' =>
				  [ 'oligoDB.oligo_name', 'oligo_array_values.value' ]
			}
		);

}

