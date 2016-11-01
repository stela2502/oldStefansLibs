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

=head1 Identify_CpG_SNPs.pl

A spider to quuery the NCBI SNPdb web portal and identifys the SNPs that could change a CpG site

To get further help use 'Identify_CpG_SNPs.pl -help' at the comman line.

=cut

use Getopt::Long;
use WWW::Mechanize;

use strict;
use warnings;

my $VERSION = 'v1.0';

my ( $help, $debug, @rsIDs, $outfile );

Getopt::Long::GetOptions(
	"-rsIDs=s{,}"   => \@rsIDs,
	"-outfile=s" => \$outfile,

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
 command line switches for Identify_CpG_SNPs.pl

   -rsIDs         :The rsIDs you want to check
   -outfile       :the outfile where you find your results

   -help           :print this help
   -debug          :verbose output
   

";
}

## now we set up the logging functions....

my ( $task_description, $web_interface, $data, $before, $after, $A, $B,
	$A_effect, $B_effect, $count );

## and add a working entry
$count = 0;
$task_description =
  "Identify_CpG_SNPs.pl-rsIDs " . join( ", ", @rsIDs ) . " -outfile $outfile";

$web_interface = WWW::Mechanize->new( 'stack_depth' => 0 );
open( OUT, ">$outfile" ) or die "could not craete outfile '$outfile'\n";

foreach my $rsID (@rsIDs) {
	if ( $rsID =~ m/[rR][Ss](\d+)/ ) {
		$web_interface->get(
			"http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=" . $1 );
		#print "we analyze the SNP $rsID\n";
		$data = $web_interface->content();
		next unless ( defined $data );
		if ( $data =~
m/<td >([CGTA])\/([CGTA])<\/td><td ><FONT  *face="courier" *size="-2">([acgt]+)<\/FONT><\/td><td *><FONT *face="courier" *size="-2">([acgt]+)</
		  )
		{


			( $A, $B, $before, $after ) = ( $1, $2, $3, $4 );
			print "I got the two alles $A and $B with the flanking sequences '$before' and '$after'\n";
			$A_effect = &check_4_CpG_effect( $A, $before, $after );
			$B_effect = &check_4_CpG_effect( $B, $before, $after );
			if ( defined $A_effect ) {
				print OUT "$rsID\tmajor allele ($A)\t$A_effect\t$before$A$after\n";
				$count++;
			}
			if ( defined $B_effect ) {
				print OUT "$rsID\tminor allele ($B)\t$B_effect\t$before$B$after\n";
				$count++;
			}
		}
	}
	else {
		warn "Sorry, but I can not parse the rsID $rsID\n";
	}
}

print "we got $count alleles, that affect CpG sites\n";
close(OUT);
if ( $count > 0 ) {
	print "The results were written to '$outfile'\n";
}

sub check_4_CpG_effect {
	my ( $allel, $before, $after ) = @_;
	#print "we got the last char in string '$before' is "
	#  . substr( $before, length($before) - 1, 1 )
	#  . " - we have an influence if $allel eq G and the car was a c\n"
	#  ;
	#print "and the first char in '$after' is " . substr( $after, 0, 1 ) . "\n";
	if ( $allel eq "G" ) {
		if ( substr( $before, length($before) - 1, 1 ) eq "c" ) {
			print "\tupstream CpG\n";
			return "upstream CpG";
		}
	}
	elsif ( $allel eq "C" ) {
		if ( substr( $after, 0, 1 ) eq "g" ) {
			print "\tdownstream CpG\n";
			return "downstream CpG";
		}
	}
	return undef;
}
