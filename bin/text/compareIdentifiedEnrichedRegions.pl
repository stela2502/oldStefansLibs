#! /usr/bin/perl
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

use strict;
use stefans_libs::root;
use stefans_libs::V_segment_summaryBlot::List4enrichedRegions;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::gbFile;

my ( $file1, $file2 ) = @ARGV;

my $gffFile = gffFile->new;
my ( $gbFeature1, $inTheSet, $gbFeature2, $data1, $data2, $enrichedRegionHash1, $enrichedRegionHash2 );

$enrichedRegionHash1 = $gffFile->getEnrichedRegions($file1);
$enrichedRegionHash2 = $gffFile->getEnrichedRegions($file2);

## jetzt muessen erst mal die Vh segmente raussortiert werden!

my $gbFile = gbFile->new();
$gbFile->AddGbfile("/Mass/ArrayData/Evaluation/Files/BN000872.gb");
my @searchArray = ("V_segment");

my $gbFeatures = $gbFile->SelectMatchingFeatures_by_Tag(\@searchArray);
my $V_segment = @$gbFeatures;

#print "IN File /Mass/ArrayData/Evaluation/Files/BN000872.gb $V_segment V_segments were found!\n";
#root::print_hashEntries($gbFile,2);

print "regions start\tregion end\tfilename\tenriched in\tnot enriched in\n";

foreach my $filename ( sort keys %$enrichedRegionHash1){
	next unless ($filename =~  m/BN000872/  );
	$data1 = $enrichedRegionHash1->{$filename};
	$data2 = $enrichedRegionHash2->{$filename};
	## und jetzt muss man das vergleichen...
	## sowohl in 1 als auch in 2 müssen regionen sein, die nicht im anderen sind...	
	foreach $gbFeature1 (@$data1){
		foreach $V_segment (@$gbFeatures){
			#warn "evaluation V_segment ", $V_segment->getAsGB();
                        if ( $V_segment->Match($gbFeature1->Start(), $gbFeature1->End() , 0 )  ){
                                print $gbFeature1->Start(),"\t",$gbFeature1->End(),"\t$filename",
                                "\tmatches a V_segment!\n";
				next;
                        }

		}

		$inTheSet = 1 == 0;
		foreach $gbFeature2 (@$data2){
			$inTheSet = 1 == 1 if ( $gbFeature2->Match($gbFeature1->Start(), $gbFeature1->End() , 0 ) );
		}
		print $gbFeature1->Start(),"\t",$gbFeature1->End(),"\t$filename",
		"\t$enrichedRegionHash1->{info}->{CellType} $enrichedRegionHash1->{info}->{AB} ",
		"\t$enrichedRegionHash2->{info}->{CellType} $enrichedRegionHash2->{info}->{AB}\n" unless ($inTheSet); 
	}
	foreach $gbFeature2 (@$data2){
                foreach $V_segment (@$gbFeatures){
                        if ( $V_segment->Match($gbFeature2->Start(), $gbFeature2->End() , 0 )  ){
				print $gbFeature2->Start(),"\t",$gbFeature2->End(),"\t$filename",
				"\tmatches a V_segment!\n";
				next;
			}
                }

		$inTheSet = 1 == 0;
                foreach $gbFeature1 (@$data1){
                        $inTheSet = 1 == 1 if ( $gbFeature1->Match($gbFeature2->Start(), $gbFeature2->End() , 0 ) );
                }
                print $gbFeature2->Start(),"\t",$gbFeature2->End(),"\t$filename",
                "\t$enrichedRegionHash2->{info}->{CellType} $enrichedRegionHash2->{info}->{AB} ",
                "\t$enrichedRegionHash1->{info}->{CellType} $enrichedRegionHash1->{info}->{AB}\n" unless ($inTheSet);
        }
		
}

