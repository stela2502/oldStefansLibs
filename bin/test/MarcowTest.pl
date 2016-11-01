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
use stefans_libs::statistics::HMM;
#use stefans_libs::statistics::HMM::new_histogram;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;

my $hmm = HMM->new();
#$hmm->MarcowTest();

my $gffFile = gffFile->new();
#my $gffFilename = "H3K9Me3-Rag_KO_proB-Mus_musculus-2005-09-08_RZPD1538_MM6_ChIP_IterationNr10.gff";
my $gffFilename = "77585_ratio.gff";

#$hmm->CalculateHMM();
my ( $h0, $h1, $phi0) = $hmm->{UMS}->UMS($gffFile->GetData($gffFilename),"testAB","testCell");
print "$h0, $h1, $phi0 :\n";
print "$h0->{title}, $h1->{title}\n";
$h0->printHistogram2file("test_h0.txt");
$h1->printHistogram2file("test_h1.txt");

#my $histo = new_histogram->new("all");
#my @all = ( 1,2,3,4,5,6,7,8,9,0,1,3,2,3,5,3,5,4,7,6,5,5,4,3,2,2,1,3,4,6,7,8,9,5,3);
#my @all_real;
#foreach my $value (@all){
#	for (my $i = 0; $i <= $value; $i++){
#		push (@all_real, $value / ($i +1));
#	}
#}
#my $i = 0;
#my @part;
#foreach my $value ( @all_real ){
#	push (@part, $value) if ( int($i / 2) == $i / 2);
#	$i++;
#}
#
##@part = (4,7,6,5,5,4,3,2,2,1,3,4,6,7,8,9,5,3);
#$histo->CreateHistogram(\@all,undef,100);
#
#
#my $new = new_histogram->new("partial_copy_of_all");
#$new->copyLayout($histo);
#
#my $bins = $histo->{bins};
#root::print_hashEntries($bins,4,"the bins structure of the whole histo\n");
#$bins = $new->{bins};
#root::print_hashEntries($bins,4,"the bins structure of the partial histo\n");
#
#$new ->CreateHistogram(\@part);
#my @list = ($histo, $new);
#
#my @things2do = qw( removeNullstellen ScaleSumToOne);
#
#$new->printHistogram2file("test_part.txt");
#$histo->printHistogram2file("test_all.txt");
#
#foreach my $cmd (@things2do){
#	$list[0]->$cmd();
#	$list[0]->printHistogram2file("test-$list[0]->{title}.txt");
#	$list[1]->$cmd();
#	$list[1]->printHistogram2file("test-$list[1]->{title}.txt");
#}

#my $gffFile = gffFile->new();
#my $gffFilename = "/Mass/ArrayDaten/ArrayDaten4/GFF/67888_ratio.gff";



#$histo->CreateHistogram($gffFile->GetData($gffFilename),undef,100);

#$histo->printHistogram2file("Histo.csv");

#$histo->ScaleSumToOne();

#$histo->printHistogram2file("RescaledHisto.csv");

#print "Histogram of constant 10/1 values between -5 an 5 is witten to Histo.csv\n"; 
#$hmm->MarcowTest();
