#! /usr/bin/perl -w

#  Copyright (C) 2010-11-19 Stefan Lang

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

=head1 Apply_KEGG_Search_to_Phenotype_Correlations.pl

Subselect several p value cut offs and create KEGG analysies from these phenotypes to produce a large summary PDF that describes almoast everything.

To get further help use 'Apply_KEGG_Search_to_Phenotype_Correlations.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::Latex_Document;
use stefans_libs::file_readers::stat_results;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::database::genomeDB::gene_description;
use stefans_libs::file_readers::affymetrix_expression_result;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,               $debug,                  $database,
	$max_p_value,        @phenotype_correlations, $kegg_reference_geneset,
	$desease,            $outfile,                $min_genes,
	$describe_gene_list, $no_www, @add_gene_list, $expression_data_file
);

Getopt::Long::GetOptions(
	"-phenotype_correlations=s{,}" => \@phenotype_correlations,
	"-kegg_reference_geneset=s"    => \$kegg_reference_geneset,
	"-desease=s"                   => \$desease,
	"-max_p_value=s"               => \$max_p_value,
	"-outfile=s"                   => \$outfile,
	"-min_genes=s"                 => \$min_genes,
	"-add_gene_list=s{,}"          => \@add_gene_list,
	"-describe_gene_list=s"        => \$describe_gene_list,
	"-no_www"                      => \$no_www,
	"-expression_data_file=s"     => \$expression_data_file,
	"-help"                        => \$help,
	"-debug"                       => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $phenotype_correlations[0] ) {
	$error .= "the cmd line switch -phenotype_correlations is undefined!\n";
}
unless ( defined $kegg_reference_geneset ) {
	$error .= "the cmd line switch -kegg_reference_geneset is undefined!\n";
}

unless ( defined $desease ) {
	$error .= "the cmd line switch -desease is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $min_genes ) {
	$error .= "the cmd line switch -min_genes is undefined!\n";
}
unless ( defined $max_p_value ) {
	$max_p_value = 0.05;
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
 command line switches for Apply_KEGG_Search_to_Phenotype_Correlations.pl

   -phenotype_correlations :a list of batch_statistics.pl result files
   -kegg_reference_geneset :A string telling me which matched set in the database to use
                            for my analysis. E.g. 'HUGene_v1'
                            
   -desease       :the desease you want to use _(use 'T2D')
   -outfile       :the name and position of the outfile (tex or later on pdf)
   -min_genes     :how many genes need to match to a pathway?
   -max_p_value   :we can restrict the initial correlation p_value default (0.05)
   
   -add_gene_list      :an optional list of genes, that you want to have analyzed
   -describe_gene_list :a description of the user supplied gene list
   
   -no_www  :if you do not want to fetch the GeneCards description for the new genes
   
   -expression_data_file :In case you have a prepared expression file to be used with
                          the script 'plot_figure_for_complex_transcription_file.pl'
                          you can give me that here and I will add the expression plots 
                          to the gene description part of the PDF
                          
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=  'perl '.root->perl_include() ." ".$plugin_path.'/Apply_KEGG_Search_to_Phenotype_Correlations.pl';
$task_description .=
  ' -phenotype_correlations ' . join( ' ', @phenotype_correlations )
  if ( defined $phenotype_correlations[0] );
$task_description .= " -kegg_reference_geneset $kegg_reference_geneset"
  if ( defined $kegg_reference_geneset );
$task_description .= " -desease $desease"     if ( defined $desease );
$task_description .= " -outfile $outfile"     if ( defined $outfile );
$task_description .= " -min_genes $min_genes" if ( defined $min_genes );
$task_description .= " -add_gene_list '" . join( "' '", @add_gene_list ) . "'"
  if ( defined $add_gene_list[0] );
$task_description .= " -max_p_value $max_p_value" if ($max_p_value);
$task_description .= " -describe_gene_list \"$describe_gene_list\""
  if ( defined $describe_gene_list );
  
$task_description .= " -no_www" if ( $no_www );
$task_description .= " -expression_data_file $expression_data_file" if ( -f $expression_data_file );

open( LOG, ">$outfile.logfile" )
  or die "I could not craete the log file $outfile.logfile\n";
print LOG $task_description;
close(LOG);

if ( defined $add_gene_list[0] ) {
	unless ( defined $describe_gene_list ) {
		$error .=
		  "please give me a -describe_gene_list for your -add_gene_list!\n";
	}
	if ( -f $add_gene_list[0] ) {
		open( IN, "<$add_gene_list[0]" )
		  or die "could not open the -add_gene_list $add_gene_list[0]\n";
		my @temp;
		while (<IN>) {
			chomp($_);
			push( @temp, split( /\s/, $_ ) );
		}
		shift(@temp) unless ( defined $temp[0] );
		@add_gene_list = @temp;
	}
}

my ( @temp, $filename, $path, $Latex_Document, $phenotype_file, $temp,
	$results, $probesets_2_genes );

@temp           = split( "/", $outfile );
$filename       = pop(@temp);
$path           = join( "/", @temp );
$Latex_Document = stefans_libs::Latex_Document->new();
$Latex_Document->Chapter_mode(1);
$Latex_Document->Outpath($path);

my $stat_results = stat_results->new();
$stat_results->p_value_cutoff($max_p_value);
my ( $genes_not_expressed_in_celltype,
	$genes_expressed_in_celltype, $result_pathways, @phenotypes );

my $main_intro_section =
  $Latex_Document->Section( "Introduction", 'main::intro' );
## TODO Here it would be hell cool to get the information from the database!!
## Intead I will make something up
$main_intro_section->AddText(
"I wanted to create a huge and comprehensive summary over the comparison between "
	  . "the expression values and the phenotypes for this dataset.\n"
	  . "To describe the comparisons, I have splitt all genes according to the correlation of expression vs. purity.\n"
	  . "\n"
	  . "If Addition I have separated the genes according to ther expression in each analyzed phenotype.\n"
	  . "The pathways that are enriched in any of the resulting gene lists are reported in the Summay table or \n"
	  . " more detailed in the results section.\n"
	  . "In addition I have focused on correlations with a p_value of less than $max_p_value."
);

my $results_sec = $Latex_Document->Section( 'Results', 'main:::res' );
my ( $latex_section, $kegg_genes, $gene_description, $genes_to_be_described );

$kegg_genes       = kegg_genes->new( root->getDBH() );
$gene_description = gene_description->new( root->getDBH() );
$gene_description -> DoNotConnect2WWW ( $no_www );
my ( $comparison_1, $comparison_2 );

#$comparison_1 = 'exp. in islets';
#$comparison_2 = 'exp. in pancreas';

$comparison_1 = 'higher expr.';
$comparison_2 = 'lower expr.';

my $sumary_table = data_table->new();
foreach ( 'phenotype', 'pathway', $comparison_1, $comparison_2, 'all genes' ) {
	$sumary_table->Add_2_Header($_);
}
$sumary_table->createIndex('phenotype');
$sumary_table->make_column_LaTeX_p_type( 'phenotype', '4cm' );

$sumary_table->createIndex('pathway');
$sumary_table->make_column_LaTeX_p_type( 'pathway', '5cm' );

$sumary_table->setDefaultValue( $comparison_1, '-' );
$sumary_table->setDefaultValue( $comparison_2, '-' );
$sumary_table->setDefaultValue( 'all genes',   '-' );

foreach my $infile (@phenotype_correlations) {
	my @file      = split( "/", $infile );
	my $table_obj = pop @file;
	my $outpath = join("/", @file);
	@file = split ( /\./, $table_obj );
	$table_obj = $file[0];
	
	if ( $infile =~ m/.tar$/ ) {
		## OK a new data file! DAMN IT
		## 1. untar the stuff - the real filename will always be named 'purged_results.xls'
		mkdir ($outpath."/$table_obj");
		system("tar -xf $infile --directory $outpath/$table_obj purged_results.xls");
		$table_obj = $stat_results->read_file("$outpath/$table_obj/purged_results.xls");
		#unlink("$outpath/purged_results.xls");
	}
	else {
		$table_obj = $stat_results->read_file($infile);
	}
	$table_obj->{'kegg_genes'} = $kegg_genes;
#	( $genes_not_expressed_in_celltype, $genes_expressed_in_celltype ) =
#	  $table_obj->get_down_and_upregulated_genes();
	@temp = split( "/", $infile );
	$phenotype_file = pop(@temp);
	@temp = split ( /\./,$phenotype_file );
	$phenotype_file = $temp[0];
	$table_obj->Name($phenotype_file);
	push( @phenotypes, $table_obj );
	
	
	## I want to select three different sub groups from each analysis - hehehe
	print "we are at \$phenotype_file '$phenotype_file'\n";
	if ( ref($genes_not_expressed_in_celltype) eq "HASH" ) {
		&create_results_4_data(
			{
				'results_sec'     => $results_sec,
				'section_title'   => $phenotype_file,
				'table_obj'       => $table_obj,
				'phenotype'       => $phenotype_file,
				'exclusion_lists' => {
					"$comparison_1" => $genes_not_expressed_in_celltype,
					"$comparison_2" => $genes_expressed_in_celltype
				},
				'outpath'      => $path . "/$phenotype_file/",
				'sumary_table' => $sumary_table
			}
		);
	}
	else {
		&create_results_4_data(
			{
				'results_sec'     => $results_sec,
				'section_title'   => $phenotype_file,
				'table_obj'       => $table_obj,
				'phenotype'       => $phenotype_file,
				'exclusion_lists' => {},
				'outpath'         => $path . "/$phenotype_file/",
				'sumary_table'    => $sumary_table
			}
		);
	}
}

$main_intro_section->Section('Phenotype based summary')
  ->AddText(
'To get an overview over all results I have added an overview table, that highlights the KEGG pathways, '
	  . 'that are found to be significantly correlated with any of the phenotypes. This result has been corrected for multiple testings on a per phenotype and estimated cell type basis.'
  )->Add_Table($sumary_table);

my $Pathways_based_summary =
  $sumary_table->Sort_by( [ [ 'pathway', 'lexical' ] ] );
$Pathways_based_summary->make_column_LaTeX_p_type( 'phenotype', '4cm' );
$Pathways_based_summary->make_column_LaTeX_p_type( 'pathway',   '5cm' );

$main_intro_section->Section('Pathway based summary')
  ->AddText(
	'That table might help in selecting Pathways, that have multiple hits.')
  ->Add_Table($Pathways_based_summary);

$filename .= ".tex" unless ( $filename =~ m/\.tex$/ );

$kegg_genes->{'pathway_setting_2_genes'}
  ->write_file( $path . "/pathway_and_setting_2_genes.txt" );

if ( defined $add_gene_list[0] ) {
	## OK I want to get a new pathway_setting_2_genes file
	$kegg_genes = kegg_genes->new( root->getDBH() );
	## then I want to check all of the new genes, but group them into three groups for all the datasets.
	## I will not do that for the Kruskal_Wallis_Results!
	$Latex_Document->Section('The special gene list')
	  ->AddText($describe_gene_list);
	my $summary_section =
	  $Latex_Document->Section('The special gene list')
	  ->Section("signififcant Pathway summary");
	my $table_obj = stefans_libs_file_readers_stat_results_base_class->new();
	$table_obj->Add_2_Header('Gene Symbol');
	$table_obj->{'kegg_genes'} = $kegg_genes;
	foreach (@add_gene_list) {
		$genes_to_be_described->{$_} = 1;
		$table_obj->AddDataset( { 'Gene Symbol' => $_ } );
	}

	my $sumary_table_2 = data_table->new();
	foreach (
		'phenotype',
		'pathway',
		'lower expression',
		'higher expression',
		'all genes'
	  )
	{
		$sumary_table_2->Add_2_Header($_);
	}
	$sumary_table_2->createIndex('phenotype');
	$sumary_table_2->make_column_LaTeX_p_type( 'phenotype', '4cm' );

	$sumary_table_2->createIndex('pathway');
	$sumary_table_2->make_column_LaTeX_p_type( 'pathway', '5cm' );
	$results_sec = $Latex_Document->Section('The special gene list');

	&create_results_4_data(
		{
			'results_sec'     => $results_sec,
			'section_title'   => 'Unmodified Gene List',
			'table_obj'       => $table_obj,
			'phenotype'       => "Co-Expressed Genes",
			'exclusion_lists' => {},
			'outpath'         => $path . "/add_gene_list_all/",
			'sumary_table'    => $sumary_table_2
		}
	);

	foreach my $phenotype_obj (@phenotypes) {
		my $temp;
#		( $genes_not_expressed_in_celltype, $genes_expressed_in_celltype ) =
#		  $phenotype_obj->get_down_and_upregulated_genes();
		unless ( ref($genes_expressed_in_celltype) eq "HASH" ) {
			&create_results_4_data(
				{
					'results_sec'     => $results_sec,
					'section_title'   => 'Unmodified Gene List',
					'table_obj'       => $table_obj,
					'phenotype'       => "Co-Expressed Genes",
					'exclusion_lists' => {},
					'outpath'         => $path
					  . "/add_gene_list_all"
					  . join( "_", split( /\s/, $phenotype_obj->Name() ) )
					  . "/",
					'sumary_table' => $sumary_table_2
				}
			);
		}
		else {
			&create_results_4_data(
				{
					'results_sec'     => $results_sec,
					'section_title'   => 'Unmodified Gene List',
					'table_obj'       => $table_obj,
					'phenotype'       => "Co-Expressed Genes",
					'exclusion_lists' => {
						'lower expression'  => $genes_expressed_in_celltype,
						'higher expression' => $genes_not_expressed_in_celltype
					},
					'outpath' => $path
					  . "/add_gene_list_all"
					  . join( "_", split( /\s/, $phenotype_obj->Name() ) )
					  . "/",
					'sumary_table' => $sumary_table_2
				}
			);
		}
	}
	$summary_section->AddText(
"This summary table shows all pathways, that are associated wioth the user added gene list\n"
		  . " and the probable influence the different phenotypes might have onto the expression of the genes in the pathways.\n"
		  . "If you miss a pathway, that was described for the whole dataset, that does mean, that there were genes in that pathway,\n"
		  . " that were up and down regulated f you separate the samples according to the phenotype."
		  . "If you see pathways, that previously were not highlighted,\n"
		  . " that does translate into a change in the total amount of identifiued pathways due to a loss of genes."
	)->Add_Table($sumary_table_2);
}

@phenotypes = undef;
my $i = 0;
$stat_results->Only_Genes([ sort keys %$genes_to_be_described ] );
foreach my $infile (@phenotype_correlations) {
	my @file      = split( "/", $infile );
	my $table_obj = pop @file;
	my $outpath = join("/", @file);
	
	if ( $infile =~ m/.tar$/ ) {
		## OK a new data file! DAMN IT
		## 1. untar the stuff - the real filename will always be named 'purged_results.xls'
		system("tar -xf $infile --directory $outpath purged_results.xls");
		$table_obj = $stat_results->read_file("$outpath/purged_results.xls");
		unlink("$outpath/purged_results.xls");
	}
	else {
		$table_obj = $stat_results->read_file($infile);
	}
	$table_obj->{'kegg_genes'} = $kegg_genes;
#	( $genes_not_expressed_in_celltype, $genes_expressed_in_celltype ) =
#	  $table_obj->get_down_and_upregulated_genes();
	@temp = split( "/", $infile );
	$phenotype_file = pop(@temp);
	@temp = split ( /\./,$phenotype_file );
	$phenotype_file = $temp[0];
	$table_obj->Name($phenotype_file);
	$phenotypes[$i++] = $table_obj;
}
#my $str = '';
#foreach ( @phenotypes ){#
#	$str.= "phenotype ".$_->Name()."\n";
#}
#Carp::confess ($str  );
my $affy_file =  stefans_libs_file_readers_affymetrix_expression_result ->new();
$affy_file -> read_file ( $expression_data_file );
mkdir ( "$path/expression_plots/" );
print "This hash does kill the whole analysis - WHY??\n\$hash = ".root->print_perl_var_def({
		'LaTeX_object'  => $results_sec,
		'genes'         => [ sort keys %$genes_to_be_described ],
		'probesets'     => $probesets_2_genes,
		'outfile'       => "$path/expression_plots/automatics_plots",
		'data_file'     => $affy_file,
		'otherDatasets' => \@phenotypes,
		'desease' => $desease
	} ).";\n";

$gene_description->add_LaTeX_section_for_Gene_List(
	{
		'LaTeX_object'  => $results_sec,
		'genes'         => [ sort keys %$genes_to_be_described ],
		'probesets'     => $probesets_2_genes,
		'outfile'       => "$path/expression_plots/automatics_plots",
		'data_file'     => $affy_file,
		'otherDatasets' => \@phenotypes,
		'desease' => $desease
	}
);

$Latex_Document->Outpath($path);
$Latex_Document->write_tex_file($filename);

=head2 create_results_4_data {
	 'results_sec', 
	 'section_title', 
	 'table_obj', 
	 'phenotype',
	 'exclusion_lists',
	 'outpath',
	 'sumary_table'
}
	I will create a new section in the 'results_sec' using the title 'section_title'.
	I will use the 'Gene Symbols' stored in the data_table 'table_obj' to call
	the stefans_libs_file_readers_stat_results_base_class::Add_KEGG_Pathway_for_settings
	function.
	I will create two gene subselections for the hash 'exclusion_lists'.
	
	In this has I expect named hashes that have the structure 'Gene Symbol' => 1 
	for all genes that should be excluded (!!) for the named state!
	
	I need the outpath option in order to print the temporary Figures. You can delete the whole path after
	you have got your final PDF!
	
	In addition I use the global variables $min_genes and $kegg_reference_geneset!
	
	Fianlly I push all significant results into the 'sumary_table_2'.
	I expect, that you have prepared that table to contain the columns
	'pathway_name', 'Figure Lable', 'phenotype', 'all genes' and one column for each key of the 'exclusion_lists' hash!

	And at the end we add the genes, that were toiuched in this section to the global hash $genes_to_be_described.
=cut

sub create_results_4_data {
	my ($hash) = @_;
	$hash->{'exclusion_lists'} = {}
	  unless ( ref( $hash->{'exclusion_lists'} ) eq "HASH" );

	my $results = $hash->{'table_obj'}->Add_KEGG_Pathway_for_settings(
		{
			'LaTeX_document' => $Latex_Document,
			'LaTeX_obj' =>
			  $hash->{'results_sec'}->Section( $hash->{'section_title'} ),
			'phenotype'              => $hash->{'phenotype'},
			'exclusion_lists'        => $hash->{'exclusion_lists'},
			'outpath'                => $hash->{'outpath'},
			'min_genes'              => $min_genes,
			'kegg_reference_geneset' => $kegg_reference_geneset
		}
	);
	if ( defined $results ->{'summary_table'} ) {
		unless ( -d "$path/pathway_summaries" ){
			mkdir ( "$path/pathway_summaries" );
		}
		$results ->{'summary_table'}->write_file("$path/pathway_summaries/$hash->{'phenotype'}.summary_table" );
	}
	foreach my $lable ( 'all', keys %{ $hash->{'exclusion_lists'} } ) {
		if ( defined $results->{$lable} ) {
			if ( defined $results->{$lable}->Header_Position('Figure Lable') ) {
				$temp =
				  $results->{$lable}
				  ->getAsHash( 'pathway_name', 'Figure Lable' );
				my $use = $lable;
				if ( $lable eq "all" ) {
					$use = 'all genes';
				}
				foreach ( keys %$temp ) {
					$hash->{'sumary_table'}->AddDataset(
						{
							'phenotype' => $hash->{'phenotype'},
							'pathway'   => $_,
							$use        => '**' . "\\ref{$temp->{$_}}"
						}
					);
				}
			}
		}
	}
	foreach ( keys %{ $results->{genes_to_be_described} } ) {
		$genes_to_be_described->{$_} = 1;
	}
#	my ( $probeset, $gene );
#	Carp::confess ( print root::get_hashEntries_as_string ( $results , 3 , "Do I have a hash at all -> 'Probe Set ID'?" ));
#	foreach my $probeset ( keys %{ $results->{'all'}->{'Probe Set ID'}} ){
#		$gene = $results->{'all'}->{'Probe Set ID'}->{$probeset};
#		$probesets_2_genes->{ $gene } = {} unless ( ref($probesets_2_genes->{ $gene }) eq "HASH");
#		$probesets_2_genes->{ $gene } ->{$probeset} = 1;
#	}
	return 1;
}
