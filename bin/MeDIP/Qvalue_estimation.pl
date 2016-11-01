#! /usr/bin/perl -w

#  Copyright (C) 2010-06-15 Stefan Lang

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

=head1 Qvalue_estimation.pl

the script calls the R qvalue library to estimate the q_values for list of p_values. The p_values are expected to be stored as -log10 values in a gffFile.

To get further help use 'Qvalue_estimation.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::array_analysis::correlatingData::qValues;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;

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

unless ( defined $infile) {
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
 	this script reads from a gff file containing -log10(p_value) entries,
 	converts these entries into normal p_values, uses the R-qvalue package
 	to estimate FDR and finally creates a new gff file that now contains 
 	FDR values for each and every oligo in the original gff file.
 	
 $errorMessage
 command line switches for Qvalue_estimation.pl

   -infile        :the gff file containing the -log10(p_value) entries that you want to check
   -outfile       :the new gff file

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'Qvalue_estimation.pl';
$task_description .= " -infile $infile" if (defined $infile);
$task_description .= " -outfile $outfile" if (defined $outfile);

print "CMD:\n$task_description\n";

my ( $qValues, $gffFile, $gffSample, @p_values, $dataset, $stat_obj );
open ( LOG ,">$outfile.log") or die "could not create the log file '$outfile.log'\n";
print LOG $task_description."\n";

$gffFile = gffFile->new();
$gffSample = $gffFile->GetData( $infile , 'preserve_structure');

## create the initial data
foreach $dataset ( @$gffSample ){
	push ( @p_values, 10**-$dataset->{'value'});
}
$stat_obj = qValues->new();
$qValues = $stat_obj->calculateTest( \@p_values);

for (my $i = 0; $i < @$gffSample; $i++ ){
	@$gffSample[$i]->{'value'} = @{$qValues->{q_values}}[$i];
}
$gffFile->{'data_handler'} = '';
my @filename = split ( "/", $infile);
$gffFile->{'data_label'} = $filename[ @filename - 1 ]. "_q-values";

$outfile .= ".gff" unless ($outfile =~ m/\.gff$/ );
$gffFile-> writeData ( $gffSample, $outfile );

print LOG "overall q_value = $qValues->{'overall_q_value'}\n";
print LOG "Cumulative number of significant calls:\n\n".$qValues->{'summary_table'}->AsString()."\n";

close ( LOG );
print "All q_values are stored in the gff file $infile\nAdditional information can be found in the log file '$outfile.log'\n";