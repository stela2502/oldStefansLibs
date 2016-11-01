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

=head1 insert_into_dbTable_materialsTable.pl

INFO_STR

To get further help use 'insert_into_dbTable_materialsTable.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::materials::materialsTable;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my ( $help, $debug, $database_name, $resorce_path, $materialsTable_company, $materialsTable_name, $materialsTable_OrderNumber, $materialsTable_LotNumber, $materialsTable_type, $materialsTable_orderDate, $materialsTable_storage_id, $storage_table_building, $storage_table_floor, $storage_table_room, $storage_table_description, $materialsTable_description );

Getopt::Long::GetOptions(
         "-materialsTable_company=s"  => \$materialsTable_company,
         "-materialsTable_name=s"  => \$materialsTable_name,
         "-materialsTable_OrderNumber=s"  => \$materialsTable_OrderNumber,
         "-materialsTable_LotNumber=s"  => \$materialsTable_LotNumber,
         "-materialsTable_type=s"  => \$materialsTable_type,
         "-materialsTable_orderDate=s"  => \$materialsTable_orderDate,
         "-materialsTable_storage_id=s"  => \$materialsTable_storage_id,
         "-storage_table_building=s"  => \$storage_table_building,
         "-storage_table_floor=s"  => \$storage_table_floor,
         "-storage_table_room=s"  => \$storage_table_room,
         "-storage_table_description=s"  => \$storage_table_description,
         "-materialsTable_description=s"  => \$materialsTable_description,

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

if ( -f "$resorce_path/materialsTable_company.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_company.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_company = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_name.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_OrderNumber.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_OrderNumber.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_OrderNumber = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_LotNumber.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_LotNumber.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_LotNumber = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_type.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_type.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_type = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_orderDate.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_orderDate.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_orderDate = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_storage_id.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_storage_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_storage_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/storage_table_building.dta" ) { 
       open ( IN , "<$resorce_path/storage_table_building.dta" );
       foreach ( <IN> ){
              chomp($_);
              $storage_table_building = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/storage_table_floor.dta" ) { 
       open ( IN , "<$resorce_path/storage_table_floor.dta" );
       foreach ( <IN> ){
              chomp($_);
              $storage_table_floor = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/storage_table_room.dta" ) { 
       open ( IN , "<$resorce_path/storage_table_room.dta" );
       foreach ( <IN> ){
              chomp($_);
              $storage_table_room = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/storage_table_description.dta" ) { 
       open ( IN , "<$resorce_path/storage_table_description.dta" );
       foreach ( <IN> ){
              chomp($_);
              $storage_table_description = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/materialsTable_description.dta" ) { 
       open ( IN , "<$resorce_path/materialsTable_description.dta" );
       foreach ( <IN> ){
              chomp($_);
              $materialsTable_description = $_;
              last;
       }
       close ( IN );
 }


}

my $dataset = { 
'company' => $materialsTable_company,
'name' => $materialsTable_name,
'OrderNumber' => $materialsTable_OrderNumber,
'LotNumber' => $materialsTable_LotNumber,
'type' => $materialsTable_type,
'orderDate' => $materialsTable_orderDate,
'storage_id' => $materialsTable_storage_id,
'storage' => { 
'id' => $materialsTable_storage_id,
'building' => $storage_table_building,
'floor' => $storage_table_floor,
'room' => $storage_table_room,
'description' => $storage_table_description,
},
'description' => $materialsTable_description,
};


my ( $error, $dataStr) = check_dataset ( $dataset );

if ( $error =~ m/\w/){
	print helpString( $error ) ;
	exit;
}

$database_name = 'genomeDB' unless ( defined $database_name );
my $materialsTable = materialsTable->new ( root::getDBH( 'root', $database_name ), $debug);

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad , $loggingEntries,  $errorTable);

$workingTable = workingTable->new($database_name, $debug);
$loggingTable = loggingTable->new($database_name, $debug);
$errorTable = errorTable->new($database_name, $debug);

## and add a working entry

my $rv = $workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'insert_into_dbTable_materialsTable.pl',
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

$materialsTable->AddDataset( $dataset );

my $id =$materialsTable->_return_unique_ID_for_dataset( $dataset );

## work is finfished - we add a log entry and remove the workload entry!
if ( defined $id && $id > 0 ){
	$loggingTable->set_log ( {
		'start_time' => @$workLoad[0]->{'timeStamp'},
		'programID' => @$workLoad[0]->{'programID'},
		'description' => @$workLoad[0]->{'description'}
	} );
}
else {
	warn "insert_into_dbTable_materialsTable.pl -> we could not add the data $dataStr\n";
	$errorTable -> AddDataset ( { 'name' => 'insert_into_dbTable_materialsTable.pl', 'description' => $dataStr } );
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
		'orderDate' => 1	
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

    command line switches for insert_into_dbTable_materialsTable.pl
 
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
 -materialsTable_company
       the company you bought the product from
 -materialsTable_name
       the common name for this compound
 -materialsTable_OrderNumber
       the order number to for this product
 -materialsTable_LotNumber
       the lot number to for this product sample
 -materialsTable_type
       the type of the compound (e.g. antibody, chemical, ...)
 -materialsTable_orderDate
       the date you ordered/recieved this compound
 -materialsTable_description
       some further description
 LINKAGE variables:
 -materialsTable_storage_id
       the id of the storage of this compound
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

   -help           :print this help
   -debug          :verbose output

"; 
}
