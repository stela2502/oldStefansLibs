#! /usr/bin/perl -w

#  Copyright (C) 2010-11-24 Stefan Lang

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

=head1 plot_Phenotype_to_phenotype_correlations.pl

This script will create a comrehensive comparison between the phenotypes based on one initial phenotype of interest. Therefore it can aswer questions like - does the phenotype Purity affect the Diabetes status.

To get further help use 'plot_Phenotype_to_phenotype_correlations.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::stat_results;
use stefans_libs::Latex_Document;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @phenotype_correlations, $PHoI, $outfile );

Getopt::Long::GetOptions(
	"-phenotype_correlations=s{,}" => \@phenotype_correlations,
	"-PHoI=s"                      => \$PHoI,
	"-outfile=s"                   => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $phenotype_correlations[0] ) {
	$error .= "the cmd line switch -phenotype_correlations is undefined!\n";
}
unless ( defined $PHoI ) {
	$error .= "the cmd line switch -PHoI is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for plot_Phenotype_to_phenotype_correlations.pl

   -phenotype_correlations   :a list of phenotype to phenotype correlation files
   -PHoI     :A substring of the Phenptype of interest
   -outfile  :the tex outfile

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'plot_Phenotype_to_phenotype_correlations.pl';
$task_description .=
  ' -phenotype_correlations ' . join( ' ', @phenotype_correlations )
  if ( defined $phenotype_correlations[0] );
$task_description .= " -PHoI $PHoI"       if ( defined $PHoI );
$task_description .= " -outfile $outfile" if ( defined $outfile );

my (
	$stat_results, $Latex_Document, $outpath,
	$filename,     @temp,           $temp,
	@file,         $table_obj,      $randomData,
	$figure_files, @figures, $figure_register, $phenotype, $figure_obj, $correlation_type
);

@temp     = split( "/", $outfile );
$filename = pop(@temp);
$outpath  = join( "/", @temp );

$stat_results   = stat_results->new();
$Latex_Document = stefans_libs::Latex_Document->new();
$Latex_Document -> Title ( "Analyzing the effect of $PHoI on all other phenotypes");
$Latex_Document -> Author ( "Stefan Lang" );
 
$temp = $Latex_Document->Section( "Introduction");
$temp ->AddText( "The script command that did produce this PDF was '$task_description'. \n"
."We checked for the correlation between the phenotype $PHoI and all other phenotypes. \n"
."The correlations are summed displayed in the results section." );

$figure_register = data_table->new();
foreach ( 'correlated phenotype', 'correlation type', 'figure' ) {
	$figure_register->Add_2_Header($_);
}
$temp = $Latex_Document->Section( "Results" );
$temp = $temp -> AddText ( "For the moment I want to focus on the figures for each phenotype to phenoytpe correlation. ");
$temp  -> Add_Table ( $figure_register);
my $i= 0;
foreach my $infile (@phenotype_correlations) {
	$i ++;
	## I want to get the correlation to $PHoI for each of the analysies
	@file      = split( "/", $infile );
	$table_obj = $file[ @file - 1 ];
	@file      = split( /\./, $table_obj );
	$phenotype = $file[0];
	$phenotype =~ s/-Phenotype_vs_Phenotype_correlations//;
	my $table_obj = $stat_results->read_file($infile);
	$table_obj = $table_obj -> select_where ( 'Gene Symbol', sub { return 1 if ( $_[0] =~ m/$PHoI/); return 0;});
	$correlation_type = 'unknown';
	$correlation_type = "Wilcox signed rank" if ( ref($table_obj) =~ m/Wilcoxon/ );
	$correlation_type = "Spearman correlation" if ( ref($table_obj) =~ m/Spearman/ );
	if ( scalar (@{$table_obj->{'data'}}) == 0){
		$figure_register -> AddDataset ( {
			'correlated phenotype' => $phenotype, 'correlation type' => $correlation_type, 'figure' => 'no data'
		});
		next;
	}
	$figure_files = $table_obj -> plot( $outpath, $phenotype, 1 );
	foreach ( @$figure_files ){
		push ( @figures, $_);
	}
	$figure_obj = $temp->Add_Figure();
	$figure_obj -> AddPicture( {
		'placement' => 'tbp',
	'files' => $figure_files,
	'caption' => "Correlation between Phenotype $PHoI and the phenotype $phenotype",
	'width' => 0.5,
	'label' => "fig::$i"		
	} );
	$figure_register -> AddDataset ( {
			'correlated phenotype' => $phenotype, 'correlation type' => $correlation_type, 'figure' => "\\ref{fig::$i}"
		});
}
$outfile .= ".tex" unless ( $outfile =~ m/\.tex$/);
$Latex_Document -> Outpath ( $outpath );
$Latex_Document -> write_tex_file ( $outfile );
