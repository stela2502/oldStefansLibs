#! /usr/bin/perl -w

#  Copyright (C) 2010-09-07 Stefan Lang

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

=head1 import_WGAS_data.pl

A script to import WGAS data in plink text format using the ped and bim files - map files won't work.

To get further help use 'import_WGAS_data.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::WGAS;
use stefans_libs::file_readers::plink;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $bim_file, $ped_file, $WGAS_name);

Getopt::Long::GetOptions(
	 "-bim_file=s"    => \$bim_file,
	 "-ped_file=s"    => \$ped_file,
	 "-WGAS_name=s"    => \$WGAS_name,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $bim_file) {
	$error .= "the cmd line switch -bim_file is undefined!\n";
}
unless ( -f $ped_file) {
	$error .= "the cmd line switch -ped_file is undefined!\n";
}
unless ( defined $WGAS_name) {
	$error .= "the cmd line switch -WGAS_name is undefined!\n";
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
 command line switches for import_WGAS_data.pl

   -bim_file       :<please add some info!>
   -ped_file       :<please add some info!>
   -WGAS_name       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'import_WGAS_data.pl';
$task_description .= " -bim_file $bim_file" if (defined $bim_file);
$task_description .= " -ped_file $ped_file" if (defined $ped_file);
$task_description .= " -WGAS_name $WGAS_name" if (defined $WGAS_name);

my $WGAS = WGAS->new(root->getDBH());
my $initail_samples = $WGAS ->readLatestID();
my $rsID_2_SNP_table = $WGAS->store_bim_file($bim_file, $WGAS_name );
$WGAS->store_ped_file ( { 'WGAS_name' => $WGAS_name, 'ped_file' => $ped_file, 'rsID_2_SNP' => $rsID_2_SNP_table});

## get some statistics for the dataset
my $SNPs = $rsID_2_SNP_table->readLatestID();
my $samples = $WGAS ->readLatestID();

print "$task_description\nwe have added $SNPs SNP informations times ".($samples - $initail_samples)." SNP array results to the database\n".
"That translates to " . ( $SNPs * ($samples - $initail_samples) ). " new datasets!\n";

