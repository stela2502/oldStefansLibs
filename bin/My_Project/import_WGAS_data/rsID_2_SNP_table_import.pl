#! /usr/bin/perl -w

#  Copyright (C) 2010-09-24 Stefan Lang

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

=head1 rsID_2_SNP_table_import.pl

A script, that would only import the bed file, not a ped file.

To get further help use 'rsID_2_SNP_table_import.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::WGAS;
use stefans_libs::file_readers::plink;


use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $bim_file, $WGAS_name);

Getopt::Long::GetOptions(
	 "-bim_file=s"    => \$bim_file,
	 "-WGAS_name=s"    => \$WGAS_name,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $bim_file) {
	$error .= "the cmd line switch -bim_file is undefined!\n";
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
 command line switches for rsID_2_SNP_table_import.pl

   -bim_file       :the plink SNP description file
   -WGAS_name      :a name for the WGAS study

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'rsID_2_SNP_table_import.pl';
$task_description .= " -bed_file $bim_file" if (defined $bim_file);
$task_description .= " -WGAS_name $WGAS_name" if (defined $WGAS_name);


## Do whatever you want!

my $WGAS = WGAS->new(root->getDBH());
my $initail_samples = $WGAS ->readLatestID();
my $rsID_2_SNP_table = $WGAS->store_bim_file($bim_file, $WGAS_name );
