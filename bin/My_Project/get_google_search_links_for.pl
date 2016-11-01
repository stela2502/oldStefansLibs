#! /usr/bin/perl -w

#  Copyright (C) 2010-12-09 Stefan Lang

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

=head1 get_google_search_links_for.pl

Use a list of query strings to get a table containing all the putatively interesting links to the queries.

To get further help use 'get_google_search_links_for.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::WebSearch::Googel_Search;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @query_strings, $outfile);

Getopt::Long::GetOptions(
	 "-query_strings=s{,}"    => \@query_strings,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $query_strings[0]) {
	$error .= "the cmd line switch -query_strings is undefined!\n";
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
 command line switches for get_google_search_links_for.pl

   -query_strings       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/get_google_search_links_for.pl';
$task_description .= ' -query_strings '.join( ' ', @query_strings ) if ( defined $query_strings[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);

if ( -f $query_strings[0] ){
	## OK I will read the file
	my @temp;
	open ( IN, "<$query_strings[0]" ) or die "could not open the query_strings file\n";
	while ( <IN> ){
		chomp($_);
		push ( @temp , split(/\s/ ,$_) );
	}
	close ( IN );
	pop ( @temp ) unless ( defined $temp[0]);
	@query_strings = @temp;
}
## Do whatever you want!
my ($data_table, $Googel_Search, $with_entry );
$Googel_Search = stefans_libs_WebSearch_Googel_Search -> new();

$data_table = data_table->new();
foreach ( 'query string', 'href' ){
	$data_table ->Add_2_Header( $_ );
}
my $used;
foreach my $str ( @query_strings ){
	next if ( $used -> { $str } );
	$with_entry = 0;
	 foreach ( @{$Googel_Search->search_for($str)}){
	 	$data_table ->AddDataset( {'query string' => $str, 'href' => $_} );
	 	print "$str ->  $_\n";
	 	$with_entry = 1;
	 }
	 unless ( $with_entry ){
	 	$data_table ->AddDataset( {'query string' => $str, 'href' => "no search result" });
	 }
	 $used -> { $str } = 1;
}

$data_table -> write_file ( $outfile );
