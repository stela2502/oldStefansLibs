#! /usr/bin/perl -w

#  Copyright (C) 2010-10-29 Stefan Lang

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

=head1 remove_variable_influence_from_expression_array.pl

The script expects an expression array data file and a phenotype data file. The same type of sample IDs are expected to be column heraders in both files. You can specify a list of variables from the Phenotypes file that you want to remove the estimated influence on the dataset. To estimate the influence the linear model of the R-lm package is used. Only + connections between the models is supported at the moment.

To get further help use 'remove_variable_influence_from_expression_array.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::array_analysis::regression_models::linear_regression;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $expression_data, $phenotype_data, @description_columns_to_keep, @remove_these_phenotypes, $outfile);

Getopt::Long::GetOptions(
	 "-expression_data=s"    => \$expression_data,
	 "-phenotype_data=s"    => \$phenotype_data,
	 "-description_columns_to_keep=s{,}"    => \@description_columns_to_keep,
	 "-remove_these_phenotypes=s{,}"    => \@remove_these_phenotypes,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $expression_data) {
	$error .= "the cmd line switch -expression_data is undefined!\n";
}
unless ( defined $phenotype_data) {
	$error .= "the cmd line switch -phenotype_data is undefined!\n";
}
unless ( defined $description_columns_to_keep[0]) {
	$error .= "the cmd line switch -description_columns_to_keep is undefined!\n";
}
unless ( defined $remove_these_phenotypes[0]) {
	$error .= "the cmd line switch -remove_these_phenotypes is undefined!\n";
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
 command line switches for remove_variable_influence_from_expression_array.pl

   -expression_data  :the expression data as tab separated text file
   -phenotype_data   :the Phenotype data as tab separated text file
                      first column has to contain the Phenotype name and all other 
                      columns need to be samples
                      having the same column header as in the expression array file
   -description_columns_to_keep :a list of column that you would like to transfere 
   								 without change from the old to the new dataset
   								 DO NOT USE THE SAMPLES HERE
   -remove_these_phenotypes :A list of phenotype names that you want 
                             to use to built the linear model
   -outfile       :the outfile containing the modified data

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'remove_variable_influence_from_expression_array.pl';
$task_description .= " -expression_data $expression_data" if (defined $expression_data);
$task_description .= " -phenotype_data $phenotype_data" if (defined $phenotype_data);
$task_description .= ' -description_columns_to_keep '.join( ' ', @description_columns_to_keep ) if ( defined $description_columns_to_keep[0]);
$task_description .= ' -remove_these_phenotypes '.join( ' ', @remove_these_phenotypes ) if ( defined $remove_these_phenotypes[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);

open ( LOG ,">$outfile.log" );
print LOG $task_description."\n";
close ( LOG );

## Do whatever you want!
## Do whatever you want!

my ( $expression_data_table, $phenotype_data_table, @samples, $corrected_data_table, $linear_regression);

$expression_data_table = data_table->new();
$phenotype_data_table =  data_table->new();

$expression_data_table -> read_file ( $expression_data );
$phenotype_data_table  -> read_file ( $phenotype_data );

foreach ( @description_columns_to_keep ){
        Carp::confess ( "Ooops - the description_columns_to_keep '$_' does not exist in the expression data file!\n") unless ( defined $expression_data_table->Header_Position( $_ ) );
}

for ( my $i = 1; $i < @{$phenotype_data_table->{'header'}}; $i++){
        push ( @samples, @{$phenotype_data_table->{'header'}}[$i] ) if ( defined $expression_data_table ->Header_Position (@{$phenotype_data_table->{'header'}}[$i]));
}
$phenotype_data_table->define_subset( 'samples', \@samples);
$linear_regression = linear_regression->new();

$corrected_data_table =  $linear_regression -> remove_influence_from_dataset ({
        'influence_data_table' => $phenotype_data_table,
        'variables_data_table' => $expression_data_table,
        'list_of_vars_to_remove' => \@remove_these_phenotypes,
        'vars_to_keep' => \@description_columns_to_keep
});

## now we need to print the data to an outfile
$corrected_data_table->{'no_doubble_cross'} = 1;

$corrected_data_table->print2file ( $outfile );

