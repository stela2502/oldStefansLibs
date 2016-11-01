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

=head1 insert_into_dbTable_protocol_table.pl

INFO_STR

To get further help use 'insert_into_dbTable_protocol_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::protocol_table;
use stefans_libs::root;
use Digest::MD5 qw(md5_hex);
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my ( $help, $debug, $database_name, @listOfMaterials, $resorce_path, $protocol_table_name, $protocol_table_description, $protocol_table_version, $protocol_table_working_copy, $protocol_table_original_protocol_description_id, $external_files_file, $external_files_filetype, $protocol_table_PMID );

Getopt::Long::GetOptions(
         "-protocol_table_name=s"  => \$protocol_table_name,
         "-protocol_table_description=s"  => \$protocol_table_description,
         "-protocol_table_version=s"  => \$protocol_table_version,
         "-protocol_table_working_copy=s"  => \$protocol_table_working_copy,
         "-protocol_table_original_protocol_description_id=s"  => \$protocol_table_original_protocol_description_id,
         "-external_files_file=s"  => \$external_files_file,
         "-external_files_filetype=s"  => \$external_files_filetype,
         "-protocol_table_PMID=s"  => \$protocol_table_PMID,
         "-listOf_usedMaterials=s{,}" => \@listOfMaterials,

	 "-jobid=s"          => \$resorce_path,
	 "-database_name=s"  => \$database_name,
	 "-help"             => \$help,
	 "-debug"            => \$debug
) or die (helpString());

if ( $help ){
	print helpString( ) ;
	exit;
}

if ( defined $resorce_path ){

if ( -f "$resorce_path/listOf_usedMaterials.dta"){
	open ( IN , "<$resorce_path/listOf_usedMaterials.dta");
	foreach ( <IN> ){
              chomp($_);
              push ( @listOfMaterials, "$_;;" );
              $protocol_table_name = $_;
              last;
       }
       close ( IN );
}

if ( -f "$resorce_path/protocol_table_name.dta" ) { 
       open ( IN , "<$resorce_path/protocol_table_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $protocol_table_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/protocol_table_description.dta" ) { 
       open ( IN , "<$resorce_path/protocol_table_description.dta" );
       foreach ( <IN> ){
              chomp($_);
              $protocol_table_description = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/protocol_table_version.dta" ) { 
       open ( IN , "<$resorce_path/protocol_table_version.dta" );
       foreach ( <IN> ){
              chomp($_);
              $protocol_table_version = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/protocol_table_working_copy.dta" ) { 
       open ( IN , "<$resorce_path/protocol_table_working_copy.dta" );
       foreach ( <IN> ){
              chomp($_);
              $protocol_table_working_copy = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/protocol_table_original_protocol_description_id.dta" ) { 
       open ( IN , "<$resorce_path/protocol_table_original_protocol_description_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $protocol_table_original_protocol_description_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/external_files_file.dta" ) { 
       $external_files_file = "$resorce_path/external_files_file.dta";
 }
if ( -f "$resorce_path/external_files_filetype.dta" ) { 
       open ( IN , "<$resorce_path/external_files_filetype.dta" );
       foreach ( <IN> ){
              chomp($_);
              $external_files_filetype = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/protocol_table_PMID.dta" ) { 
       open ( IN , "<$resorce_path/protocol_table_PMID.dta" );
       foreach ( <IN> ){
              chomp($_);
              $protocol_table_PMID = $_;
              last;
       }
       close ( IN );
 }


}

my $dataset = { 
'name' => $protocol_table_name,
'description' => $protocol_table_description,
'version' => $protocol_table_version,
'working_copy' => $protocol_table_working_copy,
'original_protocol_description_id' => $protocol_table_original_protocol_description_id,
'original_protocol_description' => { 
'id' => $protocol_table_original_protocol_description_id,
'file' => $external_files_file,
'filetype' => $external_files_filetype,
},
'PMID' => $protocol_table_PMID,
'materialList' => { 'others_id' => \@listOfMaterials }
};


my ( $error, $dataStr) = check_dataset ( $dataset );

if ( $error =~ m/\w/){
	print helpString( $error ) ;
	exit;
}

$database_name = 'genomeDB' unless ( defined $database_name );
my $protocol_table = protocol_table->new ( root::getDBH( 'root', $database_name ), $debug);

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad , $loggingEntries,  $errorTable);

$workingTable = workingTable->new($database_name, $debug);
$loggingTable = loggingTable->new($database_name, $debug);
$errorTable = errorTable->new($database_name, $debug);

## and add a working entry

my $rv = $workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'insert_into_dbTable_protocol_table.pl',
			'description' =>
			  "the dataset: $dataStr"
		}
);

unless ( defined $rv) {
	print "OOPS - we have a stuck process that wants to do the task - please mention that to your database administrator!\n";
	exit;
}

$workLoad = $workingTable->select_workloads_for_PID ( $$ );
$loggingEntries = $loggingTable->select_logs_for_description ( "the dataset: $dataStr" );
unless ( defined @$loggingEntries[0]){

$protocol_table->AddDataset( $dataset );

my $id =$protocol_table->_return_unique_ID_for_dataset( $dataset );

## work is finfished - we add a log entry and remove the workload entry!
if ( defined $id && $id > 0 ){
	$loggingTable->set_log ( {
		'start_time' => @$workLoad[0]->{'timeStamp'},
		'programID' => @$workLoad[0]->{'programID'},
		'description' => @$workLoad[0]->{'description'}
	} );
}
else {
	warn "insert_into_dbTable_protocol_table.pl -> we could not add the data $dataStr\n";
	$errorTable -> AddDataset ( { 'name' => 'insert_into_dbTable_protocol_table.pl', 'description' => $dataStr } );
}

}
else{
	print 'OOPS - the dataset was already present in the database!
';
} 

$workingTable->delete_workload_for_PID($$);


sub check_dataset{
	my ( $dataset, $variable_name ) = @_;
	my $error = '';
	my $dataStr = '';
	my ($temp, $temp_data, $notNecessary);
	$notNecessary = {
		'protocol_table_original_protocol_description_id' => 1,
		'file' => 1,
		'filetype' => 1,
#		'listOf_usedMaterials' => 1,
		'PMID' => 1
	};
	foreach my $value_tag ( keys %$dataset ){
		next if ( $notNecessary -> {$value_tag});
		$dataStr .= "-$value_tag => $dataset->{$value_tag}, " 
			if ( defined $dataset->{$value_tag} 
				&& ! (ref( $dataset->{$value_tag} ) eq "HASH") );
		#next if ( ref( $dataset->{$value_tag} ) eq "HASH" );
		next if ( $value_tag eq "id" );
		unless (defined $dataset->{$value_tag} ){
			$temp = $value_tag;
			$temp =~ s/_id//;
			if (  ref( $dataset->{$temp} ) eq "HASH" ){
				($temp, $temp_data) = check_dataset ( $dataset->{$temp} );
				$dataStr .= $temp_data;
				$error .= "we miss the data for value $value_tag and the downstream table:\n".$temp if ( $temp =~ m/\w/) ;
			}
			else {
				$error .= "we miss the data for value $value_tag\n";
			}
		}
	}
	
	return ($error, $dataStr);
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	
 	return "

$errorMessage

    command line switches for insert_into_dbTable_protocol_table.pl
 
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
 -protocol_table_name
       the name of the protocol
 -protocol_table_description
       a (long) description of the protocol
 -protocol_table_version
       the version of that protocol
 -protocol_table_working_copy
       The working copy of the protocol - it should be possible to print that
 -external_files_file
       the name of the file
 -external_files_filetype
       the filetype (one of picture, text_document or data_file
 -protocol_table_PMID
       An optional link to pubmed - if the protocol was published
 -listOf_usedMaterials
       A list of material IDs you have used for that protocol
 LINKAGE variables:
 -protocol_table_original_protocol_description_id
       the link to the file
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -external_files_file
          the name of the file
    -external_files_filetype
          the filetype (one of picture, text_document or data_file

   -help           :print this help
   -debug          :verbose output

"; 
}
