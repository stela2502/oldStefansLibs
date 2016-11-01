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

=head1 compare_two_result_files.pl

A script, that creates a merged table from two MeDIP result files using different input data, but hopefully everything else is keept as it was.

To get further help use 'compare_two_result_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile_1, $infile_2, $comment_1, $comment_2, $outfile, $merge_column);

Getopt::Long::GetOptions(
	 "-infile_1=s"    => \$infile_1,
	 "-infile_2=s"    => \$infile_2,
	 "-comment_1=s"    => \$comment_1,
	 "-comment_2=s"    => \$comment_2,
	 "-outfile=s"    => \$outfile,
	 "-merge_column=s"    => \$merge_column,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile_1) {
	$error .= "the cmd line switch -infile_1 is undefined!\n";
}
unless ( defined $infile_2) {
	$error .= "the cmd line switch -infile_2 is undefined!\n";
}
unless ( defined $comment_1) {
	$error .= "the cmd line switch -comment_1 is undefined!\n";
}
unless ( defined $comment_2) {
	$error .= "the cmd line switch -comment_2 is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $merge_column) {
	$error .= "the cmd line switch -merge_column is undefined!\n";
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
 command line switches for compare_two_result_files.pl

   -infile_1       :<please add some info!>
   -infile_2       :<please add some info!>
   -comment_1       :<please add some info!>
   -comment_2       :<please add some info!>
   -outfile       :<please add some info!>
   -merge_column       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'compare_two_result_files.pl';
$task_description .= " -infile_1 $infile_1" if (defined $infile_1);
$task_description .= " -infile_2 $infile_2" if (defined $infile_2);
$task_description .= " -comment_1 $comment_1" if (defined $comment_1);
$task_description .= " -comment_2 $comment_2" if (defined $comment_2);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= " -merge_column $merge_column" if (defined $merge_column);

my $data_table_1 = data_table->new();
my $data_table_2 = data_table->new();

$data_table_1->read_file ( $infile_1 );
$data_table_2->read_file ( $infile_2 );

$data_table_1->createIndex ( $merge_column );
$data_table_2->createIndex ( $merge_column );

## to keep the information we need to change the column titles of the second file!!
foreach my $header_2 ( @{$data_table_2->{'header'}}){
	next if ( $header_2 eq $merge_column);
	$data_table_2-> Rename_Column ( $header_2, $header_2." file#2");
}
foreach my $header_2 ( @{$data_table_1->{'header'}}){
	next if ( $header_2 eq $merge_column);
	$data_table_1 -> Rename_Column ( $header_2, $header_2." file#1");
}

$data_table_1-> merge_with_data_table ( $data_table_2 );

$data_table_1 -> Add_2_Description ( "we merged the files $infile_1 and $infile_2");
$data_table_1 -> Add_2_Description ( "Comment on file#1: '$comment_1'");
$data_table_1 -> Add_2_Description ( "Comment on file#2: '$comment_2'");

foreach ( @{ $data_table_2->{'description'} } ){
	$data_table_1 -> Add_2_Description ( $_ );
}

$data_table_1 -> print2file ( $outfile  );