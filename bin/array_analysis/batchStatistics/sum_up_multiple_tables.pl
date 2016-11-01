#! /usr/bin/perl -w

#  Copyright (C) 2010-12-13 Stefan Lang

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

=head1 sum_up_multiple_tables.pl

The tool makes it possible to create summary tables for one variable 
in a set of PDF result tables. Therefore I need the ID of the result table, 
the path to each of the PDF creation folders, 
the name of the key columns in the respective tables 
and the name of the varibale columns.

To get further help use 'sum_up_multiple_tables.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @pdf_folders, $table_id, @index_columns,
	@data_columns, $outfile );

Getopt::Long::GetOptions(
	"-pdf_folders=s{,}"   => \@pdf_folders,
	"-table_id=s"         => \$table_id,
	"-index_columns=s{,}" => \@index_columns,
	"-data_columns=s{,}"  => \@data_columns,
	"-outfile=s"          => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -d $pdf_folders[0] ) {
	$error .= "the cmd line switch -pdf_folders is undefined/not accessible!\n";
}
unless ( defined $table_id ) {
	$error .= "the cmd line switch -table_id is undefined!\n";
}
unless ( defined $index_columns[0] ) {
	$error .= "the cmd line switch -index_columns is undefined!\n";
}
unless ( defined $data_columns[0] ) {
	$error .= "the cmd line switch -data_columns is undefined!\n";
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

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
	
The tool makes it possible to create summary tables for one variable 
in a set of PDF result tables. Therefore I need the ID of the result table, 
the path to each of the PDF creation folders, 
the name of the key columns in the respective tables 
and the name of the varibale columns.
	
 $errorMessage
 command line switches for sum_up_multiple_tables.pl

   -pdf_folders       :<please add some info!> you can specify more entries to that
   -table_id       :<please add some info!>
   -index_columns       :<please add some info!> you can specify more entries to that
   -data_columns       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ( $task_description, $results_table, $temp_table, $pdf_folder, $dataset, $line_hash );

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/sum_up_multiple_tables.pl';
$task_description .= ' -pdf_folders ' . join( ' ', @pdf_folders )
  if ( defined $pdf_folders[0] );
$task_description .= " -table_id $table_id" if ( defined $table_id );
$task_description .= " -index_columns '" . join( "' '", @index_columns ) ."'"
  if ( defined $index_columns[0] );
$task_description .= " -data_columns '" . join( "' '", @data_columns )."'"
  if ( defined $data_columns[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

open ( LOG, ">$outfile.log" ) or die "I could not create the log file $outfile.log\n";
print  LOG $task_description;
close ( LOG );

$results_table = data_table->new();
foreach (@index_columns) {
	$results_table->Add_2_Header($_);
	$results_table->createIndex($_);
}

foreach $pdf_folder (@pdf_folders) {
	next unless ( -d $pdf_folder );
	unless (
		-f $pdf_folder . "/Tables/" . sprintf( '%04d', $table_id ) . ".xls" )
	{
		warn
" I could not open the table file yoiu were interested in for folder $pdf_folder\n";
		next;
	}
	$temp_table = data_table->new();
	$temp_table->read_file(
		$pdf_folder . "/Tables/" . sprintf( '%04d', $table_id ) . ".xls" );
	$error = '';
	foreach (@index_columns) {
		$error .=
"the index column '$_' is not defined in the table for path $pdf_folder\n"
		  unless ( defined $temp_table->Header_Position($_) );
	}
	foreach (@data_columns) {
		$error .=
"the data column '$_' is not defined in the table for path $pdf_folder\n"
		  unless ( defined $temp_table->Header_Position($_) );
	}
	Carp::confess( "Sorry, but the file '"
		  . $pdf_folder
		  . "/Tables/"
		  . sprintf( '%04d', $table_id )
		  . ".txt' did not contain the expected columns:\n"
		  . $error. "Instead we had this table:\n".$temp_table->AsString()."\n" )
	  if ( $error =~ m/\w/ );
	foreach ( @data_columns ){
		$results_table->Add_2_Header( "$pdf_folder ".$_);
	}
	for ( my $i = 0; $i < @{$temp_table->{'data'}}; $i ++ ){
		$line_hash = $temp_table->get_line_asHash ( $i );
		$dataset = {};
		foreach ( @index_columns ){
			$dataset -> {$_} = $line_hash->{$_};
		}
		foreach (@data_columns) {
			$dataset -> {"$pdf_folder ".$_ } = $line_hash->{$_};
		}
		$results_table->AddDataset ( $dataset );
	}
}

$results_table -> write_file ( $outfile );
