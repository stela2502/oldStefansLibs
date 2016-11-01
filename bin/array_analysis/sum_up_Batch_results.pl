#! /usr/bin/perl -w

#  Copyright (C) 2010-11-25 Stefan Lang

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

=head1 sum_up_Batch_results.pl

The script will read a bunch of Batch results and add the Phenotype to the real results removing all data values, that leadt to the p_value.

To get further help use 'sum_up_Batch_results.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::stat_results;


use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $outfile, @remove_from_phenotype, $p_cutoff);

Getopt::Long::GetOptions(
	 "-infiles=s{,}"    => \@infiles,
	 "-outfile=s"    => \$outfile,
	 "-remove_from_phenotype=s{,}"    => \@remove_from_phenotype,
	 "-p_cutoff=s"    => \$p_cutoff,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $remove_from_phenotype[0]) {
	#no problem - then I will not remove anything...
}
unless ( defined $p_cutoff) {
	$p_cutoff = 1;
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
 command line switches for sum_up_Batch_results.pl

   -infiles       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>
   -remove_from_phenotype       :<please add some info!> you can specify more entries to that
   -p_cutoff       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'sum_up_Batch_results.pl';
$task_description .= ' -infiles '.join( ' ', @infiles ) if ( defined $infiles[0]);
$task_description .= " -outfile $outfile" if (defined $outfile);
$task_description .= ' -remove_from_phenotype '.join( ' ', @remove_from_phenotype ) if ( defined $remove_from_phenotype[0]);
$task_description .= " -p_cutoff $p_cutoff" if (defined $p_cutoff);

my ( $path, $filename, $results_table, $data_table, $stat_results, @temp, $hash );
$stat_results = stat_results->new();

$results_table = data_table->new();
foreach ( 'phenotype', 'Probe Set ID', 'Gene Symbol', 'p-value' ){
	$results_table -> Add_2_Header($_);
}

foreach my $infile ( @infiles ){
	next unless ( -f $infile );
	$data_table = $stat_results->read_file($infile);
	@temp = split ( "/", $infile);
	$filename = pop( @temp );
	$path = join("/", @temp);
	foreach ( @remove_from_phenotype ){
		$filename =~ s/$_//;
	}
	for ( my $i = 0; $i < @{$data_table->{'data'}}; $i ++ ){
		$hash = $data_table ->get_line_asHash( $i  );
		$results_table -> AddDataset( { 
			'phenotype' => $filename, 
			'Probe Set ID' => $hash->{'Probe Set ID'}, 
			'Gene Symbol' => $hash->{'Gene Symbol'}, 
			'p-value' => $hash->{'p-value'}
		});
	}
}
$results_table->write_file( $outfile );

