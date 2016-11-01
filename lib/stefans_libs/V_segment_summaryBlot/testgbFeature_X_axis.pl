#!/usr/bin/perl
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
use gbFeature_X_axis;
use stefans_libs::gbFile::gbFeature;

my $gbFeature_X_axis = gbFeature_X_axis->new(1000);

my $feature1 = gbFeature->new("test", "200..300,500..600,700..800");
my $feature2 = gbFeature->new("test", "205..255");
my $feature3 = gbFeature->new("test", "505..595");
my $feature4 = gbFeature->new("test", "650..850");

my ($start, $end, @V_segs, @tests);

$gbFeature_X_axis->Add_gbFeature(gbFeature->new("test", "200..300,500..600,700..820"));

for (my $i = 0; $i < 4; $i ++){
	$start = 1000 + 100 *$i;
	$end = 1050 + 100 * $i;
	$V_segs[$i] = gbFeature->new("V_segment","$start..$end");
	$tests[$i] = gbFeature->new("test","$start..$end");	
}

$gbFeature_X_axis->Add_gbFeatures(\@V_segs, 500 , 1500);
#$gbFeature_X_axis->Add_gbFeatures(\@tests, 500 , 1500);
print "\n\JETZT\n\n";
$gbFeature_X_axis->Add_gbFeature( gbFeature->new("V_segment" , "330..350" ));
print "\n\nfertig!\n\n";

#$gbFeature_X_axis->Add_gbFeature($feature1);

#$gbFeature_X_axis->Add_gbFeature(gbFeature->new("test", "200..300,500..600,700..820"));

#$gbFeature_X_axis->Print;

#$gbFeature_X_axis->Add_gbFeature($feature2);

#$gbFeature_X_axis->Print;

#$gbFeature_X_axis->Add_gbFeature($feature3);

#$gbFeature_X_axis->Print;

#$gbFeature_X_axis->Add_gbFeature($feature4);

$gbFeature_X_axis->Finalize("test V_segment");
$gbFeature_X_axis = $gbFeature_X_axis->{gbFile};
$gbFeature_X_axis->Print;

