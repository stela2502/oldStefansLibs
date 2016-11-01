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

=head1 insert_into_dbTable_expression_estimate.pl

INFO_STR

To get further help use 'insert_into_dbTable_expression_estimate.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::expression_estimate;
use stefans_libs::tableHandling;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my (
	$help,                             $debug,
	$database_name,                    $resorce_path,
	$expression_estimate_sample_id,    @sampleTable_sample_lable,
	$sampleTable_subject_id,           $sampleTable_tissue_id,
	$expression_estimate_program_call, $expression_estimate_affy_desc_id,
	$dataFile
);

Getopt::Long::GetOptions(
	"-sampleTable_sample_lables=s{,}"     => \@sampleTable_sample_lable,
	"-sampleTable_subject_id=s"           => \$sampleTable_subject_id,
	"-sampleTable_tissue_id=s"            => \$sampleTable_tissue_id,
	"-expression_estimate_program_call=s" => \$expression_estimate_program_call,
	"-expression_estimate_affy_desc_id=s" => \$expression_estimate_affy_desc_id,
	"-jobid=s"                            => \$resorce_path,
	"-database_name=s"                    => \$database_name,
	"-dataFile=s"                         => \$dataFile,
	"-help"                               => \$help,
	"-debug"                              => \$debug
) or die( helpString() );

if ($help) {
	print helpString();
	exit;
}

if ( defined $resorce_path ) {

	if ( -f "$resorce_path/expression_estimate_sample_id.dta" ) {
		open( IN, "<$resorce_path/expression_estimate_sample_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$expression_estimate_sample_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/dataFile.dta" ) {
		$dataFile = "$resorce_path/dataFile.dta";
	}
	if ( -f "$resorce_path/sampleTable_sample_lables.dta" ) {
		open( IN, "<$resorce_path/sampleTable_sample_lables.dta" );
		foreach (<IN>) {
			chomp($_);
			push( @sampleTable_sample_lable, $_ );
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_subject_id.dta" ) {
		open( IN, "<$resorce_path/sampleTable_subject_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_subject_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_tissue_id.dta" ) {
		open( IN, "<$resorce_path/sampleTable_tissue_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_tissue_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/expression_estimate_program_call.dta" ) {
		open( IN, "<$resorce_path/expression_estimate_program_call.dta" );
		foreach (<IN>) {
			chomp($_);
			$expression_estimate_program_call = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/expression_estimate_affy_desc_id.dta" ) {
		open( IN, "<$resorce_path/expression_estimate_affy_desc_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$expression_estimate_affy_desc_id = $_;
			last;
		}
		close(IN);
	}

}

my $dataset = {
	'sample' => { 'sample_lable' => \@sampleTable_sample_lable },
	'program_call' => $expression_estimate_program_call,
	'affy_desc_id' => $expression_estimate_affy_desc_id,
	'affy_desc'    => { 'id' => $expression_estimate_affy_desc_id, },
};

my ( $error, $dataStr ) = check_dataset($dataset);

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

my $expression_estimate = expression_estimate->new( $database_name, $debug );

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad, $loggingEntries, $errorTable );

$workingTable = workingTable->new( $database_name, $debug );
$loggingTable = loggingTable->new( $database_name, $debug );
$errorTable = errorTable->new( $database_name, $debug );

## and add a working entry

my $rv = $workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'insert_into_dbTable_expression_estimate.pl',
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

	#$expression_estimate->AddDataset($dataset);
	my ( $tableHandling, $rv, $probeID, @sample_ids, $Data_Column, $data,
		$value, $probeID_pos, @accessibleSample_identifers, @dataset );
	my $id = $expression_estimate->_return_unique_ID_for_dataset($dataset);

	### DO THE WORK!

	$tableHandling = tableHandling->new();

	## "-expression_estimate_sample_id=s"    => \$expression_estimate_sample_id,
	## "-sampleTable_sample_lable=s"         => \$sampleTable_sample_lable,
	## "-sampleTable_subject_id=s"           => \$sampleTable_subject_id,
	## "-sampleTable_tissue_id=s"            => \$sampleTable_tissue_id,
	## "-expression_estimate_program_call=s" => \$expression_estimate_program_call,
	## "-expression_estimate_affy_desc_id=s" => \$expression_estimate_affy_desc_id,

	open( IN, "<$dataFile" )
	  or die "I could not open the data file '$dataFile'\n";

	#print "we have opened the data file $dataFile\n";
	$error = '';
	my $i = 0;
	while (<IN>) {
		$i++;
		unless ( ref($probeID_pos) eq "ARRAY" ) {
			$probeID_pos =
			  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
				{ 'probeset_id' => 1 } );

			$Data_Column =
			  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
				$tableHandling->createSearchHash(@sampleTable_sample_lable) );
			unless ( scalar(@$Data_Column) > 0 ) {
				$probeID_pos = undef;
				next if ( $_ =~ m/^#/ );
			}
			@accessibleSample_identifers =
			  $tableHandling->get_column_entries_4_columns( $_, $Data_Column );

			## You know - these sample_ids have to be defined in the database!
			foreach my $identifer (@accessibleSample_identifers) {
				$identifer = $1 if ( $identifer =~ m/ *([\w\-]+) */ );
				$rv = $expression_estimate->getArray_of_Array_for_search(
					{
						'search_columns' => [
							'sampleTable.id',
							'sampleTable.sample_lable',
							'sampleTable.subject_id'
						],
						'where' =>
						  [ [ 'sampleTable.sample_lable', '=', 'my_value' ] ]
					},
					$identifer
				);
				unless ( @{ @$rv[0] }[1] eq $identifer ) {
					Carp::confess(
"insert_into_dbTable_expression_estimate -> the sample_identififer '$identifer' is not present in the database!"
					);
				}
				push(
					@sample_ids,
					{
						'id'           => @{ @$rv[0] }[0],
						'sample_lable' => @{ @$rv[0] }[1],
						'subject_id'   => @{ @$rv[0] }[2]
					}
				);

				$data->{$identifer} = {};
			}

		}
		unless ( scalar(@$probeID_pos) > 0 ) {
			$error .=
'We have not identifed the column that corresponds to the "probeset_id"'
			  . "\n$_\n";
		}
		unless ( scalar(@$Data_Column) > 0 ) {
			$error .=
'We have not identifed the columns that correspond to the data values'
			  . "\n$_\n";
		}
		

		Carp::confess(
			"we could not identify the important header columns\n$error")
		  if ( $error =~ m/\w/ );

#		else {
#			print "we had an data header and therefore this line has to contain data:\n$_\n";
#		}
		$_ =~ s/,/./g;
		($probeID) =
		  $tableHandling->get_column_entries_4_columns( $_, $probeID_pos );
		@dataset =
		  $tableHandling->get_column_entries_4_columns( $_, $Data_Column );
		for ( my $it = 0 ; $it < @accessibleSample_identifers ; $it++ ) {
			$dataset[$it] = $1 if ( $dataset[$it] =~ m/^ *([\w\-\d\.]+) */ );
			$data->{ $accessibleSample_identifers[$it] }->{$probeID} =
			  $dataset[$it];

#			print
#"we read the estimate $dataset[$it] for the probe $probeID and the sample $accessibleSample_identifers[$it]\n";
		}

	}
	close(IN);
	## OK now we have the datasets as entries in the $data->{<subject_id>}->{<probe_id>}->{<value>} hash
	## We now have to think about the sample_id - how to get that? That has to be dome with the help of the user!
	for ( my $it = 0 ; $it < @accessibleSample_identifers ; $it++ ) {
		next unless ( defined $accessibleSample_identifers[$it] );
		$value = $expression_estimate->AddDataset(
			{
				'sample_id'    => $sample_ids[$it]->{'id'},
				'sample'       => $sample_ids[$it],
				'program_call' => $expression_estimate_program_call,
				'affy_desc_id' => $expression_estimate_affy_desc_id,
				'affy_desc'    => { 'id' => $expression_estimate_affy_desc_id },
				'estimates'    => $data->{ $accessibleSample_identifers[$it] }
			}
		);
	}

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
"insert_into_dbTable_expression_estimate.pl -> we could not add the data $dataStr\n";
		$errorTable->AddDataset(
			{
				'name'        => 'insert_into_dbTable_expression_estimate.pl',
				'description' => $dataStr
			}
		);
	}

}
else {
	print 'OOPS - the dataset was already present in the database!
';
}

$workingTable->delete_workload_for_PID($$);

sub check_dataset {
	my ( $dataset, $variable_name ) = @_;
	my $error   = '';
	my $dataStr = '';
	my ( $temp, $temp_data, $notNecessary );
	$notNecessary = {

	};
	foreach my $value_tag ( keys %$dataset ) {
		next if ( $notNecessary->{$value_tag} );
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

    command line switches for insert_into_dbTable_expression_estimate.pl
 
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
 -expression_estimate_program_call
       the cmd string that lead to the creation of the datasets
 -sampleTable_sample_lables
       the lables of the storage tubes
 -expression_estimate_affy_desc_id
       the id of the affy description table entry, that describes this probeset lib
       If you do not know this value you should provide the following needed values
    NEEDED values:


   -dataFile       :the file containing the expression estimates 
                    as gotten e.g. after RMA normalization
                    Make shure, that the column titles are the sample IDs for the smples you wnt to import
                    These sample IDs have to be known to the database!!
   -help           :print this help
   -debug          :verbose output

";
}
