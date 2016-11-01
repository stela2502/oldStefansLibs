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

=head1 order_TMeDIP_Test_Dataa.pl

A tool to get an ordered list of values, that anyone could use with his/her favorit statistical sotfware to check the p_values for a list of oligoIDs.

To get further help use 'order_MeDIP_Test_Data.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @oligoIDs, $data_path, $outfile, $array_dataset_ids_groupA, $array_dataset_ids_groupB);

Getopt::Long::GetOptions(
	 "-oligoIDs=s{,}"    => \@oligoIDs,
	 "-data_path=s"    => \$data_path,
	 "-outfile=s"    => \$outfile,
	 "-array_dataset_ids_groupA=s"    => \$array_dataset_ids_groupA,
	 "-array_dataset_ids_groupB=s"    => \$array_dataset_ids_groupB,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $oligoIDs[0]) {
	$error .= "the cmd line switch -oligoIDs is undefined!\n";
}
unless ( defined $data_path) {
	$error .= "the cmd line switch -data_path is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $array_dataset_ids_groupA) {
	$error .= "the cmd line switch -array_dataset_ids_groupA is undefined!\n";
}
unless ( defined $array_dataset_ids_groupB) {
	$error .= "the cmd line switch -array_dataset_ids_groupB is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for order_TMeDIP_Test_Dataa.pl

   -oligoIDs       :<please add some info!> you can specify more entries to that
   -data_path       :<please add some info!>
   -outfile       :<please add some info!>
   -array_dataset_ids_groupA       :<please add some info!>
   -array_dataset_ids_groupB       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'order_TMeDIP_Test_Dataa.pl';
$task_description .= ' -oligoIDs '.join( ' ', @oligoIDs ) if ( defined $oligoIDs[0]);
$task_description .= " -data_path $data_path" if (defined $data_path);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -array_dataset_ids_groupA $array_dataset_ids_groupA" if (defined $array_dataset_ids_groupA);
$task_description .= " -array_dataset_ids_groupB $array_dataset_ids_groupB" if (defined $array_dataset_ids_groupB);


## Do whatever you want!
## Outline
## 1: get the data from the .mod files using a 'normal grep'
## 2: transform the grep output into a sample_id -> data hash
## 3: group the data including all the necessary informations (sample_id etc.)
## 4: repeat 1-3 for each OligoID
## 5: print a file that could be used with ANY spreadsheet application
