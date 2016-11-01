package V_segment_summaryBlot;
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
use stefans_libs::gbFile;
use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use stefans_libs::database_old::fileDB;
use stefans_libs::root;
use stefans_libs::database_old::hybInfoDB;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::V_segment_summaryBlot::gbFeature_X_axis;
use stefans_libs::V_segment_summaryBlot::GFF_data_Y_axis;
use stefans_libs::plot;
use stefans_libs::database_old::array_TStat;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

V_segment_summaryBlot

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

=head3 retrun values

A object of the class V_segment_summaryBlot

=cut

sub new {

   my ( $class ) = @_;

my ( $self, $fileDB, $oligo2dnaDB, @oligoBins, $hybInfoDB, $gffFile, %gbData, $array_TStat);

   $fileDB = fileDB->new();
   $oligo2dnaDB = oligo2dnaDB->new;
   $hybInfoDB = hybInfoDB->new;
   $gffFile = gffFile->new;
  

   $self = {
      createSequenceSlides => undef,
#      createSequenceSlides => 1,
      featureArray => undef,
      array_TStat => array_TStat->new(),
      oligoArrays => \@oligoBins,
      nimbleGeneGFF_Files => undef,
      fileDB => $fileDB,
      hybInfoDB => $hybInfoDB,
      gbData => \%gbData,
      gffFile => $gffFile,
      oligo2dnaDB => $oligo2dnaDB
   };

   bless ($self , $class ) if ( $class eq "V_segment_summaryBlot");
   return $self;
}

sub Plot{

  my ( $self, $filename) = @_;
  my ( $data, $dataRows, $plot );
  $data = $self->{gbData};
  foreach my $designID ( keys %$data){
    next unless ( defined $data->{$designID}->{Y_axis});
    $plot = plot->new();
    print "Adding $data->{$designID}->{Y_axis} as Y Axis ($data->{$designID}->{Y_axis}->{min} to $data->{$designID}->{Y_axis}->{max})\n";
    $plot->AddRows($data->{$designID}->{Y_axis});
    print "Adding $data->{$designID}->{X_axis} as X Axis ($data->{$designID}->{X_axis}->{min} to $data->{$designID}->{X_axis}->{max}) \n";
    $plot->AddGbFeatureInfos($data->{$designID}->{X_axis});
    $plot->Plot($filename);
  }
}

sub PrintTable {

 my ( $self, $filename ) = @_;

 open (OUT, ">$filename") or die "Konnte $filename nicht anlegen!\n";

 my ( $data, $dataRows );
 $data = $self->{gbData};
  foreach my $datatype (keys %$data){
     next unless ( defined $data-> {$datatype}->{Y_axis});
     print OUT "$datatype\n";
     $dataRows = $data->{$datatype}->{Y_axis};
     print OUT $dataRows->AsTable();
  }
  close (OUT);
  print "Table written as $filename\n";
}

sub File_containgNimbleID{
  my ( $self, $file ) = @_;

  my( $fileNimbelID );
  $fileNimbelID = $1 if ( $file =~ m/^(\d+) .*/); 
  $fileNimbelID = $1 if ( $file =~ m/^(\d+)$/);
  if ( $file =~ m/\//){
     $fileNimbelID = $1 if ( $file =~ m/(\d+)_/ );
     $fileNimbelID = $1 if ( $file =~ m/IP_(\d+)/);
  }
  return $fileNimbelID;
}

sub AddData{

  my ( $self, $gbFileIdentifier, $GFF_file, $FeatureMatchingStringArray, $regionLength) = @_;

  my ( $nimbleInfos, $nimbleID ,$specificity, $designString, $celltype, $oligoDataHash,
       $fileNameHash, $gbFilename, $fileRef, $pictureData, $gffData, @X_axis_data, $oligoData ,$i, $filename, $useTStatGFF, $tempGFF, @gffFile );
  # 1. get Nimble Information!
  @gffFile = split(" ", $GFF_file);
  for (my $i = 0; $i < @gffFile; $i++){
    if ( $gffFile[$i] =~ m/[\w\d]+/ ){
      $GFF_file = $gffFile[$i];
      last;
    }
  }

  $nimbleInfos = $self->{hybInfoDB}->getAllByNimbleID();
  $useTStatGFF = 1 == 1 unless ( $GFF_file =~ m/\//);
  $tempGFF = $self->File_containgNimbleID($GFF_file);

  foreach $nimbleID (keys %$nimbleInfos){
#     print "$GFF_file???????\n";
     print "NimbelGeneID ($GFF_file -> $tempGFF) könnte $nimbleID sein!\n";
     if ( $tempGFF == $nimbleID ){
         print "$nimbleID ist ein Teil von $GFF_file!\n";
     $i = "cy5" if ( $nimbleInfos->{$nimbleID}->{cy5}->{TemplateType} =~ m/^E/);
     $i = "cy3" if ( $nimbleInfos->{$nimbleID}->{cy3}->{TemplateType} =~ m/^E/);
#     print "We are looking for the $i hybridization\n";
     ($specificity, $designString, $celltype) = 
     ( $nimbleInfos->{$nimbleID}->{$i}->{Antibody}, 
       $nimbleInfos->{$nimbleID}->{$i}->{ArrayDesign},
       $nimbleInfos->{$nimbleID}->{$i}->{Celltype});
     print "\$specificity $specificity, \$designString $designString, \$celltype $celltype\n";
     last;
     }

  }
  # 2. get gbFileInfo
  $fileRef = root->getPureSequenceName($gbFileIdentifier);
  $fileNameHash = $self->{fileDB}->SelectFiles_ByDesignId($designString);
  foreach my $temp (keys %$fileNameHash ){
#     print "V_seg AddData $temp\n";
     $filename = $temp if ( $temp =~m/$fileRef->{MySQL_entry}/);
  }
#  print "Filename from Design $designString for MySQL_entry string $fileRef->{MySQL_entry} is $filename\n";

  $regionLength = 2000 unless ( defined $regionLength);

  $pictureData = $self->Define_gbSlices($filename, $FeatureMatchingStringArray, $regionLength, $designString);

  unless ( $useTStatGFF ){
    $gffData = $self->{gffFile}->GetData($GFF_file);
    print "$gffData = $self->{gffFile} -> GetData($GFF_file);\n";
  }
  if ($useTStatGFF ){
    $gffData = $self->getTStatGFF_data($specificity,$celltype, $designString);
    print "$gffData = $self->getTStatGFF_data($specificity,$celltype, $designString);\n";
  }

  $oligoData = $pictureData->{OligoInfo};
  $i = 0;
  foreach my $oligoBox (@$oligoData){
       foreach my$oligoInfoHash (@$oligoBox){
#          print "Oligo location: $oligoInfoHash->{mean} value = $gffData->{$oligoInfoHash->{oligoID}}, oligoID = $oligoInfoHash->{oligoID}\n";
          $X_axis_data[$i++] = {mean => $oligoInfoHash->{mean}, value => $gffData->{$oligoInfoHash->{oligoID}}, oligoID => $oligoInfoHash->{oligoID}}
            if ( $oligoInfoHash->{oligoCount} < 5);
       }
  }
  unless ( defined $pictureData->{Y_axis} ){
     $pictureData->{Y_axis} = GFF_data_Y_axis->new();
  }
  $pictureData->{Y_axis}->AddDataforChipType($designString,$specificity,$celltype,\@X_axis_data,$regionLength *2);
  print "Y_axis min = ",$pictureData->{Y_axis}->{min}," max = ",$pictureData->{Y_axis}->{max},"\n";
}

sub getTStatGFF_data{
  my ( $self, $antibody, $celltype, $designID) = @_;

  my ( $organism);

  ($organism, $celltype ) = split(":", $celltype); 

#  ($organism, $celltype ) = $self->{array_TStat}->GetValue_forInfoID($self->{array_TStat}->getInfo($antibody,$celltype ,$organism,$designID), "tstat");
  ($organism, $celltype ) = $self->{array_TStat}->GetValue_forInfoID($self->{array_TStat}->getInfo($antibody,$celltype ,$organism,$designID), "gff_summary");

  foreach my $value ( values %$organism){
      $value = exp($value / 1.442695);
  }
   return $organism;

}

=head2 AddgbFile

=head3 atributes

[0]: the complete filename of the genabnk formated Sequence to evaluate

[1]: the string matching to the V_segment gbFeatures, that should be evaluated

=head3 return value

none

=cut

sub AddgbFile {

  my ( $self, $filename, $searchString_Array ) = @_;

  my ( $gbFile, $arrayRef, $filenameRef );

  $self->{gbFile} = gbFile->new($filename);
  
  $arrayRef = $self->{gbFile}->SelectMatchingFeatures($searchString_Array);
#  $arrayRef = $self->{gbFile}->SelectNotMatchingFeatures($searchString_Array);
  $self->{featureArray} = $arrayRef; #$gbFile->SelectMatchingFeatures($searchString_Array);
  $arrayRef = @$arrayRef;
  
  return $self->{gbFile}->Name() , $filename;

}

sub Define_gbSlices{

  my ( $self, $mysqlFileEntry, $searchString_Array, $sliceLength, $designString ) = @_;

  ## alle gbFeatures werden als V_segmente behandelt und auf den Anfang des 2. Exons zentriert, falls es 2 exons gibt.
  ## falls keine 2 exons defineiert waren fehlt nämlich das 1..

  return $self->{gbData}->{"$mysqlFileEntry"} if ( defined $self->{gbData}->{"$mysqlFileEntry$designString"});

  my ( $features, $gbFeature, $region, $internalRegion, $gbFileName, $filename, @temp, $i );

  ($gbFileName, $filename) = $self->AddgbFile( $mysqlFileEntry, $searchString_Array );

  warn "No gbFile found!\n" unless (defined $gbFileName);
  open (OUT ,">select_sequences_in_rage_2400-5100_10100-13000_38000-40000.sh") 
       or die "konnte Datei select_sequences_in_rage_2400-5100_10100-13000_38000-40000.sh nicht anlegen!\n";

  $features = $self->{featureArray};
  $i = @$features;
  
  print "Define_gbSlices start with gbFile ->$filename<- ($i features) \n";
  $i = 0;
  foreach $gbFeature ( @$features){
#     print "gbFeature:  $gbFeature\n";
#     next unless (ref($gbFeature) eq "gbFeature");

    if ( $gbFeature =~ m/gbFeature/ ) {
#    if ( $gbFeature->Tag() eq "V_segment" ) {
        my ($hash, @_features);
#        print "Define_gbSlices got a ",$gbFeature->Tag(),"\n";
        $region = $gbFeature->getRegionForDrawing();
        if ( @$region == 2 ){
          ## Leader + 2.exon
          $hash->{start} = @$region[1]->{start} - $sliceLength;
          $hash->{end} = @$region[1]->{start} + $sliceLength;
          $_features[0] = $gbFeature->ChangeRegion_Add(- $hash->{start});
          $hash->{featureList} = \@_features;
          $internalRegion->{$hash->{start}} = $hash;
        }
        if ( @$region == 1){
          ##  2.exon
          $hash->{start} = @$region[0]->{start} - $sliceLength;
          $hash->{end} = @$region[0]->{start} + $sliceLength;
          $_features[0] = $gbFeature->ChangeRegion_Add(- $hash->{start});
          $hash->{featureList} = \@_features;
          $internalRegion->{$hash->{start}} = $hash;
        }
        next unless ( defined $self->{createSequenceSlides});
        @temp = ($hash->{start} + 2400,  $hash->{start} + 5100,
                 $hash->{start} + 10100, $hash->{start} + 13000,
                 $hash->{start} + 38000, $hash->{start} + 40000);
        $self->{gbFile}->setLocus("BN000872#$i:$temp[0]-$temp[1]");
        $self->{gbFile}->WriteAsGB("./BN000872_slides$i-1-$temp[0]-$temp[1]",$temp[0],$temp[1]);
        $self->{gbFile}->WriteAsFasta("./BN000872_slides$i-1-$temp[0]-$temp[1].fasta","BN000872_slides$i-1-$temp[0]-$temp[1]",$temp[0],$temp[1]);
        $self->{gbFile}->setLocus("BN000872#$i:$temp[2]-$temp[3]");
        $self->{gbFile}->WriteAsGB("./BN000872_slides$i-2-$temp[2]-$temp[3]",$temp[2],$temp[3]);
        $self->{gbFile}->WriteAsFasta("./BN000872_slides$i-2-$temp[2]-$temp[3].fasta","BN000872_slides$i-1-$temp[2]-$temp[3]",$temp[2],$temp[3]);
        $self->{gbFile}->setLocus("BN000872#$i:$temp[4]-$temp[5]");
        $self->{gbFile}->WriteAsGB("./BN000872_slides$i-3-$temp[4]-$temp[5]",$temp[4],$temp[5]);
        $self->{gbFile}->WriteAsFasta("./BN000872_slides$i-3-$temp[4]-$temp[5].fasta","BN000872_slides$i-1-$temp[4]-$temp[5]",$temp[4],$temp[5]);
        $i++;
     }
   }
   # jetzt sind alle wichtigen Regionen definiert!

   # hole die oligoInfos!!
   my (%hash, @OligoData);

   $self->{gbData}->{"$mysqlFileEntry"} = \%hash;
   $self->{gbData}->{"$mysqlFileEntry"}->{X_axis} = gbFeature_X_axis->new($sliceLength * 2);
   print "X_axismin =  $self->{gbData}->{\"$mysqlFileEntry\"}->{X_axis}->{min}; max = $self->{gbData}->{\"$mysqlFileEntry$designString\"}->{X_axis}->{max}\n";
   $self->{gbData}->{"$mysqlFileEntry"}->{OligoInfo} = \@OligoData;
   $i = 0;
   foreach my $start ( keys %$internalRegion ){
        ## X Achse generieren
        $gbFeature = $internalRegion->{$start}->{featureList};
#        print "InternalRegion gbFeature = @$gbFeature[0]\n";
        $self->{gbData}->{"$mysqlFileEntry"}->{X_axis}->Add_gbFeature(@$gbFeature[0]);

        ## Oligo Liste generieren
        $OligoData[$i++] = $self->GetOligoArray($designString, $gbFileName, $start, $internalRegion->{$start}->{end});
   }
   return $self->{gbData}->{"$mysqlFileEntry"};
}

sub GetOligoArray {
  my ( $self, $designString, $gbFileName, $start, $end ) = @_;

  my ($oligoLocationArray, @return, $mean, $i);

  $oligoLocationArray = $self->{oligo2dnaDB}->GetOligoLocationArray($designString, $gbFileName);
  $i = 0;

  foreach my $hash ( @$oligoLocationArray){
     $mean = (@$hash[1] + @$hash[2]) / 2;
     if ( $mean < $end && $mean > $start ){
        @$hash[0] = $1 if ( @$hash[0] =~ m/(CHR\d+[RP]\d+)/);
        $return[$i++] = {mean=> $mean - $start, oligoID => "@$hash[0]", oligoCount => @$hash[5] } ;
     }
  }
  return \@return;
}


1;
