#! /usr/bin/perl -w

#  Copyright (C) 2010-11-04 Stefan Lang

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

=head1 plot_co_expression_incorporating_phenotype_corrections_results.pl

THis is the 5th step in the reanalysis process - idenitify pathways that seam to be affected and and show how these the p_values for these pathways differ (a) by the choosen R_square and (b) on the residuals used.

To get further help use 'plot_co_expression_incorporating_phenotype_corrections_results.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::CoExpressionDescription;
use stefans_libs::plot::simpleXYgraph;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $tab_separated_reanalysis_result, $outpath);

Getopt::Long::GetOptions(
	 "-tab_separated_reanalysis_result=s"    => \$tab_separated_reanalysis_result,
	 "-outpath=s"    => \$outpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $tab_separated_reanalysis_result) {
	$error .= "the cmd line switch -tab_separated_reanalysis_result is undefined!\n";
}
unless ( defined $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
elsif ( ! -d  $outpath){
	mkdir ( $outpath );
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
 command line switches for plot_co_expression_incorporating_phenotype_corrections_results.pl

   -tab_separated_reanalysis_result :the final table that is created using the scipt
                      reanalyse_co_expression_incorporating_phenotype_corrections.pl
                
   -outpath  :the outpath for the whole analysis results
   
   -help  :print this help
   -debug :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'plot_co_expression_incorporating_phenotype_corrections_results.pl';
$task_description .= " -tab_separated_reanalysis_result $tab_separated_reanalysis_result" if (defined $tab_separated_reanalysis_result);
$task_description .= " -outpath $outpath" if (defined $outpath);


## Check the infile(s)
my ($description_file, $kegg_results );

$description_file = stefans_libs::file_readers::CoExpressionDescription->new();
$description_file -> read_file( $tab_separated_reanalysis_result );

foreach ( @{$description_file->get_column_entries ( 'KEGG results table')} ){
	die "sorry, but the KEGG results table file '$_' can not be found!\n" unless ( -f $_ );
}

$description_file->Link_in_KEGG_results();

my ( @genes_pathways, @expression_net_pathways, $hash, @merged );

@genes_pathways = $description_file->get_interesting_Pathways('genes.txt');
@expression_net_pathways = $description_file->get_interesting_Pathways('connection_group_genes.txt');

print "pathways in the overall list:\n".join(", ",sort(@genes_pathways))."\n";
print "pathways in the co-expression net gene list:\n".join(", ",sort(@expression_net_pathways))."\n";
## to be honest - I want to get the information for all these pathways in both conditions!
foreach ( @genes_pathways, @expression_net_pathways){
	$hash -> {$_} = 1;
}
@merged = ( keys %$hash );

my $latex_figure_str = $description_file->plot_p_value_changes_for_these_pathways( \@merged, $outpath );

open ( LATEX, ">$tab_separated_reanalysis_result.tex" ) or die "I could not create the latex summary for this analysis!\n$!\n";
 
print LATEX '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ KEGG Pathways Identified during the Co-Expression Analysis }
\author{Stefan Lang}\\
\date{' . root->Today() . '}
\maketitle

\section{Introduction}

The dataset for this analysis is based on several sets of modified Islet expression datasets. The influence of a list of phenotypes was removed from
the initial expression values. For each of these new datasets, a co-expression analysis was performed and the genes
identified either by simple co-expression or during the co-expression net approach were matched against the KEGG pathways.
The co-expression analysis was performed with three different R$^2$ cut-off levels (0.7; 0.75 and 0.8). 

Each KEGG pathway that passed the significance threashhold (bon ferroni correction for each co-expression dataset) was analyzed.

Each Figure represents one Pathway in all the different datasets.

\section{Figures}

'.$latex_figure_str.'

\bibliographystyle{plain}
\bibliography{library}

\end{document}
';

close ( LATEX );
my $cmd = "perl "
	  . root->perl_include()
	  . " $plugin_path/../text/trimPictures.pl -infile $outpath/*.svg -outpath $outpath";
#system ( $cmd );


