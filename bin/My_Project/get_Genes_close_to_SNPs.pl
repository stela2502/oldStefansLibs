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

=head1 get_Genes_close_to_SNPs.pl

A script to identify the closest genes for a lost of rsIDs.

To get further help use 'get_Genes_close_to_SNPs.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @rsIDs, $outfile, $organism_tag, $max_distance );

Getopt::Long::GetOptions(
	"-rsIDs=s{,}"     => \@rsIDs,
	"-outfile=s"      => \$outfile,
	"-max_distance=s" => \$max_distance,
	"-organism_tag=s" => \$organism_tag,
	"-help"           => \$help,
	"-debug"          => \$debug
);

my $warn  = '';
my $error = '';
my $temp;
unless ( defined $rsIDs[0] ) {
	$error .= "the cmd line switch -rsIDs is undefined!\n";
}
elsif ( -f $rsIDs[0] ) {
	open( IN, "<$rsIDs[0]" ) or die "could not open the rsIDs file!\n$!\n";
	@rsIDs = undef;
	while (<IN>) {
		chomp $_;
		push( @rsIDs, split( /[ \t]/, $_ ) );
	}
	for (my $i = @rsIDs -1; $i > -1 ; $i -- ){
		splice ( @rsIDs, $i, 1) unless ( $rsIDs[$i] =~ m/rs\d+/);
	}
	close(IN);
	print "we got the rsIDs: ".join(", ",@rsIDs)."\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $max_distance ) {
	$warn .= "the cmd line switch -max_distance is undefined!\n";
}
unless ( defined $organism_tag ) {
	$organism_tag = "H_sapiens";
	warn "we had to set the organism tag to $organism_tag\n";
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
 command line switches for get_Genes_close_to_SNPs.pl

   -rsIDs        :a list or file including rsIDs
   -outfile      :the outfile name
   -max_distance :a maximum distance between the SNP and any expression sequence of the gene
   -organism_tag :the organism where we should take the SNP information from

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'get_Genes_close_to_SNPs.pl';
$task_description .= ' -rsIDs ' . join( ' ', @rsIDs ) if ( defined $rsIDs[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -max_distance $max_distance"
  if ( defined $max_distance );

$max_distance = 0 unless ( defined $max_distance ) ;
## Do whatever you want!
my ( $sql, $genome, $genomeInterface );
$genome          = genomeDB->new();
$genomeInterface = $genome->GetDatabaseInterface_for_Organism($organism_tag);
$genomeInterface = $genomeInterface->get_rooted_to('gbFilesTable');
$genomeInterface = $genomeInterface -> get_SNP_Table_interface();

my $data_table = $genomeInterface->get_data_table_4_search(
#my $data_table = $genomeInterface->create_SQL_statement(
	{
		'search_columns' => [ 'gbFeaturesTable.name', 'SNP_table.rsID','gbFeaturesTable.start','gbFeaturesTable.end' , 'SNP_table.position' ],
		'where'          => [
			[ 'gbFeaturesTable.tag', '=', 'my_value' ],
			[
				[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
				'>',
				[
					'chromosomesTable.chr_start', '+',
					[ 'gbFeaturesTable.start', '-', 'my_value' ]
				]
			],
			
				[
					[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
					'<',
					[
						'chromosomesTable.chr_start', '+',
						[ 'gbFeaturesTable.end', '+', 'my_value' ]
					]
				]
			,
			[ 'SNP_table.rsID', '=', 'my_value']
		]
	},
	'gene', $max_distance, $max_distance, \@rsIDs
);

$data_table->Add_2_Description ( $genomeInterface->{'complex_search'});

$data_table->print2file( $outfile );



