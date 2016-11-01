#! /usr/bin/perl -w

#  Copyright (C) 2011-01-17 Stefan Lang

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

=head1 add_Expression_Estimates_from_theHPA.pl

The sript makes the data from the Human Protein Atlas available. You need to download the data file named normal_tissue.csv.zip from there download page http://www.proteinatlas.org/download/ and unzip it.

To get further help use 'add_Expression_Estimates_from_theHPA.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::Protein_Expression;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $data_table);

Getopt::Long::GetOptions(
	 "-data_table=s"    => \$data_table,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $data_table) {
	$error .= "the cmd line switch -data_table is undefined!\n";
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
 command line switches for add_Expression_Estimates_from_theHPA.pl

   -data_table   :the data from the Human Protein Atlas. 
                  You need to download the data file named normal_tissue.csv.zip 
                  from there download page http://www.proteinatlas.org/download/ 
                  and unzip it.

   -help         :print this help
   -debug        :verbose output
   

"; 
}


my ( $task_description, $Protein_Expression, $data);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/add_Expression_Estimates_from_theHPA.pl';
$task_description .= " -data_table $data_table" if (defined $data_table);


## Do whatever you want!
$data = data_table->new();
$data -> read_file ( $data_table );

$Protein_Expression = stefans_libs_database_Protein_Expression->new( root->getDBH() );
$Protein_Expression ->  Add_Human_Protein_Atlas_Data ( $data );
