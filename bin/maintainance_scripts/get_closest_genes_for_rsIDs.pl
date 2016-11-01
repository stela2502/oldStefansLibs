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

=head1 add_NCBI_SNP_chr_rpts_files.pl

A script that can import NCBI chr_rpts SNP tables into the databse. The files need to be downloaded by the user. Take care to download the right files for the most actual genome version, that is stored in the databse.

To get further help use 'get_closest_gene_for_rsIDs.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::expression_net_reader;
use stefans_libs::Latex_Document;
use stefans_libs::file_readers::stat_results;

use strict;
use warnings;

my (
	$help,                  $debug,         $genome,
	@files,                 $database,      $max_dist,
	$outfile,               $tex_skeleton,  $outpath,
	@otherCorrelationFiles, @otherDatasets, @described_genes,
	@SNP_gene_correlations
);

Getopt::Long::GetOptions(
	"-help"                            => \$help,
	"-debug"                           => \$debug,
	"-database=s"                      => \$database,
	"-genome_string=s"                 => \$genome,
	"-outfile=s"                       => \$outfile,
	"-tex_skeleton=s"                  => \$tex_skeleton,
	"-further_correlatio_results=s{,}" => \@otherCorrelationFiles,
	"-outpath=s"                       => \$outpath,
	"-maximal_range=s"                 => \$max_dist,
	"-rsIDs=s{,}"                      => \@files,
	'-described_genes=s{,}'            => \@described_genes,
	'-SNP_gene_correlations=s{,}'      => \@SNP_gene_correlations
);

if ($help) {
	print helpString();
	exit;
}
unless ( defined $genome ) {
	print helpString("We need the genome identifer to import the SNP data");
	exit;
}
unless ( defined $files[0] ) {
	print helpString("We need at least one NCBI chr_rpts file do import data");
	exit;
}
if ( defined $otherCorrelationFiles[0] ) {
	my $i = 0;
	foreach my $other_correlation_file (@otherCorrelationFiles) {
		next unless ( -f $other_correlation_file );

		#warn "we read the file $other_correlation_file\n";
		$otherDatasets[$i] = data_table->new();
		$otherDatasets[$i]->read_file($other_correlation_file);
		$otherDatasets[$i]->Rename_Column( 'p-value', 'p value' )
		  if ( $otherDatasets[$i]->Header_Position('p-value') );

#warn "we got the column headers '".join("', '",@{$otherDatasets[$i]->{'header'}})."\n";
		$otherDatasets[$i]->createIndex('Gene Symbol');
		$otherDatasets[$i]->Name($1)
		  if $other_correlation_file =~ m/([\w\-_]+).txt/;

#print "We got the headers: '".join( "', '",@{$otherDatasets[$i]->{'header'}})."'\n";
		$i++;
	}
	print
"get_closest_gene_for_rsIDs.pl -> we have added $i other correlation datasets to our analysis\n"
	  if ( $i > 0 );
	for ( my $i = 0 ; $i < @otherDatasets ; $i++ ) {
		print $otherDatasets[$i]->Name()
		  . " - did we get some value 4 gene KLHDC5? '"
		  . $otherDatasets[$i]
		  ->get_value_for( 'Gene Symbol', 'KLHDC5', 'p value' ) . "'\n";
	}

}
if ( defined $described_genes[0] ) {
	if ( -f $described_genes[0] ) {
		open( G, "<$described_genes[0]" )
		  or die
		  "could not open the initial genes file '$described_genes[0]'\n";
		my $i = 0;
		while (<G>) {
			chomp($_);
			foreach my $gene ( split( / +/, $_ ) ) {
				$described_genes[ $i++ ] = $gene;
			}
		}
	}
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for get_closest_gene_for_rsIDs.pl
 
   -help           :print this help
   -debug          :verbose output
   -maximal_range  :get all genes in a certain region arround the SNP
                    if this value is not set return the closest gene only
   -database       :the name of the database to use (default = 'genomeDB')
   -further_correlatio_results
                   :other correlation result files that are 
                    created using the batchStatistics.pl script 
                    FROM that gene to other genes 
   -outfile        :the name of the file you want to store this data to
   -outpath        :the outpath used to link into the latex report system
   -tex_skeleton   :the latex file we should push our data to
   -genome_string  :the genome string (i.a. H_sapiens as used by the NCBI to describe the genome)
   -rsIDs          :either a list of rsIDs separated by a space, or a [list] of files containing rsIDs (one per line)
   
   -described_genes :if you plan to create a PDF if might be usfull to set links to genes, 
                     that have already been described in the PDF. 
                     Please give me the list of gene names so I can set up the links.
   
   -SNP_gene_correlations :a list of SNP 2 gene expression correlations that can be used to 
                           describe the cis effect of the SNPs on the genes
";
}

## now we set up the logging functions....

my (
	$genomeDB,  $genomeInterface, $rv,   $gbFile_accs,
	$lineArray, $SNP_table,       @line, @rsIDs,
	$sql,       $temp,            $ordered_by_rsID
);

my $stat_results = stat_results->new();

## 1. select the genome interface
$genomeDB = genomeDB->new( $database, $debug );
$genomeInterface =
  $genomeDB->getGenomeHandle_for_dataset( { 'organism_tag' => $genome } );
$genomeInterface = $genomeInterface->get_rooted_to("gbFilesTable");

## 2. get me the SNP_Table interface
$SNP_table = $genomeInterface->get_SNP_Table_interface();

#$SNP_table->printReport();

## 3. get me the wanted rsIDs
foreach my $SNP_file (@files) {
	if ( -f $SNP_file ) {
		## the rsID seams to be a file containing several SNPs

		print "I will open the file $SNP_file\n" if ($debug);
		open( IN, "<$SNP_file" );
		while (<IN>) {
			chop($_);
			@line = split( /\s/, $_ );
			push( @rsIDs, @line );
		}
	}
	else {
		push( @rsIDs, $SNP_file );
	}
}
print "We search for the rsIDs\n" . join( "\n", @rsIDs ) if ($debug);
my $result = '';
## 4. create the SQL search statement
if ( defined $max_dist ) {

	$rv =
'#1, #2, #3,#5, #4 + #5 as position_on_chromosome, (#5 - #6) as distance_to_gbFeature_start, (#5  - #7) as distance_to_gbFeature_end, #8';
	$sql = $SNP_table->create_SQL_statement(
		{
			'search_columns' => [
				'SNP_table.rsID',              'gbFeaturesTable.name',
				'chromosomesTable.chromosome', 'chromosomesTable.chr_start',
				'SNP_table.position',          'gbFeaturesTable.start',
				'gbFeaturesTable.end',         'gbFeaturesTable.gbString'
			],

			#'complex_select' => \$rv,
			'where' => [
				[ 'gbFeaturesTable.tag', '=', 'my_value' ],
				[ 'SNP_table.rsID',      '=', 'my value' ],
				[
					[ 'chr_start', '+', 'gbFeaturesTable.start' ],
					"<",
					[
						[ 'chr_start', '+', "SNP_table.position" ], '+',
						'my_value'
					]
				],
				[
					[ 'chr_start', '+', 'gbFeaturesTable.end' ],
					">",
					[
						[ 'chr_start', '+', "SNP_table.position" ], '-',
						'my_value'
					]
				],
			]
		}
	);
	my $sth;
	print "we will try to execute the sql statement '$sql;'\n" if ($debug);
	$result .=
"#rsID\tgbFeature name\tchromosome\tSNP_table.position\tposition_on_chromosome\tdistance_to_gbFeature_start\tdistance_to_gbFeature_end\n";
	foreach my $rsID (@rsIDs) {
		$temp = $sql;
		foreach ( 'gene', $rsID, $max_dist, $max_dist ) {
			$temp =~ s/\?/$_/;
		}
		print "we will execute the sql statement '$temp;'\n" if ($debug);
		$sth = $SNP_table->{'dbh'}->prepare($temp);
		unless ( $sth->execute() ) {
			Carp::confess("we could not execute $temp!\n");
		}
		$rv = $sth->fetchall_arrayref();
		foreach my $array (@$rv) {
			$result .= join( "\t",
				@$array[0], @$array[1], @$array[2],
				@$array[3] + @$array[4],
				@$array[3] - @$array[5],
				@$array[3] - @$array[6] )
			  . "\n";
			$ordered_by_rsID->{ @$array[0] } = {
				'info' => {
					'chromosome'      => @$array[2],
					'position_on_chr' => @$array[3] + @$array[4]
				},
				'data' => []
			  }
			  unless ( ref( $ordered_by_rsID->{ @$array[0] } ) eq "HASH" );
			## gbFeature_name;start_on_chr;end_on_chr
			push(
				@{ $ordered_by_rsID->{ @$array[0] }->{'data'} },
				[
					@$array[1], @$array[3] + @$array[5], @$array[3] + @$array[6]
				]
			);

			#print join( "\t", @$array ) . "\n";
		}
	}
}
else {
	$rv =
'#1, #2, #3,#5, #4 + #5 as position_on_chromosome, (#4 + #5) - (#4 +#6) as distance_to_gbFeature_start, (#4 + #5 ) - (#7 + #4) as distance_to_gbFeature_end';
	$sql = $SNP_table->create_SQL_statement(
		{
			'search_columns' => [
				'SNP_table.rsID',              'gbFeaturesTable.name',
				'chromosomesTable.chromosome', 'chromosomesTable.chr_start',
				'SNP_table.position',          'gbFeaturesTable.start',
				'gbFeaturesTable.end'
			],

			#'complex_select' => \$rv,
			'where' => [
				[ 'gbFeaturesTable.tag', '=', 'my_value' ],
				[ 'SNP_table.rsID',      '=', 'my value' ]
			],
			'order_by' =>
			  [ [ 'SNP_table.position', '-', 'gbFeaturesTable.start' ] ],
			'limit' => 'limit 5'
		}
	);

	print "we would try to execute the sql statement '$sql;'\n" if ($debug);

	my $sth = $SNP_table->{'dbh'}->prepare($sql);
	$result .=
"#rsID\tgbFeature name\tchromosome\tSNP_table.position\tposition_on_chromosome\tdistance_to_gbFeature_start\tdistance_to_gbFeature_end\n";
	foreach my $rsID (@rsIDs) {
		$sth->execute( 'gene', $rsID );
		$rv = $sth->fetchall_arrayref();
		foreach my $array (@$rv) {
			$result .= join( "\t",
				@$array[0], @$array[1], @$array[2],
				@$array[3] + @$array[4],
				@$array[3] - @$array[5],
				@$array[3] - @$array[6] )
			  . "\n";
			$ordered_by_rsID->{ @$array[0] } = {
				'info' => {
					'chromosome'      => @$array[2],
					'position_on_chr' => @$array[3] + @$array[4]
				},
				'data' => []
			  }
			  unless ( ref( $ordered_by_rsID->{ @$array[0] } ) eq "HASH" );
			## gbFeature_name;start_on_chr;end_on_chr
			push(
				@{ $ordered_by_rsID->{ @$array[0] }->{'data'} },
				[
					@$array[1], @$array[3] + @$array[5], @$array[3] + @$array[6]
				]
			);
		}
	}
	
}

unless ( -d $outpath ) {
	##you want to have a text output, no latex output
	if ( defined $outfile ) {
		open( OUT, ">$outfile" ) or die "could not open outfile '$outfile'\n";
		print OUT $result;
		close(OUT);
	}
	else {
		print $result;
	}
}
else {
	my $latex_Document = stefans_libs::Latex_Document->new();
	$latex_Document->Outpath($outpath);
	my $main_section;
	my $columns;
	my $temp_hash;
	my $cis_genes = data_table->new();
	my $gene_symbol_temp;
	foreach ( 'Gene Symbol', 'rsID' ) {
		$cis_genes->Add_2_Header($_);
	}
	$cis_genes->createIndex('Gene Symbol');
	$cis_genes->createIndex('rsID');

	#$cis_genes->Add_unique_key('Unique');

	$result = [];
	## we should create some latex output!
	my $str = '';
	$str .= '';

#	$str .= "In order to estimate the importande of the genes for T2D in beta cells,".
#	 " we have done correlations between the expression of these genes and several phenotypes: \n";
#	$str .= $expression_net_reader->__describe_other_dataset(\@otherDatasets);
	my $data_table = data_table->new();
	$gene_symbol_temp = '';

	$main_section =
	  $latex_Document->Section( 'Genes laying in close proximity to SNPs',
		'SNP-to-gene' );
	$main_section->AddText(
		    '\section{Genes laying in close proximity to SNPs}' . "\n"
		  . '\label{SNP-to-gene}' . "\n\n"
		  . 'You wanted to have a list of genes, that overlapps a region of '
		  . ( 2 * $max_dist )
		  . "bp around several SNPs.\n"
		  . "You asked for these SNPs: "
		  . join( ", ", @rsIDs )
		  . "." );
	$main_section->Section('Summary Cis Effected genes')
	  ->AddText(
"The table describes which genes were identified in this connection net "
		  . "and do lie close to  one of the interesting SNPs.\n" )
	  ->Add_Table($cis_genes);

	foreach my $rsID (@rsIDs) {
		$main_section->Section( $rsID, $rsID );

		unless ( defined $ordered_by_rsID->{$rsID} ) {
			$main_section->Section($rsID)
			  ->AddText(
				"Sorry, but we have not got an overlapping gene for this SNP");
		}
		else {
			$data_table = $data_table->_copy_without_data();
			$data_table->delete_all_data();
			$data_table->Add_2_Header('gene name');
			$data_table->Add_2_Header('start [bp]');
			$data_table->Add_2_Header('end [bp]');
			for ( my $i = 1 ; $i <= @otherDatasets ; $i++ ) {
				$data_table->Add_2_Header($i);
			}

			# gbFeature_name;start_on_chr;end_on_chr
			$main_section->Section($rsID)
			  ->AddText( "The SNP $rsID is located on chromosome "
				  . "$ordered_by_rsID->{$rsID}->{'info'}->{'chromosome'}"
				  . " at the position $ordered_by_rsID->{$rsID}->{'info'}->{'position_on_chr'}."
			  );

			foreach my $array ( @{ $ordered_by_rsID->{$rsID}->{'data'} } ) {
				@$array[0] = $1 if ( @$array[0] =~ m/ +(.*)/ );

				unless ( ref( $otherDatasets[0] ) eq "data_table" ) {
					$temp_hash->{'gene name'}  = @$array[0];
					$temp_hash->{'start [bp]'} = @$array[1];
					$temp_hash->{'end [bp]'}   = @$array[2];
				}
				else {
					$temp_hash =
					  &__create_columnEntry_OtherDataset( @$array[0],
						@otherDatasets );
					$temp_hash->{'gene name'}  = @$array[0];
					$temp_hash->{'start [bp]'} = @$array[1];
					$temp_hash->{'end [bp]'}   = @$array[2];
				}

				foreach (@described_genes) {
					if ( $temp_hash->{'gene name'} eq $_ ) {
						$gene_symbol_temp = $temp_hash->{'gene name'};
						$temp_hash->{'gene name'} =
						    "\\nameref{"
						  . root->Latex_Label( $temp_hash->{'gene name'} )
						  . "} \$^*\$";
						$cis_genes->AddDataset(
							{
								'Gene Symbol' => $gene_symbol_temp,
								'rsID'        => $rsID
							}
						);
						last;
					}
				}
				$data_table->Add_Dataset($temp_hash);
			}
			my $table_added = 0;
			if ( ref( $otherDatasets[0] ) eq "data_table" ) {

				$main_section->Section($rsID)
				  ->AddText(
"As it is of general interest if these genes show some difference\n"
					  . "in correlation with any phenotype, I have included a complex report according the p values\n"
					  . "I got from the correlation of all opssible expression arrays with the phenotypes: "
					  . &__describe_other_dataset(@otherDatasets)
					  . ".\n The reported values are the \$ -log10(p_value) \$ (roud up)."
				  )->Add_Table($data_table);
				$table_added = 1;
			}
			if ( defined $SNP_gene_correlations[0] ) {
				## OK I want to add a new table describing all the genes on the basis of cis acting of this SNP
				&Add_Expression_Influence_ON_SNP( $rsID,
					$main_section->Section($rsID),
					\@SNP_gene_correlations,
					$data_table->getAsArray('gene name') );
			}
		}
	}
	$cis_genes->LaTeX_modification_for_column(
		{
			'column_name' => 'Gene Symbol',
			'before'      => "\\nameref{",
			'after'       => "} \$^*\$"
		}
	);

	$cis_genes->write_file("$outpath/cis_affected_genes.txt");
	open( OUT, ">$outpath/SNP_to_gene.txt" )
	  or die "could not create outfile '$outpath/SNP_to_gene.txt'\n";
	foreach (@$result) {
		print OUT join( "\t", @$_ ) . "\n";
	}
	close(OUT);
	$str = $main_section->AsString(0);
	unless ( defined $tex_skeleton ) {
		$latex_Document->write_tex_file($outfile);
	}
	else {
		my $tex_file = &_tex_file();
		$tex_file =~ s/##SPECIAL GENES##/$str/;

		open( OUT, ">$tex_skeleton" )
		  or die "could not write to the tex file $tex_skeleton\n";
		print OUT $tex_file;

		#print $str;
		close OUT;
	}
}

sub __describe_other_dataset {
	my (@otherDataset) = @_;
	return '' unless ( defined $otherDataset[0] );

	#return '' unless ( $self->output_type() eq "long" );
	my $entry;
	my $desc .=
"The last columns contain the information from the other correlations as mentioned in section \\ref{corr-data-overview}.\n";
	$desc .= "the columns contain the \$-log10(p_value)\$" .

	  #" and primary statistic values".
	  " for the comparisons \n"
	  . "between the gene expression and these phenotypes: ";
	for ( my $i = 1 ; $i < @otherDataset + 1 ; $i++ ) {
		$desc .= " "
		  . $otherDataset[ $i - 1 ]->Name()
		  . " (\\hyperlink{data$i}{$i}), ";
	}
	chop($desc);
	chop($desc);
	return $desc . ".\n\n";
}

sub __create_columnEntry_OtherDataset {
	my ( $gene1, @otherDataset ) = @_;
	my $desc = {};
	my ( $temp, $value );
	if ( scalar(@otherDataset) > 0 ) {
		for ( my $i = 0 ; $i < @otherDataset ; $i++ ) {
			($value) =
			  $otherDataset[$i]
			  ->get_value_for( 'Gene Symbol', "$gene1 ", 'p value' );

			#	print "initially we got the value $value for gene '$gene1'\n";
			unless ( $value =~ /\d/ ) {

			  #print "we need to get the gene name without a trailing space!\n";
				($value) =
				  $otherDataset[$i]
				  ->get_value_for( 'Gene Symbol', "$gene1", 'p value' );
			}
			$temp = '-';
			if ( defined $value ) {
				$temp = int( -&log10($value) )
				  if ( $value =~ m/\d/ && $value < 0.6 && $value > 0 );
			}
			$desc->{ ( $i + 1 ) } = $temp;
		}
	}

	return $desc;
}

sub Add_Expression_Influence_ON_SNP {
	my ( $rsID, $section, $SNP_gene_correlations, $genes ) = @_;
	my $data_table = data_table->new();
	my ( $stat_result_table, @temp, $filename, $p_value, $description );
	$data_table->Add_2_Header('Gene Symbol');
	$data_table->createIndex('Gene Symbol');
	my $i = 0;
	my $translation_table = data_table->new();
	foreach ( 'table column', 'real name'){
		$translation_table -> Add_2_Header ( $_ );
	}
	$section->AddText( 'The columns of the table have been number coded as the real anmes are too long. The real table names are shown in the following table:')
		->Add_Table ( $translation_table );
	foreach my $SNP_file (@$SNP_gene_correlations) {
		next unless ( $SNP_file =~ m/$rsID/ );
		$i ++;
		$stat_result_table = $stat_results->read_file($SNP_file);

		#print "initial_file = $SNP_file\n";
		@temp = split( "/", $SNP_file );
		$filename = pop(@temp);

		#print "first reduction = '$filename'\n";
		@temp = split( '\.', $filename );
		$filename = shift(@temp);

		#print "second reduction = '$filename'\n";
		$data_table->Add_2_Header($i);
		$translation_table -> AddDataset ( {
			'table column' => $i, 'real name' => $filename
		});
		$description .= "";
		foreach my $gene (@$genes) {
			($p_value) = $stat_result_table->get_value_for( 'Gene Symbol', $gene,
				'p-value' );
			#print "we got a p-value '$p_value' for file $filename\n";
			if ( $p_value eq "" ) {
				$data_table->AddDataset(
					{
						'Gene Symbol' => $gene,
						$i     => 'n.s.'
					}
				);
			}
			else {
				print "we got a p_value '$p_value' for gene $gene\n";
				$data_table->AddDataset(
					{
						'Gene Symbol' => $gene,
						$i     => sprintf('%.1e',$p_value)
					}
				);
			}

		}
	}
	if ( scalar( @{ $data_table->{'data'} } ) > 0 ) {
		$section->AddText(
"We have analyzed the cis effect of the SNP $rsID and sum up the results in the fillowing table:"
		)->Add_Table($data_table);
	}
	return 1;
}

sub log10 {
	my ($value) = @_;
	return log($value) / log(10);
}

sub _tex_file {
	if ( -f $tex_skeleton ) {
		my $str = '';
		open( IN, "<$tex_skeleton" )
		  or die "could not open tex file '$tex_skeleton'\n";
		while (<IN>) {
			$str .= $_;
		}
		close(IN);
		if ( $str =~ m/##SPECIAL GENES##/ ) {
			## OK this sceleton is usable!
			return $str;
		}
		else {
			warn
"The tex sceleton $tex_skeleton does not contain the necessary tags - I will use the inbuilt tex template!\n";
		}
	}

	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}

\begin{document}
\tableofcontents
  
\title{ ##TITLE## }
\author{Stefan Lang}\\
\date{' . root->Today() . '}
\maketitle
    
    ##INTRODUCTION##
    
    ##GENE GROUPS##
    
    ##SPECIAL GENES##
    
    ##EXPRESSION-NET-FIGURE##
    
    ##SUMMARY##
    
    ##GENE DESCRIPTION##
  
  \end{document}
';
}
