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

=head1 get_location_for_gene_list.pl

A script to reat a tab separated file, interprete the entries as gene names and identify the location of these genes in a genome.

To get further help use 'get_location_for_gene_list.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::database::genomeDB;

my ( $help, $debug, $organism, $tableFile, @geneNames,$outfile );

Getopt::Long::GetOptions(
	"-organism_tag=s" => \$organism,
	"-table_file=s"   => \$tableFile,
	"-geneNames=s{,}" => \@geneNames,
	"-outfile=s"      => \$outfile,
	"-help"           => \$help,
	"-debug"          => \$debug,
);

my ($error);
if ($help) {
	print helpString();
	exit;
}

unless ( defined $organism){
	$error .= "we definitely need the -organism_tag to select the right table set in the database!\n";
}

unless ( defined $tableFile || -f $tableFile ) {
	## possible you have given me a list of genes instead?
	unless ( defined $geneNames[0] ) {
		$error .= "We have neither a -table_file nor a list of -geneNames\n";
	}
}
elsif ( defined $geneNames[0] ) {
	$error .= "Please define either a -table_fil or a list of -geneNames!\n";
}

if ( $error =~ m/\w/ ){
	print &helpString( $error );
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for get_location_for_gene_list.pl
 
   -organism_tag   :the organism you want to search for the genes
   -table_file     :the_file you stored the gene names in (first column will be used to identify the name of the output file
   -geneNames      :A list of genes you wnt to get info on
   -outfile        :the name of the outfile you wnat to store the info in
   -help           :print this help
   -debug          :verbose output

";
}
my ( $genome, $interface, $data, $name );

$genome    = genomeDB->new();
$interface = $genome->GetDatabaseInterface_for_Organism($organism);
unless ( defined $geneNames[0] ) {
	open( IN, "<$tableFile" );
	while (<IN>) {
		chomp($_);
		@geneNames = split( "\t", $_ );
		$name = shift (@geneNames);
		$data = $interface->getArray_of_Array_for_search(
			{
				'search_columns' => [
					'chromosomesTable.chr_start', 'chromosomesTable.chr_stop',
					'gbFeaturesTable.name'
				],
				'where' => [
					[ 'gbFeaturesTable.tag',  '=', 'my_value' ],
					[ 'gbFeaturesTable.name', '=', 'my_value' ]
				]
			},
			'gene',
			[@geneNames]
		);
		&printData( $data, $name);
	}
}
else {
	$data = $interface->getArray_of_Array_for_search(
			{
				'search_columns' => [
					'gbFeaturesTable.name','chromosomesTable.chromosome','chromosomesTable.chr_start', 'chromosomesTable.chr_stop',
					
				],
				'where' => [
					[ 'gbFeaturesTable.tag',  '=', 'my_value' ],
					[ 'gbFeaturesTable.name', '=', 'my_value' ]
				]
			},
			'gene',
			[@geneNames]
		);
		&printData( $data );
}


sub printData{
	my ( $data, $name ) =@_;
	if ( defined $outfile){
		unless ( -f $outfile ){
			open ( OUT, ">$outfile" ) or die "could not create file $outfile\n$!\n";
			print OUT &dataAsString( $data, $name );
			close (OUT);
		}
		else {
			open ( OUT, ">>$outfile" ) or die "could not access file $outfile\n$!\n";
			print OUT &dataAsString( $data, $name );
			close (OUT);
		}
	}
	else {
		print &dataAsString( $data, $name );
	}
}

sub dataAsString {
	my ( $data, $name ) =@_;
	my $str = '';
	$str .= "$name\n" if ( defined $name);
	$str .= join("\t", ( 'geneName','chromosome','start on chromosome','end on chromosome'))."\n";
	foreach my $dataset ( @$data ){
		$str .= join("\t",@$dataset )."\n";
	}
	return $str;
}