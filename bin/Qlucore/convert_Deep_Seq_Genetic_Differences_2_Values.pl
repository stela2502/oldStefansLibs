#! /usr/bin/perl -w

#  Copyright (C) 2010-10-20 Stefan Lang

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

=head1 convert_Deep_Seq_Genetic_Differences_2_Values.pl

The sript will take a tab separated file containing the column 'refSeq' that shows the refSeq nucleotide at that position and a set of samples that contain a double nucleotide that defined there configuration. The script will create a outfile that will show the affymetrix SNP call nomenclature including the clumns Allele_A and Allele_B.

To get further help use 'convert_Deep_Seq_Genetic_Differences_2_Values.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, $outfile, @p4Cs );

Getopt::Long::GetOptions(
	"-infile=s"  => \$infile,
	"-outfile=s" => \$outfile,
	"-p4Cs=s{,}" => \@p4Cs,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $p4Cs[0] ) {
	$error .= "the cmd line switch -p4Cs is undefined!\n";
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
 $errorMessage
 command line switches for convert_Deep_Seq_Genetic_Differences_2_Values.pl

   -infile   :a tab separated table file containing at least 
              one column named 'refSeq' and a set of sample columns.
   -outfile  :the name of the outfile
   -p4Cs     :a pattern, that will allow to select the sample columns 
              or a list of sample names

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'convert_Deep_Seq_Genetic_Differences_2_Values.pl';
$task_description .= " -infile $infile" if ( defined $infile );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -p4Cs " . join( " ", @p4Cs ) if ( defined $p4Cs[0] );

## Do whatever you want!
my ( $data_table, @sample_headers, @values, $a, $b, $colA, $colB );

$data_table = data_table->new();
$data_table->read_file($infile);
$data_table->Add_2_Header('Allele A');
$data_table->Add_2_Header('Allele B');
$colA = $data_table->Header_Position('Allele A');
$colB = $data_table->Header_Position('Allele B');

if ( scalar(@p4Cs) == 1 ) {
	foreach ( @{ $data_table->{'header'} } ) {
		push( @sample_headers, $_ ) if ( $_ =~ m/$p4Cs[0]/ );
	}
}
else {
	@sample_headers = @p4Cs;
}
print "we use the samples " . join( " ", @sample_headers ) . "\n";
$data_table->define_subset( 'samples', [@sample_headers] );
@sample_headers = $data_table->Header_Position ( 'samples' );

for ( my $i = 0 ; $i < @{ $data_table->{'data'} } ; $i++ ) {
	@values = $data_table->get_row_entries( $i, 'samples' );
	#print "we have selected the values ".join(" ", @values)."\n";
	foreach (@values) {
		next unless ( defined $_);
		if ( $_ =~ m/([agctAGCT])([agctAGCT])/ ) {
			( $a, $b ) = ( $1, $2 );
			#print "A = $a, B = $b\n";
			last unless ( $a eq $b );
		}
	}
	@values = $data_table->get_row_entries( $i, 'refSeq' );
	if ( $b eq $values[0] ) {
		$b = $a;
		$a = $values[0];
	}
	@{ @{ $data_table->{'data'} }[$i] }[$colA] = $a;
	@{ @{ $data_table->{'data'} }[$i] }[$colB] = $b;
	foreach (@sample_headers) {
		@{ @{ $data_table->{'data'} }[$i] }[$_] = &encode( $a, $b, @{ @{ $data_table->{'data'} }[$i] }[$_]);
	}
}

$data_table->print_as_gedata($outfile);


sub encode{
	my ( $a, $b, $value ) = @_;
	return 0 if (! defined $value || $value eq "" );
	return 0 if ( $value eq $a.$a );
	return 1 if ( $value eq $a.$b || $value eq $b.$a);
	return 2 if ( $value eq $b.$b );
	return -1;
}