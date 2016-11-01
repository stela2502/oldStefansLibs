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

=head1 expression_net_to_R_network.pl

A test to cast a expression net into an R network

To get further help use 'expression_net_to_R_network.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::file_readers::expression_net_reader;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::statistics::new_histogram;
use Statistics::R;
use Carp;
use strict;
use warnings;

my (
	$help,                $debug,
	$infile,              $outpath,
	$tex_skeleton,        @drop_connections_from_genes,
	$R_squared,           $describe_connection,
	$max_p_value,         $other_infile,
	@reference_gene_list, $min_links,
	$only_statistics,     @initial_genes,
	@otherDatasets,       @otherCorrelationFiles,
	$output_type,         $organism_tag
);

Getopt::Long::GetOptions(
	"-infile=s"                         => \$infile,
	"-outpath=s"                        => \$outpath,
	"-tex_skeleton=s"                   => \$tex_skeleton,
	"-R_squared=s"                      => \$R_squared,
	"-max_p_value=s"                    => \$max_p_value,
	"-other_infile=s"                   => \$other_infile,
	"-initial_genes=s{,}"               => \@initial_genes,
	"-describe_connection=s"            => \$describe_connection,
	"-drop_connections_from_genes=s{,}" => \@drop_connections_from_genes,
	"-further_correlatio_results=s{,}"  => \@otherCorrelationFiles,
	"-min_connections=s"                => \$min_links,
	"-output_type=s"                    => \$output_type,
	"-reference_gene_list=s{,}"         => \@reference_gene_list,
	"-only_statistics"                  => \$only_statistics,
	"-KEGG_organism_tag=s"              => \$organism_tag,
	"-help"                             => \$help,
	"-debug"                            => \$debug,
);
my $error = '';

if ($help) {
	print helpString();
	exit;
}

unless ( -f $infile ) {
	$error .= "we got no readabele infile!\n";
}

unless ( defined $outpath ) {
	$error .= "we need to have the outpath to store the graphical net!\n";
}
elsif ( !( -d $outpath ) ) {
	mkdir($outpath);
}
unless ( defined $initial_genes[0] ) {
	warn 'the cmd line switch -initial_genes is undefined';
}
elsif ( -f $initial_genes[0] ) {
	open( G, "<$initial_genes[0]" )
	  or die "could not open the initial genes file '$initial_genes[0]'\n";
	my $i = 0;
	while (<G>) {
		chomp($_);
		foreach my $gene ( split( / +/, $_ ) ) {
			$initial_genes[ $i++ ] = $gene;
		}
	}
	close(G);
}
unless ( defined $reference_gene_list[0] ) {
	warn
"I will not calculate the percent overlap in the logfile unless you specify the -reference_gene_list\n";
}
elsif ( -f $reference_gene_list[0] ) {
	open( G, "<$reference_gene_list[0]" )
	  or die
	  "could not open the initial genes file '$reference_gene_list[0]'\n";
	my $i = 0;
	while (<G>) {
		chomp($_);
		foreach my $gene ( split( /\s+/, $_ ) ) {
			$reference_gene_list[ $i++ ] = $gene;
		}
	}
	close(G);
}
$min_links = 2 unless ( defined $min_links );
unless ($only_statistics) {
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
"expression_net_to_R_network.pl -> we have added $i other correlation datasets to our analysis\n"
		  if ( $i > 0 );
		for ( my $i = 0 ; $i < @otherDatasets ; $i++ ) {
			print $otherDatasets[$i]->Name()
			  . " - did we get some value 4 gene KLHDC5? '"
			  . $otherDatasets[$i]
			  ->get_value_for( 'Gene Symbol', 'KLHDC5', 'p value' ) . "'\n";
		}

		#	die ;
	}
}
if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit();
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );

#' drop_connections_from_genes#array tex_skeleton min_connections max_p_value  R_squared infile other_infile describe_connection further_correlatio_results#array output_type outpath';
	return "
 $errorMessage
 command line switches for expression_net_to_R_network.pl

   -drop_connections_from_genes
                   :a list of genes where you do not want to see the connections 
                    from that gene (only to the gene)
   -tex_skeleton   :A tex document that contains the '##EXPRESSION-NET-FIGURE##' tag
                    this script will place a latex formated figure there.
                    If you do not give me that file I have a basic inbuilt tex template.
   -min_connections:The minimal amount of links for a gene to be included in the picture
                    (default = 2)
   -max_p_value    :the cutoff for the correlation p_value
   -R_squared      :if you want to restirct the dataset to a min R squared for the correlation
   -infile         :the expression net you want to cast into a R network
   -other_infile   :a second expression net, that you want to use to identify obviouse changes
                    in the correlation patterns
   -initial_genes  :a list of initial genes. These genes should have passed the 
                    first correlation cutoff. 
   -describe_connection
                   :a short description of how the other infile is connected to the main infile 
                    and why you think a the difference between the two files is important
   -further_correlatio_results
                   :other correlation result files that are 
                    created using the batchStatistics.pl script
   -output_type    :if set, we can modify the output type - please look in
                    stefans_libs::file_readers::expression_net_reader.pm for a description of the options
   -outpath        :the name of the expression net picture
   
   -only_statistics :use this switch in case you do only want to get a small summary info
   
   -reference_gene_list :if you want to compare this connection net to another connection net, you
                         need to give me the file containing all the genes that correlated with the other net
                         I will then be able to report a 'percent overlap' value in the log file
   -KEGG_organism_tag   :an optional organism_tag that will add the amount of hits 
                         to all KEGG pathways in the database to the expression_net_statistics_log file
                         This data could be used to identify those KEGG pathways that were hit more 
                         frequently than expected by chance!
                         
   -help           :print this help
   -debug          :verbose output

";
}

my $task_description = 'expression_net_to_R_network.pl';
$task_description .=
  ' -drop_connections_from_genes ' . join( ' ', @drop_connections_from_genes )
  if ( defined $drop_connections_from_genes[0] );
$task_description .= " -tex_skeleton $tex_skeleton"
  if ( defined $tex_skeleton );
$task_description .= " -min_connections $min_links" if ( defined $min_links );
$task_description .= " -max_p_value $max_p_value"   if ( defined $max_p_value );
$task_description .= " -R_squared $R_squared"       if ( defined $R_squared );
$task_description .= " -infile $infile"             if ( defined $infile );
$task_description .= " -other_infile $other_infile"
  if ( defined $other_infile );
$task_description .= " -describe_connection $describe_connection"
  if ( defined $describe_connection );
$task_description .=
  ' -further_correlatio_results ' . join( ' ', @otherCorrelationFiles )
  if ( defined $otherCorrelationFiles[0] );
$task_description .= " -output_type $output_type" if ( defined $output_type );
$task_description .= " -outpath $outpath"         if ( defined $outpath );
$task_description .= " -initial_genes '" . join( "' '", @initial_genes ) . "'"
  if ( defined $initial_genes[0] );
$task_description .=
  " -reference_gene_list '" . join( "' '", @reference_gene_list ) . "'"
  if ( defined $reference_gene_list[0] );

my ( $other_exp_net, $temp );
if ( defined $other_infile ) {
	if ( -f $other_infile ) {
		die helpString( "sorry, but if you give me another expression net,\n"
			  . "I definitively want to know WHY you did that (-describe_connection)\n"
		) unless ( defined $describe_connection );
		$other_exp_net = expression_net_reader->new();

		$other_exp_net->Read_from_File( $other_infile, \@initial_genes, 1 );
		$describe_connection .=
" Keep in mind, that the correlations were not filtered in this other dataset.\n"
		  . "Therefore even a correlation with a p value of 0.05 will result in a replication of the correlation.\n";
	}
}

#die "sorry , but the initial genes were not defined as needed:".join("; ", @initial_genes)."\n" if ( !defined $initial_genes[0]);
my $expression_net_reader =
  expression_net_reader->new( $infile, @initial_genes );
$expression_net_reader =
  $expression_net_reader->restrict_R_squared_moreThan($R_squared)
  if ( defined $R_squared );
$expression_net_reader =
  $expression_net_reader->restrict_p_value_lessThan($max_p_value)
  if ( defined $max_p_value );
$expression_net_reader =
  $expression_net_reader->drop_connections_from_gene(
	@drop_connections_from_genes)
  if ( defined $drop_connections_from_genes[0] );

my $fileHandle =
  $expression_net_reader->Logfile( $outpath . "/expression_net_statistcs.txt" );
die "Hej, we did not get a open file handle by setting the LogFile!\n"
  unless ( ref($fileHandle) eq "GLOB" );

$expression_net_reader->output_type($output_type)
  ;    ## this will set a default ouput type if $output_type is not defined.
$expression_net_reader->connection_exists( 'rag1', 'rag2' );
if ( defined $reference_gene_list[0] ) {
	$expression_net_reader->Compare_to_Reference_list( \@reference_gene_list );
}
$expression_net_reader->Add_Phenotype_Informations(@otherCorrelationFiles);
if ( defined $organism_tag ){
	## this will add a lot to the statistics part!
	#  be careful if you want to use it
	$expression_net_reader -> use_organism ( $organism_tag );
}
$expression_net_reader->__create_connection_dataset();
$expression_net_reader->__define_connection_groups($min_links);

if ($only_statistics) {
	open( OUT, ">$outpath/genes.txt" )
	  or die
	  "sorry, but I could not create the genes report '$outpath/genes.txt'\n";
	print OUT join( " ", sort keys %{ $expression_net_reader->{'defined'} } )
	  . "\n";
	close ( OUT );
	open ( OUT ,">$outpath/connection_group_genes.txt") or die
	  "sorry, but I could not create the genes report '$outpath/connection_group_genes.txt'\n";
	
	#my $R_cmd = $expression_net_reader->getAs_R_matrix( $outpath, $min_links );
	print OUT join( " ", sort @{$expression_net_reader->{'cg_gene_list'}} )."\n";
	close ( OUT );
	print
"as you only wanted to get the statistics done please get them from $outpath/expression_net_statistcs.txt\n";
	exit;
}

print "we try to identfy the connection net figure '$outpath/pic.svg'\n";
unless ( -f "$outpath/pic.svg" ) {
	#die "we try to create the figure using getAs_R_matrix( $outpath, $min_links )\n";
	my $R_cmd = $expression_net_reader->getAs_R_matrix( $outpath, $min_links );

	my $R = Statistics::R->new();
	$R->{'START_CMD'} = "$R->{R_BIN} --slave --vanilla --gui=X11";
	$R->startR() unless ( $R->is_started() );
	my @cmd = split( "\n", $R_cmd );
	foreach my $cmd (@cmd) {
		$R->send($R_cmd);
		$cmd = $R->read();
		print "R output: '$cmd'\n" if ( $cmd =~ m/\w/ );
	}
	$R->stopR();
}

#print "we have executed the R command\n$R_cmd\n";
$expression_net_reader->Write_to_File( $infile . "cutoff_R_$R_squared.txt" );

#$expression_net_reader->Logfile("$outpath/GENE_CONNECTIONS_LOG.txt");
my @path = split( '/', $infile );

pop(@path);
open( OUT, ">$outpath/genes.txt" )
  or die "could not craete $outpath/genes.txt\n";
print OUT join( " ", @{ $expression_net_reader->{'initial_genes'} } ) . " "
  . join( " ", @{ $expression_net_reader->{'new_genes'} } ) . "\n";

#  print "we touched the genes ".join( " ", @{ $expression_net_reader->{'initial_genes'} } ) . " "
#  . join( " ", @{ $expression_net_reader->{'new_genes'} } ) ."\n";
close OUT;
print "all touched genes are in $outpath/genes.txt\n";
open( OUT, ">$outpath/initial_genes.txt" )
  or die "could not create $outpath/initial_genes.txt\n";
print OUT join( " ", @{ $expression_net_reader->{'initial_genes'} } ) . "\n";
close OUT;
open ( OUT ,">$outpath/connection_group_genes.txt") or die
  "sorry, but I could not create the genes report '$outpath/connection_group_genes.txt'\n";
print OUT join( " ", sort @{$expression_net_reader->{'cg_gene_list'}} )."\n";
close ( OUT );
print "All initial genes are in $outpath/initial_genes.txt\n";
open( OUT, ">$outpath/new_genes.txt" )
  or die "could not create $outpath/new_genes.txt\n";
print OUT join( " ", @{ $expression_net_reader->{'new_genes'} } ) . "\n";
close OUT;
print "All new genes are in $outpath/new_genes.txt\n";

#$tex_skeleton =~ s/\t?e?x?^/with_exp_netFig.tex/;

my $figure = '
\section{Graphical view of the expression net}
\label{r-network}
'
  . "The graphical view should give an impression of which genes influence the expression of an other gene.\n"
  . "But the results may also indicate which genes are regulated by similar external influences on a cell.\n"
  . "The external influence on these genes might by anything including promoter variations in these genes or"
  . " in genes upstream of the \\textbf{expression} of these genes.\n\n"
  . "We have got a list of correlations between the genes ";

foreach my $initial_gene ( @{ $expression_net_reader->{'initial_genes'} } ) {
	$figure .= " \\nameref{" . root->Latex_Label($initial_gene) . "},";
}
chop($figure);
$figure .=
  " and the expression of each and every other gene on the expression array.\n";
$figure .=
"We have applied a quality filter to these correlations that dropps all correlations, \n"
  . "that show a \$R^2\$ value \$ <$R_squared \$ AND \$ >-$R_squared\$.\n";
$figure .= '\begin{figure}[tbp]
\centering
\includegraphics[width=17cm]{pic}
\caption{The expression net figure was created using the data stored in '
  . "'$infile'\n";
$figure .=
"We used only the correlations, that were reported with a R square of more than $R_squared or less than -$R_squared."
  if ( defined $R_squared );
$figure .=
"We applied a p value cutoff, removing correlations with a p value above $max_p_value\n"
  if ( defined $max_p_value );

if ( defined $drop_connections_from_genes[0] ) {
	$figure .= "In addition we dropped connections from the ";
	if ( scalar(@drop_connections_from_genes) == 1 ) {
		$figure .= "gene \\nameref{"
		  . root->Latex_Label( $drop_connections_from_genes[0] ) . "}.\n";
	}
	else {
		for ( my $i = 0 ; $i < @drop_connections_from_genes ; $i++ ) {
			$drop_connections_from_genes[$i] = "\\nameref{"
			  . root->Latex_Label( $drop_connections_from_genes[0] ) . "}";
		}
		$figure .=
		  "genes " . join( ", ", @drop_connections_from_genes ) . ".\n";
	}
}

$figure .=
"In order to focus on the connections between the genes, we have limited the figure to show only genes,\n"
  . " that have a connection to at least $min_links other genes. In addition, \n"
  . "I grouped the genes, that make up the connection into groups. "
  . "The groups are ordered by the amount of grouping genes, starting at Gr.1 with "
  . "the maximum amount of grouping genes. The contents of the groups are described in section \\ref{connectingGroups}.\n";
$figure .= "}\n\\end{figure}\n\n";
my $file = '';
$temp = {
	'header_level' => 1,
	'otherDataset' => \@otherDatasets,
	'outpath'      => $outpath
};

$figure .= $expression_net_reader->Connection_Groups_Description($temp);
##now we need to create the group list
open( G_LIST, ">$tex_skeleton.G_LIST" )
  or die "could not create outfile $tex_skeleton.G_LIST";
foreach my $groupName (
	sort {
		my ( $x, $y ) = ( $a, $b );
		$x =~ s/$expression_net_reader->{'groupTag'}//;
		$y =~ s/$expression_net_reader->{'groupTag'}//;
		$x =~ s/ \(\d+\)//;
		$y =~ s/ \(\d+\)//;
		return $x <=> $y;
	} keys %{ $expression_net_reader->{'connection_group_description'} }
  )
{
	print G_LIST "$groupName\n"
	  . join(
		"\t",
		@{
			$expression_net_reader->{'connection_group_description'}
			  ->{$groupName}->{'connecting_genes'}
		  }
	  ) . "\n";
}
close(G_LIST);
$temp = {
	'header_level'                     => 1,
	'section_text'                     => '',
	'otherDataset'                     => \@otherDatasets,
	'arbitrary_desease_score'          => 0,
	'add_desciption_2_each_subsection' => 0
};
if ( defined $other_exp_net ) {
	$temp->{'other_expression_net'}    = $other_exp_net;
	$temp->{'describe_other_expr_net'} = $describe_connection;
}
$output_type ='' unless ( defined $output_type);
if ( $output_type eq "long" ) {
	$temp->{'arbitrary_desease_score'} = 1;
}
else {
	$temp->{'otherDataset'} = [];
}

$figure .= $expression_net_reader->getDescription_table($temp);

#my $new_histogram = new_histogram->new();
#$new_histogram->CreateHistogram( [ values %{$expression_net_reader->getGeneDigest()} ], undef, 100 );
#$new_histogram->plot( { 'outfile' => $tex_skeleton . ".histogram_over_word_counts" } );
my $app = $expression_net_reader->getCorrelationAppendix(@otherDatasets);

my $file_str = &_tex_file();
$file_str =~ s/##EXPRESSION-NET-FIGURE##/$figure/;
$file_str =~ s/##APPENDIX##/$app/;

$tex_skeleton = md5_hex($task_description) . ".tex"
  unless ( defined $tex_skeleton );

open( OUT, ">$tex_skeleton" )
  or die "could not open the outfile '$tex_skeleton'\n";
print OUT $file_str;
close(OUT);
print "the latex formated figure has been added to '$tex_skeleton'\n";

sub _tex_file {
	if ( -f $tex_skeleton ) {
		my $str = '';
		open( IN, "<$tex_skeleton" )
		  or die "could not open tex file '$tex_skeleton'\n";
		while (<IN>) {
			$str .= $_;
		}
		close(IN);
		if ( $str =~ m/##EXPRESSION-NET-FIGURE##/ ) {
			## OK this sceleton is usable!
			return $str;
		}
		else {
			warn
"The tex sceleton $tex_skeleton does not contain the ##EXPRESSION-NET-FIGURE## tag - I will use the inbuilt tex template!\n";
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
  
\title{ A small summary for a list of genes }
\author{Stefan Lang}\\
\date{' . root->Today() . '}
\maketitle
    
##INTRODUCTION##

##SUMMARY##

##GENE GROUPS##

##EXPRESSION-NET-FIGURE##

##SPECIAL GENES##

##GENE DESCRIPTION##

##APPENDIX##
  
  \end{document}
';
}
