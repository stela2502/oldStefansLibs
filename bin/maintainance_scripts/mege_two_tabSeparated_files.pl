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

=head1 compare_two_files.pl

A small script to search in two files for one column and identify the overall differences in column entries and the difference in the times the column entries were present in the different files

To get further help use 'compare_two_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,          $debug,       $database,    $file1,
	$file2,         $key_column1, $key_column2, $outfile,
	@column_names1, @column_names2
);

Getopt::Long::GetOptions(
	"-file1=s"             => \$file1,
	"-file2=s"             => \$file2,
	"-key_column1=s"       => \$key_column1,
	"-key_column2=s"       => \$key_column2,
	"-outfile=s"           => \$outfile,
	'-column_names1=s{,}' => \@column_names1,
	'-column_names2=s{,}' => \@column_names2,
	"-help"                => \$help,
	"-debug"               => \$debug,
	"-database=s"          => \$database
);

my $warn  = '';
my $error = '';

unless ( defined $file1 ) {
	$error .= "the cmd line switch -file1 is undefined!\n";
}
unless ( defined $file2 ) {
	$error .= "the cmd line switch -file2 is undefined!\n";
}
unless ( defined $key_column1 ) {
	$error .= "the cmd line switch -key_column1 is undefined!\n";
}
unless ( defined $key_column2 ) {
	$error .= "the cmd line switch -key_column2 is undefined!\n";
}
unless ( defined $column_names1[0] ) {
	$warn .=
	  "without a list of column names we will select all columns from file1!\n";
	  $column_names1[0] = "ALL";
}
unless ( defined $column_names2[0] ) {
	$warn .=
	  "without a list of column names we will select all columns from file2!\n";
	$column_names2[0] = "ALL";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

warn $warn if ( $warn =~ m/\w/ );

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for compare_two_files.pl

   -file1         :the first tab separated data file
   -file2         :the second tab separated data file

   -key_column1   :the key column name to match on for file1
   -key_column2   :the key column name to match on for file2

   -column_names1 :the column names from file1 to go into the new file (all if not set)
   -column_names2 :the column names from file2 to go into the new file (all if not set)

   -outfile       :the outfile

   -help           :print this help
   -debug          :verbose output
   

";
}

## now we set up the logging functions....

my ($task_description);

$task_description =
    "compare_two_files.pl -file1 $file1 -file2 $file2 -key_column1 "
  . "$key_column1 -key_column2 $key_column2 -outfile $outfile";
$task_description .= " -column_names1 " . join( " ", @column_names1 )
  if ( defined $column_names1[0] );
$task_description .= " -column_names2 " . join( " ", @column_names2 )
  if ( defined $column_names2[0] );

my $data_1 = data_table->new();
$data_1->read_file($file1);
die
"Sorry, but we could not find the column name $key_column1 in the header of file1:\n"
  . join( ";", @{ $data_1->{'header'} } ) . "\n"
  unless ( defined $data_1->Header_Position($key_column1) );
$data_1->createIndex($key_column1);

my $data_2 = data_table->new();
$data_2->read_file($file2);
die
"Sorry, but we could not find the column name $key_column2 in the header of file2:\n"
  . join( ";", @{ $data_2->{'header'} } ) . "\n"
  unless ( defined $data_2->Header_Position($key_column2) );
$data_2->createIndex($key_column2);

## now we are going to create a new table object
my ( $out, @columns_1, @columns_2, $key_col_name, $dataset );
$out = data_table->new();

## And now we are going to define the column names...

if ( $key_column2 eq $key_column1 ) {
	$key_col_name = $key_column1;
}
else {
	$key_col_name = $key_column1 . ' AND ' . $key_column2;
}
$out->Add_2_Header($key_col_name);
$out->createIndex($key_col_name);

if ( defined $column_names1[0] ) {
	foreach my $name (@column_names1) {
		if ( defined $data_1->Header_Position($name) ) {
			foreach ( $data_1->Header_Position($name) ){
				$out->Add_2_Header(@{$data_1->{'header'}}[$_]);
				push( @columns_1, @{$data_1->{'header'}}[$_]);
			}
		}
		else { warn"\n\nwe could not identify the column $name in file 1!\n"}
	}
}
if ( defined $column_names2[0] ) {
	foreach my $name (@column_names2) {
		if ( defined $data_2->Header_Position($name) ) {
			foreach ( $data_2->Header_Position($name) ){
				$out->Add_2_Header(@{$data_2->{'header'}}[$_]);
				push( @columns_2, @{$data_2->{'header'}}[$_]);
			}
		}
		else { warn"\n\nwe could not identify the column $name in file 2!\n"}
	}
}
print "file1: we found the column names: ".join ("; ", @columns_1)."\n".
"file2: we found the column names: ".join ("; ", @columns_2)."\n";

## Now I need to create a subset for the wanted regions

push (@columns_1, $key_column1 ) unless ( join(" ", @columns_1) =~ m/$key_column1/ );
$data_1->define_subset( 'THE_SELECTION', \@columns_1);
my ($hash);
for (my $col_id = 0; $col_id < @{$data_1->{'data'}}; $col_id++) {
	$hash = $data_1->get_line_asHash( $col_id, 'THE_SELECTION' );
	print root::get_hashEntries_as_string ($hash, 3, "the line hash for file1[0]") if ( $col_id == 0);
	unless ( $key_col_name eq $key_column1){
		$hash->{$key_col_name} = $hash->{$key_column1};
		delete($hash->{$key_column1});
	}
	$out->Add_Dataset($hash);
}
push (@columns_2, $key_column2 ) unless ( join(" ", @columns_2) =~ m/$key_column2/ );
$data_2->define_subset( 'THE_SELECTION', \@columns_2);
for (my $col_id = 0; $col_id < @{$data_2->{'data'}}; $col_id++) {
	$hash = $data_2->get_line_asHash( $col_id, 'THE_SELECTION' );
	print root::get_hashEntries_as_string ($hash, 3, "the line hash for file2[0]") if ( $col_id == 0);
	
	unless ( $key_col_name eq $key_column2){
		$hash->{$key_col_name} = $hash->{$key_column2};
		delete($hash->{$key_column2});
	}
	$out->Add_Dataset($hash);
}
$out->Add_2_Description($task_description);
$out->print2file( $outfile);
