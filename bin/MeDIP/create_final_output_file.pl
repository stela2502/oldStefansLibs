#! /usr/bin/perl -w

#  Copyright (C) 2011-02-18 Stefan Lang

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

=head1 create_final_output_file.pl

A rewritten version to calculate the final MeDIP result files.

To get further help use 'create_final_output_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::MeDIP_results;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $medip_result_file, $paired, $nimblegene_ndf, $nimblegene_genome_gff, @expression_files, $outfile);

Getopt::Long::GetOptions(
	 "-medip_result_file=s"    => \$medip_result_file,
	 "-nimblegene_ndf=s"    => \$nimblegene_ndf,
	 "-nimblegene_genome_gff=s"    => \$nimblegene_genome_gff,
	 "-expression_files=s{,}"    => \@expression_files,
	 "-outfile=s"    => \$outfile,
	 "-paired"       => \$paired,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $medip_result_file) {
	$error .= "the cmd line switch -medip_result_file is undefined!\n";
}
unless ( -f $nimblegene_ndf) {
	$error .= "the cmd line switch -nimblegene_ndf is undefined!\n";
}
unless ( -f $nimblegene_genome_gff) {
	$error .= "the cmd line switch -nimblegene_genome_gff is undefined!\n";
}
unless ( -f $expression_files[0]) {
	$error .= "the cmd line switch -expression_files is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for create_final_output_file.pl

   -medip_result_file       :<please add some info!>
   -nimblegene_ndf       :<please add some info!>
   -nimblegene_genome_gff       :<please add some info!>
   -expression_files       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>
   -paired         :use this option if you want to calculate the expression differences in paired mode
   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/create_final_output_file.pl';
$task_description .= " -medip_result_file $medip_result_file" if (defined $medip_result_file);
$task_description .= " -nimblegene_ndf $nimblegene_ndf" if (defined $nimblegene_ndf);
$task_description .= " -nimblegene_genome_gff $nimblegene_genome_gff" if (defined $nimblegene_genome_gff);
$task_description .= ' -expression_files '.join( ' ', @expression_files ) if ( defined $expression_files[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -paired" if ( $paired );

open ( OUT, ">$outfile.log" ) or die " could not create $outfile.log\n";
print OUT "$task_description\n";
close (OUT);

my $MeDIP_results = stefans_libs_file_readers_MeDIP_results ->new();
$MeDIP_results -> read_file ( $medip_result_file );
print "we read the file\n";
$MeDIP_results -> restrict_to_p_value ( 0.05 );
print "we restricted the file to contain only oligos with a p value < 0.05\n";
$MeDIP_results ->Add_Olig_Infos( $nimblegene_ndf );
print "we have added the oligos\n";
$MeDIP_results ->parse_oligo_id_2_position();
print "we parsed the positions\n";
$MeDIP_results ->Add_Genes_Using_this_GFF( $nimblegene_genome_gff );
print "we added the gene names\n";

my ( @temp, $temp );
foreach ( @expression_files ) {
	@temp = split( "/", $_ );
	$temp = pop ( @temp );
	$MeDIP_results->Add_GeneExpression_File ( $_, $temp, $paired );
	print "we added the expression for file $temp\n";
}

$MeDIP_results ->  Check_MeDIP_Hypothesis ();
$MeDIP_results ->  write_file( $outfile );
print "We have written all the results\n";
my $result = $MeDIP_results  -> get_best_oligo_per_gene ();
$result ->  write_file(  $outfile."_one_oligo_per_gene" );
print "we have written the best oligo per file\n";
$result = $MeDIP_results  ->get_all_supportive_oligos();
$result ->  write_file(  $outfile."_oligos_hypo_true" );


