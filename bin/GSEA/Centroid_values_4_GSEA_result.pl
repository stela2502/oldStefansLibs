#! /usr/bin/perl -w

#  Copyright (C) 2010-12-14 Stefan Lang

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

=head1 Centroid_values_4_GSEA_result.pl

Analyze all GSEA result tables for the influence of a list of phenotyoes on the identifies Pathways.

To get further help use 'Centroid_values_4_GSEA_result.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,           $debug,           $database,
	@GSEA_results,   $expression_file, @p4cS,
	$phenotype_file, @phenotypes,      $kegg_reference_geneset,
	$outpath
);

Getopt::Long::GetOptions(
	"-GSEA_results=s{,}"        => \@GSEA_results,
	"-expression_file=s"        => \$expression_file,
	"-p4cS=s{,}"                => \@p4cS,
	"-phenotype_file=s"         => \$phenotype_file,
	"-phenotypes=s{,}"          => \@phenotypes,
	"-outpath=s"                => \$outpath,
	"-kegg_reference_geneset=s" => \$kegg_reference_geneset,
	"-help"                     => \$help,
	"-debug"                    => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $GSEA_results[0] ) {
	$error .= "the cmd line switch -GSEA_results is undefined!\n";
}
unless ( defined $expression_file ) {
	$error .= "the cmd line switch -expression_file is undefined!\n";
}
unless ( defined $p4cS[0] ) {
	$error .= "the cmd line switch -p4cS is undefined!\n";
}
unless ( defined $phenotype_file ) {
	$error .= "the cmd line switch -phenotype_file is undefined!\n";
}
unless ( defined $phenotypes[0] ) {
	$error .= "the cmd line switch -phenotypes is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( !-d $outpath ) {
	mkdir($outpath);
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
 command line switches for Centroid_values_4_GSEA_result.pl

   -GSEA_results    :A list of tab separated GSEA results descibing single pathways
   -expression_file :the expression data that was used to create the GSEA result
   -p4cS            :a pattern or list of Sample ids to select for which samples 
                     I should do the analysis for
   -phenotype_file  :a tab separated text file containing the phenotypes
   -phenotypes      :a list of phenotype names mentioned in the phenotypes file that 
                     you want to analyze the GSEA data for
   -outpath         :the path to store all outfiles in
   
   -kegg_reference_geneset
                    :the name of the gene set where you have drawn your genes from 
                     needed to calculate the hypergeometric test the names are stored 
                     in the column 'reference_dataset' in the table handled by the class
                     stefans_libs::databse::pathways::kegg::hypergeometric_max_hits
                     for my installation I need to take 'HUGene_v1'
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/Centroid_values_4_GSEA_result.pl';
$task_description .= ' -GSEA_results ' . join( ' ', @GSEA_results )
  if ( defined $GSEA_results[0] );
$task_description .= " -expression_file $expression_file"
  if ( defined $expression_file );
$task_description .= " -p4cS '" . join( "' '", @p4cS ) if ( defined $p4cS[0] );
$task_description .= " -phenotype_file $phenotype_file"
  if ( defined $phenotype_file );
$task_description .= ' -phenotypes "' . join( '" "', @phenotypes ) . '"'
  if ( defined $phenotypes[0] );
$task_description .= " -outpath $outpath" if ( defined $outpath );
$task_description .= " -kegg_reference_geneset $kegg_reference_geneset"
  if ( defined $kegg_reference_geneset );

open( LOG, ">$outpath/Centroid_values_4_GSEA_result.log" )
  or die
"could not create log file '$outpath/Centroid_values_4_GSEA_result.log'\n$!\n";
print LOG $task_description . "\n";
close(LOG);

## NAME    PROBE   DESCRIPTION<br>(from dataset)   GENE SYMBOL     GENE_TITLE      RANK IN GENE LIST       RANK METRIC SCORE       RUNNING ES      CORE ENRICHMENT

my ( $table, @genes, $cmd, $filename, @temp );

foreach my $file (@GSEA_results) {
	$table = data_table->new();
	$table->read_file($file);
	@temp = split( "/", $file );
	$filename = pop(@temp);
	$filename =~ s/\.xls$//;
	unless ( defined $table->Header_Position('PROBE') ) {
		warn
"Oh - we have a problem here - the file is not a GSEA results text file!\n";
		next;
	}
	## I want to have the overall analysis!
	@genes = @{ $table->getAsArray('PROBE') };
	#&make_PDF( \@genes, "all_genes" );
	@genes = @{
		$table->select_where( 'CORE ENRICHMENT',
			sub { return 1 if ( $_[0] eq "Yes" ) } )->getAsArray('PROBE')
	  };
	&make_PDF( \@genes, "Core_Enriched_Genes" );
	@genes = @{
		$table->select_where( 'CORE ENRICHMENT',
			sub { return 1 if ( $_[0] eq "No" ) } )->getAsArray('PROBE')
	  };
	print "Do we have any genes (?):" . join( ", ", @genes ) . "\n";
	#&make_PDF( \@genes, "NOT_Core_Enriched_Genes" );
}

sub make_PDF {
	my ( $genes, $type ) = @_;
	die "I did not gen genes for the setting $filename $type\n"
	  unless ( scalar(@$genes) > 0 );
	$cmd = 'perl '
	  . root->perl_include() . ' '
	  . $plugin_path
	  . '/../Centroid_Expression/Centroid_analysis_for_gene_list.pl '
	  . " -expression_file $expression_file -p4cS '"
	  . join( "' '", @p4cS )
	  . "' -phenotype_file $phenotype_file";
	$cmd .= ' -phenotypes "' . join( '" "', @phenotypes ) . '"'
	  if ( defined $phenotypes[0] );
	$cmd .= " -outfile $outpath/$filename/$type ";
	$cmd .= ' -genes ' . join( " ", @$genes );
	$cmd .= " -pathway_name $filename";
	$cmd .= " -recalc_stat";
	$cmd .= " -kegg_reference_geneset $kegg_reference_geneset"
	  if ( defined $kegg_reference_geneset );
	&print_2_log( $cmd . "\n" );
	mkdir("$outpath/$filename/") unless ( -d "$outpath/$filename/" );
	system($cmd );
	system("make -C $outpath/$filename/ ");
	
	## And now we want to see the correlation for the best 3 genes for the phenotypes ?
	
}

sub print_2_log {
	my ($str) = @_;
	open( LOG, ">>$outpath/Centroid_values_4_GSEA_result.log" )
	  or die
"I could not open the log file $outpath/Centroid_values_4_GSEA_result.log\n$!\n";
	print LOG $str;
	close(LOG);
}
