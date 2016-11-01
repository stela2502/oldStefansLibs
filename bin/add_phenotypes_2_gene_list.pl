#! /usr/bin/perl -w

#  Copyright (C) 2010-10-14 Stefan Lang

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

=head1 add_phenotypes_2_gene_list.pl

a smal script, that can read the phenotype outfiles and add some of the results to a list of GOIs.

To get further help use 'add_phenotypes_2_gene_list.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $gene_list_file, @phenotype_results);

Getopt::Long::GetOptions(
	 "-gene_list_file=s"    => \$gene_list_file,
	 "-phenotype_results=s{,}"    => \@phenotype_results,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $gene_list_file) {
	$error .= "the cmd line switch -gene_list_file is undefined!\n";
}
unless ( defined $phenotype_results[0]) {
	$error .= "the cmd line switch -phenotype_results is undefined!\n";
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
 command line switches for add_phenotypes_2_gene_list.pl

   -gene_list_file       :<please add some info!>
   -phenotype_results       :<please add some info!> you can specify more entries to that

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description, $results_table, $phenotype_table, @genes, $data, $matching_column );

$task_description .= 'add_phenotypes_2_gene_list.pl';
$task_description .= " -gene_list_file $gene_list_file" if (defined $gene_list_file);
$task_description .= ' -phenotype_results '.join( ' ', @phenotype_results ) if ( defined $phenotype_results[0]);


## Do whatever you want!
$results_table = data_table->new();
$results_table -> read_file( $gene_list_file );
die "sorry, but we need a data file containing a column names 'Gene Symbol' in order to add gene data (-gene_list_file)!\n'".join("','",@{$results_table ->{'header'}})."'\n"
	unless ( defined $results_table -> Header_Position ( 'Gene Symbol') );
$results_table -> createIndex( 'Gene Symbol' );
$matching_column = 'Gene Symbol';
if ( defined $results_table -> Header_Position ('Probe Set ID') ){
	$results_table -> createIndex( 'Probe Set ID');
	$matching_column = 'Probe Set ID';
}

@genes = @{ $results_table->getAsArray($matching_column) };

foreach my $infile (@phenotype_results){
	$phenotype_table = data_table->new();
	$phenotype_table -> read_file ( $infile );
	Carp::confess ( "Sorry, but the data_file $infile does not contain the necessary column $matching_column\n'".join("','",@{$phenotype_table ->{'header'}})."'\n" ) unless ( defined $phenotype_table -> Header_Position( $matching_column ));
	Carp::confess ( "Sorry, but the data_file $infile does not contain the necessary column 'p value'\n'".join("','",@{$phenotype_table ->{'header'}})."'\n" ) unless ( defined $phenotype_table -> Header_Position( 'p value' ) || defined $phenotype_table -> Header_Position( 'p-value' ));
	$results_table -> Add_2_Header ( $infile );
	$data = $phenotype_table -> getAsHash ( $matching_column, 'p value') if ( defined $phenotype_table -> Header_Position( 'p value' ));
	$data = $phenotype_table -> getAsHash ( $matching_column, 'p-value') if ( defined $phenotype_table -> Header_Position( 'p-value' ));

	print root::get_hashEntries_as_string ($data, 3, "we match the dataset to the gene list") if ( $debug);
	foreach ( @genes ){
		unless ( defined $data->{$_} ){
			$data->{$_} = 'n.s.';
			print "we did not find an entry for the gene '$_'\n" if ( $debug);
		} 
		$results_table -> AddDataset ( {$matching_column => $_, $infile => $data->{$_}} );
	}
}
$results_table ->print2file( $gene_list_file.".out" );

