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

A script to identify the closest SNPs for a lot of genes.

To get further help use 'get_SNPs_close_to_genes.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @genes, $outfile, $organism_tag, $max_distance );

Getopt::Long::GetOptions(
	"-geness=s{,}"     => \@genes,
	"-outfile=s"      => \$outfile,
	"-max_distance=s" => \$max_distance,
	"-organism_tag=s" => \$organism_tag,
	"-help"           => \$help,
	"-debug"          => \$debug
);

my $warn  = '';
my $error = '';
my $temp;
unless ( defined $genes[0] ) {
	$error .= "the cmd line switch -genes is undefined!\n";
}
elsif ( -f $genes[0] ) {
	open( IN, "<$genes[0]" ) or die "could not open the genes file!\n$!\n";
	@genes = undef;
	while (<IN>) {
		chomp $_;
		push( @genes, split( /[ \t]/, $_ ) );
	}
	for (my $i = @genes -1; $i > -1 ; $i -- ){
		splice ( @genes, $i, 1) unless ( $genes[$i] =~ m/\w/);
	}
	close(IN);
	print "we got the genes: ".join(", ",@genes)."\n";
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

   -genes        :a list or file including genes
   -outfile      :the outfile name
   -max_distance :a maximum distance between the SNP and any expression sequence of the gene
   -organism_tag :the organism where we should take the SNP information from

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'get_Genes_close_to_SNPs.pl';
$task_description .= ' -genes ' . join( ' ', @genes ) if ( defined $genes[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -max_distance $max_distance"
  if ( defined $max_distance );

$max_distance = 0;
## Do whatever you want!
my ( $sql, $genome, $genomeInterface );
$genome          = genomeDB->new();
$genomeInterface = $genome->GetDatabaseInterface_for_Organism($organism_tag);
$genomeInterface = $genomeInterface->get_rooted_to('gbFilesTable');
$genomeInterface = $genomeInterface -> get_SNP_Table_interface();
$genomeInterface->{'Do_not_execute'} = 1;

my $use_this_search = "SELECT H_sapiens_36_3_gbFeaturesTable.name, H_sapiens_36_3_SNP_table.rsID 
FROM H_sapiens_36_3_SNP_table  
LEFT JOIN H_sapiens_36_3_chromosomesTable ON  H_sapiens_36_3_SNP_table.gbFile_id = H_sapiens_36_3_chromosomesTable.id   
LEFT JOIN H_sapiens_36_3_gbFeaturesTable ON  H_sapiens_36_3_gbFilesTable.id = H_sapiens_36_3_gbFeaturesTable.gbFile_id  
WHERE H_sapiens_36_3_gbFeaturesTable.tag = 'gene' AND H_sapiens_36_3_SNP_table.position  + H_sapiens_36_3_chromosomesTable.chr_start  > H_sapiens_36_3_chromosomesTable.chr_start  +  ( H_sapiens_36_3_gbFeaturesTable.start  - 0  )   AND H_sapiens_36_3_SNP_table.position  + H_sapiens_36_3_chromosomesTable.chr_start  < H_sapiens_36_3_chromosomesTable.chr_start  +  ( H_sapiens_36_3_gbFeaturesTable.end  + 0  )   AND H_sapiens_36_3_gbFeaturesTable.name IN ( '".
join("', '",@genes)."'
)";

my $hash = {'search_columns' => [ 'gbFeaturesTable.name', 'SNP_table.rsID' ]};

my $sth        = $genomeInterface->{dbh}->do($use_this_search);
my $return     = $sth->fetchall_arrayref();
my $data_table = data_table->new();
$data_table->Add_db_result( $hash->{'search_columns'}, $return );

#my $data_table = $genomeInterface->get_data_table_4_search(
##my $data_table = $genomeInterface->create_SQL_statement(
#	{
#		'search_columns' => [ 'gbFeaturesTable.name', 'SNP_table.rsID' ],
#		'where'          => [
#			[ 'gbFeaturesTable.tag', '=', 'my_value' ],
#			[
#				[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
#				'>',
#				[
#					'chromosomesTable.chr_start', '+',
#					[ 'gbFeaturesTable.start', '-', 'my_value' ]
#				]
#			],
#			
#				[
#					[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
#					'<',
#					[
#						'chromosomesTable.chr_start', '+',
#						[ 'gbFeaturesTable.end', '+', 'my_value' ]
#					]
#				]
#			,
#			[ 'gbFeaturesTable.name', '=', 'my_value']
#		],
#		'limit' => 'limit 100'
#	},
#	'gene', $max_distance, $max_distance, \@genes
#);
#
#die $genomeInterface->{'complex_search'}."\n";

$data_table->print2file( $outfile );



