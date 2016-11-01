#! /usr/bin/perl -w

#  Copyright (C) 2011-02-15 Stefan Lang

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

=head1 plot_rsIDs_on_chromosomes.pl

takes a list of rsIDs and plots the location of these SNPs.

To get further help use 'plot_rsIDs_on_chromosomes.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::MyProject::compare_SNP_2_Gene_expression_results;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @rsIDs, $outfile );

Getopt::Long::GetOptions(
	"-rsIDs=s{,}" => \@rsIDs,
	"-outfile=s"  => \$outfile,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $rsIDs[0] ) {
	$error .= "the cmd line switch -rsIDs is undefined!\n";
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
 $errorMessage
 command line switches for plot_rsIDs_on_chromosomes.pl

   -rsIDs       :<please add some info!> you can specify more entries to that
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/plot_rsIDs_on_chromosomes.pl';
$task_description .= ' -rsIDs ' . join( ' ', @rsIDs ) if ( defined $rsIDs[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

open( LOG, ">$outfile.log" )
  or die "I could not create the log file $outfile.log\n$!\n";
print LOG $task_description;
close(LOG);

if ( -f $rsIDs[0] ) {
	my @temp;
	open( IN, "<$rsIDs[0]" );
	while (<IN>) {
		chomp($_);
		push( @temp, split( /\s/, $_ ) );
	}
	close(IN);
	shift(@temp) unless ( defined $temp[0] );
	@rsIDs = @temp;
}

my ($data_obj);

$data_obj = compare_SNP_2_Gene_expression_results->new();
foreach (@rsIDs) {
	$data_obj->{'SNP_count'} -> {$_} = 1 ;
}

my $SNP_on_Chromosome =
  $data_obj->plot_chromosome_distribution( $outfile, 'H_sapiens' );
$SNP_on_Chromosome->print2file($outfile);

## Do whatever you want!

