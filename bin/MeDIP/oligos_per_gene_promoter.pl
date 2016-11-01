#! /usr/bin/perl -w

#  Copyright (C) 2011-01-19 Stefan Lang

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

=head1 oligos_per_gene_promoter.pl

I ned to know how may oligs did match to a gene promoter for each gene.

To get further help use 'oligos_per_gene_promoter.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::array_analysis::dataRep::Nimblegene_GeneInfo;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $gene_info, $oligo_info, $outfile);

Getopt::Long::GetOptions(
	 "-gene_info=s"    => \$gene_info,
	 "-oligo_info=s"    => \$oligo_info,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( -f $gene_info) {
	$error .= "the cmd line switch -gene_info is undefined!\n";
}
unless ( -f $oligo_info) {
	$error .= "the cmd line switch -oligo_info is undefined!\n";
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
 command line switches for oligos_per_gene_promoter.pl

   -gene_info       :<please add some info!>
   -oligo_info       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/oligos_per_gene_promoter.pl';
$task_description .= " -gene_info $gene_info" if (defined $gene_info);
$task_description .= " -oligo_info $oligo_info" if (defined $oligo_info);
$task_description .= " -outfile $outfile" if (defined $outfile);

open( LOG, ">$outfile.log" )
  or die "could not create the log file $outfile.log\n";
print LOG $task_description . "\n";
close(LOG);

my ( $Nimblegene_GeneInfo, $promoters );
$Nimblegene_GeneInfo = Nimblegene_GeneInfo->new();
$Nimblegene_GeneInfo->GetData($gene_info);
$promoters = $Nimblegene_GeneInfo -> define_promoter_locations ( 2500, 7500);
$promoters -> define_subset ( 'position' , ['chromosome','promoter start','promoter end', 'Gene Symbol' ] );
my $chromosome_based = {};
$promoters -> createIndex ('chromosome');
foreach ( $promoters ->getIndex_Keys('chromosome')  ){
	$chromosome_based -> { $_ } = $promoters ->select_where ( 'chromosome', sub { return 1 if ( $_[0] eq $_); return 0;});
	$chromosome_based -> { $_ } -> define_subset ( 'position' , ['chromosome','promoter start','promoter end', 'Gene Symbol' ] );
}

my ( @line, $i, $oligoID, $line, $chr, $start, $end, $temp, $hash );
$line = 0;
open ( IN , "<$oligo_info") or die "I could not open the oligo info file '$oligo_info'\n$!\n";
open (OUT , ">$outfile") or die "I could not create the outfile '$outfile'\n$!\n";
print OUT  "Gene Symbol	oligoID	chromosome\n";

while ( <IN> ) {
	$line ++;
	next if ( $_ =~ m/^#/ );
	chomp $_;
	@line    = split( "\t", $_ );
	($chr, $start, $end, $oligoID) = ( $line[0], $line[3], $line[4], $line[8]);
	if ( $oligoID =~ m/(CHR[\d\w]+\d+)/ ){
		$oligoID = $1;
	}
	else
	{
		print "$oligo_info line $line stimmt was nicht! ($oligoID) \n";
		next;
	}
	print "we are at chromosome $chr\n";
	unless ( defined $chromosome_based -> { $chr }){
	warn "we do not have information for chr $chr\n" ;
	next;
	}
	$temp = $chromosome_based -> { $chr } -> select_where ( 'position', sub { return 0 unless ( $_[0] eq  $chr); return 1 if ( $_[2] > $start && $_[1] < $end ); return 0 ;});
	for ( $i = 0; $i < @{$temp->{'data'}};$i ++){
		$hash = $temp -> get_line_asHash( $i );
		#print join("; ", keys %$hash)."\n";
		print OUT "$hash->{'Gene Symbol'}\t$oligoID\t$chr\n";
	}
}

close ( IN );
close ( OUT );
print "results written to outfile '$outfile'\n";

