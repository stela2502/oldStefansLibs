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

=head1 estimate_SNP_influence_on_expression_dataset.pl

A quite complex script, that needs SNP information and expression information for a group of subjects. The first identifies the genes, that lie in a 1MB region arround the SNP, correlates the expression of all genes to that SNP and afterwards selects the genes of interest from that list. If there is a signifiocant correlation between the genotype and any of these genes, the sript starts to generate an expression net for tehse genes. In other means,m it tries to correlate the expression of the significantly correlated gene with all other genes an the array. At last, the script tries to identify the gene names using the genecrds web site. And finally, the script tries to create a qualified report of what iut has done, including as much data as possible into a pdf file. I sincerly hope, that this final piece of information will be digestable and will help to find te right and most informative information inside of the gene list. But that will then be the work of a human scientist

To get further help use 'estimate_SNP_influence_on_expression_dataset.pl -help' at the comman line.

=cut

use Getopt::Long;

use strict;
use warnings;

my ( $help, $debug);

Getopt::Long::GetOptions(
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

if ( $help ){
	print helpString( ) ;
	exit;
}



sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for estimate_SNP_influence_on_expression_dataset.pl
 
   -help           :print this help
   -debug          :verbose output

"; 
}

## now we set up the logging functions....

## 1. get the genome interface

## 2. get the genes, that are close to the SNP - keep in mind, that it would be greate to plot that in the end!

## 3. get the expression values for the genes. If you can not identify one gene get help from the gene_description interface.

## 4. get the genotype for the SNP. If we can not get the geneotype for this SNP all other steps are useless!!

## 5. correlate the genotype with the expression of the/all genes

## 6. create a plot for each of the correlations
##    get the description for these genes from the gene_descriptions object
##    and create a latex figure from that

## 7. if there is a significant correlation to the genotype,
##    correlate the expression of this gene to all other genes.
##    Perhaps we can find a transcription factor or some coregulated genes.


## 8. If we have found a set of significant correlation (Bon Feroni!),
##    craete plot for these correlations - perhaps in one figure?
##    Create a latex figure from that including the genecards description of the genes.

## 9. If we have identified some trsnription factors in our search for correlating genes
##    we definitely need to correlate this transcription factor to all genes.
##    whichever gene we can identfy in that search might help us to identify the putative binding motive for that transcription factor.
##    To identify that motive, we might need to use a extrernal program (easy way)
##    That has to be done for each transcriptio factor that we can identify.
##    Perhaps this is the CUP OF GOLD we want to find!

## 10. Try to generate a latex report for that part including figures and so on.

## 11. print the latex source tree for the resulting document.

## 12. craete a pdf from the latex source and show that as a result to the caller of that script.
