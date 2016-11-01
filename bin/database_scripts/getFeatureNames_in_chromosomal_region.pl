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

=head1 getFeatureNames_in_chromosomal_region.pl

A script to select the faeture_names of a (supplied) feature name in a chromosomal region. The NCBI genome string has to be supplied

To get further help use 'getFeatureNames_in_chromosomal_region.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;

my ( $chr, $start, $end, $tag, $help, $debug, $genomeStr);

Getopt::Long::GetOptions(
	 "-chr=s"			 => \$chr,
	 "-tag=s"			 => \$tag,
	 "-start=s"			 => \$start,
	 "-end=s"            => \$end,
	 "-NCBI=s"           => \$genomeStr,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

unless ( defined $chr ){
	print helpString( "you have to supply a chromosome name (-chr)!" ) ;
	exit;
}
unless ( defined $start ){
	print helpString( "you have to supply the start position (-start)!" ) ;
	exit;
}
unless ( defined $chr ){
	print helpString( "you have to supply the end position (-end)!" ) ;
	exit;
}
unless ( defined $genomeStr ){
	print helpString( "you have to supply the NCBI genome string (-NCBI)!" ) ;
	exit;
}

if ( $help ){
	print helpString( ) ;
	exit;
}

my $genomeDB = genomeDB->new('genomeDB', $debug);

my $chromsomesTable = $genomeDB->GetDatabaseInterface_for_Organism ( $genomeStr );

my $gbFeaturesArray = $chromsomesTable -> get_features_in_chr_region_by_type ( { 'chr' => $chr, 'start' => $start, 'end' => $end, 'tag' => $tag } );

print "gene symbol\tstart on chromosome [bp]\tend on chromosome [bp]\n";
foreach ( @$gbFeaturesArray ){
	print $_->Name,"\t",$_->Start(),"\t",$_->End(),"\n";
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for getFeatureNames_in_chromosomal_region.pl
   -chr            :the chromosome name ( 1,2,3 or Y,X)
   -tag            :the gbFeature tag that should be used (default to 'gene')
   -start          :the chromosomal start in bp
   -end            :the chromosomal end in bp
   -NCBI           :the NCBI genome tag string (e.g. 'M_musculus')
   -help           :print this help
   -debug          :verbose output


"; 
}