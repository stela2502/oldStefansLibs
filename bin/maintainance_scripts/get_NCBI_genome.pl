#! /usr/bin/perl -w

#  Copyright (C) 2010-06-03 Stefan Lang

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

=head1 get_NCBI_genome.pl

A script to import a NCBI genome database into the Genexpress database.

To get further help use 'get_NCBI_genome.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB::genomeImporter;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $organism_name, $outdir);

Getopt::Long::GetOptions(
	 "-organism_name=s"    => \$organism_name,
	 "-outdir=s"    => \$outdir,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $organism_name) {
	$error .= "the cmd line switch -organism_name is undefined!\n";
}
unless ( defined $outdir) {
	$error .= "the cmd line switch -outdir is undefined!\n";
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
 command line switches for get_NCBI_genome.pl

   -organism_name :the genome string (i.a. H_sapiens as used by the NCBI to describe the genome)
   -outdir        :the path where the genbank files will be stored to
   -debug         :display some more debug information (might not do anything!)
   -help          :display this help message
   
   the script connects to the NCBI FTP server at ftp://ftp.ncbi.nlm.nih.gov, changes to the path 
   genomes/<genome_string>/ and downloads the file mapview/seq_contig.md.gz 
   and each file in the CHR* paths that contains 'ref' and 'gbk'.
   afterwards these files are imported into the MySQL database and the separate genbank files 
   are stored in the path '-outdir'.

"; 
}

my ( $task_description);

$task_description .= 'get_NCBI_genome.pl';
$task_description .= " -organism_name $organism_name" if (defined $organism_name);
$task_description .= " -outdir $outdir" if (defined $outdir);


## Do whatever you want!

print "cmd='$task_description'\n";

my $genomeImporter = genomeImporter->new();
$genomeImporter->{databaseDir} = $outdir;
$genomeImporter->import_refSeq_genome_for_organism($organism_name);

print "ready!"
