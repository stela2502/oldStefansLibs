package X_feature;
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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

X_feature

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

none 

=head3 retrun values

A object of the class X_feature

=cut

sub new {

   my ( $class ) = @_;

   my ( $self, %ref, @regions);

   $self = {
     inTranscriptionOrientation => 1 == 1,
#	 inTranscriptionOrientation => 1 == 0,
     regions => undef,
     refToRegions => \%ref
   };

   bless ($self , $class ) if ( $class eq "X_feature");
   return $self;
}

sub AddNew_RegionEntry{
	my ( $self, $start, $end) = @_;
	my ($hash, @start, @end, $regions);
	$regions = $self->{regions};
	$start[0]	=	$start;
	$end[0]		=	$end;
	$hash = { start => \@start, end => \@end, trsnientMatch => undef};
	push (@$regions,$hash);
	$self->{refToRegions}->{$hash} = $hash;
	return $hash;
}

sub AddTo_RegionItemEntry{
	my ( $self, $regionEntry, $start, $end) =@_;
	my ( $_start, $_end);
	$_start = $regionEntry->{start};
	$_end = $regionEntry->{end};
	push (@$_start, $start);
	push (@$_end, $end);
	return 1;
}

sub AddRegion{

  my ( $self, $gbFeature, $end ) = @_;

  my ( $hash, $start, $regionItem, $refToRegionsItem, $difference, @temp, $_regions);
#  print "\n\n\nX_feature_ AddRegion!\n\n\n";
#   if ( $self->{inTranscriptionOrientation}){
#     if ( defined $gbFeature->isComplement()){#
#	    $gbFeature->ChangeRegion_Complement($end);
#	 }
#  }
  my $gbRegion_forDrawing = $gbFeature->getRegionForDrawing();

  $_regions = $self->{regions};
  
  unless ( defined $self->{regions} ){
     print "X_feature (",$gbFeature->Tag(),") first Region (was not jet defined)!\n";
     my (@regions, $i);
     $i = 0;
     $self->{regions} =\@regions;
     foreach my $regionItem (@$gbRegion_forDrawing){
        print "X_feature AddRegion: (",$gbFeature->Tag(),") start = $regionItem->{start}; end = $regionItem->{end}\n";
		$self->AddNew_RegionEntry($regionItem->{start}, $regionItem->{end});
     }
  }
  else {
	## Jetzt sollte eine entscheidung getroffen werden, ob ein neuer Eintrag noetig wird oder nicht
    my $bestMatches;
	
     foreach $regionItem (@$gbRegion_forDrawing){
		print "needed for test purpose: tag = ",$gbFeature->Tag(),"\n";
        ($refToRegionsItem, $difference) = $self->getBestMatch( $regionItem );
		## Falls es ein V_segment ist besteht die Moeglichkeit, 
		## dass wir ein vorher fehlendes 1. exon haben!
		if ( $refToRegionsItem->{transientMatch} == 1){
			## die regionen ueberlappen!
			$self->AddTo_RegionItemEntry($refToRegionsItem, $regionItem->{start},$regionItem->{end});
		}
		elsif ( $gbFeature->Tag() eq "V_segment"){
			print "For Test purpose V_segment best difference = $difference\n";
			if ( $difference < 200 && $gbFeature->Start < root->mean($refToRegionsItem->{start})){
				$self->AddNew_RegionEntry($regionItem->{start},$regionItem->{end});
			}
		}
		else{
			## jetzt brauchen wir tatsaechlich einen neuen eintrag!
			## Hmm, was jetzt?
			## wir lassen das einfach unter den Tisch fallen!
			## NEIN! Alles wird eingetragen - auch wenn es erst mal schlecht aussieht!
			$self->AddNew_RegionEntry($regionItem->{start},$regionItem->{end});
		}

      }
 }
 #     ## bestMatches->refToInternalRegionItem->'differnece of start and end'->regionItem to be inserted
 #     while( my ($refToInternalRegionItem, $hashOfgbRegionItems_by_difference ) = each %$bestMatches){
 #       @temp = ( sort numeric keys %$hashOfgbRegionItems_by_difference);
 #       while ( ! defined ($temp[0]) && @temp != 0 ){
 #           shift @temp;
 #       }
 #       $difference =  shift @temp;
 #       $refToInternalRegionItem = $self->{refToRegions}->{$refToInternalRegionItem};

 #       $start = $refToInternalRegionItem->{start};
 #       push(@$start, $hashOfgbRegionItems_by_difference->{$difference}->{start});
 #       $end = $refToInternalRegionItem->{end};
 #       push(@$end, $hashOfgbRegionItems_by_difference->{$difference}->{end});
 #       while ( @temp != 0){
 #			#return if ( "V_segment J_segment D_segment" =~ m/$gbFeature->Tag()/ );
 #   		print "HIER WIRD EIN NEUES FRAGMENT EINGEFUEGT!!!!\n";
 #           #print "Aber nicht in diesem Lauf!!\n";
 #          $difference = shift @temp;
 #          my ( $hash, @start, @end );
 #          $start[0] = $hashOfgbRegionItems_by_difference->{$difference}->{start};
 #          $end[0] = $hashOfgbRegionItems_by_difference->{$difference}->{end};
 #          $hash = { start => \@start, end => \@end};
 #          push(@$_regions, $hash);
 #       }
 #     }
 # }

  return 1;
}

sub getBestMatch{
  my ( $self, $regionItem ) = @_;
  my ( $regions, $matches, $difference, $region, @keys );
  $regions = $self->{regions};
  
  foreach $region ( @$regions ){
	$region->{transientMatch} = undef;
    $difference = 0;
    $difference = $self->calculateDifference(root->mean($region->{start}),$regionItem->{start});
    $difference += $self->calculateDifference(root->mean($region->{end}),$regionItem->{end});
	$difference /= 2;
    $matches->{$difference} = $region;
	$region->{transientMatch} = 0 unless ( root->mean($region->{start}) < $regionItem->{end} &&
									root->mean($region->{end}) > $regionItem->{start} );
	$region->{transientMatch} = 1 unless ( defined $region->{transientMatch});
  }
  @keys = sort numeric (keys %$matches );
#  print "best match with difference = $keys[0]\n";
  return $matches->{$keys[0]},$keys[0];
}  


sub numeric {
  return $a <=> $b;
}

sub calculateDifference {
  my ( $self, $a, $b ) = @_;
  my $return = (($a - $b ) ** 2) ** 0.5;
#  print "difference between $a and $b = $return\n";
  return $return;
}

sub getForDrawing{
  my ( $self ,$gbFeatureTag) = @_;
  my ( $regionString,$min ,$max, @return, $regions, $i, $region, $mean, $varianz, $StdAbw, $extreme );
  $regions = $self->{regions};

  $i = 0;
  
#  print "Get For Drawing\n";
  foreach $region (@$regions) {
     ($mean, $varianz, $StdAbw ) = root->getStandardDeviation($region->{start});
	 $min = $mean if ( ! defined $min);
	 $min = $mean if ( $min > $mean);
      $extreme = root->Min($region->{start});
#      print "Get For Drawing: lower = ",$mean - $StdAbw," mean = $mean upper = ",$mean + $StdAbw,"\n";
      my ($hash, $start, $end);
      $start = { lower => $mean - $StdAbw, mean => $mean, upper => $mean + $StdAbw, min => $extreme };

      ($mean, $varianz, $StdAbw ) = root->getStandardDeviation($region->{end});
      $max = $mean unless (defined $max);
	  $max = $mean if ( $max < $mean);
	  $extreme = root->Max($region->{end});
      $end = { lower => $mean - $StdAbw, mean => $mean, upper => $mean + $StdAbw, max => $extreme };
	  if ( $end->{mean} < $start->{mean}){
		my $temp = $end;
		$end = $start;
		$start = $temp;
	  }
		
      $hash = { start => $start, end => $end, gbFeatureTag => $gbFeatureTag };
      $return[$i++] = $hash;
  }
	foreach my $value ( sort byStart @return ){
		$value->{start}->{mean} = int($value->{start}->{mean});
		$value->{end}->{mean} = int($value->{end}->{mean});
		$regionString = "$regionString$value->{start}->{mean}..$value->{end}->{mean},";
	}
	@return = undef;
	chop $regionString;
	$max = int($max);
	$min = int($min);
	print "new gbFeature $gbFeatureTag $regionString\n";
	#print "new gene $min..$max \n";
	$return[0] = gbFeature->new($gbFeatureTag,$regionString);
	$return[0]->Name($gbFeatureTag);
	#$return[1] = gbFeature->new("gene","$min..$max");
    return \@return;
}

sub byStart{
	return $a->{start}->{mean} <=> $b->{start}->{mean};
}

1;
