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

=head1 model_geneInfluence.pl

An experimental tool to craete gene - gene expression differneces based models to predict a phenotypic outcome from a expression array dataset

To get further help use 'model_geneInfluence.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::statistics::HMM::probabilityFunction;
use Math::Trig;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $array_dataset, $reference_gene, @other_genes, $predict_for, @learn_group_A, @learn_group_B, @test_group, $outfile);

Getopt::Long::GetOptions(
	 "-array_dataset=s"    => \$array_dataset,
	 "-reference_gene=s"    => \$reference_gene,
	 "-other_genes=s{,}"    => \@other_genes,
	 "-predict_for=s"    => \$predict_for,
	 "-learn_group_A=s{,}"    => \@learn_group_A,
	 "-learn_group_B=s{,}"    => \@learn_group_B,
	 "-test_group=s{,}"    => \@test_group,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $array_dataset) {
	$error .= "the cmd line switch -array_dataset is undefined!\n";
}
unless ( defined $reference_gene) {
	$error .= "the cmd line switch -reference_gene is undefined!\n";
}
unless ( defined $other_genes[0]) {
	$error .= "the cmd line switch -other_genes is undefined!\n";
}
unless ( defined $predict_for) {
	$error .= "the cmd line switch -predict_for is undefined!\n";
}
unless ( defined $learn_group_A[0]) {
	$error .= "the cmd line switch -learn_group_A is undefined!\n";
}
unless ( defined $learn_group_B[0]) {
	$error .= "the cmd line switch -learn_group_B is undefined!\n";
}
unless ( defined $test_group[0]) {
	$error .= "the cmd line switch -test_group is undefined!\n";
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
 command line switches for model_geneInfluence.pl

   -array_dataset     :a file containing the array values
   -reference_gene    :one reference gene, that will be used to create the model
   -other_genes       :the difference between these genes and the reference_gene
                       will be used to create the model
   -predict_for       :the name the prediction should have
   -learn_group_A     :the control group
   -learn_group_B     :a group that shows the value we should predict for
   -test_group        :a group that we should predict the predict_for value
   -outfile           :a outfile that will contain the results

   -help           :print this help
   -debug          :verbose output
   

"; 
}

my ( $task_description);

$task_description .= 'model_geneInfluence.pl';
$task_description .= " -array_dataset $array_dataset" if (defined $array_dataset);
$task_description .= " -reference_gene $reference_gene" if (defined $reference_gene);
$task_description .= ' -other_genes '.join( ' ', @other_genes ) if ( defined $other_genes[0]);
$task_description .= " -predict_for $predict_for" if (defined $predict_for);
$task_description .= ' -learn_group_A '.join( ' ', @learn_group_A ) if ( defined $learn_group_A[0]);
$task_description .= ' -learn_group_B '.join( ' ', @learn_group_B ) if ( defined $learn_group_B[0]);
$task_description .= ' -test_group '.join( ' ', @test_group ) if ( defined $test_group[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);

my $expression_table = data_table->new();
$expression_table->read_file($array_dataset);

$expression_table->define_subset( 'learn_A', \@learn_group_A);
$expression_table->define_subset( 'learn_B', \@learn_group_B);
$expression_table->define_subset( 'test', \@test_group );
$expression_table->createIndex( "Gene Symbol");
## In this model I will have 
my $model = {};

## I need to populate two probabilityFunctions per gene_gene value set
my ($ref_exp_values_A, $ref_exp_values_B, $temp, $data_A, $data_B, @data );

$ref_exp_values_A = $expression_table->get_subset_4_columnName_and_entry( "Gene Symbol", $reference_gene, 'learn_A');
$ref_exp_values_B = $expression_table->get_subset_4_columnName_and_entry( "Gene Symbol", $reference_gene, 'learn_B');

@data = undef;
foreach my $var_gene ( @other_genes ){
	$data_A = $expression_table->get_subset_4_columnName_and_entry( "Gene Symbol", $var_gene, 'learn_A');
	$data_B = $expression_table->get_subset_4_columnName_and_entry( "Gene Symbol", $var_gene, 'learn_B');
	
}

## and now I have to create a summary p_value for the state!


sub _deg{
	my ( $expA, $expB ) = @_;
	return 
}
