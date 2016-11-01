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

=head1 classify_nets.pl

The cript takes a gene net text file and creates the lists of correlating genes from it. In order to estimate the importance of the gene lists, it gets the RefSeq summary for all the genes and searches for a list of key words. Each gene in the list will be qualified like that and in the end, the gene list will get the summ of all these values attatched.

To get further help use 'classify_nets.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::database::genomeDB::gene_description;
use strict;
use warnings;

my ( $help, $debug, $inFile, $outfile, $p_cut, $R_cut );

Getopt::Long::GetOptions(
	"-help"                  => \$help,
	"-debug"                 => \$debug,
	"-expression_net_file=s" => \$inFile,
	"-outfile=s"             => \$outfile,
	"-p_cutoff=s"            => \$p_cut,
	"-R_cutoff=s"            => \$R_cut
);

if ($help) {
	print helpString();
	exit;
}
my $error = '';
unless ( defined $inFile ) {
	$error .= "We need an infile -expression_net_file\n";
}
elsif ( ! (-f $inFile ) ) {
	$error .= "Sorry, but we can not find the infile '$inFile'\n";
}

unless ( defined $p_cut ) {
	$p_cut = 1;
	warn "you have not set the -p_cutoff -> defaults to 1!\n";
}
elsif ( $p_cut > 1 ){
	warn "you have set the -p_cutoff to $p_cut, but the max is 1 (set to 1)\n";
	$p_cut = 1;
}


unless ( defined $R_cut || $R_cut > 1 ) {
	$R_cut = 0;
	warn "you have not set the -R_cutoff -> defaults to 0!\n";
}
elsif ( $R_cut > 1  ){
	warn "you have set the -R_cutoff to $R_cut, but the max is 1 (set to  0)\n";
	$R_cut = 0;
}

if ( $error =~ m/\w/ ){
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for classify_nets.pl
   
   -expression_net_file 
                   :the input file that contains a tab separated array consisting of 
                    gene1,gene2,p_value,S and R square
   -outfile        :an optional outfile to print the data to (default STDOUT)
   -p_cutoff       :only genes that correlate with a p_value below this cutoff w2ill be used (default 1)
   -R_cutoff       :only gened with a R_squared value above this cutoff will be used (default 0 )
   -help           :print this help
   -debug          :verbose output

";
}

open( IN, "<$inFile" ) or die "I could not open the infile '$inFile'\n$!\n";

my ( $data, @result, @line, $sum );
while (<IN>) {
	next if ( $_ =~ m/^gene\t/ );
	chomp($_);
	@line = split( "\t", $_ );
	next if ( $line[2] > $p_cut || $line[4] < $R_cut );
	$data->{ $line[0] } = [] unless ( defined $data->{ $line[0] } );
	push( @{ $data->{ $line[0] } }, $line[1] );
}

my $gene_description = gene_description->new( root->getDBH(), 0 );
foreach my $gene1 ( sort keys %$data ) {
	$sum =
	  $gene_description->determineInfluence_of_gene_on_desease( $gene1, "T2D" );
	foreach my $gene2 ( @{ $data->{$gene1} } ) {
		$sum +=
		  $gene_description->determineInfluence_of_gene_on_desease( $gene2,
			"T2D" );
	}
	push( @result,
		[ $gene1, join( ";", sort ( @{ $data->{$gene1} } ) ), $sum ] );
	last if ( $debug);
}

if ( defined $outfile ) {
	unless ( open( OUT, ">$outfile" ) ) {
		warn "I could not create the outfile '$outfile'\n$!\n";
	}
	else {
		print OUT
"gene1\tcorrelates with the genes\tand seams to have this influence on T2D\n";
		foreach my $array (@result) {
			print OUT join( "\t", @$array ) . "\n";
		}
		close(OUT);
		print "Data was saved to $outfile\n";
		exit;
	}
}

print
  "gene1\tcorrelates with the genes\tand seams to have this influence on T2D\n";
foreach my $array (@result) {
	print join( "\t", @$array ) . "\n";
}

