#! /usr/bin/perl -w

#  Copyright (C) 2010-08-20 Stefan Lang

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

=head1 qualify_genes_with_pubmed_search.pl

This script will execute a pubmed search for each gene and the connection to the strings T2D fat insulin or mitochondria. It will print a <tab> table including the gene name, the number of pubmed hits and a list of the pubmed ids found.

To get further help use 'qualify_genes_with_pubmed_search.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::PubMed_queries;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @genes, $type, $outfile, $task );

Getopt::Long::GetOptions(
	"-genes=s{,}" => \@genes,
	"-outfile=s"  => \$outfile,
	"-task=s"     => \$task,
	"-type=s"     => \$type,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';


unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}

unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $type){
	$error .= "the cmd line switch -type is undefined!\n";
}
elsif (! 'Targeted T2D' =~ m/$type/){
	$error .= "the -type option only supprts 'Targeted' or 'T2D', not '$type'\n";
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
 command line switches for qualify_genes_with_pubmed_search.pl

   -genes    :the name of the genes that you want info for
   -outfile  :the name and position for the outfile(s)
   -type     :which type of PubMed query do you want to do?
              'T2D' influence or 'Targeted'
              
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'qualify_genes_with_pubmed_search.pl';
$task_description .= ' -genes ' . join( ' ', @genes ) if ( defined $genes[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

print $task_description. "\n";

if ( -f $genes[0] ) {
	my $data;
	open( IN, "<$genes[0]" ) or die "could not open the genes file $genes[0]\n";
	@genes = undef;
	while (<IN>) {
		chomp $_;
		foreach ( split( /[ \t]/, $_ ) ) {
			$data->{$_} = 1 if ( defined $_ );
		}
	}
	@genes = ( keys %$data );
}

my ( $PubMed_queries, $data_table );

$PubMed_queries = PubMed_queries->new( root::getDBH(), $debug );
$data_table = data_table->new();
$data_table->Add_2_Header('gene symbol');
$data_table->Add_2_Header('PubMet T2D hits');

if ( $type eq "T2D"){
foreach my $gene (@genes) {
	$data_table->Add_Dataset(
		{
			'gene symbol' => $gene,
			'PubMet T2D hits' =>
			  $PubMed_queries->get_T2D_hit_count_4_GeneSymbol($gene)
		}
	);
}
}
elsif ( $type eq "Targeted" ){
foreach my $gene (@genes) {
	$data_table->Add_Dataset(
		{
			'gene symbol' => $gene,
			'PubMet T2D hits' =>
			  $PubMed_queries->get_Targeted_count_4_GeneSymbol($gene)
		}
	);
}	
}
$data_table = $data_table->Sort_by( [ [ 'PubMet T2D hits', 'numeric' ] ] );

$data_table->print2file($outfile);
print "the results were saved as '$outfile'"

