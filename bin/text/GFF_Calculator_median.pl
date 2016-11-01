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
use stefans_libs::statistics::newGFFtoSignalMap;
use stefans_libs::database::dataset::oligo_array_values;
use stefans_libs::database_old::array_GFF;
use stefans_libs::histogram;
use stefans_libs::root;

die "USAGE:\n",
    "atribute[0] = HybInfo.ID of the first array hybridization data set\n",
    "atribute[1] = HybInfo.ID of the second array hybridization data set\n",
    "atribute[2] = filenameBase for the resulting GFF file\n\n",
    "foreach oligo the pending_GFF = log2( first_array_value / second_array_value )\n",
    "all oligo values are rescaled that the median( SUM( GFF ) ) = 0\n\n"
    unless ( @ARGV == 3);
   
print "First HybID = $ARGV[0], second HybID = $ARGV[1], Gff_information = $ARGV[2]\n";

my ($newGFFtoSignalMap, $array_Hyb, $histogram, $data1, $data2, $oligosLocationArray, $gff, $median, $path );

$newGFFtoSignalMap = newGFFtoSignalMap->new();
$array_Hyb = array_Hyb->new();
$histogram = histogram->new();

$oligosLocationArray = $newGFFtoSignalMap->AddData( { 'what' => "gff_nimble", 'nimbleID' => 68705 , 'designID' => "2005-09-08_RZPD1538_MM6_ChIP"} );


$data1 = $array_Hyb->GetHybValue_forInfoID($ARGV[0],"hyb_OligoID","no count");
$data2 = $array_Hyb->GetHybValue_forInfoID($ARGV[1],"hyb_OligoID","no count");

$gff = $histogram->createGFF_greedy($data1, $data2);
$median = root->median($gff);

print "Median( SUM ( <pending_GFF> ) ) = $median\n";

foreach my $oligo ( @$oligosLocationArray ){
   $oligo->{'value'} = $gff->{$oligo->{'oligoID'}} - $median;
   $oligo->{'identifier'} = $ARGV[2];
}

$path = NimbleGene_config->DataPath();
$path = "$path/newGFF_values";
root->CreatePath($path);

$newGFFtoSignalMap->ExportData($oligosLocationArray, $path );

print "Fertig!\n";
