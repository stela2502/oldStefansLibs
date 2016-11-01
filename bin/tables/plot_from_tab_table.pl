#! /usr/bin/perl -w

#  Copyright (C) 2011-01-20 Stefan Lang

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

=head1 plot_from_tab_table.pl

use my plot functions on a tab separated table file - options are XY_plot, histogram, box_plot, and whisker_plot.

To get further help use 'plot_from_tab_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $figure_file, $plot_type, @columns, $line_separator, $title, $x_title, $y_title, $x_res, $y_res, $x_border, $y_border);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-figure_file=s"    => \$figure_file,
	 "-plot_type=s"    => \$plot_type,
	 "-columns=s{,}"    => \@columns,
	 "-line_separator=s"    => \$line_separator,
	 "-title=s"    => \$title,
	 "-x_title=s"    => \$x_title,
	 "-y_title=s"    => \$y_title,
	 "-x_res=s"    => \$x_res,
	 "-y_res=s"    => \$y_res,
	 "-x_border=s"    => \$x_border,
	 "-y_border=s"    => \$y_border,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $figure_file) {
	$error .= "the cmd line switch -figure_file is undefined!\n";
}
unless ( defined $plot_type) {
	$error .= "the cmd line switch -plot_type is undefined!\n";
}
unless ( defined $columns[0]) {
	$error .= "the cmd line switch -columns is undefined!\n";
}
unless ( defined $line_separator) {
	$line_separator = '\t';
}
unless ( defined $title) {
	$error .= "the cmd line switch -title is undefined!\n";
}
unless ( defined $x_title) {
	$x_title = '';
}
unless ( defined $y_title) {
	$y_title = '';
}
unless ( defined $x_res) {
	$x_res = 800;
}
unless ( defined $y_res) {
	$y_res = 600;
}
unless ( defined $x_border) {
	$x_border = 40;
}
unless ( defined $y_border) {
	$y_border = 40;
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
 command line switches for plot_from_tab_table.pl

   -infile         :the data file
   -figure_file    :the figure outfile
   -plot_type      :one of XY_plot, histogram, box_plot, and whisker_plot
   -columns        :a list of columns, that you want to process
   -line_separator :default = '\\t'
   
   -title     :the figure title   (default = '')
   -x_title   :x column title     (default = '')
   -y_title   :y column title     (default = '')
   -x_res     :x resolution in px (default = 800)
   -y_res     :y resolution in px (default = 600)
   -x_border  :x border           (default = 40)
   -y_border  :y border           (default = 40)

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/plot_from_tab_table.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -figure_file $figure_file" if (defined $figure_file);
$task_description .= " -plot_type $plot_type" if (defined $plot_type);
$task_description .= ' -columns '.join( ' ', @columns ) if ( defined $columns[0]);
$task_description .= " -line_separator $line_separator" if (defined $line_separator);
$task_description .= " -title $title" if (defined $title);
$task_description .= " -x_title $x_title" if (defined $x_title);
$task_description .= " -y_title $y_title" if (defined $y_title);
$task_description .= " -x_res $x_res" if (defined $x_res);
$task_description .= " -y_res $y_res" if (defined $y_res);
$task_description .= " -x_border $x_border" if (defined $x_border);
$task_description .= " -y_border $y_border" if (defined $y_border);

open ( LOG , ">$figure_file.log" ) or die "I could not create the log file '$figure_file.log'\n$!\n";
print LOG $task_description."\n";
close ( LOG );

my $data_table = data_table->new();
$data_table -> line_separator ( $line_separator );
$data_table -> read_file ( $infile );

if ( $plot_type eq "whisker_plot" ){
	$data_table -> plot_columns_as_whisker_plot({
	'title' => $title,
	'y_title' => $y_title,
	'x_title' => $x_title,
	'outfile' => $figure_file, 
	'columns' => \@columns,
	'x_res' => $x_res,
	'y_res' => $y_res,
	'x_border' => $x_border,
	'y_border'=> $y_border,
});
}
else {
	die "Sorry, but at this time we have not implemented the plot_type '$plot_type'\n";
}
## Do whatever you want!

