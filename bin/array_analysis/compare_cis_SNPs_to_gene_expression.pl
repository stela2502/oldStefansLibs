#! /usr/bin/perl -w

#  Copyright (C) 2010-12-02 Stefan Lang

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

=head1 compare_cis_SNPs_to_gene_expression.pl

Do batch correlations with a SNP list file.

To get further help use 'compare_cis_SNPs_to_gene_expression.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::Latex_Document;
use stefans_libs::file_readers::stat_results;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $expression_estimates, @SNP_lists, $outfile,
	$p4gS, @p4cS, $batch_statistics, $Latex_Document );

$batch_statistics = $plugin_path . "/batchStatistics.pl";
die "Sorry, but I can not find the downstream script $batch_statistics\n"
  unless ( -f $batch_statistics );

$batch_statistics = "perl " . root->perl_include() . " $batch_statistics ";

Getopt::Long::GetOptions(
	"-expression_estimates=s" => \$expression_estimates,
	"-SNP_lists=s{,}"         => \@SNP_lists,
	"-outfile=s"              => \$outfile,
	"-p4gS=s"                 => \$p4gS,
	"-p4cS=s{,}"              => \@p4cS,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $expression_estimates ) {
	$error .= "the cmd line switch -expression_estimates is undefined!\n";
}
unless ( -f $SNP_lists[0] ) {
	$error .= "the cmd line switch -SNP_lists is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $p4gS ) {
	$error .= "the cmd line switch -p4gS is undefined!\n";
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

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for compare_cis_SNPs_to_gene_expression.pl
Internally I will call the script batch_statistics.pl to do the calculations

   -expression_estimates :the expression estimates file
                          has to contain a Gene Symbol column!
   -SNP_lists :a list of phenotype files
   -outfile   :a outfile
   -p4gS      :I need a pattern to select the Gene Symbol from each SNP_lists file
   -p4cS      :A pattern or list of column names that I should use to calulate

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '.root->perl_include()." $plugin_path/compare_cis_SNPs_to_gene_expression.pl";
$task_description .= " -expression_estimates $expression_estimates"
  if ( defined $expression_estimates );
$task_description .= ' -SNP_lists ' . join( ' ', @SNP_lists )
  if ( defined $SNP_lists[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -p4gS '$p4gS'"     if ( defined $p4gS );
$task_description .= ' -p4cS \'' . join( "' '", @p4cS ) . "'"
  if ( defined $p4cS[0] );

my ( $expression_file, $phenotype_file, $gene_symbol, $gene_table,
	$expr_samples, @temp, $correlatingData, $stat_obj );

$expression_file = data_table->new();
$expression_file->read_file($expression_estimates);
die
"Sorry, but the expression_estimates file does not contain a 'Gene Symbol' column"
  unless ( defined $expression_file->Header_Position('Gene Symbol') );

if ( defined $p4cS[1] ) {
	$expression_file->define_subset( 'samples', \@p4cS );
}
else {
	foreach ( @{ $expression_file->{'header'} } ) {
		push( @temp, $_ ) if ( $_ =~ m/$p4cS[0]/ );
		$expr_samples->{$_} = 1;
	}
	Carp::confess(
"I could not identify any of the columns you wanted for the pattern '$p4cS[0]'\n"
	) if ( scalar(@temp) == 0 );
	shift(@temp) unless ( defined $temp[0] );
	$expression_file->define_subset( 'samples', \@temp );
}

## OK I need to find the path I should work on!

my (
	$path,         $filename,      @outfiles, $summary_table,
	$stat_results, $results_table, $figure,   $dataset,
	$text_par,     $SNP,           $temp
);
@temp     = split( "/", $outfile );
$filename = pop(@temp);
$path     = join( "/", @temp );
$path     = "./" if ( $path eq "" );
$Latex_Document = stefans_libs::Latex_Document->new();
$Latex_Document ->Outpath( $path );
$summary_table = data_table->new();
$stat_results  = stat_results->new();
mkdir ( $path ) unless ( -d $path);
open ( LOG ,">$path/compare_cis_SNPs_to_gene_expression.log") or die "Sorry, but I could not create the log file!\n";
print LOG $task_description;
close ( LOG );

foreach ( 'Gene Symbol', 'SNP', 'p value', 'figure' ) {
	$summary_table->Add_2_Header($_);
}
$Latex_Document->Section("Introduction")
  ->AddText(
"This file was created using the script 'compare_cis_SNPs_to_gene_expression.pl'."
  );
$Latex_Document->Section("Introduction")->Section('CMD')
  ->AddText("This command did create the pdf:\n$task_description\n");
$Latex_Document->Section("Results")->Section('Significant results')
  ->AddText(
"This table sums up the significant results. All results can be found in the following sections."
  )->Add_Table($summary_table);

foreach my $SNP_list (@SNP_lists) {
	die
"I could not identify the Gene Symbol using this pattern:'$p4gS' and the filename '$SNP_list'\n"
	  unless ( $SNP_list =~ m/$p4gS/ );
	$gene_symbol = $1;
	$gene_table =
	  $expression_file->select_where( 'Gene Symbol',
		sub { return 1 if ( $_[0] eq $gene_symbol ); return 0; } );
	$gene_table -> {'no_doubble_cross'} = 1;
	unless ( scalar( @{ $gene_table->{'data'} } ) > 0 ) {
		warn
"Sorry, but I do not get gene expression for the Gene Symbol '$gene_symbol'\n";
		next;
	}
	mkdir( $path . "/" . $gene_symbol );
	$gene_table->write_file(
		$path . "/" . $gene_symbol . "/expression_values.txt" );
	print "we would now execute the script\n"
	  . $batch_statistics
	  . " -array_values $path/$gene_symbol/expression_values.txt"
	  . " -phenotypeTable $SNP_list"
	  . " -p_value 1"
	  . " -outfile $path/$gene_symbol/correlation.txt"
	  . " -p4cS '"
	  . join( "' '", @p4cS ) . "'\n";
	system( $batch_statistics
		  . " -array_values $path/$gene_symbol/expression_values.txt"
		  . " -phenotypeTable $SNP_list"
		  . " -p_value 1"
		  . " -outfile $path/$gene_symbol/correlation.txt"
		  . " -p4cS '"
		  . join( "' '", @p4cS )
		  . "'" );
	## And now I need to collect the results!
	opendir( DIR, $path . "/" . $gene_symbol );
	@outfiles = readdir(DIR);
	closedir(DIR);
	$text_par =
	  $Latex_Document->Section("Results")->Section("Gene $gene_symbol")
	  ->AddText(
		    "We checked for "
		  . ( scalar( @outfiles - 1 ) / 2 )
		  . "SNPs if they might influence the expression of the gene $gene_symbol\n"
		  . "A summary over all analyzed SNPs and the corresponding figure are shown in the following table:\n"

	  );
	my $data_table = data_table->new();
	$text_par->Add_Table($data_table);
	foreach ( 'Gene Symbol', 'SNP', 'p value', 'figure' ) {
		$data_table->Add_2_Header($_);
	}
	foreach my $correlation_file (@outfiles) {
		next if ($correlation_file eq "expression_values.txt");
		next if ($correlation_file =~ m/log$/);
		next if ( $correlation_file  =~ m/^\.+$/);
		next if ( -d $path . "/" . $gene_symbol."/". $correlation_file );
		
		print "I created the outfile '$correlation_file' and now I will start to analyze that!\n";
		## OK the files look like _rs2000796-correlation.txt
		$results_table = $stat_results->read_file("$path/$gene_symbol/$correlation_file");
		$SNP           = $correlation_file;
		$SNP           = $1 if ( $correlation_file =~ m/_(.+)-correlation.txt/ );
		print "we sum up SNP '$SNP'\n";
		unless ( scalar( @{$results_table->{'data'}} ) > 0 ) {
			$data_table->AddDataset(
				{
					'Gene Symbol' => $gene_symbol,
					'SNP'         => $SNP,
					'p value'     => 'n.a.',
					'figure'      => "--"
				}
			);
		}
		else {
			## OK I will create figures from the correlations!
			$temp = 0;
			foreach ( @{ $results_table->getAsArray('p-value') } ) {
				$temp = 1 if ( $_ < 0.05 );
			}
			if ($temp) {
				$figure =
			  $Latex_Document->Section("Results")->Section("Gene $gene_symbol")
			  ->Section($SNP)->AddText("Gene $gene_symbol and SNP $SNP")
			  ->Add_Figure();
			mkdir("$path/$gene_symbol/$SNP");
			$figure->AddPicture(
				{
					'placement' => 'tbp',
					'files' =>
					  [ @{$results_table->plot("$path/$gene_symbol/$SNP")} ],
					'caption' =>
"The correlations between the expression on gene $gene_symbol and SNP $SNP.",
					'width' => 0.9
				}
			);
			$data_table->AddDataset(
				{
					'Gene Symbol' => $gene_symbol,
					'SNP'         => $SNP,
					'p value' =>
					  join( " ", @{ $results_table->getAsArray('p-value') } ),
					'figure' => "\\ref{" . $figure->Label() . "}"
				}
			);
			
				$summary_table->AddDataset(
					{
						'Gene Symbol' => $gene_symbol,
						'SNP'         => $SNP,
						'p value' =>
						  join( " ", @{ $results_table->getAsArray('p-value') } ),
						'figure' => "\\ref{" . $figure->Label() . "}"
					}
				);
			}
			else {
				$data_table->AddDataset(
				{
					'Gene Symbol' => $gene_symbol,
					'SNP'         => $SNP,
					'p value'     =>  join( " ", @{ $results_table->getAsArray('p-value') } ),
					'figure'      => "--"
				}
			);
			}
		}
	}
}

$Latex_Document->write_tex_file($filename);
