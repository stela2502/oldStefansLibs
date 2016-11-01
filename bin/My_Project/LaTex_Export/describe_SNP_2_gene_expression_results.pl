#! /usr/bin/perl -w

#  Copyright (C) 2010-08-23 Stefan Lang

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

=head1 describe_SNP_2_gene_expression_results.pl

This script will call the scripts get_Genes_close_to_SNPs and 
qualify_genes_with_pubmed_search on the results of SNP_2_Gene_Expression.pl, 
trying to get the next point of evidence, that we could identify important 
facts about T2D.

To get further help use 'describe_SNP_2_gene_expression_results.pl -help' 
at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::MyProject::compare_SNP_2_Gene_expression_results;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $only_figure, $task,
	@SNP_2_Gene_Expression_files, $latex_title, $outpath, $p_value_cutoff );

Getopt::Long::GetOptions(
	"-SNP_2_Gene_Expression_files=s{,}" => \@SNP_2_Gene_Expression_files,
	"-latex_title=s"                    => \$latex_title,
	"-outpath=s"                        => \$outpath,
	"-p_value_cutoff=s"                 => \$p_value_cutoff,
	"-task=s"                           => \$task,
	"-only_figure"                      => \$only_figure,
	"-help"                             => \$help,
	"-debug"                            => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $SNP_2_Gene_Expression_files[0] ) {
	$error .=
	  "the cmd line switch -SNP_2_Gene_Expression_files is undefined!\n";
}
unless ( defined $latex_title ) {
	$error .= "the cmd line switch -latex_title is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
unless ( defined $p_value_cutoff ) {
	$error .= "the cmd line switch -p_value_cutoff is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for describe_SNP_2_gene_expression_results.pl

   -SNP_2_Gene_Expression_files :a list of files containing SNP_2_gene_expression results
   
   -latex_title    :the name and title of the latex file
   -outpath        :the outpath
   -p_value_cutoff :an optional cutoff for the gene SNP correlation
   -task           :one of 'all' 'figure' 'pubmed' 'SNP_highlight'

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'describe_SNP_2_gene_expression_results.pl';
$task_description .=
  ' -SNP_2_Gene_Expression_files ' . join( ' ', @SNP_2_Gene_Expression_files )
  if ( defined $SNP_2_Gene_Expression_files[0] );
$task_description .= " -latex_title $latex_title" if ( defined $latex_title );
$task_description .= " -outpath $outpath"         if ( defined $outpath );
$task_description .= " -p_value_cutoff $p_value_cutoff"
  if ( defined $p_value_cutoff );

my ( $data_obj, $SNP_correlations, $less_restrictive_data_object );
$SNP_correlations = 0;
$data_obj         = compare_SNP_2_Gene_expression_results->new();
foreach my $data_file (@SNP_2_Gene_Expression_files) {
	$SNP_correlations += $data_obj->Add_file( $data_file, $p_value_cutoff );
}
if ( $SNP_correlations == 0 ) {
	warn
"we do not have any SNPs that correlate at the given cutoff with any of the analyzed genes!\n";
	exit -1;
}

open ( LOG, ">$outpath/describe_SNP_2_gene_expression_results_$p_value_cutoff.log") or die "could not create the log file!\n";
print LOG $task_description;
close ( LOG );

open ( OUT ,">$outpath/rsIDs_2_gene_"."$p_value_cutoff.xls" ) or die "I could not craete the file '$outpath/rsIDs_"."$p_value_cutoff.xls'\n";
foreach ( sort keys %{$data_obj->{'SNP_count'}} ){
	print OUT "$_\t".join(", ", sort @{$data_obj->{'SNP_count'}->{$_}})."\n";
}
close ( OUT );

open ( OUT ,">$outpath/rsIDs_"."$p_value_cutoff.xls" ) or die "I could not craete the file '$outpath/rsIDs_"."$p_value_cutoff.xls'\n";
print OUT join("\n", keys %{$data_obj->{'SNP_count'}} );
close ( OUT );


if ( $task eq "SNP_highlight" || $task eq "all" ){
	## I want to identify the most interesting regions!
	$less_restrictive_data_object = compare_SNP_2_Gene_expression_results->new();
	foreach my $data_file (@SNP_2_Gene_Expression_files) {
		$less_restrictive_data_object->Add_file( $data_file, $p_value_cutoff * 10 );
	}
	
	my $interesting_regions_table = $data_obj ->identify_regions_with_more_entries_in_object( $less_restrictive_data_object);
	&plot_figure($less_restrictive_data_object, $p_value_cutoff * 10 );
	$interesting_regions_table->print2file(
		$outpath . "/SNP_highlight"."_"."$p_value_cutoff.tsv");
	print "Done!\n";
	exit;
}



unless ( $only_figure ) {
	my ( $SNP_description_table, $gene_description_table ) = 
		&print_data_files( $data_obj, $p_value_cutoff );
}

my $SNP_on_Chromosome = &plot_figure( $data_obj, $p_value_cutoff );

print "Done!\n";


### SUBs

sub plot_highlight_figure{
	&plot_figure( @_);
}

sub print_data_files{
	my ( $data_obj, $p_value_cutoff ) = @_;
	my ( $SNP_description_table, $gene_description_table ) =
	  $data_obj->qualify_SNPs( 'H_sapiens', 100000 );
	$SNP_description_table->print2file(
		$outpath . "/SNP_description_table_$p_value_cutoff.tsv" );
	$gene_description_table->print2file(
		$outpath . "/gene_description_table_$p_value_cutoff.tsv" );
	return $SNP_description_table, $gene_description_table;
}

sub plot_figure {
	my ( $data_obj, $p_value_cutoff ) = @_;
	my $SNP_on_Chromosome =
 	 $data_obj->plot_chromosome_distribution(
		$outpath . "/Chromosomal_distribution_of_SNPs_$p_value_cutoff",
		'H_sapiens' );
	$SNP_on_Chromosome->print2file(
		$outpath . "/SNP_on_chromosome_$p_value_cutoff.tsv" );
	return $SNP_on_Chromosome;
}




