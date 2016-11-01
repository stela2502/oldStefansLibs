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

=head1 insert_into_dbTable_scientistTable.pl

INFO_STR

To get further help use 'insert_into_dbTable_scientistTable.pl -help' at the comman line.

=cut

use Getopt::Long;
use 
use Digest::MD5 qw(md5_hex);
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

my ( $help, $debug, $database_name, $resorce_path, $scientistTable.username, $scientistTable.name, $scientistTable.workgroup, $scientistTable.position, $scientistTable.email, $scientistTable.action_gr_id, $action_group_list.list_id, $action_group_list.others_id, $scientistTable.roles_list_id, $role_list.list_id, $role_list.others_id, $scientistTable.pw );

Getopt::Long::GetOptions(
         "-scientistTable.username=s"  => \$scientistTable.username,
         "-scientistTable.name=s"  => \$scientistTable.name,
         "-scientistTable.workgroup=s"  => \$scientistTable.workgroup,
         "-scientistTable.position=s"  => \$scientistTable.position,
         "-scientistTable.email=s"  => \$scientistTable.email,
         "-scientistTable.action_gr_id=s"  => \$scientistTable.action_gr_id,
         "-action_group_list.list_id=s"  => \$action_group_list.list_id,
         "-action_group_list.others_id=s"  => \$action_group_list.others_id,
         "-scientistTable.roles_list_id=s"  => \$scientistTable.roles_list_id,
         "-role_list.list_id=s"  => \$role_list.list_id,
         "-role_list.others_id=s"  => \$role_list.others_id,
         "-scientistTable.pw=s"  => \$scientistTable.pw,

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

if ( -f "$resorce_path/scientistTable.username.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.username.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.username = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.name.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.name.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.name = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.workgroup.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.workgroup.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.workgroup = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.position.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.position.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.position = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.email.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.email.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.email = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.action_gr_id.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.action_gr_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.action_gr_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/action_group_list.list_id.dta" ) { 
       open ( IN , "<$resorce_path/action_group_list.list_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $action_group_list.list_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/action_group_list.others_id.dta" ) { 
       open ( IN , "<$resorce_path/action_group_list.others_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $action_group_list.others_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.roles_list_id.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.roles_list_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.roles_list_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/role_list.list_id.dta" ) { 
       open ( IN , "<$resorce_path/role_list.list_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $role_list.list_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/role_list.others_id.dta" ) { 
       open ( IN , "<$resorce_path/role_list.others_id.dta" );
       foreach ( <IN> ){
              chomp($_);
              $role_list.others_id = $_;
              last;
       }
       close ( IN );
 }
if ( -f "$resorce_path/scientistTable.pw.dta" ) { 
       open ( IN , "<$resorce_path/scientistTable.pw.dta" );
       foreach ( <IN> ){
              chomp($_);
              $scientistTable.pw = $_;
              last;
       }
       close ( IN );
 }


}

my $dataset = { 
'username' => $scientistTable.username,
'name' => $scientistTable.name,
'workgroup' => $scientistTable.workgroup,
'position' => $scientistTable.position,
'email' => $scientistTable.email,
'action_gr_id' => $scientistTable.action_gr_id,
'action_gr' => { 
'id' => $scientistTable.action_gr_id,
'list_id' => $action_group_list.list_id,
'others_id' => $action_group_list.others_id,
},
'roles_list_id' => $scientistTable.roles_list_id,
'roles_list' => { 
'id' => $scientistTable.roles_list_id,
'list_id' => $role_list.list_id,
'others_id' => $role_list.others_id,
},
'pw' => $scientistTable.pw,
};


my ( $error, $dataStr) = check_dataset ( $dataset );

if ( $error =~ m/\w/){
	print helpString( $error ) ;
	exit;
}

my $scientistTable = scientistTable->new (  $database_name );

## now we set up the logging functions....

my ( $workingTable, $loggingTable, $workLoad , $loggingEntries,  $errorTable);

$workingTable = workingTable->new($database_name, $debug);
$loggingTable = loggingTable->new($database_name, $debug);
$errorTable = errorTable->new($database_name, $debug);

## and add a working entry

my $rv = $workingTable->set_workload(
{
			'PID'       => $$,
			'programID' => 'insert_into_dbTable_scientistTable.pl',
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

$scientistTable->AddDataset( $dataset );

my $id =$scientistTable->_return_unique_ID_for_dataset( $dataset );

## work is finfished - we add a log entry and remove the workload entry!
if ( defined $id && $id > 0 ){
	$loggingTable->set_log ( {
		'start_time' => @$workLoad[0]->{'timeStamp'},
		'programID' => @$workLoad[0]->{'programID'},
		'description' => @$workLoad[0]->{'description'}
	} );
}
else {
	warn "insert_into_dbTable_scientistTable.pl -> we could not add the data $dataStr\n";
	$errorTable -> AddDataset ( { 'name' => 'insert_into_dbTable_scientistTable.pl', 'description' => $dataStr } );
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

    command line switches for insert_into_dbTable_scientistTable.pl
 
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
 -scientistTable.username
       a unique identifier for you
 -scientistTable.name
       the name of the scientif (you)
 -scientistTable.workgroup
       the name of your group leader
 -scientistTable.position
       your position (PhD student, postdoc, .. )
 -scientistTable.email
       your e-mail address
 -scientistTable.pw
       the PW
 LINKAGE variables:
 -scientistTable.action_gr_id
       the link to the action groups
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -action_group_list.list_id
          
    -action_group_list.others_id
          
 -scientistTable.roles_list_id
       which roles you might be able to use
       If you do not know this value you should provide the following needed values
    NEEDED values:
    -role_list.list_id
          
    -role_list.others_id
          

   -help           :print this help
   -debug          :verbose output

"; 
}
