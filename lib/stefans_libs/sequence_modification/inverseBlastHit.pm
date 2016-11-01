package inverseBlastHit;
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

sub new {

   my ( $class, $blastLineRef, $gbFeatureRef ) = @_;

   my ( $self);

   $self = {
     blastLineRef => undef, ## gbFeature
     gbFeatureRef => undef,  ## gbFeature
     start        => undef,
     end          => undef
   };

   bless ($self , $class ) if ( $class eq "inverseBlastHit");
#   print "inverseBlastHit blastLineRef = $blastLineRef\n";
   $self->BLAST_Line($blastLineRef);
   $self->GBfeature($gbFeatureRef);
   return $self;
}

sub BLAST_Line{
  my ( $self, $blastLineRef ) = @_;
  ## blastLineRef hast to be a gbFeature ref!
  if ( defined $blastLineRef ) {
     $self->{blastLineRef} = $blastLineRef if ( ref($blastLineRef) eq  "gbFeature");
  }
  return $self->{blastLineRef};
}

sub Name {
  my ( $self) =  @_;

  my ( $gbFeatureRef_Array, $return);
  return $self->{name} if ( defined $self->{name});

  $gbFeatureRef_Array =  $self->{gbFeatureRef};
  foreach my $temp (@$gbFeatureRef_Array){
     $return = $temp->Name() if ( defined $temp->Name());
  }
  $self->{name} = $return;
  return $return;
} 

sub E_value{
  my ( $self ) = @_;
  return 1 unless ( defined $self->{blastLineRef});
  my ( $noGB_info);
  $noGB_info = $self->{blastLineRef}->Add_noGB_Info();
  return 1 unless (defined $self->Name());
  return $noGB_info->{"E_value"};
}

sub Gene{
	my ( $self, $gene) = @_;
	warn "inverseBlastHit does not insert gene names -> '$gene' not storded!\n"
		if (defined $gene );
	my $features = $self->GBfeature;
	foreach my $gbFeature ( @$features ) {
		return $gbFeature -> Gene () if ( defined $gbFeature -> Gene());
	}
	return undef;
}

sub GBfeature {
  my ( $self, $gbFeatureRef ) = @_;

  if ( defined $gbFeatureRef ) {
     my ($feature, $gbFeatureRef_Array, @temp);
     $self->{gbFeatureRef} = \@temp unless (defined $self->{gbFeatureRef});
     $gbFeatureRef_Array = $self->{gbFeatureRef};
     if ( ref($gbFeatureRef) eq  "gbFeature"){
        push (@$gbFeatureRef_Array, $gbFeatureRef);
		$self->StartOnQueryFile( $gbFeatureRef->Start() ) 
			if ( ! (defined $self->StartOnQueryFile()) || $gbFeatureRef->Start() < $self->$self->StartOnQueryFile() );
        $self->EndOnQueryFile ( $gbFeatureRef->End() ) 
			if ( ! (defined $self->EndOnQueryFile ()) || $gbFeatureRef->End() > $self->EndOnQueryFile () );
     }
     else {
     foreach $feature (@$gbFeatureRef){
       ## gbFeatureRef hast to be a gbFeature ref!
       push (@$gbFeatureRef_Array, $feature) if ( ref($feature) eq  "gbFeature");
       $self->StartOnQueryFile( $feature->Start() ) if ( ! (defined $self->{start}) || $feature->Start() < $self->{start} );
       $self->EndOnQueryFile ( $feature->End() ) if ( ! (defined $self->{end}) || $feature->End() > $self->{end});
     }
     }
  }
#  print "inverseBlastHit GBfeature start = $self->{start} end = $self->{end}\n";
  return $self->{gbFeatureRef};
}

sub StartOnQueryFile{
  my ( $self, $start ) = @_;
  $self->{start} = $start if ( defined $start);
  return $self->{start};
}

sub EndOnQueryFile {
  my ( $self ,$end) = @_;
  $self->{end} = $end if ( defined $end );
  return $self->{end};
}

sub getAsGB{
  my ( $self ) = @_;
  my ( @return, $gbFeatureRef_Array );
  $gbFeatureRef_Array = $self->{gbFeatureRef} if ( defined $self->{gbFeatureRef});

  push (@return, $self->{blastLineRef}->getAsGB()) if ( defined $self->{blastLineRef});
  foreach my $feature (@$gbFeatureRef_Array){
     push (@return, $feature->getAsGB());
  }
  return join ("", @return);
}

sub As_gbFeature{
  my ( $self) = @_;
  my ( @return, $gbFeatures, $feature);
  $gbFeatures = $self->{gbFeatureRef};
#  print "inverseBalastHit As_gbFeature blastLineRef = $self->{blastLineRef}\n";
  push (@return, $self->{blastLineRef} ) if ( $self->{blastLineRef} =~ m/gbFeature/ );
  foreach $feature (@$gbFeatures){
     push (@return, $feature ) if ($feature =~ m/gbFeature/);
  }
  return \@return;
}

sub print {
  my ( $self) = @_;

  print $self->{blastLineRef}->getAsGB() if ( defined $self->{blastLineRef});
  if ( defined $self->{gbFeatureRef}){
    my $gbFeatureRef_Array = $self->{gbFeatureRef};
    foreach my $feature (@$gbFeatureRef_Array){
       print $feature->getAsGB();
    }
  }

  print "blastLineRef not defined\n" unless ( defined $self->{blastLineRef});
  print "gbFeatureRef not defined\n" unless ( defined $self->{gbFeatureRef});

  return 1;
}

1;
