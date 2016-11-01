#! /usr/bin/perl -w

#  Copyright (C) 2010-09-20 Stefan Lang

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

=head1 describe_genomic_regions.pl

This script takes a set of genomic region in the format 'CHR<chr_name>:<start>..<end>'. The genes close by these regions are selected and finally a cummulative PubMed score will be calculated.

To get further help use 'describe_genomic_regions.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::PubMed_queries;
use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @chr_region, $outfile, @genes_of_interest,
	$organism_tag );

Getopt::Long::GetOptions(
	"-chr_region=s{,}"        => \@chr_region,
	"-outfile=s"              => \$outfile,
	"-genes_of_interest=s{,}" => \@genes_of_interest,
	"-organism_tag=s"         => \$organism_tag,
	"-help"                   => \$help,
	"-debug"                  => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $chr_region[0] ) {
	$error .= "the cmd line switch -chr_region is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $genes_of_interest[0] ) {
	warn "we will not highlight any genes, as you did not tell me which!\n";
}
elsif ( -f $genes_of_interest[0] ) {
	open( IN, "<$genes_of_interest[0]" )
	  or die
"could not read from the genes of interest file $genes_of_interest[0]\n$!\n";
	my @temp;
	foreach (<IN>) {
		chomp($_);
		push( @temp, split( /\s/, $_ ) ) unless ( $_ eq "" );
	}
	@genes_of_interest = @temp;
}
unless ( defined $organism_tag ) {
	$organism_tag = "H_sapiens";
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
 command line switches for describe_genomic_regions.pl

   -chr_region    :a set of chromosomal regions 'CHR<chr_name>:<start>..<end>'
   -organism_tag  :the tag for the genome DB to use (default H_sapiens )

   -genes_of_interest :a list or file containing a set of genes, 
                       that we are especially interested in
   
   -outfile  :the outfile

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'describe_genomic_regions.pl';
$task_description .= ' -chr_region ' . join( ' ', @chr_region )
  if ( defined $chr_region[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -genes_of_interest " . join( " ", @genes_of_interest )
  if ( defined $genes_of_interest[0] );
$task_description .= " -organism_tag $organism_tag";

my (
	$genome,          $genomeInterface, $chr_reg,
	$chr_name,        $start,           $end,
	$chr_descr_table, $result_table,    $is_GOI,
	$PubMed_queries,  $GOI_score,       $PubMed_score,
	$gene_list,       $gene,            $gene_level_result,
	$temp
);

foreach (@genes_of_interest) {
	$is_GOI->{$_} = 1;
}

$genome          = genomeDB->new();
$genomeInterface = $genome->GetDatabaseInterface_for_Organism($organism_tag);
$PubMed_queries  = PubMed_queries->new( $genomeInterface->{'dbh'} );
$result_table    = data_table->new();
foreach ( 'chr region', 'PubMed score', 'GOI score', 'GOIs' ) {
	$result_table->Add_2_Header($_);
}
$result_table->Add_2_Description(
	"the table was created using the CMD $task_description\n");
$result_table->Add_2_Description(
"PubMed score\tthe PubMed score is the sum of all publications that link any gene in this region to T2D - for details look into the lib stefans_libs::database::PubMed_queries"
);
$result_table->Add_2_Description(
"GOI score\tsimply the amount of genes that overlapp with this region that were in your initial GOI list"
);

$gene_level_result = data_table->new();
foreach ( 'chr region', 'Gene  Symbol', 'GOI', 'PubMed score' ) {
	$gene_level_result->Add_2_Header($_);
}
$gene_level_result->Add_2_Description(
	"the table was created using the CMD $task_description\n");
$gene_level_result->Add_2_Description(
"PubMed score\tthe PubMed score is the sum of all publications that link any gene in this region to T2D - for details look into the lib stefans_libs::database::PubMed_queries"
);
my $i = 0; 
my $all = scalar ( @chr_region );
foreach $chr_reg (@chr_region) {
	Carp::confess(
		"Sorry, but this genomic region could not be parsed: $chr_reg")
	  unless ( $chr_reg =~ m/CHR(\w+):(\d+)\.\.(\d+)/ );
	( $chr_name, $start, $end ) = ( $1, $2, $3 );
	$chr_descr_table = $genomeInterface->get_data_table_4_search(
		{
			'search_columns' => ['gbFeaturesTable.name'],
			'where'          => [
				[ 'gbFeaturesTable.tag',         '=', 'my_value' ],
				[ 'chromosomesTable.chromosome', '=', 'my_value' ],
				[
					'my_value',
					'<',
					[ 'chromosomesTable.chr_start', '+', 'gbFeaturesTable.end' ]
				],
				[
					'my_value',
					'>',
					[
						'chromosomesTable.chr_start', '+',
						'gbFeaturesTable.start'
					]
				]
			]
		},
		'gene',
		$chr_name,
		$start, $end
	);
	print "we have selected the gene names "
	  . join( ", ",
		@{ $chr_descr_table->get_column_entries('gbFeaturesTable.name') } )
	  . "from the database using the sql query\n"
	  . $genomeInterface->{'complex_search'} . "\n"
	  if ($debug);
	$GOI_score = $PubMed_score = 0;
	$gene_list = '';
	foreach $gene (
		@{ $chr_descr_table->get_column_entries('gbFeaturesTable.name') } )
	{
		$PubMed_score += $temp =
		  $PubMed_queries->get_T2D_hit_count_4_GeneSymbol($gene);
		if ( $is_GOI->{$gene} ) {
			$GOI_score++;
			$gene_list .= "$gene ";
			$gene_level_result->AddDataset(
				{
					'chr region'   => $chr_reg,
					'GOI'          => 1,
					'Gene  Symbol' => $gene,
					'PubMed score' => $temp
				}
			);
		}
		else {
			$gene_level_result->AddDataset(
				{
					'chr region'   => $chr_reg,
					'GOI'          => 0,
					'Gene  Symbol' => $gene,
					'PubMed score' => $temp
				}
			);
		}
	}
	chop($gene_list);
	$result_table->AddDataset(
		{
			'chr region'   => $chr_reg,
			'PubMed score' => $PubMed_score,
			'GOI score'    => $GOI_score,
			'GOIs'         => $gene_list
		}
	);
	$i++;
	print "done with $i / $all\n";
}

$result_table->print2file($outfile);
$gene_level_result->print2file("$outfile.gene_level");
