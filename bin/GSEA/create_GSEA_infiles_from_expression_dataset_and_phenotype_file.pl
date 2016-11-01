#! /usr/bin/perl -w

#  Copyright (C) 2010-12-06 Stefan Lang

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

=head1 create_GSEA_infiles_from_expression_dataset_and_phenotype_file.pl

You can specifiy a phenotype or use all phenotypes ( not redcomended) and vcraete the clf and txt files to run GSEA on.

To get further help use 'create_GSEA_infiles_from_expression_dataset_and_phenotype_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::phenotypes;
use stefans_libs::file_readers::affymetrix_expression_result;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $expreesion_data, @p4cS, $phenotype_file, $outpath, $PoI);

Getopt::Long::GetOptions(
	 "-expreesion_data=s"    => \$expreesion_data,
	 "-p4cS=s{,}"    => \@p4cS,
	 "-phenotype_file=s"    => \$phenotype_file,
	 "-outpath=s"    => \$outpath,
	 "-PoI=s"      => \$PoI,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $expreesion_data) {
	$error .= "the cmd line switch -expreesion_data is undefined!\n";
}
unless ( defined $p4cS[0]) {
	$error .= "the cmd line switch -p4cS is undefined!\n";
}
unless ( -f $phenotype_file) {
	$error .= "the cmd line switch -phenotype_file is undefined!\n";
}
unless ( defined $outpath) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}
unless ( defined $PoI){
	$error .= "the cmd line switch -$PoI is undefined!\n";
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
 command line switches for create_GSEA_infiles_from_expression_dataset_and_phenotype_file.pl

   -expreesion_data :the expression data file
   -p4cS            :a pattern or array of smaple names
   -phenotype_file  :the tab separated phenotype file
   -outpath         :where to put the data
   -PoI             :the phenotype I should export data for

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/create_GSEA_infiles_from_expression_dataset_and_phenotype_file.pl';
$task_description .= " -expreesion_data $expreesion_data" if (defined $expreesion_data);
$task_description .= ' -p4cS '.join( ' ', @p4cS ) if ( defined $p4cS[0]);
$task_description .= " -phenotype_file $phenotype_file" if (defined $phenotype_file);
$task_description .= " -outpath $outpath" if (defined $outpath);
$task_description .= " -PoI $PoI";

open (LOG ,">$outpath/create_GSEA_infiles_from_expression_dataset_and_phenotype_file.log") or die "could not create the logfile '$outpath/create_GSEA_infiles_from_expression_dataset_and_phenotype_file.log'\n";
print LOG $task_description;
close ( LOG );

my $phenotypes = stefans_libs_file_readers_phenotypes->new();
$phenotypes -> read_file ( $phenotype_file );
my $expression_file = stefans_libs_file_readers_affymetrix_expression_result->new();
$expression_file ->p4cS( @p4cS );
$expression_file -> read_file (  $expreesion_data );
my $samples = $expression_file ->Samples ();

my $data_hash = $phenotypes -> As_CLS_file_str ( $PoI, $samples );

open (OUT1, ">$outpath/$PoI.cls" ) or die "I could onot create the cls file '$outpath/$PoI.cls'\n$!\n";
print OUT1 $data_hash->{'str'};
close (OUT1);
my @usable_samples;
foreach ( @{$data_hash->{'samples'}} ) {
	push ( @usable_samples, $_ )
}
$expression_file -> Rename_Column ( 'Gene Symbol', 'NAME' );
$expression_file -> Rename_Column (  'Probe Set ID' , 'DESCRIPTION');
$expression_file -> define_subset ( 'printable', [ 'NAME', 'DESCRIPTION', @{$data_hash->{'samples'}}]);

$expression_file -> write_file ( "$outpath/$PoI.expreesion_estimates.txt",'printable' );

