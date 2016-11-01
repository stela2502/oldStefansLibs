#! /usr/bin/perl -w

#  Copyright (C) 2008 Stefan Lang

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

=head1 simpleXYplot.pl

a simple tool to create a XY plot from a data file containing X and Y values.

To get further help use 'simpleXYplot.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::tableHandling;
use stefans_libs::plot::simpleXYgraph;

my ( $help, $debug, $file, $x_col_title, $y_col_title, $data_mod, $picture_title, $separator );

Getopt::Long::GetOptions(
	"-datafile=s"            => \$file,
	"-x_column_title=s"      => \$x_col_title,
	"-y_column_title=s"      => \$y_col_title,
	"-picture_title=s"       => \$picture_title,
	"-separator=s"             => \$separator,
	"-data_transformation=s" => \$data_mod,
	"-help"                  => \$help,
	"-debug"                 => \$debug
);

unless ( -f $file ) {
	print helpString("we need a filename to get the data from!");
	exit;
}

unless ( defined $x_col_title) {
	print helpString("we need a column title for the x_values!");
	exit;
}

unless ( defined $y_col_title) {
	print helpString("we need a column title for the y_values!");
	exit;
}

print "the line separator = '$separator'\n";

if ( defined $data_mod){
	my $match = 0;
	foreach my $mod ( ('log10', '-log10' ) ){
		$match = 1 if ( $mod eq $data_mod);
	}
	unless ( $match ){
		print helpString("sorry, but the data_transformation $data_mod is not supported!");
		exit;
	}
}

if ($help) {
	print helpString();
	exit;
}

my ( $x_column_id, $y_column_id, $data, $tableHandling, @array );

$tableHandling = tableHandling->new( $separator );

## we need a data hash looking like $hash -> { <data name> => { x=> [<x_values>], y => [ <y_values> ] } }

open( IN, "<$file" ) or die "could not open file '$file'\n";

while (<IN>) {
	unless ( defined $x_column_id ) {
		$x_column_id =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			$tableHandling->createSearchHash($x_col_title) );
		unless ( defined @$x_column_id[0] ){
			print helpString("we did not get any column id for the header string '$x_col_title' when looking at the line \n$_");
			exit
		}
		$y_column_id =
		  $tableHandling->identify_columns_of_interest_bySearchHash( $_,
			$tableHandling->createSearchHash($y_col_title) );
		unless ( defined @$y_column_id[0] ){
			print helpString("we did not get any column id for the header string '$y_col_title' when looking at the line \n$_");
			exit
		}
		next;
		$data = { 'xy_data' => { 'x' => [], 'y' => [] } };
	}
	chomp $_;
	@array = $tableHandling->get_column_entries_4_columns( $_, $y_column_id);
	next if ($array[0] eq "NA" ); 
	push ( 	@{$data->{'xy_data'}->{'y'}}, $array[0]);
	@array = $tableHandling->get_column_entries_4_columns( $_, $x_column_id);
	push ( 	@{$data->{'xy_data'}->{'x'}}, $array[0]);
	

}

close(IN);

if ( $data_mod eq '-log10' ){
	for( my $i = 0; $i < @{$data->{'xy_data'}->{y} }; $i++){
		@{$data->{'xy_data'}->{y} }[$i] = &minus_log10( @{$data->{'xy_data'}->{y} }[$i] );
	}
}

elsif ( $data_mod eq "log10" ){
	for( my $i = 0; $i < @{$data->{'xy_data'}->{y} }; $i++){
		@{$data->{'xy_data'}->{y} }[$i] = &log10( @{$data->{'xy_data'}->{y} }[$i] );
	}
}



my $simpleXYgraph = simpleXYgraph->new();
$y_col_title .= " [$data_mod]" if ( defined $data_mod);

$simpleXYgraph -> plotData ( $data, 800, 600, $x_col_title, $y_col_title, $picture_title, "$file.svg" );


sub log10 {
	my ($value) = @_;
	return log($value) / log(10);
}
 
sub minus_log10 {
	my ($value) = @_;
	return - (log($value) / log(10) );
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for simpleXYplot.pl
 
   -datafile       :the name of the datafile
   -x_column_title :the column title for the x_values
   -y_column_title :the column title for the y_values
   -data_transformation 
                   :the data transformation wanted for the x values
                    possibilliteis: -log10; log10 default -> none
   -picture_title  :the optional title of the picture
   -separator      :the column separator (default <TAB>)
   -help           :print this help
   -debug          :verbose output


";
}
