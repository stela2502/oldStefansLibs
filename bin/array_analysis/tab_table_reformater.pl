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

=head1 tab_table_reformater.pl

A tool to handle and convert tab separated table files

To get further help use 'tab_table_reformater.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;
use strict;
use warnings;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $table_file, @sort_by, $restrict_to, $outfile);

Getopt::Long::GetOptions(
	 "-table_file=s"    => \$table_file,
	 "-sort_by=s{,}"    => \@sort_by,
	 "-restrict_to=s"    => \$restrict_to,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 "-database=s"       => \$database
);

my $error = '';

unless ( -f $table_file) {
	$error .= 'the cmd line switch -table_file is undefined!';
}
unless ( defined $sort_by[0]) {
	warn 'the cmd line switch -sort_by is undefined!';
}
unless ( defined $restrict_to) {
	warn 'the cmd line switch -restrict_to is undefined!';
}
unless ( defined $outfile) {
	$error .= 'the cmd line switch -outfile is undefined!';
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}
my $old_table;
my $data_table = data_table->new();
$data_table -> read_file( $table_file );
if ( defined $sort_by[0] ){
	my @sortArray;
	$old_table = "$data_table";
	foreach my $string ( @sort_by ){
		$sortArray[@sortArray] = [ split(";", $string ) ];
	}
	$data_table = $data_table->Sort_by( \@sortArray );
}
if ( defined $restrict_to ) {
	$old_table = "$data_table";
	my @sortArray = split ( ";", $restrict_to);
	$data_table = $data_table->Get_first_for_column(@sortArray);
}
if ( defined  $old_table ){
	$data_table->print2file( $outfile );
}
else {
	print "we did do nothing - no things to do...!\n";
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for tab_table_reformater.pl

   -table_file     :the infile
   -sort_by        :the sort order in as an array of '<columnName>;<sort type>' srtings
   -restrict_to    :a module to restrict the data to the top values '<columnName>';<amount>;<sort type>'
   -outfile        :<please add sime info!>

   -help           :print this help
   -debug          :verbose output

   the 'sort types' can be one of 'numeric', 'antiNumeric' or 'lexical'
   

"; 
}

