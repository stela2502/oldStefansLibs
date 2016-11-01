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

use stefans_libs::XY_Evaluation;

my $xy = XY_Evaluation->new;
#my $hash = {start => 402000, end => 408000, filename => "Emu_region.png", gbFile => "IgH"};
#my $hash = {start => 2310000, end => 2320000, filename => "Vh_region.png", gbFile => "IgH"};
#my $hash = {start => 221000, end => 231000, filename => "Pax5_promotor.png", gbFile => "pax5"};
my $hash = {start => 35000, end => 45000, filename => "DMP1_promotor.png", gbFile => "DMP"};

my @regions;

$regions[0] = $hash;

#my $pictureData = 
#   $xy->Add2Y_axis(
#        $xy->GetY_axisData(
#           $xy->defineRegions(\@regions,"2005-09-08_RZPD1538_MM6_ChIP","IgH")
#           ,"82356")
#        ,$hash->{start},$hash->{end});

my $pictureData = $xy->defineRegions(\@regions,"2005-09-08_RZPD1538_MM6_ChIP",$hash->{gbFile});
$pictureData = $xy->Add2Y_axis( $xy->GetY_axisData( $pictureData, "68697 #H3Ac proB"), $hash->{start},$hash->{end});
$pictureData = $xy->Add2Y_axis( $xy->GetY_axisData( $pictureData, "82356 #H3K4 proB"), $hash->{start},$hash->{end});
$pictureData = $xy->Add2Y_axis( $xy->GetY_axisData( $pictureData, "68699 #H3K9 proB"), $hash->{start},$hash->{end});




#print "First Line is processed! pictureData = $pictureData\n";

#printPlottable($pictureData);

#$pictureData = $xy->AddX_axis($pictureData,560000,570000);
$pictureData = $xy->AddX_axis($pictureData, $hash->{start},$hash->{end});


#print "Second Line is processed! pictureData = $pictureData\n";

#printPlottable($pictureData);

$xy->Plot($pictureData, $hash->{filename});


sub printPlottable {
  my $pictureData = shift;
  print "Inhalt von pictureData:\n";
  foreach my $key (keys %$pictureData){
     print "\t$key -> $pictureData->{$key}\n";
  }

  my $regionList = $pictureData->{regionList};
  print "Inhalt von regionList:\n";
  foreach my $region ( @$regionList){
    print "$region\n";
    while ( my ( $key, $value) = each %$region){
       print "\t\t$key->$value\n";
    }
  }
}
