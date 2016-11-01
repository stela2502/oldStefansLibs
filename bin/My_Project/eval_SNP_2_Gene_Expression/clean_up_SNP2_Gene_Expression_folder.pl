#! /usr/bin/perl -w

#  Copyright (C) 2011-02-08 Stefan Lang

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

=head1 clean_up_SNP2_Gene_Expression_folder.pl

Read through a folder creating a first summary PDF result and summing up all datasets.

To get further help use 'clean_up_SNP2_Gene_Expression_folder.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $inpath);

Getopt::Long::GetOptions(
	 "-inpath=s"    => \$inpath,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -d $inpath) {
	$error .= "the cmd line switch -inpath is undefined!\n";
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
 command line switches for clean_up_SNP2_Gene_Expression_folder.pl

   -inpath       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'clean_up_SNP2_Gene_Expression_folder.pl';
$task_description .= " -inpath $inpath" if (defined $inpath);


## Do whatever you want!

