#! /usr/bin/perl -w

#  Copyright (C) 2010-11-29 Stefan Lang

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

=head1 reanalyze_Pathway_research_massive_results.pl

The scrupt will help in analyzing the pathway summary file, that is created during a Apply_KEGG_Search_to_Phenotype_Correlations.pl run.

To get further help use 'reanalyze_Pathway_research_massive_results.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::Latex_Document;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, $outfile, $mode, $KEGG_aim );

Getopt::Long::GetOptions(
	"-infile=s"   => \$infile,
	"-outfile=s"  => \$outfile,
	"-mode=s"     => \$mode,
	"-KEGG_aim=s" => \$KEGG_aim,
	"-help"       => \$help,
	"-debug"      => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $KEGG_aim ) {
	$error .= "the cmd line switch -KEGG_aim  is undefined!\n";
}
unless ( defined $mode ) {
	$mode = 'all';

	#$error .= "the cmd line switch -mode is undefined!\n";
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
 command line switches for reanalyze_Pathway_research_massive_results.pl

   -infile   :the Apply_KEGG_Search_to_Phenotype_Correlations.pl
              'pathway_and_setting_2_genes.txt' file
   -outfile  :any file you want the output in
   -mode     :you might be able to modify the output type here - at the moment 
              I only support the default 'all'
   -KEGG_aim :Please describe, what you did analyse in the KEGG pathway search.
   
   -help   :print this help
   -debug  :verbose output
   

";
}

my ($task_description);

$task_description .= 'reanalyze_Pathway_research_massive_results.pl';
$task_description .= " -infile $infile" if ( defined $infile );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -KEGG_aim" if ( defined $KEGG_aim );
$task_description .= " -mode $mode" if ( defined $mode );

my ( $document, $latex_result, $temp, $actual_paragraph );
$document = data_table->new();
$document->read_file($infile);
## Table headers are phenoytpe sub_type pathway gene

## First I want to know how manny pathways are described in the analysis
$KEGG_aim .= "." unless  ( $KEGG_aim =~ m/\.$/ );
$latex_result = stefans_libs::Latex_Document->new();
$latex_result->Section('Initial Description');
$latex_result->Section('Initial Description')->AddText(
"we have opened the text description of a large scale KEGG pathway search.\n"
	  ."The aim of the KEGG analysis was: $KEGG_aim\n"
);

$temp = $document->pivot_table(
	{
		'grouping_column'    => 'pathway',
		'Sum_data_column'    => 'gene',
		'Sum_target_columns' => [ 'gene amount', 'gene list' ],
		'Suming_function'    => sub {
			my $sum = 0;
			my $list;
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				##do the +=2 because we have two columns per data line
				$list->{ $_[ $i + 1 ] } = 1;
			}
			return scalar( keys %$list ), join( " ", sort keys %$list );
		  }
	}
);

$actual_paragraph = $latex_result->Section('Initial Description')->AddText("In total we have identified ".scalar (@{$temp->{'data'}} )." different pathways "
."containing in mean ".sprintf('%.2f',root->mean( $temp->getAsArray('gene amount')))." genes.");

$latex_result -> write_tex_file ( $outfile );