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
 
 use stefans_libs::database::dataset::oligo_array_values;
 use stefans_libs::database_old::array_GFF;
 use stefans_libs::database_old::hybInfoDB;
 use stefans_libs::database::antibodyTable;
 use stefans_libs::histogram;
 use stefans_libs::root;
 
 my ( $array_Hyb, $array_GFF, $hybInfoDB, $hybridizations, $histogram, $antibodyDB, $nimbleID, $data_INPUT, $data_IP, $GFF, $antibody, $i, $infoID);
 
 $array_Hyb = array_Hyb->new();
 $hybInfoDB = hybInfoDB->new();
 $array_GFF = array_GFF->new();
 $antibodyDB = antibodyDB->new();
 
 my $designID = $ARGV[0];
 
 die "Hier bräuchten wir schon den NimbleGeneDesign String!\n" unless ( defined $designID );
 
 ## 1. look if normalized GFF data exists
 
 $hybridizations = $hybInfoDB->selectHybInfosForDesignID_byHybID($designID);
 
 foreach my $hybridization ( values %$hybridizations ){
     unless ( $array_GFF -> DataExists ( $hybridization->{NimbleGen_Id} )) {
         $nimbleID = $hybridization->{NimbleGen_Id};
         $infoID = $hybInfoDB->SelectID_ByHybInfo($hybridization->{NimbleGen_Id});
         $data_INPUT = $data_IP = undef;
 
         foreach my $_hybridization ( values %$hybridizations ){
             if ( $_hybridization->{NimbleGen_Id} eq $hybridization->{NimbleGen_Id} ){
 #                print "Antibody: ",$antibodyDB -> SelectSpecificity_ByID($_hybridization->{Antibody_ID}),"\n";
 
                 ($data_INPUT, $GFF) = $array_Hyb->GetHybValue_forInfoID( $_hybridization->{ID},"norm_OligoID" ) 
                     if ( $antibodyDB -> SelectSpecificity_ByID($_hybridization->{Antibody_ID}) eq "INPUT");
                 ($data_IP, $GFF) = $array_Hyb->GetHybValue_forInfoID( $_hybridization->{ID}, "norm_OligoID" )
                     unless ( $antibodyDB -> SelectSpecificity_ByID($_hybridization->{Antibody_ID}) eq "INPUT");
                 $GFF =  $antibodyDB -> SelectSpecificity_ByID($_hybridization->{Antibody_ID});
 
                 $antibody = $GFF unless ( $GFF eq "INPUT");
             }
         }
         if ( defined ($data_INPUT) && defined ($data_IP)){
 
              $histogram = histogram->new();
              print "$nimbleID : data_IP = $data_IP; data_INPUT = $data_INPUT\n";
              $GFF = $histogram->createGFF_greedy($data_IP, $data_INPUT);
              $i = 0;
              foreach my $keys (keys %$GFF){
                  print "$keys\n";
                  last if ( $i++ > 2);
              }
              $array_GFF->insertData($nimbleID ,"undef","normalized", $GFF );
              print "Normalized GFF data for $nimbleID were inserted!\n";
         }
     }
 }
 
