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

=head1 populate_genes_translation_table.pl

The script uses a table file containing the columns Ensembl_ID and Gene Symbol to populate the ENSEMBL_2_GeneSymbol database table necessary to store ENSEMBL_ID based gene expression estimates from the Human Protein Atlas.

To get further help use 'populate_genes_translation_table.pl -help' at the comman line.

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
 command line switches for populate_genes_translation_table.pl

   -data_table       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description, $Protein_Expression, $data );

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/populate_genes_translation_table.pl';
$task_description .= " -data_table $data_table" if (defined $data_table);

$data = data_table->new();
$data -> read_file ( $data_table );

$Protein_Expression = stefans_libs_database_Protein_Expression->new( root->getDBH() );
$Protein_Expression -> process_ENSEMBLE_ID_2_GeneSymbols ( $data );



## Do whatever you want!

