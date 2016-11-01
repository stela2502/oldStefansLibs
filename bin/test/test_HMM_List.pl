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
use stefans_libs::V_segment_summaryBlot::List4enrichedRegions;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::gbFile::gbFeature;

my ( $hmmListFile ) = @ARGV;

open ( IN ,"<$hmmListFile") or die "Konnte hmmList nicht öffnen!\n";

my ( $gbFileName, $gffFile, $List4enrichedRegions, @temp);

$gbFileName = "DMP1";

$gffFile = gffFile->new();
$List4enrichedRegions = List4enrichedRegions->new();

while ( <IN> ){
	chomp $_;
	next if ($_ =~ m/^#/);
	#next unless ( $_ =~ m/^\/);
	@temp = split ( " ", $_);
	print "Add HMM data $temp[0]\n";
	$List4enrichedRegions->AddData($gffFile->getEnrichedRegions($temp[0]));
}

$List4enrichedRegions->Print();

my $enrichedRegions = $List4enrichedRegions->{enrichedRegions};
my ($celltype, $data_by_celltype, $temp);
print "List4enrichedRegions::Plot: Type of enriched regions: $enrichedRegions\n";
foreach my $data ( @$enrichedRegions){
	unless ( defined $data_by_celltype->{$data->Celltype()}){
		my @temp;
		$data_by_celltype->{$data->Celltype()} = \@temp;
	}
	$celltype = $data->Celltype();
	$temp = $data_by_celltype->{$data->Celltype()};
	push (@$temp, $data);
}

print "List4enrichedRegions: try to obtain number of $celltype specific ChIPs\n";
my $dataArray = $data_by_celltype->{$celltype};
my $i = @$dataArray;
print "$i ChIPs evalautions\n";
$List4enrichedRegions->Print();
$i = @$dataArray[0]->getEnrichedRegions4gbFileString($gbFileName);
#$temp = undef;
$List4enrichedRegions->Print();
$i = 0;
print "deleted the temporary array\n";
$i = @$dataArray[0]->getEnrichedRegions4gbFileString($gbFileName);
$List4enrichedRegions->Print();
print "@$i ChIPs evalautions\n";
foreach my $gFeature (@$i) {
	print "Feature info: \n",$gFeature->getAsGB(),"\n";
	$gFeature->getAsPlottable();
}
print "Und jetzt das ganze nochmal!\n";
$i = @$dataArray[0]->getEnrichedRegions4gbFileString($gbFileName);
$List4enrichedRegions->Print();
print "@$i ChIPs evalautions\n";
foreach my $gFeature (@$i) {
    print "Feature info: \n",$gFeature->getAsGB(),"\n";
	$gFeature->getAsPlottable();
}
