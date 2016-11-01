#! /usr/bin/perl -w

#  Copyright (C) 2011-12-23 Stefan Lang

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

=head1 plot_figure_for_complex_transcription_file.pl

This script uses a modified transcription table to plot it with the internal function of the class 'stefans_libs_file_readers_affymetrix_expression_result'. It was mainly used to check whether everything wen well during the modification of the transcription table using the script AddGroupInfos_to_expression_table.pl.

To get further help use 'plot_figure_for_complex_transcription_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::affymetrix_expression_result;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $column, @values, $oufile, $title_column);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-column=s"    => \$column,
	 "-values=s{,}"    => \@values,
	 "-oufile=s"    => \$oufile,
	 "-title_column=s"    => \$title_column,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $column) {
	$error .= "the cmd line switch -column is undefined!\n";
}
unless ( defined $values[0]) {
	$error .= "the cmd line switch -values is undefined!\n";
}
unless ( defined $oufile) {
	$error .= "the cmd line switch -oufile is undefined!\n";
}
unless ( defined $title_column) {
	$error .= "the cmd line switch -title_column is undefined!\n";
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
 command line switches for plot_figure_for_complex_transcription_file.pl

   -infile       :<please add some info!>
   -column       :<please add some info!>
   -values       :<please add some info!> you can specify more entries to that
   -oufile       :<please add some info!>
   -title_column       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/plot_figure_for_complex_transcription_file.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -column $column" if (defined $column);
$task_description .= ' -values '.join( ' ', @values ) if ( defined $values[0]);
$task_description .= " -oufile $oufile" if (defined $oufile);
$task_description .= " -title_column $title_column" if (defined $title_column);


## Do whatever you want!

my $affy_file = stefans_libs_file_readers_affymetrix_expression_result ->new();
$affy_file -> read_file ( $infile );

my $file_count = $affy_file->plot( {
	'outfile' => "/home/stefan/tmp/affy_plotting_device", 
	'select_column' => $column,
	'values' => \@values,
	'title_column' => $title_column
});

print "We created $file_count plot!\n";
