#! /usr/bin/perl -w

#  Copyright (C) 2010-08-18 Stefan Lang

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

=head1 SNPs_compare_to_DGI.pl

a script that only works on black using the localy stored DGI results. Tries to understand, if a list of rsIDs is somehow more often associated with a nominal significance than a random SNP list for each phenotype file separately.

To get further help use 'SNPs_compare_to_DGI.pl -help' at the command line.

=cut

use Getopt::Long;
use strict;
use warnings;

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
elsif ( -f $rsIDs[0] ) {
	open( IN, "<$rsIDs[0]" );
	@rsIDs = undef;
	while (<IN>) {
		chomp $_;
		push( @rsIDs, split( /[ \t]/, $_ ) );
	}
	close(IN);
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( -d "/storage/sandbox/shared/ins30/meta_gwama_new_phenotypes/" ) {
	$error .=
"Sorry, but we need some statistical result in the (not existing) path\n  /storage/sandbox/shared/ins30/meta_gwama_new_phenotypes/\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

my $temp;
foreach ( @rsIDs ){
	$temp ->{ $_} = 1 if ( $_ =~ m/^rs[\d]+/);
}
@rsIDs = ( keys %$temp);

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for SNPs_compare_to_DGI.pl

   -rsIDs     :a list of rsIDs that you would like to analyze. The list can be stored in a file.
   -outfile   :a file to store the results to

   -help  :print this help
   -debug :verbose output
   

";
}

my ($task_description);

$task_description .= 'SNPs_compare_to_DGI.pl';
$task_description .= ' -rsIDs ' . join( ' ', @rsIDs ) if ( defined $rsIDs[0] );
$task_description .= " -outfile $outfile" if ( defined $outfile );

my ( @files, $file );
## Do whatever you want!
opendir( DIR, "/storage/sandbox/shared/ins30/meta_gwama_new_phenotypes/" );
@files = readdir(DIR);
closedir(DIR);
open( OUT, ">$outfile" )
  or die "Sorry, but I could not create the outfile $outfile\n$!\n";
foreach $file (@files) {
	next unless ( $file =~ m/\.txt$/ );
	print OUT &process_p_values_file(
		"/storage/sandbox/shared/ins30/meta_gwama_new_phenotypes/",
		$file, \@rsIDs );
	last if ( $debug);
}
close(OUT);

sub process_p_values_file {
	my ( $path, $file, $rsID_array ) = @_;
	open( IN, $path . $file )
	  or die "sorry, but I could not open the infile $path$file\n$!\n";
	my ( $data, @line, $ok, @SNP_LIST );
	while (<IN>) {
		chomp $_;
		@line = split( " ", $_ );
		unless ($ok) {
			$ok = 1 if ( $line[2] eq "SNP" && $line[10] eq "P_VAL" );
			warn
				"sorry, but we do not support a file with the header\n$_\n"
			  unless ($ok);
			next;
		}
		$data->{ $line[2] } = $line[10];
		push( @SNP_LIST, $line[2] );
	}
	close(IN);
	my (
		$genotyped,   $SNP,          $report,
		$significant, @compare_dist, $temp,
		$max_SNP,     $p_value,      $number
	);
	$genotyped = 0;
	$report    = '';
	foreach $SNP (@$rsID_array) {
		next unless ( $SNP =~ m/rs/ );
		if ( defined $data->{$SNP} ) {
			$genotyped++;
			if ( $data->{$SNP} <= 0.05 ) {
				$report .= "$file\t$SNP\t$data->{$SNP}\n";
				$significant++;
			}
		}
	}
	$max_SNP = scalar(@SNP_LIST);
	return "No significant SNPs in file $file\n" unless ( $report =~ m/\w/ );

	for ( my $rep = 0 ; $rep < 100000 ; $rep++ ) {
		$temp = 0;
		for ( my $ok_SNP = 0 ; $ok_SNP < $genotyped ; $ok_SNP++ ) {
			$temp++
			  if ( $data->{ $SNP_LIST[ int( rand($max_SNP) ) ] } <= 0.05 );
		}
		push( @compare_dist, $temp );
	}
	( $p_value, $number ) =
	  &estimated_p_value( $significant, \@compare_dist, 'higher' );
	$report .= "probabillity that the result is random:\t$number\n";
	return $report;
}

sub estimated_p_value {
	my ( $value, $list, $mode ) = @_;
	my ( @temp, $p_value, $number );
	warn "the dataset is empty!\n" unless ( @$list > 0 );
	warn "we have a missing value in the data array\n"
	  if ( !defined @$list[0] );
	Carp::confess("please fix that - the \$value was not defined!\n")
	  unless ( defined $value );
	@temp = ( sort { $a <=> $b } @$list );
	if ( $mode eq "higher" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( $temp[$i] >= $value ) {
				$p_value = ( scalar(@temp) - $i ) / scalar(@temp);
				last;
			}
		}
		$p_value = 1 / scalar(@temp)
		  unless ( defined $p_value );
		$p_value = 1 / scalar(@temp) if ( $p_value == 0 );
		$number  = $p_value;
		$p_value = sprintf( '%.1e', $p_value );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value, $number;
	}
	if ( $mode eq "lower" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( $temp[$i] >= $value ) {
				$p_value = 1 - ( scalar(@temp) - $i ) / scalar(@temp);
				last;
			}
		}
		$p_value = 1 / scalar(@temp)
		  unless ( defined $p_value );
		$p_value = 1 / scalar(@temp) if ( $p_value == 0 );
		$number  = $p_value;
		$p_value = sprintf( '%.1e', $p_value );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value, $number;
	}
	if ( $mode eq "both" ) {
		for ( my $i = 0 ; $i < @temp ; $i++ ) {
			if ( !defined $temp[$i] ) {
				warn "we do not have an entry for the dataset at pos $i!\n";
			}
			if ( $temp[$i] >= $value ) {
				$p_value = ( scalar(@temp) - $i ) / scalar(@temp);
				last;
			}
		}
		$p_value = 1 - $p_value if ( $p_value > 0.5 );
		$p_value = 1 / scalar(@temp)
		  unless ( defined $p_value );
		$p_value = 1 / scalar(@temp) if ( $p_value == 0 );
		$number  = $p_value;
		$p_value = sprintf( '%.1e', $p_value * 2 );
		if ( $p_value =~ m/([\.\d]+)e-(\d+)/ ) {
			$p_value = "\$$1e^{-$2}\$";
		}
		return $p_value, $number;
	}
	Carp::confess(
		"Sorry, but we only support the modes higher, lower or both\n");
}
