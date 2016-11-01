#! /usr/bin/perl -w

#  Copyright (C) 2011-01-13 Stefan Lang

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

=head1 expand_gene_lust_with_PPI.pl

Expand a gene list in PPI data

To get further help use 'expand_gene_lust_with_PPI.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::PPI_text_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @genes, @link_only_genes, $PPI_data, $PPI_outfile);

Getopt::Long::GetOptions(
	 "-genes=s{,}"    => \@genes,
	 "-PPI_data=s"    => \$PPI_data,
	 "-link_only_genes=s{,}" => \@link_only_genes,
	 "-PPI_outfile=s"  => \$PPI_outfile,
	 
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $genes[0]) {
	$error .= "the cmd line switch -genes is undefined!\n";
}

unless ( defined $PPI_data) {
	$error .= "the cmd line switch -PPI_data is undefined!\n";
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
 command line switches for expand_gene_lust_with_PPI.pl

   -genes       :a list of genes that should be the seed for this analysis
   -PPI_data    :a PPI links file that contains the same gene lables as the 
                 -genes data
   -PPI_outfile :if you want to visualize the PPI network, you should give me an outfile
                
   -link_only_genes :as PPI might identify a lot of genes, that can not be of 
                     interest as they do pass certain restriction, please give 
                     me a list of acceptable genes

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/expand_gene_lust_with_PPI.pl';
$task_description .= ' -genes '.join( ' ', @genes ) if ( defined $genes[0]);
$task_description .= ' -link_only_genes '.join( ' ', @link_only_genes ) if ( defined $link_only_genes[0]);
$task_description .= " -PPI_data $PPI_data" if (defined $PPI_data);
$task_description .= " -PPI_outfile $PPI_outfile" if ( defined $PPI_outfile);

if ( defined $PPI_outfile ){
	open ( LOG , ">$PPI_outfile.log") or die "I could not create the log file '$PPI_outfile.log'\n$!\n";
	print LOG $task_description."\n";
	close ( LOG );
}
else {
	print $task_description."\n";
}

if ( -f  $genes[0]){
	my @temp;
	open ( IN , "<$genes[0]" ) or die "intrenal file open error for genes file:\n\t$!\n";
	while ( <IN>) {
		chomp ( $_ );
		push ( @temp, split(/\s/,$_));
	}
	close ( IN );
	shift ( @temp ) unless ( defined $temp[0]);
	@genes = @temp;
}

if ( -f  $link_only_genes[0]){
	my @temp;
	open ( IN , "<$link_only_genes[0]" ) or die "intrenal file open error for link_only_genes file:\n\t$!\n";
	while ( <IN>) {
		chomp ( $_ );
		push ( @temp, split(/\s/,$_));
	}
	close ( IN );
	shift ( @temp ) unless ( defined $temp[0]);
	@link_only_genes = @temp;
}

my $PPI_file = stefans_libs_file_readers_PPI_text_file->new();
$PPI_file ->read_file ( $PPI_data );
$PPI_file ->Links_Outfile( $PPI_outfile );

print join(" ",@{$PPI_file->expand(\@genes, \@link_only_genes)});


