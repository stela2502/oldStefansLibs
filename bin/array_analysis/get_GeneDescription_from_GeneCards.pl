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

=head1 get_GeneDescription_from_GeneCards.pl

A script that is based on WWW::Mechanize that can read the Genecards webpages and is able to retrieve the Genecards gene description entries.

To get further help use 'get_GeneDescription_from_GeneCards.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::genomeDB::gene_description;
use stefans_libs::flexible_data_structures::data_table;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

my ( $help, $debug, @genes, $desease, $tex_skeleton, @special_genes,
	@otherCorrelationFiles, $logfile );

Getopt::Long::GetOptions(
	"-help"                            => \$help,
	"-tex_skeleton=s"                  => \$tex_skeleton,
	"-further_correlatio_results=s{,}" => \@otherCorrelationFiles,
	"-debug"                           => \$debug,
	"-genes=s{,}"                      => \@genes,
	"-desease=s"                       => \$desease,
	"-logfile=s"                       => \$logfile
);

if ($help) {
	print helpString();
	exit;
}

unless ( defined $genes[0] ) {
	print helpString("we need to get some gene names to look for!");
	exit;
}

my ( $task_description);

$task_description .= 'get_GeneDescription_from_GeneCards.pl';
$task_description .= " -tex_skeleton $tex_skeleton" if (defined $tex_skeleton);
$task_description .= ' -further_correlatio_results '.join( ' ', @otherCorrelationFiles ) if ( defined $otherCorrelationFiles[0]);
$task_description .= ' -genes '.join( ' ', @genes ) if ( defined $genes[0]);
$task_description .= " -desease $desease" if (defined $desease);
$task_description .= " -logfile $logfile" if (defined $logfile);



my (@otherDatasets);
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

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for get_GeneDescription_from_GeneCards.pl
 
   -genes          :a list of genes you want to get information about
   -further_correlatio_results
                   :other correlation result files that are 
                    created using the batchStatistics.pl script
   -tex_skeleton   :A tex document that contains a '##GENE DESCRIPTION##' tag
                    this script will place a latex section containing a small description of the genes.
   -desease        :get the qualifier for this desease for each gene
   -logfile        :if you want to process more that one gene list you might want to add that 
                    to get an overview of the used file names. (filename -> gene list)
   
   -help           :print this help
   -debug          :verbose output

";
}
my $result;
my $gene_description = gene_description->new( root->getDBH(), $debug );


&print_as_latexFile();

sub print_as_latexFile {

	my $str_summary = '';
	my $str         = '';
	my $filename;
	print $task_description ;
	$str_summary = $gene_description->get_Latex_Gene_summary(
		{ 'desease' => $desease, 'genes' => [@genes], 'header_level' => 0 } );

	$str = $gene_description->get_Latex_Gene_description(
		{
			'desease'       => $desease,
			'genes'         => [@genes],
			'header_level'  => 0,
			'otherDatasets' => [@otherDatasets]
		}
	);

	if ( $debug) {
		print "we used the search \n$gene_description->{'complex_search'}\n";
	}
	if ( $str =~ m/\w/ ) {

		my $text = &_tex_file();
		$text =~ s/##GENE GROUPS##/$str_summary/;
		$text =~ s/##GENE DESCRIPTION##/$str/;
		unless ( defined $tex_skeleton ) {
			$filename = md5_hex( join( "", @genes ) ) . ".tex";
		}
		else {
			$filename = $tex_skeleton;
		}
		open( OUT, ">$filename" )
		  or die "I could not create the filename $filename\n";
		print OUT $text;
		print "we have written the infos to the genes to the file $filename\n";
	}
	else {
		print "Sorry, but we did not get any data for the genes!\n";
	}
	close OUT;
	if ( defined $logfile ) {
		if ( -f $logfile ) {
			open( LOG, ">>$logfile" )
			  or die "could not add to the logfile $logfile\n";
		}
		else {
			open( LOG, ">$logfile" )
			  or die "could not create the logfile $logfile\n";
		}
		print LOG "$filename\t" . join( ", ", @genes ) . "\n";
		close(LOG);

	}
	return 1;
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
		if ( $str =~ m/##GENE GROUPS##/ && $str =~ m/##GENE DESCRIPTION##/ ) {
			## OK this sceleton is usable!
			return $str;
		}
		else {
			warn
"The tex sceleton $tex_skeleton does not contain the ##HERE COMES THE FUN## tag - I will use the inbuilt tex template!\n";
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
    
    ##SPECIAL GENES##
    
    ##EXPRESSION-NET-FIGURE##
    
    ##GENE DESCRIPTION##
  
  \end{document}
';
}
