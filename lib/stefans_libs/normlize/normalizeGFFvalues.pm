package normalizeGFFvalues;
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
use stefans_libs::nimbleGeneFiles::gffFile;
use stefans_libs::database::array_Hyb;
use stefans_libs::database::hybInfoDB;
use stefans_libs::histogram;
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::normlize::normalizeGFFvalues

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

=head3 retrun values

A object of the class normalizeGFFvalues

=cut

sub new {

   my ( $class ) = @_;

   my ( $self, %gff, %median);

   $self = {
      antibody => undef,
      celltype => undef,
      organism => undef,
      mean => undef,
      medians => \%median,
      IP => undef,
      INPUT => undef,
      gff => \%gff,
      histogram => histogram->new,
      gffFile => gffFile->new(),
      hybInfoDB => hybInfoDB->new(),
      array_Hyb => array_Hyb->new()
   };

   bless ($self , $class ) if ( $class eq "normalizeGFFvalues");
   return $self;
}


sub AddDataForHybType{
  my ( $self, $antibody, $celltype, $organism, $designID ) = @_;

  my ($HybIDs, $data, $hybInfo );

  $HybIDs = $self->{array_Hyb}->GetInfoIDs_forHybType($antibody, $celltype, $organism, $designID );
  $self->{antibody} = $antibody;
  $self->{celltype} = $celltype;
  $self->{organism} = $organism;

  my %temp;
  $data = $self->{IP} = \%temp;
  foreach my $hybID ( @$HybIDs ){
      $hybInfo = $self->{hybInfoDB}->SelectHybInfo_ByID($hybID);
      $data->{$hybInfo->{NimbleGen_Id}} = $self->{array_Hyb}->GetHybValue_forInfoID($hybID, "hyb_OligoID", "noCount");
  }
  $data = $self->{INPUT} = \%temp;
  $HybIDs = $self->{array_Hyb}->GetInfoIDs_forHybType("INPUT", $celltype, $organism, $designID );
  foreach my $hybID ( @$HybIDs ){
      $hybInfo = $self->{hybInfoDB}->SelectHybInfo_ByID($hybID);
      $data->{$hybInfo->{NimbleGen_Id}} = $self->{array_Hyb}->GetHybValue_forInfoID($hybID, "hyb_OligoID", "noCount");
  }

  return 1;
}

sub Normalize{
  my ( $self, $outpath) = @_;

  my ( $IP, $INPUT, $gff, @medianArray, $filename,@filename);
  $IP = $self->{IP};
  $INPUT = $self->{INPUT};
  ## Alle GFF Daten erstellen!
  foreach my $IP_NimbleID (keys %$IP ){
       foreach my $INPUT_NimbleID ( keys %$INPUT){
           $self->{gff}->{"IP_$IP_NimbleID-INPUT_$INPUT_NimbleID"} = $self->{histogram}->createGFF_greedy($IP->{$IP_NimbleID}, $INPUT->{$INPUT_NimbleID});
       }
  }
  ## Die Mediane errechnen!
  $gff = $self->{gff};
  foreach my $gffID ( keys %$gff){
     $self->{medians}->{$gffID} = root->median($gff->{$gffID});
     print "median for $gffID = $self->{medians}->{$gffID}\n";
     push ( @medianArray, $self->{medians}->{$gffID});
  }
  $self->{mean} = root->mean(\@medianArray);
  print "\nmean of all medians = $self->{mean}\n";   
  foreach my $gffID ( keys %$gff){
     print "Modify $gffID difference = ", $self->{mean} - $self->{medians}->{$gffID},"\n";
     $self->modifyGFFvalues($self->{gff}->{$gffID}, $self->{mean} - $self->{medians}->{$gffID});
     $filename = "$outpath/$self->{antibody}-$self->{celltype}-$self->{organism}-$gffID.gff";
     @filename = split(" ",$filename);
     $self->{gffFile}->writeData($self->{gff}->{$gffID}, join("_",@filename));
  }
  
  print "fertig!\n";
  return 1;
}


sub modifyGFFvalues{
  my ( $self, $gff_hash, $difference) = @_;

  foreach my $value ( values %$gff_hash){
     $value += $difference;
  }
}




1;
