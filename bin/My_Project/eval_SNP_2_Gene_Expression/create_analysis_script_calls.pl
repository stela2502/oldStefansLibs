#! /usr/bin/perl

use strict;
use warnings;
my $gene;
foreach my $infile ( @ARGV ) {
	unless ( -f $infile ){
		warn "Sorry, but that string is no file: $infile \n";
		next;
	}
	$gene = '';
	$gene = $1 if ( $infile =~ m/(\w+)-[\w_]+.txt$/);
	die "sorry, but the file '$infile' does not contain a gene name??\n" unless ( $gene =~ m/\w/);
	print "perl -I ~/Link_2_My_Libs/lib/ ~/Link_2_My_Libs/bin/My_Project/LaTex_Export/describe_SNP_2_gene_expression_results.pl -SNP_2_Gene_Expression_files $infile -latex_title \"nix\" -outpath ~/Diabetes_Postdoc/_My_Projects/Project_With_Petter/results/$gene -p_value_cutoff \"1e-4\" -task SNP_highlight\n";
;
}


