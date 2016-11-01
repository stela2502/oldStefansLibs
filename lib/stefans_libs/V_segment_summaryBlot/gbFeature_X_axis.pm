package gbFeature_X_axis;
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
use stefans_libs::V_segment_summaryBlot::gbFeature_X_axis::X_feature;
use stefans_libs::root;
use stefans_libs::plot::gbAxis;
use stefans_libs::gbFile;


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

gbFeature_X_axis

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

none

=head3 retrun values

A object of the class gbFeature_X_axis

=cut

sub new {

   my ( $class, $length, $end ) = @_;

   my ( $self, %features);

   $self = {
     features => \%features,
     min      => 0,
     max      => $length
   };

   if ( defined $end){
     $self->{min} = $length;
     $self->{end} = $end;
   }

   bless ($self , $class ) if ( $class eq "gbFeature_X_axis");
   return $self;
}

sub Finalize{
	my ( $self, $gbTag) = @_;
	my ( $i ,$plottable, $gbFile, @FeatureArray, $actual );
	
	$plottable = $self->getAsPlottable();
	$gbFile = gbFile->new();
	$i = 0;
	foreach my $featureListRep (@$plottable){
		$actual = @$featureListRep[0]->Tag();
#		print "Just for test purpose: the feature Tag: ",$actual,"\n";
		next unless ($gbTag =~ m/$actual/);
#		print "gbFeature tag $actual will be used (matches $gbTag)\n";
		foreach my $featureRep ( @$featureListRep){
			$FeatureArray[$i++] = $featureRep ;
			print $featureRep->getAsGB();
		}
	}
	$gbFile->Features(\@FeatureArray);
	$gbFile->Length($self->{end});
	$self->{gbFile} = $gbFile;
#	print "\nplotted gbFile ($gbTag):\n",$gbFile->Print(),"\n";
	$self->{start} = $self->{min};
	$self->{end} = $self->{end};
	return 1;
}

	

sub Add_gbFeatures{
  my ( $self, $gbFeatures, $start, $end) =@_;
  die "gbFeature_X_axis needes a aray ref to a array with gbFeatures!\n" unless ( @$gbFeatures[0] =~ m/gbFeature/);
#  print "\ngbFeature_X_axis Add_gbFeatures featureArray = $gbFeatures, start = $start, end = $end\n";
  
  foreach my $gbFeature ( @$gbFeatures) {
    ## Rescale first!
	#unless ( $gbFeature->Tag() eq "V_segment"){
	#	print "Feture not used ",$gbFeature->Tag,"\n";
	#	next;
	#}
#	print "Test gbFeature_X_axis: Add_gbFeature feature end $end > plottable Region end $self->{end} ?\n";
	if ( $end > $self->{end}){ ## jetzt wuss rescaliert werden!
#	   print "JA!!!!!\n";
	   if ( defined $gbFeature->IsComplement()){
#		print "Feature == complement! ( 0 == $end + revers complement)\n";
	       $gbFeature = $gbFeature->ChangeRegion_Complement($end);
		}
		else{
#		   print "Feature = normal! (-$start)\n";
		   $start = -$start;
		   $gbFeature = $gbFeature->ChangeRegion_Add( $start);
		   $start = -$start;
		}
	}	   
	## Insert
#	print "Nach dem Rescale Prozess: tag = ",$gbFeature->Tag," name = ",$gbFeature->Name()," start ", $gbFeature->Start()," end ", $gbFeature->End(),"\n";
	#print "this must not be true: ",$gbFeature->Start," <= $self->{end} && ",$gbFeature->End," >= $self->{start}\n";
	next unless ( $gbFeature->Start <= $self->{end} && $gbFeature->End >= $self->{start});
#	print "\t\tUSED\n";
	$self->Add_gbFeature($gbFeature);
  }
  return 1;
}

sub Add_gbFeature{

   my ( $self, $gbFeature ) = @_;

   unless ( defined $self->{features}->{$gbFeature->Tag()} ){
         $self->{features}->{$gbFeature->Tag()} = X_feature->new();
   }
#   print "Featurename: ",$gbFeature->Name()," start ",$gbFeature->Start()," end ",$gbFeature->End(),"\n";
   $self->{features}->{$gbFeature->Tag()}->AddRegion($gbFeature);
   return 1;
} 

=head2 getAsPlottable

=head3 return values

( 
   
      { 
        start => {lower => mean - stdDev, mean => mean, upper => mean + stdDev, min => minimum}, 
        end   => {lower => mean - stdDev, mean => mean, upper => mean + stdDev, max => maximum},
		gbFeatureTag => $gbFeatureTag
       }
  
)

=cut

sub getAsPlottable{
  my ( $self ) = @_;
  my ( @array, $_features, $gbFeatureTag, $i );

  $_features = $self->{features};
  $i = 0;
  foreach $gbFeatureTag (keys %$_features){
#	 print "Add gbFeature type $gbFeatureTag to the plottables\n";
     $array[$i++] = $_features->{$gbFeatureTag}->getForDrawing($gbFeatureTag);
  }
  return \@array;
}
 

sub Print {
  my ( $self ) = @_;

  my ( $features , $gbFeatureTag , $regions, $print) ;
  $features = $self->{features};
  $print = "";
  foreach $gbFeatureTag (keys %$features){
     $print =  "$print$gbFeatureTag: (\n";
     $regions = $features->{$gbFeatureTag}->getForDrawing();
     foreach my $region ( sort byStart @$regions){
        $print = "$print low_start:$region->{start}->{lower} - mean_start: $region->{start}->{mean} - upper_start: $region->{start}->{upper};\n";
        $print = "$print low_end:$region->{end}->{lower} - mean_end: $region->{end}->{mean} - upper_end: $region->{end}->{upper};\n";
     }
     chop $print;
     $print = "$print)\n";
  }
  print $print ;
}

sub AsTable{
   return "Not possible to convert this complex Data into an array!\n";
}

sub byStart{
   return $a->{start}->{mean} <=> $b->{start}->{mean};
}
   
1;
