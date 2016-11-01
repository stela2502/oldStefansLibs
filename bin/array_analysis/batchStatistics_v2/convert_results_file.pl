#! /usr/bin/perl -w

#  Copyright (C) 2011-12-15 Stefan Lang

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

=head1 convert_results_file.pl

This script will werge the 'Gene Symbol' Column back to the analyzed data giving you a small report about the dropped probe sets.

To get further help use 'convert_results_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::array_analysis::table_based_statistics;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @results_archives, $description, $temp_path);

Getopt::Long::GetOptions(
	 "-results_archives=s{,}"    => \@results_archives,
	 "-description=s"    => \$description,
	 "-temp_path=s"    => \$temp_path,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $results_archives[0]) {
	$error .= "the cmd line switch -results_archives is undefined!\n";
}
unless ( defined $description) {
	$error .= "the cmd line switch -description is undefined!\n";
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
 command line switches for convert_results_file.pl

   -results_archives  :A list of stat results files (batchStatistics_v2.pl)
   -description       :A list of ducumentation values - should be the same for all stat results
   -temp_path         :I mess with the arcives - please give me a tem path

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/convert_results_file.pl';
#$task_description .= ' -results_archives '.join( ' ', @results_archives ) if ( defined $results_archives[0]);
$task_description .= " -description $description" if (defined $description);
$task_description .= " -temp_path $temp_path" if (defined $temp_path);


## Do whatever you want!
my $statistics = stefans_libs_array_analysis_table_based_statistics -> new();
$statistics -> Path( $temp_path );
foreach my $results_archive ( @results_archives ){
	$statistics -> process_result_file ( $results_archive, $description, $task_description. " -results_archives $results_archive" );
}
unlink ( "$temp_path/*" );


