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

=head1 calculateMean_std_over_genes.pl

The script takes a list of probelset_ids to select expression values from a tab separated file and prints out the mean for all entries...

To get further help use 'calculateMean_std_over_genes.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::tableHandling;
use stefans_libs::root;

my ( $tableFile, $outFile, $searchColumnTitles, $help, $headingLine, $sepString,
	$columns, $pattern, $groupBy );

Getopt::Long::GetOptions(
	"tableFile=s"          => \$tableFile,
	"outFile=s"            => \$outFile,
	"groupBy=s"            => \$groupBy,
	"p4cS=s"               => \$pattern,
	"searchColumnTitles=s" => \$searchColumnTitles,
	"headingLine=s"        => \$headingLine,
	"separatingString=s"   => \$sepString,
	"help"                 => \$help
) or die &helpString();

die &helpString() if ($help);
die &helpString()
  unless ( defined $tableFile );
die helpString ( "you have not provided a pattern (p4cS)" ) unless ( defined  $pattern);
die helpString ( "you have not provided a ") unless ( defined  $headingLine);

sub helpString {
	my $warning_str = shift;
	return "$warning_str\ncommand line options:
 	
   -tableFile                 :the file containing all data in tab seaparated text format
   -separatingString          :the separating sting in the table file (default = \\t)
   -groupBy                   :the grouping tag
   -outFile                   :the file to store the selected table lines in
   -searchColumnTitles        :a semicolon (;) separated list of column titles (first line entries) 
                               we look for the different tags (complete match!)
   -p4cS                      :the pattern to select the data containing columns
   -headingLine               :the line, the column headings are stored in (default = 0)
   -help                      :display this help message
 ";
}

open( IN, "<$tableFile" ) or die "can not open file '$tableFile'\n";

my ( $lineNrs, @data, @lineArray, $line_nr, $groupBy_column );

my $tableHandling = tableHandling->new();
$headingLine = 1 unless ( defined $headingLine );

$line_nr = 0;

my $data = {};

while (<IN>) {
	$line_nr++;
	if ( $line_nr == $headingLine ) {
		if ( defined $searchColumnTitles ) {
			$lineNrs = $tableHandling->identify_columns_of_interest_bySearchHash(
				$_,
				$tableHandling->createSearchHash(
					split( ";", $searchColumnTitles )
				)
			);
			unless ( defined @$lineNrs[0] ) {
				die
"we could not identify the column titles using the data line:\n$_";
			}
		}
		elsif ( defined $pattern ) {
			$lineNrs =
			  $tableHandling->identify_columns_of_interest_patternMatch( $_,
				$pattern );
			unless ( defined @$lineNrs[0] ) {
				die
"we could not identify the column titles using the search pattern $pattern and the table line:\n$_";
			}
		}
		else {
			die &helpString(
"we do need either several table header strings or a pattern that matches to all intersting columns to select the data!"
			);
		}
		$groupBy_column =  $tableHandling->identify_columns_of_interest_bySearchHash(
				$_,
				$tableHandling->createSearchHash(
					split( ";", $groupBy )
				)
		);
		next;
	}
	unless ( defined  @$groupBy_column[0] ){
		@data = "all";
	}
	else {
		@data =  $tableHandling -> get_column_entries_4_columns ($_, $groupBy_column);
	}
	
	unless ( defined $data -> {$data[0]} ){
		$data -> {$data[0]} = [];
	}
	push( @{$data -> {$data[0]}}, ( $tableHandling-> get_column_entries_4_columns ($_, $lineNrs) ) );
}

my $root = root->new();
my ( $mean, $var, $std) ;

unless ( defined $outFile ){
	print "gene name\tamount of datapoint\tmean expression [log2]\tstd dev\n";
	foreach my $name ( keys %$data ){
		( $mean, $var, $std) = root -> getStandardDeviation ( $data->{$name} );
		print $name."\t".scalar(@{$data->{$name}})."\t$mean\t$std\n";
	}
	
}
else{
	open ( OUT, ">$outFile") or die "could not craete $outFile\n";
	print OUT "gene name\tamount of datapoint\tmean expression [log2]\tstd dev\n";
	foreach my $name ( keys %$data ){
		( $mean, $var, $std) = root -> getStandardDeviation ( $data->{$name} );
		print OUT $name."\t".scalar(@{$data->{$name}})."\t$mean\t$std\n";
	}
	close (OUT);
}
