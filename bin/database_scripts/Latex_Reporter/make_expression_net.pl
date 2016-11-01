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

=head1 make_expression_net.pl

A report script, that relies on other scripts to digest through some expression values - highly extensible

To get further help use 'make_expression_net.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::system_tables::workingTable;
use stefans_libs::database::system_tables::loggingTable;
#use stefans_libs::database::system_tables::errorTable;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,            $debug,
	$database,        $expression_net,
	$R_square,        @drop_connections_from_genes,
	$tex_skeleton,    @rsIDs,
	$max_dist_to_SNP, $work_description,$max_p_value,
	$outpath,         $latex_title,$no_PDF,
	$organism_tag,    @initial_genes, $min_links, $describe_connection, 
	$other_expression_net, $output_type, @otherCorrelationFiles
);

Getopt::Long::GetOptions(
	"-expression_net=s"                 => \$expression_net,
	"-initial_genes=s{,}"               => \@initial_genes,
	"-R_squared=s"                       => \$R_square,
	"-drop_connections_from_genes=s{,}" => \@drop_connections_from_genes,
	"-tex_skeleton=s"                   => \$tex_skeleton,
	"-rsIDs=s{,}"                       => \@rsIDs,
	"-max_dist_to_SNP=s"                => \$max_dist_to_SNP,
	"-work_description=s"               => \$work_description,
	"-other_expression_net=s"           => \$other_expression_net,
	"-describe_connection=s"            => \$describe_connection,
	"-further_correlatio_results=s{,}"  => \@otherCorrelationFiles,
	"-outpath=s"                        => \$outpath,
	"-min_connections=s"                => \$min_links,
	"-max_p_value=s"                    => \$max_p_value,
	"-output_type=s"                    => \$output_type,
	"-latex_title=s"                    => \$latex_title,
	"-help"                             => \$help,
	"-organism_tag=s"                   => \$organism_tag,
	"-debug"                            => \$debug,
	"-no_PDF"                           => \$no_PDF,
	"-database=s"                       => \$database
);

my $error = '';

unless ( defined $expression_net ) {
	$error .= 'the cmd line switch -expression_net is undefined!';
}
unless ( defined $R_square ) {
	warn 'the cmd line switch -R_square is undefined!';
}
unless ( defined $drop_connections_from_genes[0] ) {
	warn 'the cmd line switch -drop_connections_from_genes is undefined!\n';
}
unless ( defined $tex_skeleton ) {
	warn 'the cmd line switch -tex_skeleton is undefined!\n';
}
unless ( defined $rsIDs[0] ) {
	warn 'the cmd line switch -rsIDs is undefined!';
}
unless ( defined $initial_genes[0] ) {
	warn 'the cmd line switch -initial_genes is undefined';
}
elsif ( -f $initial_genes[0]){
	open (G ,"<$initial_genes[0]") or die "could not open the initial genes file '$initial_genes[0]'\n";
	my $i = 0;
	while ( <G> ){
		chomp ( $_);
		foreach my $gene ( split( / +/,$_) ){
			$initial_genes[$i++] = $gene;
		}
	}
}
$min_links = 2 unless ( defined $min_links);

unless ( defined $organism_tag ) {
	$error .= 'the cmd line switch -organism_tag is undefined!';
}

unless ( defined $max_dist_to_SNP ) {
	$max_dist_to_SNP = 500000;
	warn 'the cmd line switch -max_dist_to_SNP is undefined -> set to 500kb\n';
}
unless ( defined $work_description ) {
	$work_description = '';
	warn 'the cmd line switch -work_description is undefined!';
}
unless ( defined $outpath ) {
	$work_description = '';
	$error .= 'the cmd line switch -outpath is undefined!';
}
elsif ( !-d $outpath ) {
	mkdir($outpath);
}

unless ( defined $latex_title ) {
	$work_description = '';
	$error .= 'the cmd line switch -latex_title is undefined!';
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
 command line switches for make_expression_net.pl

   -expression_net       :a file containing an expression net 
                          as given by createConnectionNet_4_expressionArrays.pl
   -other_expression_net :a second expression net, that you want to use to identify obviouse changes
                          in the correlation patterns
   -describe_connection  :a short description of how the other infile is connected to the main infile 
                          and why you think a the difference between the two files is important
   -R_squared            :a cutoff value to further restrict the expression net 
                          to quite good correlations (e.g. 0.65; max = 1)
   -max_p_value          :only correlations with a p_value below that level will be used
   -drop_connections_from_genes       
                         :a list of genes, for which you want to drop the connections
   -further_correlatio_results
                         :other correlation result files that are 
                          created using the batchStatistics.pl script 
                          FROM that gene to other genes   
   -tex_skeleton         :a sample tex file that has to contain several strings 
                          where we will include the results.
   -rsIDs                :an optional list opf rsIDs to highlight genes that 
                          lie in close contact to these SNPs
   -max_dist_to_SNP      :this value together with the rsID defines the genes, 
                          that will be highlighted
   -work_description     :an optional string, that should describe 
                          the background and the aim for this latex output dataset.
   -min_connections      :The minimal amount of links for a gene to be included in the picture
                          (default = 2)
   -outpath              :a path to store the latex tree in
   -organism_tag         :the NCBI genome name to identify the right genome to look at
   -latex_title          :a title for this result
   -initial_genes        :a list of initial genes. These genes should have passed the 
                          first correlation cutoff. 
                          How you got that list should be described in 'work_description'
   -output_type          :if set, we can modify the output type - please look in
                          stefans_libs::file_readers::expression_net_reader.pm for a description of the options
   -no_PDF               :just create the makefile to 'make' the PDf - do not execute it
                          this option helps to identify errors in a downstream script call
   
   -help                 :print this help
   -debug                :verbose output

";
}

## now we set up the logging functions....

my (
	$task_description, $workingTable,   $loggingTable,
	$workLoad,         $loggingEntries, $usedGenes
);

$workingTable = workingTable->new( $database, $debug );
$loggingTable = loggingTable->new( $database, $debug );
open ( LOG , ">$outpath/make_expression_net.log") or die "Sorry, but I could not create the log file '$outpath/make_expression_net.log'\n$!\n";
## and add a working entry

$task_description =
"perl ".root->perl_include()." $plugin_path/make_expression_net.pl -expression_net $expression_net";
$task_description .= " -initial_genes '".join( "' '", @initial_genes) ."'" if ( defined $initial_genes[0]);
$task_description .= " -R_squared $R_square ";
$task_description .= " -drop_connections_from_genes ". join( " ", @drop_connections_from_genes ) if ( defined $drop_connections_from_genes[0]);
$task_description .= " -tex_skeleton $tex_skeleton " if ( defined $tex_skeleton);
$task_description .= " -rsIDs '".join( "' '", @rsIDs )."'" if ( defined $rsIDs[0] );
$task_description .= " -max_dist_to_SNP $max_dist_to_SNP" if ( defined $max_dist_to_SNP);
$task_description .= " -work_description '$work_description'" if ( defined $work_description);
$task_description .= " -other_expression_net $other_expression_net" if ( defined $other_expression_net);
$task_description .= " -describe_connection '$describe_connection'" if ( defined $describe_connection);
$task_description .= " -further_correlatio_results ".join( " ",@otherCorrelationFiles) if ( defined $otherCorrelationFiles[0]);
$task_description .= " -outpath $outpath" if (defined  $outpath);
$task_description .= " -min_connections $min_links" if ( defined $min_links);
$task_description .= " -max_p_value $max_p_value" if ( defined $max_p_value);
$task_description .= " -latex_title '$latex_title'" if ( defined $latex_title );
$task_description .= " -organism_tag $organism_tag" if ( defined $organism_tag);
$task_description .= " -no_PDF" if ( $no_PDF );

print LOG "MASTER CMD:\n$task_description\n";

	## first we need to create the latex file

	my ( $str, $outfile, $introduction, $cmd, @data,
		@not_in_second_correlation );
	$str = &_tex_file();

	$outfile = join( "_", split( /[ -]/, $latex_title ) );
	foreach my $name ( "aux", "out", "toc", "log" ) {
		unlink("$outpath/$outfile.$name") if ( -f "$outpath/$outfile.$name" );
	}

	open( OUT, ">$outpath/$outfile.tex" )
	  or die "could not create latex file $outpath/$outfile.tex\n";
	$str =~ s/##TITLE##/$latex_title/;

	print OUT $str;
	close(OUT);
	## OK now we need to start the downstream analysis processes...
	my @path = split( "/", $0 );
	splice( @path, @path - 4, 4 );
	print "we expect the scripts to be downstream of "
	  . join( "/", @path )
	  . "/bin\n";

	## 1. downstream process is the generation of the expression net,
	## as that will generate (hopefully) a lot of downstream information

	## the '##EXPRESSION-NET-FIGURE##' tag

	$cmd = "perl -I " . join( "/", @path ) . "/lib ";
	$cmd .= join( "/", @path )
	  . "/bin/database_scripts/expression_net/expression_net_to_R_network.pl ";
	$cmd .=
	  "-drop_connections_from_genes "
	  . join( " ", @drop_connections_from_genes ) . " "
	  if ( defined $drop_connections_from_genes[0] );
	$cmd .= " -infile $expression_net";
	$cmd .= " -min_connections $min_links";
	$cmd .= " -R_squared $R_square" if ( defined $R_square );
	$cmd .= " -max_p_value $max_p_value" if ( defined $max_p_value);
	$cmd .= " -describe_connection \"$describe_connection\"" if ( defined $describe_connection);
	$cmd .= " -other_infile $other_expression_net" if ( -f $other_expression_net);
	$cmd .= " -further_correlatio_results ".join(" ",@otherCorrelationFiles) ." " if ( defined $otherCorrelationFiles[0]);
	$cmd .= " -outpath $outpath";
	$cmd .= " -tex_skeleton $outpath/$outfile.tex";
	$cmd .= " -output_type $output_type" if ( defined $output_type);
	$cmd .= " -initial_genes '".join( "' '", @initial_genes) ."'" if ( defined $initial_genes[0]);
	print LOG "Create the figure:\n$cmd\n";
	print "we prepered the cmd \n$cmd\n";
	system($cmd );

	## now we should have the files  $outpath/genes.txt $outpath/initial_genes.txt and $outpath/new_genes.txt
	$error = '';
	unless ( -f "$outpath/genes.txt" ) {
		$error .= "we did not get the file $outpath/genes.txt\n";
	}
	unless ( -f "$outpath/initial_genes.txt" ) {
		$error .= "we did not get the file $outpath/initial_genes.txt\n";
	}
	unless ( -f "$outpath/new_genes.txt" ) {
		$error .= "we did not get the file $outpath/new_genes.txt\n";
	}
	## done with the '##EXPRESSION-NET-FIGURE##' tag

	## the '##GENE GROUPS##' and the '##GENE DESCRIPTION##' tag

	$cmd = "perl -I " . join( "/", @path ) . "/lib ";
	$cmd .= join( "/", @path )
	  . "/bin/database_scripts/trimPictures.pl -infile $outpath/pic.svg -outfile $outpath/pic.png ";
	system($cmd );

	open( IN, "<$outpath/genes.txt" )
	  or die "could not open the file $outpath/genes.txt\n";
	@data = <IN>;
	chop $data[0];
	close(IN);
	$cmd = "perl -I " . join( "/", @path ) . "/lib ";
	$cmd .= join( "/", @path )
	  . "/bin/array_analysis/get_GeneDescription_from_GeneCards.pl ";
	$cmd .= "-genes  $data[0] ";
	$cmd .= "-tex_skeleton $outpath/$outfile.tex ";
	$cmd .= "-further_correlatio_results ".join(" ",@otherCorrelationFiles) ." " if ( defined $otherCorrelationFiles[0]);
	$cmd .= "-desease T2D ";

	foreach my $gene ( split( " ", $data[0] ) ) {
		$usedGenes->{$gene} = 1;
	}
	print LOG "Get the gene descriptions:\n$cmd\n";
	print "we prepered the cmd \n$cmd\n";
	system($cmd );

	## done with the '##GENE GROUPS##' and the '##GENE DESCRIPTION##' tag

	## the '##SPECIAL GENES##' tag

	if ( defined $rsIDs[0] ) {
		$cmd = "perl -I " . join( "/", @path ) . "/lib ";
		$cmd .= join( "/", @path )
		  . "/bin/maintainance_scripts/get_closest_genes_for_rsIDs.pl ";
		$cmd .= " -rsIDs " . join( " ", @rsIDs ) . " ";
		$cmd .= " -outpath $outpath";
		$cmd .= " -tex_skeleton $outpath/$outfile.tex ";
		$cmd .= " -further_correlatio_results ".join(" ",@otherCorrelationFiles) ." " if ( defined $otherCorrelationFiles[0]);
		$cmd .= " -maximal_range $max_dist_to_SNP ";
		$cmd .= " -genome_string $organism_tag ";
		$cmd .= " -described_genes $outpath/genes.txt";
		print LOG "Describe genetic regions of interest:\n$cmd\n";
		print "CMD:\n$cmd\n";
		system($cmd);

		unless ( -f "$outpath/SNP_to_gene.txt" ) {
			warn
"there might have been an error in get_closest_genes_for_rsIDs.pl - we did not get the outfile!\n";
		}
	}
	## done with the '##SPECIAL GENES##' tag

	## the '##INTRODUCTION##' tag

	$introduction =
	    "\\section{Introduction}\n"
	  . "\\label{introduction}\n\n$work_description\n\n"
	  . "we got a inital gene list, that passed the described test:";
	foreach my $gene ( sort @initial_genes) {
		if ( $usedGenes->{$gene} ) {
			$introduction .= " \\nameref{".root->Latex_Label($gene)."},";
		}
		else {
			$introduction .= " $gene,";
			push( @not_in_second_correlation, $gene );
		}

	}
	chop($introduction);
	$introduction .=
". But not all of these initial genes have some other genes, that correlate with them.\n"
	  . "Note, that only the genes with correlations are further processed in this script.\n"
	  . "Therefore only the genes that show a good correlation with another gene will be described in \\ref{geneDescription}.\n"
	  ;
	if ( defined $drop_connections_from_genes[0]){
	$introduction .= "In addition, you have to note, that the genes that correlate with the";
	if ( scalar(@drop_connections_from_genes) == 1 ) {
		$introduction .= "gene \\nameref{".root->Latex_Label($drop_connections_from_genes[0])."}";
	}
	else {
		for ( my $i = 0 ; $i < @drop_connections_from_genes ; $i++ ) {
			$drop_connections_from_genes[$i] =
			  "\\nameref{".root->Latex_Label($drop_connections_from_genes[$i])."}";
		}
		$introduction .=
		  "genes " . join( ", ", @drop_connections_from_genes ) . "";
	}
	$introduction .=
" have been removed from the correlation view (most probably, because tehre were too manny correlations for that gene!). \n\n";
	}
	$introduction .=
	    "The main hypothesis for this whole document is, that the initial genes, that were selected due to their proximity to SNPs that influence the desease, \n"
	  . "might share a overall biological function, that links them together. The expression net described in this document could act as a starting point for \n".
	    "building up a biological network for these genes. But in order to do that you need to add some protein pathways to the findings described here.\n\n";

	open( IN, "<$outpath/$outfile.tex" )
	  or die "could not open $outpath/$outfile.tex\n";
	@data = <IN>;
	$cmd = join( "", @data );
	close(IN);
	$cmd =~ s/##INTRODUCTION##/$introduction/;
	$str = '';
	open( OUT, ">$outpath/$outfile.tex" )
	  or die "could not access the file $outpath/$outfile.tex\n$!\n";
	print OUT $cmd;
	close(OUT);

	## done with the '##INTRODUCTION##' tag

	## the '##SUMMARY##' tag

	$str = '\section{Summary}' . "\n" . '\label{summary}' . "\n\n";
	$str .=
	    "The following three questions will be answered in this summary:\n"
	  . "(1) did all genes from the first correlation with the phenotype show some significantly coregulated genes,\n"
	  . "(2) did we identify genes in the first correlation, that lie close to one of the SNPs of interest and\n"
	  . "(3) did we identify some genes during the second correlation that lead to the expression net, that lie close to one of the SNPs of interest?\n\n";

	#1
	$str .=
	    "We did not find significantly coregulated genes for "
	  . scalar(@not_in_second_correlation)
	  . " genes, namely the genes "
	  . join( ", ", sort @not_in_second_correlation ) . "\n\n";

	#2
	my $gene_to_SNP = {};
	unless ( -f "$outpath/SNP_to_gene.txt" ) {
		$str .=
"Unfortunatley we can not answer the second and the third question, as we do not know which SNPs are interesting for this analysis.\n\n";
	}

	else {
		open( IN, "<$outpath/SNP_to_gene.txt" )
		  or die
		  "We could not access the gene to SNP file $outpath/SNP_to_gene.txt\n";
		while (<IN>) {
			chomp($_);
			@data = split( "\t", $_ );
			$gene_to_SNP->{ $data[1] } = []
			  unless defined( $gene_to_SNP->{ $data[1] } );
			push( @{ $gene_to_SNP->{ $data[1] } }, $data[0] );
		}
		close(IN);

		@data = ();
		foreach my $gene (@initial_genes) {
			next unless ( defined $gene );
			push( @data, $gene ) if ( defined $gene_to_SNP->{$gene} && ! ( join(" ",@data) =~ m/$gene/ ) );
		}
		if ( scalar(@data) == 0 ) {
			$str .=
"We have found no significant correlations with the phenotype for any of the genes that lie close to the interesting SNPs.\n\n";
		}
		else {
			$str .=
			  "We have found a significant correlation with the phenotype for "
			  . scalar(@data)
			  . " genes, namely ";
			foreach my $gene (sort @data) {
				next unless ( defined $gene);
				$str .= ' \nameref{'.root->Latex_Label($gene).'},';
			}
			chop($str);
			$str .=
". For your convenience I have create a table resolving the gene to rsID connection.\n\n";
			$str .=
			    '\begin{longtable}{|c|c|}'
			    . "\n\\hline\n"
			    . 'gene name & SNP id \\\\'
			  . "\n\\hline\n"
			  . "\n\\hline\n"
			  ."\n\\endhead\n"
			 . "\n\\hline \\multicolumn{2}{|r|}{{Continued on next page}} \\\\\n"
			   . "\n\\hline\n"
			   ."\n\\endfoot\n"
			   . "\n\\hline\n"
			   . "\n\\hline\n"
			   ."\n\\endlastfoot\n";

			foreach my $gene (sort @data) {
				next unless ( defined $gene );
				$str .= $gene . ' & '
				  . join( ", ", @{ $gene_to_SNP->{$gene} } ) . '\\\\' . "\n";
			}
			$str .= "\\hline\n";
			$str .= '\end{longtable}' . "\n\n";
		}

		#3
		if ( -f "$outpath/new_genes.txt" ) {
			open( IN, "<$outpath/new_genes.txt" )
			  or die "I could not access the file $outpath/new_genes.txt\n$!\n";
			@initial_genes = ();
			while (<IN>) {
				chomp($_);
				push( @initial_genes, split( " ", $_ ) );
			}
			close(IN);
			foreach my $gene (sort @initial_genes) {
				next unless ( defined $gene );
				push( @data, $gene ) if ( defined $gene_to_SNP->{$gene} && ! ( join(" ",@data) =~ m/$gene/ ));
			}
			if ( scalar(@data) == 0 ) {
				$str .=
"We have found none of the genes that lie close to the interesting SNPs during the second correlation step.\n\n";
			}
			else {
				$str .=
				    "We have found a significant correlation for "
				  . scalar(@data)
				  . " genes with the second correlation, namely ";
				foreach my $gene (sort @data) {
					next unless ( defined $gene);
					$str .= ' \nameref{' . root->Latex_Label($gene) . '},';
				}
				chop($str);
				$str .=
". For your convenience I have create a table resolving the gene to rsID connection.\n\n";

				$str .=
				'\begin{longtable}{|c|c|}'
			    . "\n\\hline\n"
			    . 'gene name & SNP id \\\\'
			  . "\n\\hline\n"
			  . "\n\\hline\n"
			  ."\n\\endhead\n"
			 . "\n\\hline \\multicolumn{2}{|r|}{{Continued on next page}} \\\\\n"
			   . "\n\\hline\n"
			   ."\n\\endfoot\n"
			   . "\n\\hline\n"
			   . "\n\\hline\n"
			   ."\n\\endlastfoot\n";
				foreach my $gene (sort @data) {
					next unless ( defined $gene );
					$str .= $gene . ' & '
					  . join( ", ", @{ $gene_to_SNP->{$gene} } ) . '\\\\' . "\n";
				}
				$str .= "\\hline\n";
				$str .= '\end{longtable}' . "\n\n";
			}
		}
	}
	$cmd = '';
	open( IN, "<$outpath/$outfile.tex" )
	  or die "could not open tex file '$outpath/$outfile.tex'\n";
	while (<IN>) {
		$cmd .= $_;
	}
	close(IN);

	$cmd =~ s/##SUMMARY##/$str/;

	## done with the '##SUMMARY##' tag

	## clean up the latex source file

	foreach my $replace (
		'##INTRODUCTION##',          '##SUMMARY##',
		'##GENE GROUPS##',           '##SPECIAL GENES##',
		'##EXPRESSION-NET-FIGURE##', '##GENE DESCRIPTION##',
		'##APPENDIX##'
	  )
	{
		$cmd =~ s/$replace//g;
	}
	$cmd =~ s/_/\\_/g;
	$cmd =~ s/\\\\_/\\_/g;
	$cmd =~ s/\\'//g;
	open( OUT, ">$outpath/$outfile.tex" );
	print OUT $cmd;
	close(OUT);
	open ( OUT , ">$outpath/Makefile");
	print OUT "all:
\tpdflatex $outfile.tex
\tpdflatex $outfile.tex
\tpdflatex $outfile.tex
\trm $outfile.aux
\trm $outfile.out
\trm $outfile.toc
";
	close ( OUT );
	print "final tex source written to $outpath/$outfile.tex\n";
	open ( LOG ,">$outpath/$outfile.creation_log" ) or die "could not create the log file $outpath/$outfile.creation_log\n";
	print LOG $task_description."\n";
        close ( LOG );

chdir ( $outpath );
system ( 'make' ) unless ( $no_PDF );


sub _tex_file {
	if ( -f $tex_skeleton ) {
		my $str = '';
		open( IN, "<$tex_skeleton" )
		  or die "could not open tex file '$tex_skeleton'\n";
		while (<IN>) {
			$str .= $_;
		}
		close(IN);
		if (   $str =~ m/##INTRODUCTION##/
			&& $str =~ m/##GENE GROUPS##/
			&& $str =~ m/##SPECIAL GENES##/
			&& $str =~ m/##EXPRESSION-NET-FIGURE##/
			&& $str =~ m/##GENE DESCRIPTION##/ 
			&& $str =~ m/##APPENDIX##/ )
		{
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

##SUMMARY##

##GENE GROUPS##

##EXPRESSION-NET-FIGURE##

##SPECIAL GENES##

##GENE DESCRIPTION##

\appendix

##APPENDIX##

\end{document}
';
}
