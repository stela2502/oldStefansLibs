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

=head1 convert_SNP_2_Gene_Summary_to_SNP_description.pl

This script does merge multiple SNP 2 Gene correlation results into a table showing only one line per SNP.

To get further help use 'convert_SNP_2_Gene_Summary_to_SNP_description.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::MyProject::Gene_SNP_descritpion_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, @options,$GWAS_p_cut_off, $GWAS_data, $GWAS_p_column_name, $p_value_cut_off, $organism_tag, $outfile);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,
	 "-options=s{,}"    => \@options,
	 "-organism_tag=s"    => \$organism_tag,
	 "-outfile=s"    => \$outfile,
	 "-GWAS_p_column_name=s"  => \$GWAS_p_column_name,
	 "-p_value_cut_off" => \$p_value_cut_off,
     "-GWAS_data=s"  => \$GWAS_data,
     "-GWAS_p_cut_off=s" => \$GWAS_p_cut_off,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $options[0]) {
	#$error .= "the cmd line switch -options is undefined!\n";
}
unless ( defined $organism_tag) {
	$organism_tag = "H_sapiens";
}
unless ( defined $GWAS_data){
	#$error .= "the cmd line switch -GWAS_data is undefined!\n";
}
unless ( defined $GWAS_p_column_name){
	#$error .= "the cmd line switch -GWAS_p_column_name is undefined!\n";
}
unless ( defined $GWAS_p_cut_off){
	#$error .= "the cmd line switch -GWAS_p_cut_off is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $p_value_cut_off ){
	$error .= "the cmd line switch -p_value_cut_off is undefined!\n";
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
 command line switches for convert_SNP_2_Gene_Summary_to_SNP_description.pl

   -infiles       :a list of SNP 2 gene expression outfiles
   -options       :unused
   -organism_tag  :defaults to H_sapiens
   -outfile       :where I should put the output data to
   -GWAS_data     :a GWAS results file containg p_values
   
   -GWAS_p_column_name :the p_value column name 
                        (I expect teh rsID to be in a coluimn named rsID!)
   
   -GWAS_p_cut_off: the p_value cut off for the GWAS data
   -p_value_cut_off :to which p_value should I accept the correlations?
   
   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/convert_SNP_2_Gene_Summary_to_SNP_description.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= ' -options '.join( ' ', @options ) if ( defined $options[0]);
$task_description .= " -organism_tag $organism_tag" if (defined $organism_tag);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -GWAS_data $GWAS_data" if (defined $GWAS_data);
$task_description .= " -GWAS_p_column_name $GWAS_p_column_name" if (defined $GWAS_p_column_name);
$task_description .= " -GWAS_p_cut_off $GWAS_p_cut_off" if (defined $GWAS_p_cut_off);

open ( LOG ,">$outfile.log" ) or die "I could not create the log file '$outfile.log'\n$!\n";
print LOG $task_description."\n";
close ( LOG );

## Do whatever you want!
my $table = stefans_libs_MyProject_Gene_SNP_descritpion_table->new(1);
$table -> populate_on_correlation_files ( $p_value_cut_off, @infiles );
my $rs_description = $table -> merge_on_rsID();
$rs_description ->write_file ( $outfile );
$rs_description -> Add_GWAS_data( $GWAS_data, 'rsID', $GWAS_p_column_name );
$rs_description = $rs_description -> select_where ( 'GWAS p value', sub { return 1 if ( $_[0] <= $GWAS_p_cut_off); return 0;} );

$rs_description -> Add_Closest_genes ( $organism_tag );

$rs_description->write_file ( $outfile );
