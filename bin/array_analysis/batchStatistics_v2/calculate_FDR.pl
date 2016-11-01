#! /usr/bin/perl -w

#  Copyright (C) 2012-01-16 Stefan Lang

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

=head1 calculate_FDR.pl

This script calculates the FDR for a list of table based statistic results files. They are all summed up in a tar file.

To get further help use 'calculate_FDR.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::array_analysis::table_based_statistics;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $method, $temp_path);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"   => \@infiles,
	 "-method=s"       => \$method,
	 "-temp_path=s"    => \$temp_path,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $method) {
	$warn .= "the FDR method was set to 'BN'";
	#$error .= "the cmd line switch -method is undefined!\n";
}
unless ( defined $temp_path) {
	$error .= "the cmd line switch -temp_path is undefined!\n";
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
 command line switches for calculate_FDR.pl

   -infiles      :a list of statistics results files comming from batchStatistics_v2
   -method       :one in the list of 'holm', 'hochberg', 'hommel', 'bonferroni', 'BH', 'BY' and 'fdr'
                  the R documentation for the function 'p.adjust' explains the options
   -temp_path    :I mess with the arcives - please give me a tem path

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/calculate_FDR.pl';
$task_description .= " -method $method" if (defined $method);
#$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= " -temp_path $temp_path" if (defined $temp_path);

## Do whatever you want!
my $statistics = stefans_libs_array_analysis_table_based_statistics -> new();
$statistics -> Path( $temp_path );
foreach my $results_archive ( @infiles ){
	$statistics -> calculate_FDR ( $results_archive, $method, $task_description. " -infiles $results_archive" );
}
unlink ( "$temp_path/*" );
