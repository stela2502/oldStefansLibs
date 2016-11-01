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

=head1 insert_into_dbTable_sampleTable.pl

INFO_STR

To get further help use 'insert_into_dbTable_sampleTable.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::sampleTable;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my (
	$help,                      $debug,
	$database_name,             $resorce_path,
	$sampleTable_sample_lable,  $sampleTable_name,
	$sampleTable_subject_id,    $subjectTable_identifier,
	$sampleTable_storage_id,    $storage_table_building,
	$storage_table_floor,       $storage_table_room,
	$storage_table_description, $sampleTable_initial_amount,
	$sampleTable_tissue_id,     $tissueTable_organism_id,
	$tissueTable_name,          $tissueTable_extraction_protocol_id,
	$sampleTable_aliquots,      $sampleTable_extraction_protocol_id,
	$protocol_table_name,       $sampleTable_extraction_date
);

Getopt::Long::GetOptions(
	"-sampleTable_sample_lable=s"   => \$sampleTable_sample_lable,
	"-sampleTable_name=s"           => \$sampleTable_name,
	"-sampleTable_subject_id=s"     => \$sampleTable_subject_id,
	"-subjectTable_identifier=s"    => \$subjectTable_identifier,
	"-sampleTable_storage_id=s"     => \$sampleTable_storage_id,
	"-storage_table_building=s"     => \$storage_table_building,
	"-storage_table_floor=s"        => \$storage_table_floor,
	"-storage_table_room=s"         => \$storage_table_room,
	"-storage_table_description=s"  => \$storage_table_description,
	"-sampleTable_initial_amount=s" => \$sampleTable_initial_amount,
	"-sampleTable_tissue_id=s"      => \$sampleTable_tissue_id,
	"-tissueTable_organism_id=s"    => \$tissueTable_organism_id,
	"-tissueTable_name=s"           => \$tissueTable_name,
	"-tissueTable_extraction_protocol_id=s" =>
	  \$tissueTable_extraction_protocol_id,
	"-sampleTable_aliquots=s" => \$sampleTable_aliquots,
	"-sampleTable_extraction_protocol_id=s" =>
	  \$sampleTable_extraction_protocol_id,
	"-protocol_table_name=s"         => \$protocol_table_name,
	"-sampleTable_extraction_date=s" => \$sampleTable_extraction_date,

	"-jobid=s"         => \$resorce_path,
	"-database_name=s" => \$database_name,
	"-help"            => \$help,
	"-debug"           => \$debug
) or die( helpString() );

if ($help) {
	print helpString();
	exit;
}

if ( defined $resorce_path ) {

	if ( -f "$resorce_path/sampleTable_sample_lable.dta" ) {
		open( IN, "<$resorce_path/sampleTable_sample_lable.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_sample_lable = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_name.dta" ) {
		open( IN, "<$resorce_path/sampleTable_name.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_name = $_;
			last;
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
	if ( -f "$resorce_path/subjectTable_identifier.dta" ) {
		open( IN, "<$resorce_path/subjectTable_identifier.dta" );
		foreach (<IN>) {
			chomp($_);
			$subjectTable_identifier = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_storage_id.dta" ) {
		open( IN, "<$resorce_path/sampleTable_storage_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_storage_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/storage_table_building.dta" ) {
		open( IN, "<$resorce_path/storage_table_building.dta" );
		foreach (<IN>) {
			chomp($_);
			$storage_table_building = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/storage_table_floor.dta" ) {
		open( IN, "<$resorce_path/storage_table_floor.dta" );
		foreach (<IN>) {
			chomp($_);
			$storage_table_floor = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/storage_table_room.dta" ) {
		open( IN, "<$resorce_path/storage_table_room.dta" );
		foreach (<IN>) {
			chomp($_);
			$storage_table_room = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/storage_table_description.dta" ) {
		open( IN, "<$resorce_path/storage_table_description.dta" );
		foreach (<IN>) {
			chomp($_);
			$storage_table_description = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_initial_amount.dta" ) {
		open( IN, "<$resorce_path/sampleTable_initial_amount.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_initial_amount = $_;
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
	if ( -f "$resorce_path/tissueTable_organism_id.dta" ) {
		open( IN, "<$resorce_path/tissueTable_organism_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$tissueTable_organism_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/tissueTable_name.dta" ) {
		open( IN, "<$resorce_path/tissueTable_name.dta" );
		foreach (<IN>) {
			chomp($_);
			$tissueTable_name = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/tissueTable_extraction_protocol_id.dta" ) {
		open( IN, "<$resorce_path/tissueTable_extraction_protocol_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$tissueTable_extraction_protocol_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_aliquots.dta" ) {
		open( IN, "<$resorce_path/sampleTable_aliquots.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_aliquots = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_extraction_protocol_id.dta" ) {
		open( IN, "<$resorce_path/sampleTable_extraction_protocol_id.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_extraction_protocol_id = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/protocol_table_name.dta" ) {
		open( IN, "<$resorce_path/protocol_table_name.dta" );
		foreach (<IN>) {
			chomp($_);
			$protocol_table_name = $_;
			last;
		}
		close(IN);
	}
	if ( -f "$resorce_path/sampleTable_extraction_date.dta" ) {
		open( IN, "<$resorce_path/sampleTable_extraction_date.dta" );
		foreach (<IN>) {
			chomp($_);
			$sampleTable_extraction_date = $_;
			last;
		}
		close(IN);
	}

}

my $dataset = {
	'sample_lable' => $sampleTable_sample_lable,
	'name'         => $sampleTable_name,
	'subject_id'   => $sampleTable_subject_id,
	'subject'      => {
		'id'         => $sampleTable_subject_id,
		'identifier' => $subjectTable_identifier,
	},
	'storage_id' => $sampleTable_storage_id,
	'storage'    => {
		'id'          => $sampleTable_storage_id,
		'building'    => $storage_table_building,
		'floor'       => $storage_table_floor,
		'room'        => $storage_table_room,
		'description' => $storage_table_description,
	},
	'initial_amount' => $sampleTable_initial_amount,
	'tissue_id'      => $sampleTable_tissue_id,
	'tissue'         => {
		'id'                     => $sampleTable_tissue_id,
		'organism_id'            => $tissueTable_organism_id,
		'name'                   => $tissueTable_name,
		'extraction_protocol_id' => $tissueTable_extraction_protocol_id,
	},
	'aliquots'               => $sampleTable_aliquots,
	'extraction_protocol_id' => $sampleTable_extraction_protocol_id,
	'extraction_protocol'    => {
		'id'   => $sampleTable_extraction_protocol_id,
		'name' => $protocol_table_name,
	},
	'extraction_date' => $sampleTable_extraction_date,
};

my ( $error, $dataStr ) = check_dataset($dataset);

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

my $sampleTable = sampleTable->new($database_name, $debug);

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad, $loggingEntries, $errorTable );

$workingTable = workingTable->new( $database_name, $debug );
$loggingTable = loggingTable->new( $database_name, $debug );
$errorTable = errorTable->new( $database_name, $debug );

## and add a working entry

my $rv = $workingTable->set_workload(
	{
		'PID'         => $$,
		'programID'   => 'insert_into_dbTable_sampleTable.pl',
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

	my $id = $sampleTable->AddDataset($dataset);

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
"insert_into_dbTable_sampleTable.pl -> we could not add the data $dataStr\n";
		$errorTable->AddDataset(
			{
				'name'        => 'insert_into_dbTable_sampleTable.pl',
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
		next if ( $value_tag eq "extraction_date" );
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

    command line switches for insert_into_dbTable_sampleTable.pl
 
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
 -sampleTable_sample_lable
       the lable of the storage tubes
 -sampleTable_name
       some additional information, that you could use to add a tag to the sample
 -sampleTable_initial_amount
       the initial amount of purified sample material
 -sampleTable_aliquots
       how many aliquots are available
 -sampleTable_extraction_date
       the date of the sample extraction
 LINKAGE variables:
 -sampleTable_subject_id
       the link to the subjects table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -subjectTable_identifier
          an unique identifier for that individual
 -sampleTable_storage_id
       the link to the possible storage places
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -storage_table_building
          the building the storgae is placed in
    -storage_table_floor
          the floor the storage is located
    -storage_table_room
          the room of the storage
    -storage_table_description
          a description of the storage (e.g. small white fridge)
 -sampleTable_tissue_id
       the link to the tissues table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -tissueTable_organism_id
          the link to the organism table
    -tissueTable_name
          the name of the tissue type
    -tissueTable_extraction_protocol_id
          the extraction protocol for this tissue type
 -sampleTable_extraction_protocol_id
       the link to the protocols table
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -protocol_table_name
          the name of the protocol

   -help           :print this help
   -debug          :verbose output

";
}
