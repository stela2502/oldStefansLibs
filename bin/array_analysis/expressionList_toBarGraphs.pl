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

=head1 expressionList_toBarGraphs.pl

This script plots for each gene in the expression list a bargraph representation of the 'expression level'. Thereby it separates between probe sets.

To get further help use 'expressionList_toBarGraphs.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::plot::simpleBarGraph;
use stefans_libs::tableHandling;
use stefans_libs::root;

my (
	$infile,      $outfile,              $pattern,   $help,
	$debug,       $mayor_tag,            $minor_tag, $separator,
	$headingLine, $select_without_check, $xTitle,    $yTitle, $std_name, $x_res ,$y_res
);

Getopt::Long::GetOptions(
	"-infile=s"             => \$infile,
	"-outfile=s"            => \$outfile,
	"-p4cS=s"               => \$pattern,
	"-separatingString=s"   => \$separator,
	"-help"                 => \$help,
	"-primary_key_name=s"   => \$mayor_tag,
	"headingLine=s"         => \$headingLine,
	"-secondary_key_name=s" => \$minor_tag,
	"-x_title=s"            => \$xTitle,
	"-y_title=s"            => \$yTitle,
	"-x_res=s"              => \$x_res,
	"-y_res=s"              => \$y_res,
	"-debug"                => \$debug
) or die &helpString();

unless ( -f $infile ) {
	print helpString("we need an infile!");
	exit;
}

unless ( defined $outfile ) {
	print helpString("we need an outfile!");
	exit;
}

unless ( defined $pattern ) {
	print helpString("we wont find any data values without the p4cs");
	exit;
}

unless ( defined $mayor_tag ) {
	print helpString("we need an primary key!");
	exit;
}

unless ( -f $infile ) {
	print helpString("we need an infile!");
	exit;
}

unless ( -f $infile ) {
	print helpString("we need an infile!");
	exit;
}
if ($help) {
	print helpString();
	exit;
}

my (
	$tableHandling,   $simpleBarGraph, $lineCount,       $dataColumns,
	$mayorColumn,     $minorColumn,    @dataColumnNames, @primary_names,
	@secondary_names, @data_entries,   $dataset, $std_columnNr, @std_value
);

$tableHandling = tableHandling->new($separator);
$lineCount     = 0;

open( IN, "<$infile" ) or die "we could not open the infile '$infile'\n$!";
open( LOG, ">$outfile.log" )
  or die "could not create the log file '$outfile.log'\n";

## we need an internal data structure!
## defineition: an hash of hashes of hashes ;-)
## first hash key = the primary key name
## second hash key = the secondary key name
## third hash = { <data column name> => <data column entry> }

my $dataHash = {};

while (<IN>) {
	$lineCount++;
	if ( $lineCount == $headingLine ) {
		$mayorColumn =
		  $tableHandling->identify_columns_of_interest_bySearchHash(
			$_,
			$tableHandling->createSearchHash(
				$tableHandling->_split_searchString($mayor_tag)
			)
		  );
		$minorColumn =
		  $tableHandling->identify_columns_of_interest_bySearchHash(
			$_,
			$tableHandling->createSearchHash(
				$tableHandling->_split_searchString($minor_tag)
			)
		  );

		$dataColumns =
		  $tableHandling->identify_columns_of_interest_patternMatch( $_,
			$pattern );
		print "TEST we are ready with the first thging...\n";
		die "we did not find the column name(s) in the following line\n$_"
		  unless ( defined @$dataColumns[0] && defined @$mayorColumn[0] );

		## now we need to get the values!!
		@dataColumnNames =
		  $tableHandling->get_column_entries_4_columns( $_, $dataColumns );

		print LOG "primary key column name\t$mayor_tag\n";
		print LOG "secondary key column name\t$minor_tag\n";
		print LOG "not anount of data columns\t", join( "; ", @$dataColumns ),
		  "\n"
		  if ( defined @$dataColumns[0] );
		next;
	}
	@primary_names =
	  $tableHandling->get_column_entries_4_columns( $_, $mayorColumn );
	@secondary_names =
	  $tableHandling->get_column_entries_4_columns( $_, $minorColumn );
	@data_entries =
	  $tableHandling->get_column_entries_4_columns( $_, $dataColumns );
	unless ( defined $dataHash->{ $primary_names[0] } ) {
		$dataHash->{ $primary_names[0] } = {};
	}
	
	if ( defined $dataHash->{ $primary_names[0] }->{ $secondary_names[0] } ) {
		warn " we have two entries with the same primary and secondary key -"
		  . " we will ignore the second one ( $primary_names[0] - $secondary_names[0])\n";
		next;
	}
	else {
		my $hash = {};
		for ( my $i = 0 ; $i < @data_entries ; $i++ ) {
			$hash->{ $dataColumnNames[$i] } = { 'y' => $data_entries[$i] };
		}
		$dataHash->{ $primary_names[0] }->{ $secondary_names[0] } = $hash;
	}
}

if ($debug) {
	root::print_hashEntries( $dataHash, 5, "\nthe resulting data hash:" );
	print "\n";
}

my ( $color, $im, $font );

$im = GD::SVG::Image->new( 1200, 600 );
$color = color->new($im);
print "we have initialized the plot objects\n";
$font = Font->new("small");

foreach my $firstKey ( sort keys %$dataHash ) {

	$simpleBarGraph = simpleBarGraph->new();
	foreach my $secondary_key ( keys %{ $dataHash->{$firstKey} } ) {
		$simpleBarGraph->AddDataset(
			{
				'name'  => $secondary_key,
				'data'  => $dataHash->{$firstKey}->{$secondary_key},
				'color' => $color->getNextColor(),
				'order_array' => \@dataColumnNames
			}
		);
	}
	$x_res = 1200 unless ( defined $x_res);
	$y_res = 600 unless ( defined $y_res);
	$dataset = {
		'x_res'   => $x_res,
		'y_res'   => $y_res,
		'x_min'   => 60,
		'x_max'   => $x_res -40,
		'y_min'   => 50,
		'y_max'   => $y_res - 100,
		'color'   => $color,
		'font'    => $font,
		'size'    => 'med',
		'mode'    => 'landscape',
		'outfile' => $outfile . "_$firstKey",
		'xTitle' => $xTitle,
		'yTitle' => $yTitle,
		'title' => "Gene ".$firstKey
	};
	$simpleBarGraph->plot_2_image($dataset);
	$color->{nextColor} = 0;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for expressionList_toBarGraphs.pl
 
 
   -infile              :the tab separated, text formated infile
   -outfile             :the name of the outfile (a svg will be added if not present)
   -p4cS                :the pattern to identify the data containing columns
   -separatingString    :the separating sting in the table file (default = \t)
   -headingLine         :the line, the column headings are stored in (default = 0)
   -primary_key_name    :the name of the column containing the mayor grouping value
   -secondary_key_name  :the name of the column that contains the minor grouping value
   -x_title             :the title string for the x axis
   -y_title             :the title string for the y axis
   -x_res               :the x resolution in pixel
   -y_res               :the y resolution in pixel
   -help                :print this help
   -debug               :verbose output


";
}
