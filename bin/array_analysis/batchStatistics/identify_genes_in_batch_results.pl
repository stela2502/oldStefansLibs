#! /usr/bin/perl -w

#  Copyright (C) 2011-01-14 Stefan Lang

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

=head1 identify_genes_in_batch_results.pl

A simple tool, that will give you a list of genes, that are mentioned in a batch results file.

To get further help use 'identify_genes_in_batch_results.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::file_readers::stat_results;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @infiles, $outfile, $p_value_cutoff );

Getopt::Long::GetOptions(
	"-infiles=s{,}"     => \@infiles,
	"-outfile=s"        => \$outfile,
	"-p_value_cutoff=s" => \$p_value_cutoff,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infiles[0] ) {
	$error .= "the cmd line switch -infiles is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $p_value_cutoff ) {
	$p_value_cutoff = 0.05;
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
 command line switches for identify_genes_in_batch_results.pl

   -infiles       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>
   -p_value_cutoff       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/identify_genes_in_batch_results.pl';
$task_description .= ' -infiles ' . join( ' ', @infiles )
  if ( defined $infiles[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -p_value_cutoff $p_value_cutoff"
  if ( defined $p_value_cutoff );

open ( LOG, ">$outfile.log") or die "I could not create the log file '$outfile.log'\n";
print LOG $task_description."\n";
close ( LOG );
my ( $stat_results, $data, $result );
$stat_results = stat_results->new();
for ( my $i = 0 ; $i < @infiles ; $i++ ) {
	$data = $stat_results->read_file( $infiles[$i] );
	$data =
	  $data->select_where( 'p-value',
		sub { return 1 if ( $_[0] <= $p_value_cutoff ); return 0; } )
	  ;
	foreach ( @{ $data->getAsArray('Gene Symbol') } ) {
		$result->{$_} = 1;
	}
}

open ( OUT, ">$outfile") or die "I could not create the outfile '$outfile'\n";
print OUT join("\n",sort keys %$result );
close ( OUT );

