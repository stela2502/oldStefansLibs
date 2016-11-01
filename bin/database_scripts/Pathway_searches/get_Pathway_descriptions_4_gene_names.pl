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

=head1 get_Pathway_descriptions_4_gene_names.pl

A script that querioes the local KEGG table and reports some findings.

To get further help use 'get_Pathway_descriptions_4_gene_names.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::database::genomeDB::gene_description;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::Latex_Document;
use stefans_libs::database::external_files;
use GD;

use FindBin;
my $plugin_path = "$FindBin::Bin";

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,                   $debug,        @genes,
	$outpath,                $outfile,      @otherCorrelationFiles,
	$kegg_reference_geneset, $min_genes,    $only_p_values,
	$only_significants,      $introduction, $no_genes, $desease
);

Getopt::Long::GetOptions(
	"-genes=s{,}"                      => \@genes,
	"-outpath=s"                       => \$outpath,
	"-outfile=s"                       => \$outfile,
	"-further_correlatio_results=s{,}" => \@otherCorrelationFiles,
	"-desease=s"                       => \$desease,
	"-help"                            => \$help,
	"-kegg_reference_geneset=s"        => \$kegg_reference_geneset,
	"-only_p_values"                   => \$only_p_values,
	"-min_genes=s"                     => \$min_genes,
	"-only_significants"               => \$only_significants,
	"-introduction=s"                  => \$introduction,
	"-no_genes"			   => \$no_genes,
	"-debug"                           => \$debug
);

my $warn  = '';
my $error = '';

if ( $only_significants && !defined $kegg_reference_geneset ) {
	$error .=
"Sorry, but I can only select for the significant pathways if you tell me the kegg_reference_geneset\n";
}
unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
elsif ( -f $genes[0] ) {
	open( IN, "<$genes[0]" )
	  or die "could not open the genes infile $genes[0]\n";
	my @temp;
	my $filename = $genes[0];
	while (<IN>) {
		chomp($_);
		push( @temp, split( /[ \t]/, $_ ) );
	}
	close(IN);
	@genes = undef;
	my $i = 0;
	my $gene;
	foreach $gene (@temp) {
		$genes[ $i++ ] = $gene if ( $gene =~ m/^\w+$/ );
	}
	$error .=
	  "Sorry, but I did not find any gene name in the file '$filename'!\n"
	  unless ( defined $genes[0] );
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
else {
	unless ( -d $outpath ) {
		mkdir($outpath);
	}
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $desease ) {
	$error .= "the cmd line switch -desease is undefined!\n";
}
unless ( defined $min_genes ) {
	$min_genes = 5;
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
 command line switches for get_Pathway_descriptions_4_gene_names.pl

   -genes         :a list of genes you want to get information about
   -outpath       :the path you want to sore the latex source in
   -outfile       :the outfile containing all 'original' KEGG entries
   -min_genes     :how many genes have to map to a pathway to considder it interesting
                   default 5
   -further_correlatio_results
                  :other correlation result files that are 
                   created using the batchStatistics.pl script
   -desease       :a desease you want to get some estimates on the gene importance for
   -kegg_reference_geneset
                  :the name of the gene set where you have drawn your genes from 
                   needed to calculate the hypergeometric test the names are stored 
                   in the column 'reference_dataset' in the table handled by the class
                   stefans_libs::databse::pathways::kegg::hypergeometric_max_hits
                   for my installation I need to take 'HUGene_v1'
   -only_p_values :set this option if you do not want to get all the png files and so on, 
                   but only the p_values table - in this case no PDF will be created!
                   
   -only_significants :using this option, I will only include the significant results into the PDF.
   
   -no_genes  :use this option if you do not want to get unknown gene description from the web (faster)         
   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/get_Pathway_descriptions_4_gene_names.pl';
$task_description .= ' -genes ' . join( ' ', @genes ) if ( defined $genes[0] );
$task_description .= " -outpath $outpath" if ( defined $outpath );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .=
  ' -further_correlatio_results ' . join( ' ', @otherCorrelationFiles )
  if ( defined $otherCorrelationFiles[0] );
$task_description .= " -desease $desease" if ( defined $desease );
$task_description .= " -kegg_reference_geneset $kegg_reference_geneset"
  if ( defined $kegg_reference_geneset );
$task_description .= " -only_p_values"      if ( defined $only_p_values );
$task_description .= " -min_genes $min_genes";
$task_description .= " -only_signififcants" if ( defined $only_significants );
open( LOG, ">$outpath/get_Pathway_descriptions_4_gene_names.log" )
  or die
"could not open the log file '$outpath/get_Pathway_descriptions_4_gene_names.log'\n$!\n";
print LOG "$task_description\n";
close(LOG);

my ( $kegg_genes, $tex_description, @used_genes, $reference_dataset,
	$summary_table, $gene_description, $table );

## get me some infos about the genes
my @otherDatasets = &populate_otherCorrelationFiles(@otherCorrelationFiles);

## match the genes to the pathways
$gene_description = gene_description->new( root->getDBH(), $debug );
$gene_description->DoNotConnect2WWW( 1 ) if ( $no_genes );

$kegg_genes = kegg_genes->new( root->getDBH(), $debug );
$table = $kegg_genes->get_data_table_4_search(
	{
		'search_columns' => [
			'Gene_Symbol',       'pathway_id',
			'pathway_name',      'description',
			'external_files.id', 'x_coord_1',
			'y_coord_1',         'x_coord_2',
			'y_coord_2',         'kegg_pw_id',
			'kegg_pathway.id'
		],
		'where' => [ [ 'Gene_Symbol', '=', 'my_value' ] ],
		'order_by' => ['pathway_name']
	},
	\@genes
);

unless ( ref( $table->get_line_asHash(0) ) eq "HASH" ) {
	die
"Sorry, but I could not find any KEGG pathway that described any of these genes:\n"
	  . join( "; ", @genes ) . "\n"
	  . "using the sql search $kegg_genes->{'complex_search'}\n";
}
else {
	print
"we got some results for the sql search\n$kegg_genes->{'complex_search'}\n";
}

my $latex_document = stefans_libs::Latex_Document->new();

$latex_document->Outpath($outpath);

## We do not want to analyse Pathways that have less than $min_genes hits
$table->define_subset( 'hyper_data', [ 'Gene_Symbol', 'pathway_name' ] );
$summary_table = $table->pivot_table(
	{
		'grouping_column' => 'kegg_pathway.id',
		'Sum_data_column' => 'hyper_data',
		'Sum_target_columns' =>
		  [ 'matched genes', 'pathway_name', 'Gene Symbols' ],
		'Suming_function' => sub {
			my $count        = 0;
			my $genes        = '';
			my $already_used = {};
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				next if ( defined $already_used->{ $_[$i] } );
				$already_used->{ $_[$i] } = 1;
				$count++;
				$genes .= $_[$i] . " ";
			}
			chop($genes);
			return $count, $_[1], $genes;
		  }
	}
);
my $info = $summary_table->getAsHash( 'pathway_name', 'matched genes' );
my $select = {};
foreach ( keys %$info ) {
	$select->{$_} = 1 if ( $info->{$_} >= $min_genes );
}
$table =
  $table->select_where( 'pathway_name',
	sub { return 1 if ( $select->{ $_[0] } ); return 0; } );

##################################################################################
## I need to calculate the statistics - if we know the gene list to compare to! ##
##################################################################################

if ( defined $kegg_reference_geneset ) {
	$summary_table = $table->pivot_table(
		{
			'grouping_column' => 'kegg_pathway.id',
			'Sum_data_column' => 'hyper_data',
			'Sum_target_columns' =>
			  [ 'matched genes', 'pathway_name', 'Gene Symbols' ],
			'Suming_function' => sub {
				my $count        = 0;
				my $genes        = '';
				my $already_used = {};
				for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
					next if ( defined $already_used->{ $_[$i] } );
					$already_used->{ $_[$i] } = 1;
					$count++;
					$genes .= $_[$i] . " ";
				}
				chop($genes);
				return $count, $_[1], $genes;
			  }
		}
	);
	$summary_table->createIndex('kegg_pathway.id');
	## get the pre_calculated max values
	my $hypergeometric_max_hits =
	  hypergeometric_max_hits->new( root->getDBH(), $debug );
	$reference_dataset = $hypergeometric_max_hits->get_data_table_4_search(
		{
			'search_columns' => [ 'kegg_id', 'max_count', 'bad_entries' ],
			'where' => [ [ 'kegg_id', '=', 'my_value' ] ]
		},
		[ $summary_table->getIndex_Keys('kegg_pathway.id') ]
	);

	## merge the tables
	$reference_dataset->Rename_Column( 'kegg_id', 'kegg_pathway.id' );
	$summary_table->merge_with_data_table($reference_dataset);

	## calculate the hypergeometric test
	$summary_table->define_subset( 'data',
		[ 'max_count', 'bad_entries', 'matched genes' ] );
	$summary_table->calculate_on_columns(
		{
			'function' => sub {
				return sprintf( '%.1E',
					&hypergeom( $_[0], $_[1], scalar(@genes), $_[2] ) );
			},
			'data_column'   => 'data',
			'target_column' => 'hypergeometric p value'
		}
	);
	$summary_table =
	  $summary_table->Sort_by( [ [ 'hypergeometric p value', 'numeric' ] ] );
	$summary_table->define_subset( 'plottable',
		[ 'pathway_name', 'matched genes', 'hypergeometric p value' ] );
	$summary_table->Add_2_Description( "we analyzed a total of "
		  . scalar(@genes)
		  . " genes translating in the corrected p_values \n0.05="
		  . sprintf( '%.1E', ( 0.05 / scalar(@genes) ) )
		  . "\n0.01="
		  . sprintf( '%.1E', ( 0.01 / scalar(@genes) ) ) );
	$summary_table->print2file("$outpath/$outfile.p_values.txt");
	exit 1 if ($only_p_values);

	## if we want to show only the signififcant pathways we need to remove some results from the analysis!
	if ($only_significants) {

		#print "from now on we will only process the significant pathways!\n";
		my $temp = 0.05 / scalar(@genes);
		$info =
		  $summary_table->getAsHash( 'pathway_name', 'hypergeometric p value' );
		$select = {};
		foreach ( keys %$info ) {

			#print "we test $info->{$_} <= $temp\n";
			$select->{$_} = 1 if ( $info->{$_} <= $temp );
		}
		$table =
		  $table->select_where( 'pathway_name',
			sub { return 1 if ( $select->{ $_[0] } ); return 0; } );

		#print "and we still have that:\n".$table->AsString()."\n";
	}
}

$table->createIndex('Gene_Symbol');
$table->createIndex('external_files.id');

## I want to add a red box arround the genes of interest in each pathway!
my (
	$image,      @lines,      $lineID,    $red,
	$data,       $this_genes, $latex_str, @notInKeggPathway,
	@sections,   $geneGroups, @temp,      $temp,
	@geneGroups, $this_par
);
$latex_document->Section('Introduction')->AddText($introduction)
  if ( $introduction =~ m/\w/ );
$latex_document->Section( 'Summary', 'summary' )
  ->AddText(
	'This document describes the pathways, that contain at least one of the '
	  . scalar(@genes)
	  . " that should be analyzed. A complete list of the genes can be found in section \\ref{app.geneList}.\n"
  );

@notInKeggPathway = ();

foreach my $gene (@genes) {
	unless (
		$table->get_rowNumbers_4_columnName_and_Entry( 'Gene_Symbol', $gene ) )
	{
		push( @notInKeggPathway, $gene );
	}
	else {
		push( @used_genes, $gene );
	}
}
if ( $notInKeggPathway[0] =~ m/\w/ ) {
	$latex_document->Section('Summary')
	  ->AddText( "Unfortunately, "
		  . scalar(@notInKeggPathway)
		  . " genes could not be mapped to any of the known (human) KEGG pathways.\n"
		  . "A list of these genes can be found in section \\ref{app.notUsedGenes}.\n"
	  );
}
if ( ref($summary_table) eq "data_table" ) {
	$latex_document->Section('Statistics')->AddText(
		"We used a hypergeometric test to 
	determine whether the pathways are overrepresented in the gene list or not.
	Please keep in min, that we performed "
		  . scalar( @{ $summary_table->{'data'} } )
		  . " different tests and therefore these corrected significance cut off levels should be used: "
		  . "0.05 = "
		  . ( 0.05 / scalar( @{ $summary_table->{'data'} } ) )
		  . " and 0.01 = "
		  . ( 0.01 / scalar( @{ $summary_table->{'data'} } ) ) . "."
	  )->Add_Table( $summary_table->GetAsObject('plottable') )
	  ;
}

$latex_document->Section('The KEGG Pathways', 'KEGG.Pathways' );

my ($external_files);
$external_files = external_files->new( $gene_description->{'dbh'} );
foreach my $picture ( $table->getIndex_Keys('external_files.id') ) {
	my $latex_str = '';
	$image =
	  GD::Image->new( $external_files->get_fileHandle( { 'id' => $picture } ) );
	@lines =
	  $table->get_rowNumbers_4_columnName_and_Entry( 'external_files.id',
		$picture );
	print "we got the lines "
	  . join( ", ", @lines )
	  . " for the pathway $picture\n";
	$red        = $image->colorAllocate( 255, 0, 0 );
	$this_genes = {};
	$geneGroups = {};
	foreach $lineID (@lines) {
		$data = $table->get_line_asHash($lineID);
		$data->{'pathway_name'} =~ s/&/\\&/g;
		$data->{'pathway_name'} =~ s/#/\\&/g;
		$data->{'description'}  =~ s/&/\\&/g;
		$data->{'description'}  =~ s/#/\\&/g;
		$geneGroups->{"$data->{'x_coord_2'} $data->{'y_coord_2'}"} = {
			'genes' => {},
			'x'     => $data->{'x_coord_2'},
			'y'     => $data->{'y_coord_2'}
		  }
		  unless (
			defined $geneGroups->{"$data->{'x_coord_2'} $data->{'y_coord_2'}"}
		  );
		$geneGroups->{"$data->{'x_coord_2'} $data->{'y_coord_2'}"}->{'genes'}
		  ->{ $data->{'Gene_Symbol'} } = 1;
		$image->rectangle(
			$data->{'x_coord_1'}, $data->{'y_coord_1'}, $data->{'x_coord_2'},
			$data->{'y_coord_2'}, $red
		);
		$this_genes->{ $data->{'Gene_Symbol'} } = 1
		  if ( $data->{'Gene_Symbol'} =~ m/\w/ );
	}
	@temp = (
		sort {
			scalar( keys %{ $geneGroups->{$b}->{'genes}'} } ) <=>
			  scalar( keys %{ $geneGroups->{$a}->{'genes}'} } )
		  } keys %$geneGroups
	);

	@geneGroups = ();
	for ( my $i = 0 ; $i < @temp ; $i++ ) {
		$temp = "(" . ( $i + 1 ) . ") ";
		foreach ( sort keys %{ $geneGroups->{ $temp[$i] }->{'genes'} } ) {
			$temp .= "\\nameref{$_}, ";
		}
		chop($temp);
		chop($temp);
		push( @geneGroups, $temp );
		$image->string( gdSmallFont,
			$geneGroups->{ $temp[$i] }->{'x'} + 2,
			$geneGroups->{ $temp[$i] }->{'y'} - 3,
			$i + 1, $red
		);
	}
	open( OUT, ">$outpath/$data->{'kegg_pw_id'}.png" )
	  or die
	  "could not craete new image file '$outpath/$data->{'kegg_pw_id'}.png'\n";
	print OUT $image->png();
	close(OUT);
	print
"we have added a red rectangle for all GOIs and stored the pathway picture there: '$outpath/$data->{'kegg_pw_id'}.png'\n"
	  . "we gave marked the genes "
	  . join( ", ", ( keys %$this_genes ) )
	  . " by red rectangles!\n";
	$latex_str = &create_figure( $data, @geneGroups );
	
	$latex_str ->AddText( $gene_description->get_Latex_Gene_summary(
		{
			'genes' => [ ( keys %$this_genes ) ],
			'desease'      => $desease,
			'header_level' => 2
		},
		$data->{kegg_pw_id}
	));    #if ( defined $this_genes[0]);
	$latex_str ->AddText(
"The pathway in a graphical view is depicted in figure \\ref{fig.$data->{kegg_pw_id}::0}.\n\n");
}

print "we do not use the web to get Gene infos? $no_genes\n";

$gene_description->add_LaTeX_section_for_Gene_List( {
	'LaTeX_object' => $latex_document,
	'genes' =>   [@used_genes],
	'otherDatasets' => [@otherDatasets]
});
$latex_document ->Section ( 'APPENDIX' ) ->Section ( 'Genes Of Interest', 'app.geneList')
	->AddText (join( "; ", sort @genes ) );

$latex_document ->Section ( 'APPENDIX' ) ->Section ( 'Unused Genes', 'app.notUsedGenes' )
 ->AddText ( join( "; ", sort @notInKeggPathway ));
$latex_document ->Section ( 'APPENDIX' ) ->Section ( 'Command that created this document', 'command' ) ->AddText ("$task_description");
$table->define_subset( 'printables',
	[ 'Gene_Symbol', 'pathway_name', 'kegg_pw_id' ] );
$latex_document ->Section ( 'APPENDIX' ) ->Section ( 'KEGG 2 gene table' )->
	AddText ( 'The original return values from the database:' ) ->Add_Table ( $table->GetAsObject('printables') );

$latex_document->write_tex_file($outfile);


sub create_figure {
	my ( $dataHash, @interesting_genes ) = @_;
	my $section = 
	$latex_document->Section('The KEGG Pathways' ) ->Section ($dataHash->{pathway_name}, 'summmary.' . $dataHash->{kegg_pw_id});
	my $figure = $section ->AddText( $dataHash->{'description'} );
	$figure = $figure ->Add_Figure ();
	$figure -> AddPicture ( {
	'placement' => 'tbp',
	'files' => [ $outpath."/".$dataHash->{kegg_pw_id}.".png" ],
	'caption' => 'The '
	  . $dataHash->{pathway_name}
	  . ' pathway. Red rectangles mark the genes, that you wanted to get pathway information for. The red number at the rectangles is a substitute for a list of genes: '
	. join( "; ", @interesting_genes ).
	'. Go back to gene description \\nameref{summmary.'
	  . $dataHash->{kegg_pw_id} . '}',
	'width' => 0.9,
	'label' => "fig.$dataHash->{kegg_pw_id}"
	});
	return $section;
}

sub _tex_file {
	$outfile .= ".tex" unless ( $outfile =~ m/\.tex$/ );
	if ( -f "$outpath/$outfile" ) {
		my $str = '';
		open( IN, "<$outpath/$outfile" )
		  or die "could not open tex file '$outpath/$outfile'\n";
		while (<IN>) {
			$str .= $_;
		}
		close(IN);
		if ( $str =~ m/##GENE GROUPS##/ && $str =~ m/##GENE DESCRIPTION##/ ) {
			## OK this sceleton is usable!
			return $str;
		}
		else {
			warn
"The outfile $outfile does not contain the ##GENE GROUPS## tag - I will use the inbuilt tex template!\n";
		}
	}

	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{graphicx}

\begin{document}
\tableofcontents
  
\title{ A small summary for a list of genes }
\author{Stefan Lang}\\
\date{' . root->Today() . '}
\maketitle
  
##GENE GROUPS##
  
\end{document}
';
}

sub populate_otherCorrelationFiles {
	my (@otherCorrelationFiles) = @_;
	my (@otherDatasets)         = @_;
	if ( defined $otherCorrelationFiles[0] ) {
		my $i = 0;
		foreach my $other_correlation_file (@otherCorrelationFiles) {
			next unless ( -f $other_correlation_file );

			#warn "we read the file $other_correlation_file\n";
			$otherDatasets[$i] = data_table->new();
			$otherDatasets[$i]->read_file($other_correlation_file);

#warn "we got the column headers '".join("', '",@{$otherDatasets[$i]->{'header'}})."\n";
			$otherDatasets[$i]->createIndex('Gene Symbol');
			$otherDatasets[$i]->Name($1)
			  if $other_correlation_file =~ m/([\w\-_]+).txt/;

#print "We got the headers: '".join( "', '",@{$otherDatasets[$i]->{'header'}})."'\n";
			$otherDatasets[$i]->define_subset( 'info', [ 'p value', 'rho' ] );
			$i++;
		}
		if ($debug) {
			print
"expression_net_to_R_network.pl -> we have added $i other correlation datasets to our analysis\n"
			  if ( $i > 0 );
			for ( my $i = 0 ; $i < @otherDatasets ; $i++ ) {
				print $otherDatasets[$i]->Name()
				  . " - did we get some value 4 gene KLHDC5? '"
				  . $otherDatasets[$i]
				  ->get_value_for( 'Gene Symbol', 'KLHDC5', 'p value' ) . "'\n";
			}
		}
	}
	return (@otherDatasets);
}

sub logfact {
	return gammln( shift(@_) + 1.0 );
}

sub hypergeom {

	# There are m "bad" and n "good" balls in an urn.
	# Pick N of them. The probability of i or more successful selection +s:
	# (m!n!N!(m+n-N)!)/(i!(n-i)!(m+i-N)!(N-i)!(m+n)!)
	my ( $n, $m, $N, $i ) = @_;

	my $loghyp1 =
	  logfact($m) + logfact($n) + logfact($N) + logfact( $m + $n - $N );
	my $loghyp2 =
	  logfact($i) +
	  logfact( $n - $i ) +
	  logfact( $m + $i - $N ) +
	  logfact( $N - $i ) +
	  logfact( $m + $n );
	return exp( $loghyp1 - $loghyp2 );
}

sub gammln {
	my $xx  = shift;
	my @cof = (
		76.18009172947146,   -86.50532032941677,
		24.01409824083091,   -1.231739572450155,
		0.12086509738661e-2, -0.5395239384953e-5
	);
	my $y = my $x = $xx;
	my $tmp = $x + 5.5;
	$tmp -= ( $x + .5 ) * log($tmp);
	my $ser = 1.000000000190015;
	for my $j ( 0 .. 5 ) {
		$ser += $cof[$j] / ++$y;
	}
	-$tmp + log( 2.5066282746310005 * $ser / $x );
}
