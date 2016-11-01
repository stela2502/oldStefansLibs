#! /usr/bin/perl -w

#  Copyright (C) 2011-03-03 Stefan Lang

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

=head1 Add_Clopsest_Gene_2_rsID_file.pl

Add the damn closest genes to an file containing a column named rsID.

To get further help use 'Add_Clopsest_Gene_2_rsID_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::MyProject::Gene_SNP_descritpion_table;


use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile, $organism_tag, $max_distance);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,
	 "-organism_tag=s"    => \$organism_tag,
	 "-max_distance=s"    => \$max_distance,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $organism_tag) {
	$error .= "the cmd line switch -organism_tag is undefined!\n";
}
unless ( defined $max_distance) {
	#$error .= "the cmd line switch -max_distance is undefined!\n";
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
 command line switches for Add_Clopsest_Gene_2_rsID_file.pl

   -infile       :the infile
   -outfile       :your outfile
   -organism_tag       :use H_sapiens
   -max_distance       :unused 1MB

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/Add_Clopsest_Gene_2_rsID_file.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -organim_tag $organism_tag" if (defined $organism_tag);
$task_description .= " -max_distance $max_distance" if (defined $max_distance);


## Do whatever you want!
my $data_table =
	  stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description
	  ->new();
$data_table  -> read_file ( $infile  );
$data_table -> Add_Closest_genes ( $organism_tag );
$data_table->write_file ( $outfile );
