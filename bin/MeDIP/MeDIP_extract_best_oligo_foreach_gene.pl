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

=head1 extract_oligos_fromm_NimbleGene_GFF_file.pl

A script to search NimbleGene GFF oligo files and an oligo2DNA table file to 
identify the location of oligos in any genome. The oligo2DNA table has to be 
genome specific.

To get further help use 'MeDIP_extract_best_oligo_foreach_gene.pl -help' 
at the command line.

=cut

use Getopt::Long;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo;
use stefans_libs::array_analysis::correlatingData::Wilcox_Test;
use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $GFF_file, $olgio2DNA_file, $upstream,
	$downstream, $outfile );

Getopt::Long::GetOptions(
	"-GFF_file=s"       => \$GFF_file,
	"-olgio2DNA_file=s" => \$olgio2DNA_file,
	"-outfile=s"        => \$outfile,
	"-upstream=s"       => \$upstream,
	"-downstream=s"     => \$downstream,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $error   = '';
my $warning = '';

unless ( defined $GFF_file ) {
	$error .= 'the cmd line switch -GFF_file is undefined!' . "\n";
}
unless ( defined $olgio2DNA_file ) {
	$error .= 'the cmd line switch -olgio2DNA_file is undefined!' . "\n";
}
unless ( defined $outfile ) {
	$error .= 'the cmd line switch -outfile is undefined!' . "\n";
}
unless ( defined $upstream ) {
	$error .= 'the cmd line switch -upstream is undefined!' . "\n";
}
unless ( defined $downstream ) {
	$error .= 'the cmd line switch -downstream is undefined!' . "\n";
}

if ( $warning =~ m/\w/ ) {
	warn $warning . "But we can do without this information!\n";
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
 
 This script is a dirty hack to get the results from the MeDip chip exeriments as fast as possible.
 Once the database supports the results of the Wilcox over two serach results,
 this script has to be updated to use only the database and not the nimblegene info files!!
 
 command line switches for extract_oligos_fromm_NimbleGene_GFF_file.pl

   -GFF_file       :the NimbleGene GFF file containing the oligo informations
   -olgio2DNA_file :the NimbleGene Signalmap genome info file
   -outfile        :the file where the results table should be stored
   
   -upstream   :define the upstream max distance to the transcription start
   -downstream :define the downstream max distance to the trsancription start
   
   -help           :print this help
   -debug          :verbose output

";
}
my $task_description .= 'MeDIP_extract_best_oligo_foreach_gene.pl';
$task_description .= " -GFF_file $GFF_file" if ( defined $GFF_file );
$task_description .= " -olgio2DNA_file $olgio2DNA_file"
  if ( defined $olgio2DNA_file );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -upstream $upstream" if ( defined $upstream);
$task_description .= " -downstream $downstream" if ( defined $downstream);

print "\nCommand:\n$task_description\n\n";

my (
	$gffFile,         $oligo_Data, $oligoLocations, $genomeDB,
	$genomeInterface, $temp,       $var,            $array,
	@data,            $datafile,   $fastaDB,        @temp,
	$CpG_count
);

open( LOG, ">$outfile.log" )
  or die "could not create the log file $outfile.log\n";
print LOG $task_description . "\n";
close(LOG);

$datafile = data_table->new();

foreach (
	( 'oligoID', 'oligo_sequence', 'CpG content [n]', '-log10(p_value)' ) )
{
	$datafile->Add_2_Header($_);
}

foreach ( ( 'Gene Symbol', 'relative location [bp]' ) ) {
	$datafile->Add_2_Header($_);
}

my $Nimblegene_GeneInfo = Nimblegene_GeneInfo->new($debug);
$Nimblegene_GeneInfo->GetData($olgio2DNA_file);

$gffFile = gffFile->new();
my $data_table = $Nimblegene_GeneInfo->get_closeby_gene_as_table(
	$gffFile->GetData( $GFF_file, 'preserve_structure' ),
	$upstream, $downstream );
my $already_used_genes = {};
$data_table = $data_table->Sort_by(
	[ [ 'Gene Symbol', 'lexical' ], [ 'statistic_value', 'antiNumeric' ] ] );
$data_table = $data_table->select_where(
	'Gene Symbol',
	sub {
		if ( !defined $already_used_genes->{ $_[0] } ) {
			$already_used_genes->{ $_[0] } = 1;
			return 1;
		}
		return 0;
	}
);

$data_table->print2file ( $outfile );
