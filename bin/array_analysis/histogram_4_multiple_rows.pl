#! /usr/bin/perl -w

#  Copyright (C) 2012-04-20 Stefan Lang

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

=head1 histogram_4_multiple_rows.pl

This script plots the data in teh table as multiple histograms in one plot to visualize potential differences between the datasets.

To get further help use 'histogram_4_multiple_rows.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::plot::simpleXYgraph;
use stefans_libs::statistics::new_histogram;

my $VERSION = 'v1.0';

my ( $MAXVALUE, $MINVALUE, $Y_MAXVALUE);

my ( $help, $debug, $database, $table_file, @columns_A, @columns_B, $outfile, $bars);

Getopt::Long::GetOptions(
	 "-table_file=s"    => \$table_file,
	 "-columns_A=s{,}"    => \@columns_A,
	 "-columns_B=s{,}"    => \@columns_B,
	 "-outfile=s"    => \$outfile,
	 "-bars=s"    => \$bars,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $table_file) {
	$error .= "the cmd line switch -table_file is undefined!\n";
}
unless ( defined $columns_A[0]) {
	$error .= "the cmd line switch -columns_A is undefined!\n";
}
unless ( defined $columns_B[0]) {
	$warn .= "the cmd line switch -columns_B is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $bars) {
	$error .= "the cmd line switch -bars is undefined!\n";
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
 command line switches for histogram_4_multiple_rows.pl

   -table_file   :the table file containing the data
   -columns_A    :a list of columns plotted in green
   -columns_B    :a list of columns plotted in blue
   -outfile      :the outfile
   -bars         :how many x-values should I plot

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/histogram_4_multiple_rows.pl';
$task_description .= " -table_file $table_file" if (defined $table_file);
$task_description .= ' -columns_A '.join( ' ', @columns_A ) if ( defined $columns_A[0]);
$task_description .= ' -columns_B '.join( ' ', @columns_B ) if ( defined $columns_B[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -bars $bars" if (defined $bars);


my $data_table = data_table->new();
$data_table -> read_file ( $table_file );
my @temp;
foreach (@columns_A,  @columns_B) {
	Carp::confess ( "Sorry I do not know the table column '$_'\n"."I have the columns: '".join("' '",@{$data_table->{'header'}})."'\n") unless ( defined $data_table->Header_Position( $_) );
	@temp = (sort  {$a <=> $b} @{$data_table->GetAsArray($_) });
	
	shift ( @temp ) unless ( defined $temp[0]);
	&max( $temp[@temp -1 ]);
	&min( $temp[0] );
	print "the values for column $_: ".join(", ", @temp[0,1,2,3])." ... ".join(", ",@temp[@temp-3, @temp-2,@temp-1])."\n"."Leading to a min and max value of ".&min(). ", ".&max()."\n";
}

my $simpleXYgraph = simpleXYgraph->new();
$simpleXYgraph -> _createPicture ( { 'xres' => 800, 'yres' => 600 });

my $hist;

foreach (@columns_A ) {
	my $histogram = new_histogram->new();
	$histogram->Max ( &max );
	$histogram->Min ( &min );
	$histogram->Category_steps($bars);
	$histogram -> CreateHistogram ( $data_table->GetAsArray($_) );
	$hist->{$_} = $histogram;
	@temp = undef;
	foreach ( @{$histogram->getAs_XY_plottable()} ) {
		push ( @temp, $_->{'y'});
	}
	@temp = sort  {$a <=> $b} @temp;
	&y_max ( $temp[@temp -1 ] );
}

foreach (@columns_B ) {
	my $histogram = new_histogram->new();
	$histogram->Max ( &max );
	$histogram->Min ( &min );
	$histogram->Category_steps($bars);
	$histogram -> CreateHistogram ( $data_table->GetAsArray($_) );
	$hist->{$_} = $histogram;
	@temp = undef;
	foreach ( @{$histogram->getAs_XY_plottable()} ) {
		push ( @temp, $_->{'y'});
	}
	@temp = sort  {$a <=> $b} @temp;
	&y_max ( $temp[@temp -1 ] );
}

$simpleXYgraph->_createAxies ( { 'x_min' => 100, 'x_max' => 770 , 'y_min' => 20, 'y_max' => 500,} );
$simpleXYgraph->{'xaxis'}->max_value ( &max());
$simpleXYgraph->{'xaxis'}->min_value ( &min());
$simpleXYgraph->{'yaxis'}->max_value ( &y_max());
$simpleXYgraph->{'yaxis'}->min_value ( 0 );
#print root::get_hashEntries_as_string ( [$simpleXYgraph->{'xaxis'}->resolveValue ( 1 )] , 3 , "the coordinates for x 1" );
#print root::get_hashEntries_as_string ( [$simpleXYgraph->{'yaxis'}->resolveValue ( &min() )] , 3 , "the coordinates for y ". &min() );

foreach (@columns_A ) {	
	$simpleXYgraph -> plot_Data ( 
	 $hist->{$_}->getAs_XY_plottable() , # all are arrays of values!
	 $simpleXYgraph->{'color'}->{'green'}, #this color you need to get from a color object!
	 $_ , #only one dataset name will be used here!
	 );
}

foreach (@columns_B ) {
$simpleXYgraph -> plot_Data ( 
	 $hist->{$_}->getAs_XY_plottable() , # all are arrays of values!
	 $simpleXYgraph->{'color'}->{'dark_blue'}, #this color you need to get from a color object!
	 $_ , #only one dataset name will be used here!
	 );
}

$simpleXYgraph->Title( 'Multiple Histograms in two groups ('.scalar(@columns_A)." x ".scalar(@columns_B).")" );
$simpleXYgraph-> plot_title ();
$simpleXYgraph->Xtitle ( 'data values in the table');
$simpleXYgraph->Ytitle ( 'number of data values');

$simpleXYgraph->_plot_axies();

$simpleXYgraph->writePicture ( $outfile );


sub y_max {
	my ( $max ) = @_;
	return $Y_MAXVALUE unless ( defined $max);
	$Y_MAXVALUE = $max unless ( defined $Y_MAXVALUE );
	if ( $max > $Y_MAXVALUE ){
		$Y_MAXVALUE = $max;
	}
	return $Y_MAXVALUE;
}

sub max {
	my ( $max ) = @_;
	return $MAXVALUE unless ( defined $max);
	$MAXVALUE = $max unless ( defined $MAXVALUE );
	if ( $max > $MAXVALUE ){
		$MAXVALUE = $max;
	}
	return $MAXVALUE;
}

sub min {
	my ( $min ) = @_;
	return $MINVALUE unless ( defined $min);
	$MINVALUE = $min unless ( defined $MINVALUE );
	if ( $min < $MINVALUE ){
		$MINVALUE = $min;
	}
	return $MINVALUE;
}