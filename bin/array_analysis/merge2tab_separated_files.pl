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

=head1 merge2tab_separated_files.pl

a simple script to merge two tab separated files by one column.

To get further help use 'merge2tab_separated_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
#use warnings;
use stefans_libs::flexible_data_structures::data_table;

my ( $help, $debug, @infiles, $outfile, $not_add_first_only, @modify_columns, @data_columns, $title, $modify_columns );

Getopt::Long::GetOptions(
	"-infiles=s{,}"   => \@infiles,
	"-column_title=s" => \$title,
	"-data_columns=s{,}" => \@data_columns,
	"-modify_columns=s{,}" => \@modify_columns,
	"-outfile=s" => \$outfile,
	"-not_add_first_only" => \$not_add_first_only,
	"-help"           => \$help,
	"-debug"          => \$debug
);

unless ( defined $infiles[1] ) {
	print helpString("we need some infiles (more than one!)");
	exit;
}
unless ( defined $title ) {
	print helpString(
		"we definitely need a column title of a unique key between the files!");
	exit;
}
unless ( $outfile ) {
	print helpString(
		"we might want to have a outfile ?!");
	exit;
}
if ( defined $modify_columns[0] ){
	foreach ( @modify_columns ){
		$modify_columns -> {$_} = 1;
	}
}

if ($help) {
	print helpString();
	exit;
}

my ( $tableHandling, @fileReps, $title_id, $tag, @rest, @line, $keys,
	$title_str, @data, $i, $result_table, $this_table );

warn "we read in the files:\n", join( "\n", @infiles ), "\n";

foreach my $infile (@infiles) {
	$this_table = data_table->new($debug);
	$this_table ->read_file ( $infile );
	if ( defined $data_columns[0]){
		my @temp;
		foreach ( @data_columns ){
			push ( @temp, $_) if ( defined $this_table ->Header_Position ( $_ ) );
		}
		Carp::confess ( "Sorry, but the table '$infile' does not contain any of the data_columns!\nOnly these: '".join("', '",@{$this_table->{'header'}})."'\n")
		 unless ( defined $temp[0]);
		$this_table -> define_subset ( 'DaTa', \@temp );
		$this_table = $this_table -> GetAsObject ( 'DaTa' );
		print "I have selected the column names '".join("', '",@{$this_table->{'header'}})."' from the infile '$infile'\n";
	}
	if ( defined $modify_columns[0] ){
		my @temp = split ( "/", $infile );
		@temp = split ( /\./, $temp[@temp - 1] );
		#print "I would add $temp[0] to the columns\n";
		foreach ( @{$this_table->{'header'}} ){
			if ( $modify_columns->{$_}) {
				$this_table->Rename_Column ( $_, $temp[0]. " ".$_ );
			}
		}
	}
	print "we have read file '$infile'\n";
	$this_table ->createIndex( $title );
	unless ( ref($result_table) eq 'data_table'){
		$result_table = $this_table;
		next;
	}
	$result_table = $result_table -> merge_with_data_table ( $this_table, $not_add_first_only );
	print "merge with file '$infile' id done\n";
}

$result_table ->write_file( $outfile );

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for merge2tab_separated_files.pl
 
   -infiles       :a list of tab separated files tah schold be merged
   -outfile       :the outfile
   -column_title  :the columntitle of the joining key
   -data_columns  :a list of columns that you want to merge
   
   -modify_columns :a list of column names that should get the filename as prefix
   
   -not_add_first_only 
                  :by default I will merge all lines vs all lines including 
                   all lines that have no representation in the second file
                   If you use this option, these lines will not be reported.
   
   -help           :print this help
   -debug          :verbose output


";
}
