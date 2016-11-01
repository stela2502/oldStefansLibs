#! /usr/bin/perl -w

#  Copyright (C) 2010-10-15 Stefan Lang

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

=head1 import_WGAS_data_affymetrix_Format.pl

Import the files obtained from an apt-probeset-genotype run.

To get further help use 'import_WGAS_data_affymetrix_Format.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::WGAS;
use stefans_libs::file_readers::affymerix_snp_description;
use stefans_libs::file_readers::affymerix_snp_data;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ($test_a, $test_b );
$test_a = file_readers::affymerix_snp_description->new();
$test_b = file_readers::affymerix_snp_data->new();

my ( $help, $debug, $database, $WGAS_name, $affy_descr_file, $affy_data_file, @affy_data_files);

Getopt::Long::GetOptions(
	 "-WGAS_name=s"    => \$WGAS_name,
	 "-affy_descr_file=s"    => \$affy_descr_file,
	 "-affy_data_files=s"    => \@affy_data_files,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $WGAS_name) {
	$error .= "the cmd line switch -WGAS_name is undefined!\n";
}
unless ( -f $affy_descr_file) {
	$error .= "the cmd line switch -affy_descr_file is undefined!\n";
}
unless ( -f $affy_data_files[0]) {
	$error .= "the cmd line switch -affy_data_files is undefined!\n";
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
 command line switches for import_WGAS_data_affymetrix_Format.pl

   -WGAS_name       :the name of this WGAS dataset (make it meaningful)
   -affy_descr_file :the affymetrix array description file
   -affy_data_files  :the affymetrix SNP call results

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'import_WGAS_data_affymetrix_Format.pl';
$task_description .= " -WGAS_name $WGAS_name" if (defined $WGAS_name);
$task_description .= " -affy_descr_file $affy_descr_file" if (defined $affy_descr_file);
$task_description .= " -affy_data_file '".join( "' '",@affy_data_files)."'" if (defined $affy_data_files[0]);


## Do whatever you want!

my $WGAS = WGAS->new(root->getDBH());
my $initail_samples = $WGAS ->readLatestID();
my $rsID_2_SNP_table;
foreach $affy_data_file ( @affy_data_files ){
	print "we open the affy description file '$affy_data_file'\n";
	$rsID_2_SNP_table = undef;
	$rsID_2_SNP_table = $WGAS->store_affymetrix_data ( { 'WGAS_name' => $WGAS_name, 'affy_descr_file' => $affy_descr_file, 'affy_data_file' => $affy_data_file});
}

## get some statistics for the dataset
my $SNPs = $rsID_2_SNP_table->readLatestID();
my $samples = $WGAS ->readLatestID();

print "$task_description\nwe have added $SNPs SNP informations times ".($samples - $initail_samples)." SNP array results to the database\n".
"That translates to " . ( $SNPs * ($samples - $initail_samples) ). " new datasets!\n";
