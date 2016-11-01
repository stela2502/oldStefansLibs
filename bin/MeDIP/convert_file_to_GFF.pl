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

=head1 convert_file_to_GFF.pl

A simple script to convert some kind of ChIP on chip result into a NimbleGene GFF file. All we need if a GFF input file from the same array.

To get further help use 'convert_file_to_GFF.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $sampleGFF_file, @data_files, $NimbleGeneID_column, $Data_column);

Getopt::Long::GetOptions(
	 "-sampleGFF_file=s"    => \$sampleGFF_file,
	 "-data_files=s{,}"    => \@data_files,
	 "-NimbleGeneID_column=s"    => \$NimbleGeneID_column,
	 "-Data_column=s"    => \$Data_column,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $sampleGFF_file) {
	$error .= "the cmd line switch -sampleGFF_file is undefined!\n";
}
unless ( -f $data_files[0]) {
	$error .= "the cmd line switch -data_files is undefined!\n";
}
unless ( defined $NimbleGeneID_column) {
	$NimbleGeneID_column = 'Oligo_id';
	$warn .= "you have not specified a -NimbleGeneID_column and therefore I asume 'Oligo_id'!\n";
}
unless ( defined $Data_column) {
	$Data_column = 'p value';	
	$warn .= "you have not specified a -Data_column and therefore I asume ''p value'\n";
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
 command line switches for convert_file_to_GFF.pl

   -sampleGFF_file       :a sample GFF file that has to be from the same array
   -data_files           :a list of data files, that you want to convert
   -NimbleGeneID_column  :the column title of the nimbleGene oligoIDs
   -Data_column          :the column title of the oligo data

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description, $data_table, $gffSample,$new_data, $gffFile, $dataset, @filename, @new_filename);

$task_description .= 'convert_file_to_GFF.pl';
$task_description .= " -sampleGFF_file $sampleGFF_file" if (defined $sampleGFF_file);
$task_description .= ' -data_files '.join( ' ', @data_files ) if ( defined $data_files[0]);
$task_description .= " -NimbleGeneID_column $NimbleGeneID_column" if (defined $NimbleGeneID_column);
$task_description .= " -Data_column $Data_column" if (defined $Data_column);

$gffFile = gffFile->new();
$gffSample = $gffFile->GetData( $sampleGFF_file, 'preserve_structure');

foreach my $infile ( @data_files){
	unless  ( -f $infile ){
		warn "Sorry, but '$infile' is not a file that I could handle!\n";
		next;
	}
	$data_table = data_table->new();
	$data_table -> read_file ( $infile );
	$data_table -> createIndex( $NimbleGeneID_column );
	$new_data = $data_table -> getAsHash ($NimbleGeneID_column , $Data_column );
	foreach $dataset ( @$gffSample ){
		$dataset->{'value'} = $new_data->{$dataset->{'oligoID'}};
	}
	$gffFile->{'data_handler'} = '';
	@filename = split ( "/", $infile);
	$gffFile->{'data_label'} = $filename[ @filename - 1 ];
	@new_filename = split ( /\./, $filename[ @filename - 1 ]);
	if ( @new_filename > 1 ){
		$new_filename[@new_filename -1 ] = 'gff';
	}
	else {
		push ( @new_filename, 'gff');
	}
	$filename[ @filename - 1 ] = join ( '.',@new_filename );
	$gffFile-> writeData ( $gffSample, join ( "/", @filename) );
}

print "Ready!\n";
