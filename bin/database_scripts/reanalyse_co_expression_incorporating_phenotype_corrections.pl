#! /usr/bin/perl -w

#  Copyright (C) 2010-11-03 Stefan Lang

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

=head1 reanalyse_co_expression_incorporating_phenotype_corrections.pl

This script will correct a co-expression dataset for a growing list of phenotypes and then will create the co-expression networks from the corrected expression values. To estimate the differences between the datasets, we will correct for multiple phenotypes one by a time, do the co-expression, create the network statistics and finally calculate p_values for the KEGG pathways. These p_values from the KEGG pathways will be used to identify putatively important KEGG pathways. To include as much information about the pathways as possible, the connection nets will be created using R_square cut offs of 0.7, 0.75 and 0.8. The -log10 of the p_values for the analysies will be used to represent a expresseion dataset with three dots in a figure. The dots will be colored according to the R_square value. I hope to be able to really identify the sweet spot in the downtream analysis.

To get further help use 'reanalyse_co_expression_incorporating_phenotype_corrections.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use File::Copy;
use stefans_libs::file_readers::CoExpressionDescription;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,                    $debug,
	$database,                @pattern,
	$description_table_name,  $expression_data,
	$phenotype_data,          @description_columns_to_keep,
	@remove_these_phenotypes, @seeder_genes,
	$outpath
);

Getopt::Long::GetOptions(
	"-expression_data=s"                => \$expression_data,
	"-phenotype_data=s"                 => \$phenotype_data,
	"-description_columns_to_keep=s{,}" => \@description_columns_to_keep,
	"-remove_these_phenotypes=s{,}"     => \@remove_these_phenotypes,
	"-seeder_genes=s{,}"                => \@seeder_genes,
	"-outpath=s"                        => \$outpath,
	"-p4cS=s{,}"                        => \@pattern,
	"-description_table_name=s"         => \$description_table_name,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $expression_data ) {
	$error .= "the cmd line switch -expression_data is undefined!\n";
}
unless ( defined $description_table_name ) {
	$error .= "the cmd line switch -description_table_name is undefined!\n";
}
unless ( defined $phenotype_data ) {
	$error .= "the cmd line switch -phenotype_data is undefined!\n";
}
unless ( defined $description_columns_to_keep[0] ) {
	@description_columns_to_keep = ( 'Probe Set ID', 'Gene Symbol' );
}
else {
	my $OK = 0;
	foreach (@description_columns_to_keep) {
		$OK = 1 if ( $_ eq 'Probe Set ID' );
	}
	push( @description_columns_to_keep, 'Probe Set ID' ) unless ($OK);
	$OK = 0;
	foreach (@description_columns_to_keep) {
		$OK = 1 if ( $_ eq 'Gene Symbol' );
	}
	push( @description_columns_to_keep, 'Gene Symbol' ) unless ($OK);
}
unless ( defined $remove_these_phenotypes[0] ) {
	$error .= "the cmd line switch -remove_these_phenotypes is undefined!\n";
}
unless ( defined $pattern[0] ) {
	$error .= "the cmd line switch -p4cS is undefined!\n";
}
unless ( defined $seeder_genes[0] ) {
	$error .= "the cmd line switch -seeder_genes is undefined!\n";
}
elsif ( -f $seeder_genes[0] ) {
	my @temp;
	open( IN, "<$seeder_genes[0]" )
	  or die "could not open seeder genes file '$seeder_genes[0]'\n";
	while (<IN>) {
		chomp($_);
		push( @temp, split( /\s/, $_ ) );
	}
	shift(@temp) unless ( defined $temp[0] );
	@seeder_genes = @temp;
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
 command line switches for reanalyse_co_expression_incorporating_phenotype_corrections.pl

   -expression_data         :a tab separated expression dataset
   -phenotype_data          :a tab separated table file containing all phenotypes
   -remove_these_phenotypes :a list of phenotypes that should be used to 
                             correct the original expression data for
   -description_table_name  :the name of the data table, that describes the 
                             intermediate output files - a tab separated table that includes 
                             all data necessary to create the final plots
                             This file together with the log file created 
                             explains all results from step 1 to 4
                             
   -seeder_genes :a list or file containing the co-expression seeder genes
   -outpath      :the path to store the results in
   -p4cS         :the pattern to select the data containing columns for the co_expression analysis
   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= "perl "
  . root->perl_include()
  . " $plugin_path/"
  . 'reanalyse_co_expression_incorporating_phenotype_corrections.pl';
$task_description .= " -expression_data $expression_data"
  if ( defined $expression_data );
$task_description .= " -phenotype_data $phenotype_data"
  if ( defined $phenotype_data );
$task_description .=
  ' -description_columns_to_keep ' . join( ' ', @description_columns_to_keep )
  if ( defined $description_columns_to_keep[0] );
$task_description .=
  ' -remove_these_phenotypes ' . join( ' ', @remove_these_phenotypes )
  if ( defined $remove_these_phenotypes[0] );
$task_description .= ' -seeder_genes ' . join( ' ', @seeder_genes )
  if ( defined $seeder_genes[0] );
$task_description .= " -outpath $outpath" if ( defined $outpath );
$task_description .= " -p4cS '" . join( "' '", @pattern ) . "'";
$task_description .= " -description_table_name $description_table_name";

print $task_description, "\n" if ($debug);

open( LOG,
	">$outpath/reanalyse_co_expression_incorporating_phenotype_corrections.log"
  )
  or die "I could not create the log file "
  . "'$outpath/reanalyse_co_expression_incorporating_phenotype_corrections.log'\n$_\n";
print LOG $task_description . "\n";

my ( @temp, $phenotype, $cmd, $expression_source, $co_expression_net, $OK,
	$r_cutoff );
	
@temp = ('1.no_residuals');
$expression_source = $expression_data;
my $data_table = stefans_libs::file_readers::CoExpressionDescription->new();

## First we should perhaps analyse the not normalized dataset - or?


&process_files_after_expression_data_definition();
@temp = ();
for ( my $i = 0 ; $i < @remove_these_phenotypes ; $i++ ) {
	$temp[$i] = $remove_these_phenotypes[$i];
	$expression_source = "$expression_data" . "_" . join( "_", @temp ) . ".txt";
	&process_files_after_expression_data_definition();
	

}

## now we should have all the raw data in one folder
## the interesting data files are called like
# "$outpath/Pathways_search_".join("_",@temp).connection_group_genes.txt or .genes.txt or .expression_net_statistcs.txt
## hopefully all the information needed is stored inside either the log file or the data_table object.

$task_description =~ s/ -/\n-/g;
$data_table->Add_2_Description(
	"this file was created using the command:\n$task_description");

$data_table->print2file($description_table_name);

## and not TaDaaaa - the new script came into existance!
$cmd = "perl "
	  . root->perl_include()
	  . " $plugin_path/plot_co_expression_incorporating_phenotype_corrections_results.pl ".
	  "-tab_separated_reanalysis_result $description_table_name -outpath $outpath/Figures";
print LOG $cmd;
system ( $cmd );

close(LOG);


sub process_files_after_expression_data_definition{
	$cmd = "perl "
	  . root->perl_include()
	  . " $plugin_path/../array_analysis/remove_variable_influence_from_expression_array.pl -expression_data "
	  . "$expression_data -phenotype_data $phenotype_data -description_columns_to_keep '"
	  . join( "' '", @description_columns_to_keep ) . "' "
	  . "-remove_these_phenotypes '"
	  . join( "' '", @temp )
	  . "' -outfile $expression_source";
	print $cmd, "\n" if ($debug);
	print LOG $cmd . "\n";
	unless ( -f $expression_source ) {
		system( $cmd );
	}
	Carp::confess(
"OOPS - the outfile '$expression_source' from the phenotype corrections was not craeted!\n"
	) unless ( -f $expression_source );

	print "The corrected expression values are there: '$expression_source'\n";

	## Now we need to calculate the co-expression analysis
	$co_expression_net = "$outpath/Co_expression_net_batch_analysis_"
	  . join( "_", @temp ) . ".txt";
	$cmd = "perl "
	  . root->perl_include()
	  . " $plugin_path/expression_net/createConnectionNet_4_expressionArrays.pl "
	  . "-array_values $expression_source -r_cutoff 0.7 -p4cS '"
	  . join( "' '", @pattern ) . "' "
	  . "-outfile $co_expression_net -start_at_line 1 -correlate_with_genes '"
	  . join( "' '", @seeder_genes ) . "'";
	print LOG $cmd . "\n";
	print $cmd, "\n" if ($debug);
	$OK = 0;
	if ( -f "$co_expression_net.log" ) {
		open( PREVIOUS_LOG, "<$co_expression_net.log" );
		while (<PREVIOUS_LOG>) {
			$OK = 1 if ( $_ eq $cmd . "\n" );
		}
		close(PREVIOUS_LOG);
	}
	system($cmd ) unless ($OK);

	## OK - now we have the connection nets R_sqare 0.7, 0.75 and 0.8!
	$cmd = "perl "
	  . root->perl_include()
	  . " $plugin_path/expression_net/expression_net_to_R_network.pl  "
	  . "-infile  $co_expression_net -only_statistics -initial_genes '"
	  . join( "' '", @seeder_genes ) . "' "
	  . "-outpath $outpath/temp ";
	foreach $r_cutoff ( 0.7, 0.75, 0.8 ) {
		print $cmd. " -R_squared $r_cutoff\n", "\n" if ($debug);
		print LOG $cmd . " -R_squared $r_cutoff\n";
		system( $cmd. " -R_squared $r_cutoff\n" );
		## now I need to rescue the statistics files as they will be overwritten whenever we call that script!
		foreach (
			qw/connection_group_genes.txt genes.txt expression_net_statistcs.txt/
		  )
		{
			copy( "$outpath/temp/$_",
				    "$outpath/Co_expression_net_batch_analysis_"
				  . join( "_", @temp )
				  . ".R_squared_$r_cutoff.$_" );
		}
	}

	## and now we need to estimate the KEGG pathway incudings!
	$cmd = "perl "
	  . root->perl_include()
	  . " $plugin_path/Pathway_searches/get_Pathway_descriptions_4_gene_names.pl "
	  . "-outpath $outpath/temp -outfile temp -kegg_reference_geneset HuGene_v1 -only_p_values -desease T2D ";
	foreach $r_cutoff ( 0.7, 0.75, 0.8 ) {
		foreach (qw/connection_group_genes.txt genes.txt/) {
			print $cmd
			  . "-genes $outpath/Co_expression_net_batch_analysis_"
			  . join( "_", @temp )
			  . ".R_squared_$r_cutoff.$_ ", "\n"
			  if ($debug);
			print LOG $cmd
			  . " -genes $outpath/Co_expression_net_batch_analysis_"
			  . join( "_", @temp )
			  . ".R_squared_$r_cutoff.$_ \n";
			system( $cmd
				  . " -genes $outpath/Co_expression_net_batch_analysis_"
				  . join( "_", @temp )
				  . ".R_squared_$r_cutoff.$_" );
			copy( "$outpath/temp/temp.p_values.txt",
				    "$outpath/Pathways_search_"
				  . join( "_", @temp )
				  . ".R_squared_$r_cutoff.$_" );
			$data_table->AddDataset(
				{
					'r_cutoff'           => $r_cutoff,
					'gene list type'     => $_,
					'phenotype list'     => join( ";", @temp ),
					'phenotype count'    => scalar(@temp),
					'KEGG results table' => "$outpath/Pathways_search_"
					  . join( "_", @temp )
					  . ".R_squared_$r_cutoff.$_"
				}
			);
		}
	}
}