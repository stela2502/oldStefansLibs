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

=head1 classify_promoter_CpG_content.pl

Distribution, silencing potential and evolutionary impact of promoter DNA methylation in the human genome - pp457 - 466

Michael Weber, Ines Hellmann, Michael B Stadler, Liliana Ramos, Svante Pääbo, Michael Rebhan & Dirk Schübeler

doi:10.1038/ng1990

To get further help use 'classify_promoter_CpG_content.pl -help' at the comman line.

=cut

use Getopt::Long;

use strict;
use warnings;

my ( $help, $debug, $seq, $windowsize, $step, $geneName, $promoterLength,
	$region );

Getopt::Long::GetOptions(
	"-geneName=s"          => \$geneName,
	"-promoterLegth=s"     => \$promoterLength,
	"-region_to_cluster=s" => \$region,
	"-promoterSeq=s"       => \$seq,
	"-windowSize=s"        => \$windowsize,
	"-stepSize=s"          => \$step,
	"-help"                => \$help,
	"-debug"               => \$debug
);

if ($help) {
	print helpString();
	exit;
}
my @region = split( ";", $region );

unless ( scalar(@region) == 2 ) {
	@region = ( -5000, 10000 );
}

$seq    = uc($seq);
@region = split( "\n", $seq );
$seq    = join( "", @region );
unless ( $seq =~ m/^[ACTG]+$/ ) {

	print helpString(
"Sorry, there were not recognized bases in the sequence. I know only ATCG!\n$seq\n"
	);
	exit;
}

my ( @classification, $C, $G, $CpG, $GC, $data );
$windowsize     ||= 500;
$step           ||= 5;
$promoterLength ||= 10000;

my $sub_seq;
for ( my $i = 0 ; $i + $windowsize < length($seq) ; $i += $step ) {
	$sub_seq = substr( $seq, $i, $windowsize );
	my $hash = {
		'class' => calculate_CpG_qualifier_for_seq($sub_seq),
		'start' => $i,
		'end'   => $i + $windowsize,
		'GC'    => GC_content($sub_seq),
		'seq' => $sub_seq
	};
	push( @classification, $hash->{'class'} );
	$data->{ $hash->{'class'} } = $hash;
}
unless ( scalar(@classification) > 0 ) {
	##oops the seq was shorter than 500bp!
	my $hash = {
		'class' => calculate_CpG_qualifier_for_seq($seq),
		'start' => 0,
		'end'   => length($seq),
		'GC'    => GC_content($seq),
		'seq' => $seq
	};
	push( @classification, $hash->{'class'} );
	$data->{ $hash->{'class'} } = $hash;
}


my ($max) = ( sort { $b <=> $a } @classification );
print "we got a max CPG classifier of $max and a GC content of ",
  GC_content($seq), "\n";
  
print "the max hit ranged from $data->{$max}->{start} to $data->{$max}->{end} and had a GC content of $data->{$max}->{GC}\nseq = $data->{$max}->{seq}\n";

if ( $max < 0.48 ) {
	print "this seq was classified as having LOW CpG content\n";
}
elsif ( $max > 0.75 && GC_content($seq) > 0.55 ) {
	print "this seq was classified as having HIGH CpG content\n";
}
else {
	print "this seq was classified as having MEDIUM CpG content\n";
}

exit();

sub calculate_CpG_qualifier_for_seq {
	my ($seq) = @_;
	my ( $CpG, $G, $C );
	$CpG = get_amount_of_pattern_in_seq( "CG", $seq );
	$C   = get_amount_of_pattern_in_seq( "C",  $seq );
	$G   = get_amount_of_pattern_in_seq( "G",  $seq );
	return 0 if ( $G * $C  == 0);
	return ( $CpG * length($seq) ) / ( $G * $C );
}

sub GC_content {
	my ($seq) = @_;
	my $G = get_amount_of_pattern_in_seq( "G", $seq );
	my $C = get_amount_of_pattern_in_seq( "C", $seq );
	return ( $G + $C ) / length($seq);
}

sub get_amount_of_pattern_in_seq {
	my ( $pattern, $seq ) = @_;
	my $patternLength = length($pattern);
	my $result        = 0;
	for ( my $i = 0 ; $i < length($seq) ; $i++ ) {
		$result++ if ( substr( $seq, $i, $patternLength ) eq $pattern );
	}
	return $result;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for classify_promoter_CpG_content.pl
   
   -promoterSeq    :the sequence of the promoter (only AGTC!)
   -windowSize     :the widowsize to use (default 500bp)
   -stepSize       :the stepSize to shift the window (default 5bp)
   -help           :print this help
   -debug          :verbose output

";
}

