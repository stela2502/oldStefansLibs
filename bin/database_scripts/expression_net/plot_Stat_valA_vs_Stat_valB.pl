#! /usr/bin/perl -w

#  Copyright (C) 2010-08-16 Stefan Lang

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

=head1 plot_Stat_valA_vs_Stat_valB.pl

A tool to plot two variables of a expression net statistics file against each other.

To get further help use 'plot_Stat_valA_vs_Stat_valB.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use stefans_libs::file_readers::expression_net_reader;
use stefans_libs::plot::simpleXYgraph;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $expt_net_stat_file, $x_var, $y_var, $outfile);

Getopt::Long::GetOptions(
	 "-expt_net_stat_file=s"    => \$expt_net_stat_file,
	 "-x_var=s"    => \$x_var,
	 "-y_var=s"    => \$y_var,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $expt_net_stat_file) {
	$error .= "I can not acces the -expt_net_stat_file\n";
}
unless ( defined $x_var) {
	$error .= "the cmd line switch -x_var is undefined!\n";
}
unless ( defined $y_var) {
	$error .= "the cmd line switch -y_var is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for plot_Stat_valA_vs_Stat_valB.pl

   -expt_net_stat_file :the expression net statistics file you want to use as data source
   
   -x_var       :the name of the variable that should be plotted on the x axis
   -y_var       :the name of the variable that should be plotted to the y axis
   -outfile     :the name of the picture output file

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'plot_Stat_valA_vs_Stat_valB.pl';
$task_description .= " -expt_net_stat_file $expt_net_stat_file" if (defined $expt_net_stat_file);
$task_description .= " -x_var $x_var" if (defined $x_var);
$task_description .= " -y_var $y_var" if (defined $y_var);
$task_description .= " -outfile $outfile" if (defined $outfile);


## Do whatever you want!

my ( $expression_net_reader, $data, @x, @y, $temp, $plot, $i );
$expression_net_reader = expression_net_reader->new();
$data = $expression_net_reader -> read_LogFile( $expt_net_stat_file );
$i = 0;
foreach $temp ( values %$data ){
	unless ( defined $temp-> {$x_var}){
		die "Sorry, but the file $expt_net_stat_file does not contain a (x-) variable named '$x_var'\n\t".
		join("\n\t", (keys %$temp));
	}
	unless ( defined $temp-> {$y_var}){
		die "Sorry, but the file $expt_net_stat_file does not contain a (y-) variable named '$y_var'\n\t".
		join("\n\t", (keys %$temp));
	}
	$i ++;
	push ( @x , $temp-> {$x_var});
	push ( @y , $temp-> {$y_var});
} 
$plot = simpleXYgraph->new();
$plot -> AddDataset( { 'title' => 'data', 'x' => \@x, 'y'=> \@y } );
$plot -> No_Line_Between ( 'data', 1);
$plot -> Xtitle ( $x_var );
$plot -> Ytitle ( $y_var );
$plot -> Title ( "used file =  $expt_net_stat_file" );

$plot->plot({
	
	'x_res' => 1200, 
	'y_res' => 800,
	'x_min' => 300,
	'x_max' => 1100,
	'y_min' => 40,
	'y_max' => 700,
	'outfile' => $outfile
}
);