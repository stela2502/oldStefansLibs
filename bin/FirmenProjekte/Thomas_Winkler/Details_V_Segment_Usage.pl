#! /usr/bin/perl -w

#  Copyright (C) 2011-11-23 Stefan Lang

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

=head1 Details_V_Segment_Usage.pl

This tool will take one of the data files and create a statistics over the V segment usage.

To get further help use 'Details_V_Segment_Usage.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $target_column, $data_table );

Getopt::Long::GetOptions(
	"-data_table=s"    => \$data_table,
	"-target_column=s" => \$target_column,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $data_table ) {
	$error .= "the cmd line switch -data_table is undefined!\n";
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
 command line switches for Details_V_Segment_Usage.pl

   -data_table       :the data table
   -target_column    :a name for the summary column in the summary table.

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/Details_V_Segment_Usage.pl';
$task_description .= " -data_table $data_table" if ( defined $data_table );
$task_description .= " -target_column $target_column"
  if ( defined $target_column );

## Do whatever you want!

my ($data_object);

####
#Sequence number	Sequence ID	Functionality	V-GENE and allele	V-REGION score	V-REGION identity %	V-REGION identity nt	V-REGION identity % (with ins/del events)	V-REGION identity nt (with ins/del events)	J-GENE and allele	J-REGION score	J-REGION identity %	J-REGION identity nt	D-GENE and allele	D-REGION reading frame	CDR1-IMGT length	CDR2-IMGT length	CDR3-IMGT length	CDR-IMGT lengths	FR-IMGT lengths	AA JUNCTION	JUNCTION frame	Orientation	Functionality comment	V-REGION potential ins/del	J-GENE and allele comment	V-REGION insertions	V-REGION deletions	Sequence
#1	HB5P35S06HOEYB	unproductive (see comment)	Musmus IGHV1-77*01 F	1150	100.0	231/231 nt	Musmus IGHJ3*01 F	213	93.75	45/48 nt	Musmus IGHD2-5*01 F	2	8	8	X	8.8.X	[6.17.38.11]	CAR*GNYYSNYGLL#FAYW	out-of-frame	+	 stop codons				atatcctgcaaggcttctggctacaccttcactgactactatataaactgggtgaagcagaggcctggacagggccttgagtggattggaaagattggtcctggaagtggtagtacttactacaatgagaagttcaagggcaaggccacactgactgcagacaaatcctccagcacagcctacatgcagctcagcagcctgacatctgaggactctgcagtctatttctgtgcaagatgaggaaactactatagtaactacggtctactttctttgcttactggggccaagggactctggtcactgtctctgcag
###

$data_object = data_table->new();
$data_object->read_file($data_table);
## Now I want to get an information about the V_segment!
$data_object->calculate_on_columns(
	{
		'data_column'   => 'V-GENE and allele',
		'target_column' => 'V_id',
		'function' =>
		  sub { $_[0] =~ m/Musmus IGHV(\d+)-(\d+)/; return "$2.$1" }
	}
);
$data_object = $data_object->Sort_by ( [[ 'V_id', 'numeric' ]] );

my @temp = split( "/", $data_table );

my $description_table = $data_object->pivot_table(
	{
		'grouping_column'    => 'V_id',
		'Sum_data_column'    => 'V_id',
		'Sum_target_columns' => [$target_column],
		'Suming_function'    => sub { return scalar(@_) }
	}
);
$description_table = $description_table ->Sort_by (  [[ 'V_id', 'numeric' ]] );
$description_table->calculate_on_columns(
	{
		'data_column'   => 'V_id',
		'target_column' => 'V-GENE',
		'function' =>
		  sub { $_[0] =~ m/(\d+)\.(\d+)/; return "Musmus IGHV$2-$1" }
	}
);
$description_table->define_subset ( 'print' , ['V_id', 'V-GENE', $target_column ]);
$description_table->write_file("$data_table.V_gene_usage", 'print');
@temp = split ( "/", $data_table );
my $filename = pop ( @temp );
my $path = join( "/", @temp );
if ( -f "$path/Makefile" ){
	open ( MAKE, "<$path/Makefile" );
	@temp = <MAKE>;
	close ( MAKE );
	chomp ($temp[0]);
	if ( $temp[0] =~m/$filename.V_gene_usage/ ){
		next;
	}
	$temp[0] .= " $filename.V_gene_usage.xls\n";
	open ( MAKE, ">$path/Makefile" );
	print MAKE join ( "", @temp );
	close ( MAKE );
}
else {
	open ( MAKE, ">$path/Makefile" );
	print MAKE "TARGETS = $filename.V_gene_usage.xls \nsummary:\n\tperl -I /home/stefan/workspace/LabBook/lib/ /home/stefan/LibsNewStructure/bin/tables/merge2tab_separated_files.pl -column_titles 'V_id' 'V-GENE' -infiles \$(TARGETS) -outfile Comparison_V_gene_usage\n";
	close ( MAKE );
}

