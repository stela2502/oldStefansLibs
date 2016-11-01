#! /usr/bin/perl -w

#  Copyright (C) 2011-01-18 Stefan Lang

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

=head1 get_expression_differences_in_cell_types.pl

This script will create a table containing expression differences between two cell types.

To get further help use 'get_expression_differences_in_cell_types.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::Protein_Expression;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $cell_1, $cell_2, $outfile);

Getopt::Long::GetOptions(
	 "-cell_1=s"    => \$cell_1,
	 "-cell_2=s"    => \$cell_2,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $cell_1) {
	$error .= "the cmd line switch -cell_1 is undefined!\n";
}
unless ( defined $cell_2) {
	$error .= "the cmd line switch -cell_2 is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for get_expression_differences_in_cell_types.pl

   -cell_1       :<please add some info!>
   -cell_2       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description, $Protein_Expression, $data_table);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/get_expression_differences_in_cell_types.pl';
$task_description .= " -cell_1 $cell_1" if (defined $cell_1);
$task_description .= " -cell_2 $cell_2" if (defined $cell_2);
$task_description .= " -outfile $outfile" if (defined $outfile);

open ( LOG , ">$outfile.log" ) or die "I could not create the log file '$outfile.log'\n";
print LOG $task_description."\n";
close ( LOG );

## Do whatever you want!

$Protein_Expression = stefans_libs_database_Protein_Expression->new( root->getDBH() );
$data_table = $Protein_Expression->expression_difference_between_2_cell_types({ 'cell_1' => $cell_1, 'cell_2' => $cell_2});
$data_table -> write_file ( $outfile );
