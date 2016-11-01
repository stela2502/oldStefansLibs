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

=head1 makeSenseOfLists.pl

A script to create a table describing a set of lists. The first value in the ';' separated list will be the column header using YES and NO values if the value is in the list or not.

To get further help use 'makeSenseOfLists.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @lists, @column_titles, $outfile);

Getopt::Long::GetOptions(
	 "-lists=s{,}"    => \@lists,
	 "-outfile=s"    => \$outfile,
	 "-column_titles=s{,}" => \@column_titles,

	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 "-database=s"       => \$database
);

my $warn = '';
my $error = '';

unless ( defined $lists[1]) {
	$error .= "the cmd line switch -lists needs at least two differnet lists!\n";
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
 command line switches for makeSenseOfLists.pl

   -lists         :a list of strings containing a interesting information
   -outfile       :a file to print the output to
   -column_titles :one column title(pattern match!) or a list of column tiltes(exact match)
                   to be included in the horizontal summary analysis
                   
   -help           :print this help
   -debug          :verbose output
   

"; 
}

## now we set up the logging functions....

my ( $task_description, $out, $data_structure, @data, $col_name );

$task_description = "makeSenseOfLists.pl -lists @lists -outfile $outfile";

$data_structure = {};
$out = data_table->new();
$out -> Add_2_Header ('value name');
$out->createIndex('value name');
$out -> Add_2_Header ('horizontal count');

foreach my $info ( @lists ){
	@data = split (";",$info);
	$col_name = shift( @data );
	$out -> Add_2_Header ( $col_name );
	$out -> setDefaultValue ($col_name, '-' );
	foreach my $value ( @data) {
		$out->Add_Dataset( { 'value name' => $value, $col_name => 'YES' });
	}
}

$out->count_query_on_lines_to_column( {'exact' => 'YES'}, 'horizontal count', @column_titles );
$out->print2file($outfile);


