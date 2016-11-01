#! /usr/bin/perl -w

#  Copyright (C) 2012-03-19 Stefan Lang

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

=head1 QQplot_wilcox.pl

this script can crete QQ-plots for the Wilcox result files.

To get further help use 'QQplot_wilcox.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::array_analysis::table_based_statistics;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $temp_path);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,

	"-temp_path=s"    => \$temp_path,
	
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $temp_path) {
	$temp_path = "/tmp/QQplot/";
	
}
unless ( -d $temp_path){
	mkdir ( $temp_path ) ;
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
 command line switches for QQplot_wilcox.pl

   -infiles       :a list of stat result tar files
   -temp_path     :a temporary path

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/QQplot_wilcox.pl';
#$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= " -temp_path $temp_path" if (defined $temp_path);


## Do whatever you want!
my $statistics = stefans_libs_array_analysis_table_based_statistics -> new();
$statistics -> Path( $temp_path );
foreach my $results_archive ( @infiles ){
	print "Processing tar file '$results_archive'\n";
	$statistics -> create_QQ_plot ( $results_archive , $task_description. " -infiles $results_archive" );
}
unlink ( "$temp_path/*" );
