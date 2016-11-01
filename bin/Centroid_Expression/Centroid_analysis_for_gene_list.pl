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

=head1 Centroid_analysis_for_gene_list.pl

The script uses a expression estimates file and a variable gene list to create a centroid value for the list of genes. This centrid value will then be correlated to a set of phenotypes and finally we will produce a PDF file, that summs up the whle analysis.

To get further help use 'Centroid_analysis_for_gene_list.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::stat_results;

use stefans_libs::Latex_Document;
use stefans_libs::file_readers::phenotypes;
use stefans_libs::file_readers::affymetrix_expression_result;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::database::genomeDB::gene_description;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,            $debug,          $database,
	@genes,           $gene_column,    @p4cS,
	$expression_file, $phenotype_file, @phenotypes,
	$outfile,         $pathway_name,   $outpath,
	$recalc_stat,     $filename,       @show_also_genes,
	$kegg_reference_geneset
);

Getopt::Long::GetOptions(
	"-genes=s{,}"               => \@genes,
	"-gene_column=s"            => \$gene_column,
	"-expression_file=s"        => \$expression_file,
	"-phenotype_file=s"         => \$phenotype_file,
	"-phenotypes=s{,}"          => \@phenotypes,
	"-outfile=s"                => \$outfile,
	"-pathway_name=s"           => \$pathway_name,
	"-p4cS=s{,}"                => \@p4cS,
	"-help"                     => \$help,
	"-show_also_genes=s{,}"     => \@show_also_genes,
	"-recalc_stat"              => \$recalc_stat,
	"-kegg_reference_geneset=s" => \$kegg_reference_geneset,
	"-debug"                    => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
unless ( defined $gene_column ) {

	#$error .= "the cmd line switch -gene_column is undefined!\n";
}
unless ( defined $expression_file ) {
	$error .= "the cmd line switch -expression_file is undefined!\n";
}
unless ( defined $phenotype_file ) {
	$error .= "the cmd line switch -phenotype_file is undefined!\n";
}
unless ( defined $phenotypes[0] ) {

	#$error .= "the cmd line switch -phenotypes is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
else {
	my @temp = split( "/", $outfile );
	$filename = pop(@temp);
	$outpath = join( "/", @temp );
	$error .= "OUTFILE: Sorry I need an absolute pathe for the outfile!\n"
	  if ( $outpath eq "" );
}
unless ( defined $pathway_name ) {
	$error .= "the cmd line switch -pathway_name is undefined!\n";
}
unless ( defined $p4cS[0] ) {
	$error .= "the cmd line switch -p4cS is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

unless ( -d $outpath ) {
	mkdir($outpath) or die "I could not craete the oputpath '$outpath'\n$!\n";
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for Centroid_analysis_for_gene_list.pl

   -genes           :you can either give me a list of Gene Symbols or a file containnge these
   -gene_column     :this option is only necessary, if the 'genes' file 
                     does not only contain 'Gene Symbols', but is a tab separated table file.
                     In that case I will only use the values in the column names as '-gene_column'
                     
   -expression_file :the affymetrix expression estimates file
   -p4cS            :the pattern to select the data containing columns
   
   -phenotype_file  :a tab separated file containing the phenotypes
   -phenotypes      :an optional list of phenotypes in case you do not want to analyze all phenotypes
   
   -outfile         :the outfile - please give me the absolute position,
                     as I need to create a lot of dependant files and I do not know where to put them without a path!
   -pathway_name    :a name for the pathway of genes, that we are at the moment looking at
   -recalc_stat     :force the recalcualtion of the statistics
   -show_also_genes :a list of genes, that you want to be described in the PDF like the centroid value
 
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

my ( $task_description, $expression_results, $gene_hash, $mean_centroid,
	$phenotype_obj, $cmd, $kegg_genes );

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/Centroid_analysis_for_gene_list.pl';
$task_description .= ' -genes ' . join( ' ', @genes ) if ( defined $genes[0] );
$task_description .= " -gene_column $gene_column" if ( defined $gene_column );
$task_description .= " -expression_file $expression_file"
  if ( defined $expression_file );
$task_description .= " -phenotype_file $phenotype_file"
  if ( defined $phenotype_file );
$task_description .= ' -phenotypes "' . join( '" "', @phenotypes ) . '"'
  if ( defined $phenotypes[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -pathway_name $pathway_name"
  if ( defined $pathway_name );
$task_description .= ' -p4cS "' . join( '" "', @p4cS ) . '"'
  if ( defined $p4cS[0] );
$task_description .= ' -recalc_stat' if ($recalc_stat);
$task_description .= " -kegg_reference_geneset $kegg_reference_geneset"
  if ( defined $kegg_reference_geneset );
open( LOG, ">$outfile.creation_log" )
  or die "I could not craete the log file $outfile.creation_log\n$!\n";
print LOG $task_description;
close(LOG);

## Now I need to deal with the gene lists
if ( -f $genes[0] ) {
	if ( defined $gene_column ) {
		my $data_table = data_table->new();
		$data_table->read_file( $genes[0] );
		$data_table->createIndex($gene_column);
		foreach ( $data_table->getIndex_Keys($gene_column) ) {
			$gene_hash->{$_} = 1;
		}
	}
	else {
		open( IN, "<$genes[0]" )
		  or die "could not open the genes file $genes[0]\n$!\n";
		while (<IN>) {
			chomp($_);
			foreach ( split( /\s/, $_ ) ) {
				$gene_hash->{$_} = 1;
			}
		}
	}
}
else {
	foreach (@genes) {
		$gene_hash->{$_} = 1;
	}
}

## create the centroid value
$expression_results =
  stefans_libs_file_readers_affymetrix_expression_result->new();
$expression_results->p4cS(@p4cS);
$expression_results->read_file($expression_file);
$expression_results =
  $expression_results->select_where( 'Gene Symbol',
	sub { return 1 if ( $gene_hash->{ $_[0] } ); return 0; } )
  ->normalizeExpression();

$expression_results->write_file("$outpath/nomalized_expression_values.txt");
$mean_centroid = $expression_results->Calculate_MeanCentroid();
if ( defined $show_also_genes[0] ) {
	my $gene_symbols = {};
	foreach (@show_also_genes) {
		$gene_symbols->{$_} = 1;
	}
	$mean_centroid->merge_with_data_table(
		$expression_results->select_where(
			'Gene Symbol',
			sub { return 1 if ( $gene_symbols->{ $_[0] } ); return 0; }
		)
	);
}
$mean_centroid->write_file("$outpath/meanCentroid_expression_values.txt");

## Now I need to know which Phenotypes you want to analyze!
unless ( defined $phenotypes[0] ) {
	$phenotype_obj = stefans_libs_file_readers_phenotypes->new();
	$phenotype_obj->read_file($phenotype_file);
	@phenotypes = @{ $phenotype_obj->getAsArray('phenotype') };
}

mkdir("$outpath/Statistics") unless ( -d "$outpath/Statistics" );
if ( !-f "$outpath/Statistics/$phenotypes[0]-.txt" || $recalc_stat ) {
	## calaculate the statistics - if they are not already calculated
	$cmd = 'perl '
	  . root->perl_include() . ' '
	  . $plugin_path
	  . "/../array_analysis/batchStatistics.pl -array_values  $outpath/meanCentroid_expression_values.txt"
	  . " -phenotypeTable $phenotype_file "
	  . " -p_value 1 "
	  . ' -p4cS "'
	  . join( '" "', @p4cS ) . '"'
	  . " -outfile $outpath/Statistics/.txt -phenotypes " . '"'
	  . join( '" "', @phenotypes ) . '"';
	&print_2_log( ".\n" . $cmd );
	system($cmd);
}
else {
	print
"I hope, that the statistics file '$outpath/Statistics/$phenotypes[0].txt' does exist!\n";
}

## Now I need to sum up the results!
my ( $latex_document, $summary_table, $stat_results, $phenotype_correlations );

$stat_results   = stat_results->new();
$latex_document = stefans_libs::Latex_Document->new();
$latex_document->Outpath($outpath);
$latex_document->Additional_tar_files( 'nomalized_expression_values.txt',
	'meanCentroid_expression_values.txt' );
$latex_document->Author("Stefan Lang");
$latex_document->Title( 'Influence of '
	  . scalar(@phenotypes)
	  . " Phenotypes on the Expression of "
	  . join( " ", split( /_/, $pathway_name ) )
	  . " Genes" );

$latex_document->Section( 'Introduction', 'into' );
$latex_document->Section( 'Results',      'res' );

$kegg_genes = kegg_genes->new( root->getDBH() );
$kegg_genes->add_LaTeX_section_for_Gene_List(
	{
		'genes'                  => [ keys %$gene_hash ],
		'kegg_reference_geneset' => $kegg_reference_geneset,
		'only_significant'       => 1,
		'LaTeX_object'           => $latex_document,
		'temp_path'              => "$outpath/KEGG_pictures"
	}
);

my $gene_description = gene_description->new( $kegg_genes->{'dbh'} );
$gene_description->add_LaTeX_section_for_Gene_List(
	{
		'LaTeX_object' => $latex_document,
		'genes'        => [ keys %$gene_hash ],
	}
);

$latex_document->Section( 'Methods', 'meth' )
  ->AddText(
"The mean centroid expression for a set of genes (see section \\ref{app::genes}) is based on the normalized expression for each of these genes.\n"
	  . "The expression for each gene was normalized by removing the mean expression over all samples from the expression for each sample.\n"
	  . "The centroid value is the mean normalized expression over the set of genes for each sample.\n"
	  . "Details about the sample grouping and the applied statistical test for each phenotype can be found in section \\ref{app}."
  );
$latex_document->Section( 'Appendix', 'app' );

$summary_table = data_table->new();
foreach ( 'Correlating Dataset', 'Pathway', 'p value', 'Figure' ) {
	$summary_table->Add_2_Header($_);
}
$latex_document->Section('Appendix')
  ->Section( "Genes for the pathway $pathway_name", 'app::genes' )
  ->AddText( "The pathway $pathway_name was defined as the sum of these genes: "
	  . join( ", ", sort keys %$gene_hash )
	  . "\n" );
$latex_document->Section('Introduction')
  ->AddText(
"The mean centroid value is used to sum up the expression for a set of genes.\n"
	  . "Here we wanted to analyze the expression differences for the pathway '$pathway_name' (gene list can be found in section \\ref{app::genes}), \n"
	  . "The following table sums up the results:\n" )
  ->Add_Table($summary_table);

## And now get the plots
my ( $text, $figure, $label, $type, @figure_files, $width );
mkdir("$outpath/svg/") unless ( -d "$outpath/svg/" );

foreach my $pheno_type (@phenotypes) {
	$phenotype_correlations =
	  $stat_results->read_file("$outpath/Statistics/$pheno_type-.txt");
	$latex_document->Additional_tar_files("Statistics/$pheno_type-.txt");
	$label = 'fig::' . join( "", split( /[\s\-_]/, $pheno_type ) );

	my ($p_value) = @{
		@{ $phenotype_correlations->{'data'} }[
		  $phenotype_correlations->get_rowNumbers_4_columnName_and_Entry(
			  'Gene Symbol', 'mean_centroid' )
		]
	  }[ $phenotype_correlations->Header_Position('p-value') ];
	$p_value = sprintf( '%.1e', $p_value );
	$width = 0.4;
	if ( scalar( @{ $phenotype_correlations->{'data'} } ) > 1 ) {
		## OH fuck! I need to select the 3 best looking genes too
		$type = 0;
		$phenotype_correlations =
		  $phenotype_correlations->Sort_by( [ [ 'p-value', 'numeric' ] ] )
		  ->select_where(
			"Gene Symbol",
			sub {
				return 1 if ( $_[0] eq "mean_centroid" );
				return 1 if ( $type++ < 3 );
				return 0;
			}
		  );
		  $width = 0.97; 
	}
	if ( ref($phenotype_correlations) =~ m/Spearman_result/ ) {
		$phenotype_correlations->Shift_Axes(1);
		$type = $pheno_type;
	}
	else {
		$type = '';
	}
	@figure_files =
	  @{ $phenotype_correlations->plot( "$outpath/svg/$pheno_type/", $type ) };
	$text =
	  $latex_document->Section('Results')->Section( "Phenoytpe " . $pheno_type )
	  ->AddText(
"We checked whether the phenotype $pheno_type might affect the expression of the pathway $pathway_name consisting of "
		  . scalar( keys %$gene_hash )
		  . " genes."
		  . "The probabillity for this pathway to be affected by the phenotype has been estimated as p="
		  . $p_value
		  . " (see figure \\ref{$label}).\n" );

	$figure = $text->Add_Figure();
	mkdir("$outpath/svg/$pheno_type/")
	  unless ( defined "$outpath/svg/$pheno_type/" );
	$figure->AddPicture(
		{
			'placement' => 'tbp',
			'files'     => [@figure_files],
			'caption' =>
"The effect of the phenotype $pheno_type on the pathway $pathway_name.",
			'width' => $width,
			'label' => $label
		}
	);
	$summary_table->AddDataset(
		{
			'Correlating Dataset' => $pheno_type,
			'Pathway'             => $pathway_name,
			'p value'             => $p_value,
			'Figure'              => "\\ref{$label}"
		}
	);
	foreach (@figure_files) {
		$_ =~ s/$outpath\/?//;
		$latex_document->Additional_tar_files($_);
	}
	$phenotype_correlations->Describe_Samples(
		$latex_document->Section('Appendix')
		  ->Section("Sample description for phenotype $pheno_type") );
}

$latex_document->write_tex_file($filename);

sub print_2_log {
	my ($str) = @_;
	open( LOG, ">>$outfile.creation_log" )
	  or die "I could not open the log file $outfile.creation_log\n$!\n";
	print LOG $str;
	close(LOG);
}
