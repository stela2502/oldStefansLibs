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
use stefans_libs::database::dataset::oligo_array_values;
use stefans_libs::NimbleGene_config;


caculate("norm_OligoID");
caculate("hyb_OligoID");


sub caculate{
my ( $hyb_OligoID ) = shift;
my ($database, $HybIDs, $hybDataA, $hybDataB, $path, $x );

$x = log(2);
$path = NimbleGene_config::DataPath();
$path = "$path/MAplot";
root->CreatePath($path);
$database = array_Hyb->new();

$HybIDs = $database->GetInfoIDs_forHybType("H3Ac","Rag KO proB", "Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");

print "Starting calculation\n";

for (my $i; $i < @$HybIDs; $i++ ){
	$hybDataA = $database->GetHybValue_forInfoID(@$HybIDs[$i],$hyb_OligoID,"count");
	foreach ( my $a = $i + 1; $a < @$HybIDs; $a++){
		$hybDataB = $database->GetHybValue_forInfoID(@$HybIDs[$a],$hyb_OligoID,"count");
		open (OUT, ">$path/IP_@$HybIDs[$i]_vs_@$HybIDs[$a].$hyb_OligoID.dat") 
			or die "Konnte $path/IP_@$HybIDs[$i]_vs_@$HybIDs[$a].$hyb_OligoID.dat nicht anlegen!\n";
		foreach my $key ( keys %$hybDataA ){
			print OUT  0.5 *  log($hybDataA->{$key} * $hybDataB->{$key}) / $x,"\t",log($hybDataA->{$key} / $hybDataB->{$key}) / $x,"\n";
		}
		close OUT;
		print "Data written as $path/IP_@$HybIDs[$i]_vs_@$HybIDs[$a].$hyb_OligoID.dat\n";
	}
}
$database->clearData();


for (my $i; $i < @$HybIDs; $i++ ){
	$hybDataA = $database->GetHybValue_forInfoID(@$HybIDs[$i] - 1,$hyb_OligoID,"count");
	foreach ( my $a = $i + 1; $a < @$HybIDs; $a++){
		$hybDataB = $database->GetHybValue_forInfoID(@$HybIDs[$a] - 1,$hyb_OligoID,"count");
		open (OUT, ">$path/INPUT_@$HybIDs[$i]_vs_@$HybIDs[$a].$hyb_OligoID.dat") 
			or die "Konnte $path/INPUT_@$HybIDs[$i]_vs_@$HybIDs[$a].$hyb_OligoID.dat nicht anlegen!\n";
		foreach my $key ( keys %$hybDataA ){
		    print OUT  0.5 *  log($hybDataA->{$key} * $hybDataB->{$key}) / $x,"\t",log($hybDataA->{$key} / $hybDataB->{$key}) / $x,"\n";
		}
		close OUT;
		print "Data written as $path/INPUT_@$HybIDs[$i]_vs_@$HybIDs[$a].$hyb_OligoID.dat\n";
	}
}

print "fertig!\n";
}
