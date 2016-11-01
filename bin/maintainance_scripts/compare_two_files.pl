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


my ( $help, $debug, $database, $file1, $file2, $column_name1, $column_name2, $outfile);

Getopt::Long::GetOptions(
	 "-file1=s"    => \$file1,
	 "-file2=s"    => \$file2,
	 "-column_name1=s"    => \$column_name1,
	 "-column_name2=s"    => \$column_name2,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug,
	 "-database=s"       => \$database
);

my $warn = '';
my $error = '';

unless ( defined $file1) {
	$error .= "the cmd line switch -file1 is undefined!\n";
}
unless ( defined $file2) {
	$error .= "the cmd line switch -file2 is undefined!\n";
}
unless ( defined $column_name1) {
	$error .= "the cmd line switch -comlumn_name1 is undefined!\n";
}
unless ( defined $column_name2) {
	$error .= "the cmd line switch -column_name2 is undefined!\n";
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
 command line switches for compare_two_files.pl

   -file1       :<please add some info!>
   -file2       :<please add some info!>
   -column_name1       :<please add some info!>
   -column_name2       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   -database       :the database name (default='genomeDB')
   

"; 
}

## now we set up the logging functions....

my ( $task_description );


$task_description = "compare_two_files.pl -file1 $file1 -file2 $file2 -column_name1 $column_name1 -column_name2 $column_name2 -outfile $outfile";

my $data_1 = data_table->new();
$data_1 -> read_file($file1);
die "Sorry, but we could not find the column name $column_name1 in the header of file1:\n".join(";",@{$data_1->{'header'}})."\n"
unless ( defined $data_1->Header_Position($column_name1));
$data_1 -> createIndex( $column_name1 );

my $data_2 = data_table->new();
$data_2 -> read_file($file2);
die "Sorry, but we could not find the column name $column_name2 in the header of file2:\n".join(";",@{$data_2->{'header'}})."\n"
unless ( defined $data_2->Header_Position($column_name2));
$data_2 -> createIndex( $column_name2 );

my $not_in_file1;
my $not_in_file2;
my $in_both_files;
my $keys;
my @lines;

foreach my $col_f1 ( $data_1->getIndex_Keys($column_name1) ){
	$keys->{$col_f1} = 1;
	@lines = undef;
	@lines = $data_2->get_rowNumbers_4_columnName_and_Entry($column_name2, $col_f1 );
	unless ( defined $lines[0] ){
		$not_in_file2->{$col_f1} = 1;
		print "the oligo $col_f1 is not defined in file_2\n";
	}
	else {
		$in_both_files->{$col_f1} = {'file_2' => 0, 'file_1' => 0 } unless (defined  $in_both_files->{$col_f1});
		$in_both_files->{$col_f1}->{'file_2'} = scalar ( @lines );
	}
}

foreach my $col_f1 ( $data_2->getIndex_Keys($column_name2) ){
	$keys->{$col_f1} = 1;
	@lines = undef;
	@lines = $data_1->get_rowNumbers_4_columnName_and_Entry($column_name1, $col_f1 );
	unless ( defined $lines[0] ){
		$not_in_file1->{$col_f1} = 1;
		print "the oligo $col_f1 is not defined in file_1\n";
	}
	else {
		$in_both_files->{$col_f1} = {'file_2' => 0, 'file_1' => 0 } unless (defined  $in_both_files->{$col_f1});
		$in_both_files->{$col_f1}->{'file_1'} = scalar ( @lines );
	}
}

my $out = data_table->new();
my $dataset;
$out->Add_2_Header ("oligoID");
$out->Add_2_Header ("in_file1 '$file1'");
$out->Add_2_Header ("in_file2 '$file2'");
$out->Add_2_Header ("hits in file1");
$out->Add_2_Header ("hits in file2");

foreach my $tag ( keys %$keys ){
	$dataset = {'oligoID' => $tag};
	if ($not_in_file1->{$tag}){
		$dataset->{"in_file1 '$file1'"} = 'NO';
	}
	else{
		$dataset->{"in_file1 '$file1'"} = 'YES'; 
	}
	if ($not_in_file2->{$tag}){
		$dataset->{"in_file2 '$file2'"} = 'NO';
	}
	else{
		$dataset->{"in_file2 '$file2'"} = 'YES'; 
	}
	$dataset->{"hits in file1"} = $in_both_files->{$tag}->{'file_1'};
	$dataset->{"hits in file2"} = $in_both_files->{$tag}->{'file_2'};
	$out->Add_Dataset( $dataset );
}
$out->Add_2_Description ( "amount of rows not in file1 ". scalar( keys %$not_in_file1));
$out->Add_2_Description ( "amount of rows not in file2 ". scalar( keys %$not_in_file2));
$out->Add_2_Description ("program_call\t$task_description\n");

$out->print2file( $outfile);
