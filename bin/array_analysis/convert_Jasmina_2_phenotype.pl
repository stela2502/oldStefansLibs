#! /usr/bin/perl -w

#  Copyright (C) 2010-06-07 Stefan Lang

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

=head1 convert_Jasmina_2_phenotype.pl

A tool to convert Jasminas genotype informations into my phenotype file format.

To get further help use 'convert_Jasmina_2_phenotype.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
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
 command line switches for convert_Jasmina_2_phenotype.pl

   -infile       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'convert_Jasmina_2_phenotype.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);


## Do whatever you want!
my ( $data, $data_table_in, $data_table_out, $file_format_error, @missing_columns);
$data_table_in = data_table->new();
$data_table_in -> read_file ( $infile );
## I expect the file to contain the column titles
# PATIENT MARKER  ALLELE1 ALLELE2 MENDEL

foreach ( qw(PATIENT MARKER  ALLELE1 ALLELE2 MENDEL)){
	unless ( defined $data_table_in->Header_Position($_) ){
		push (@missing_columns, $_ );
	}
}
if ( $missing_columns[0] =~ m/\w/ ){
	die "Sorry, but we miss the columns ".join( "; ",@missing_columns)." in the input file!\n";
}
 
$data_table_out = data_table->new();
my ( $ALLELE1, $ALLELE2, $MARKER, $PATIENT, $last_marker  );
$ALLELE1 = $data_table_in->Header_Position( 'ALLELE1');
$ALLELE2 = $data_table_in->Header_Position( 'ALLELE2');
$PATIENT = $data_table_in->Header_Position( 'PATIENT');
$MARKER  = $data_table_in->Header_Position( 'MARKER');

foreach my $line ( @{$data_table_in->{'data'}}){
	$last_marker = @$line[$MARKER] unless ( defined $last_marker);
	unless ($last_marker eq @$line[$MARKER] ){
		unless ($data_table_out->Header_Position( 'rs_id' )){
			$data_table_out -> Add_2_Header ( 'rs_id' ) ;
			foreach ( keys %$data ){
				$data_table_out -> Add_2_Header ( $_ );
			}
		}
		$data -> {'rs_id'} = $last_marker;
		$data_table_out->Add_Dataset( $data );
		$last_marker = @$line[$MARKER];
		$data = undef;
	}
	$data -> { @$line[$PATIENT] } = "@$line[$ALLELE1]/@$line[$ALLELE2]";
}

unless ($data_table_out->Header_Position( 'rs_id' )){
	$data_table_out -> Add_2_Header ( 'rs_id' ) ;
	foreach ( keys %$data ){
		$data_table_out -> Add_2_Header ( $_ );
	}
}
$data -> {'rs_id'} = $last_marker;
$data_table_out->Add_Dataset( $data );
$data = undef;

$data_table_out-> print2file ( $outfile );
