#! /usr/bin/perl -w

#  Copyright (C) 2010-08-19 Stefan Lang

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

=head1 add_statistics_2_KEGG_pathway_pdf.pl

This script merges a KEGG descritpion pdf with a KEGG statitstics PDF thereby creating links from the statitstics table to the description figures.

To get further help use 'add_statistics_2_KEGG_pathway_pdf.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $KEGG_tex, $KEGG_stat_tex, $outfile);

Getopt::Long::GetOptions(
	 "-KEGG_tex=s"    => \$KEGG_tex,
	 "-KEGG_stat_tex=s"    => \$KEGG_stat_tex,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $KEGG_tex) {
	$error .= "the cmd line switch -KEGG_tex is undefined/not readable!\n";
}
unless ( -f $KEGG_stat_tex) {
	$error .= "the cmd line switch -KEGG_stat_tex is undefined/not readable!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for add_statistics_2_KEGG_pathway_pdf.pl

   -KEGG_tex       :the name of the tex file created by a plotConnectionNetStatistics.pl call
   -KEGG_stat_tex  :the tex file created by a get_Pathway_descriptions_4_gene_names.pl call
   -outfile        :the name of the new merged tex file

   -help           :print this help
   -debug          :verbose output

"; 
}


my ( $task_description);

$task_description .= 'add_statistics_2_KEGG_pathway_pdf.pl';
$task_description .= " -KEGG_tex $KEGG_tex" if (defined $KEGG_tex);
$task_description .= " -KEGG_stat_tex $KEGG_stat_tex" if (defined $KEGG_stat_tex);
$task_description .= " -outfile $outfile" if (defined $outfile);


## Do whatever you want!
my ( $stat_text, $refs, $text_A, $text_B, $marker, $figure_lables, $last_line, $pathway_label );
open ( INFO, "<$KEGG_tex" ) or die "could not open the file '$KEGG_tex'\n$!\n";
$marker = 0;
$text_A = $text_B= '';
while ( <INFO> ){
	if ( $marker == 0){
		$text_A .= $_;
		$marker = 1 if ( $_ =~ m/label{KEGG.Pathways}/);
	}
	elsif ( $marker == 1 ){
		$text_B .= $_;
		if ( $_ =~ m/label{summmary\.(\w+)}/ ){
			$pathway_label = $1;
			$last_line =~ m/subsection{(.+)}/;
			$figure_lables -> {$1} = $pathway_label;
		}
		$last_line = $_;
	}
}
close ( INFO );
open ( STAT, "<$KEGG_stat_tex") or die "could not open file '$KEGG_stat_tex$\n$!\n";
$marker = 0;
while ( <STAT> ){
	if ( $marker == 0){
	if ( $_ =~ m/section{Introduction}/){
		$marker = 1;
		$text_A .= "\n\n\\subsection{Estimated p values for each pathway}\n";
	}
	}
	elsif ( $marker == 1){
		if ( $_ =~ m/ ?(.+) & ?\d* ?( & \$[\d\.]+e.{-\d\d}\$  \\\\)/){
			#print "OK we look for pathway '$1'\n";
			$text_A .= "$1 (Fig.\\ref{$figure_lables->{$1}}) $2\n";
		}
		else {
			#warn "I do not know why, but we did not match to line $_\n";
			$text_A .= $_;
			last if ( $_ =~ m/end{longtable}/);
		}
	}
}
close ( STAT );
$outfile .= ".tex" unless ( $outfile =~ m/\.tex$/);

open ( OUT ,">$outfile" ) or die "Sorry, but I could not create the outfile '$outfile'\n$!\n";
print OUT $text_A.$text_B;
close ( OUT );
print "you can create the PFD file from the outfile $outfile\n";