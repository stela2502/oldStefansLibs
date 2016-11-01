package VbinElement;
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

use stefans_libs::plot::color;

sub new{

  my ( $class, $gbFeature, $gbFileName ) = @_;

	die "VbinElement: No initializon without a gbFeature\n" unless ($gbFeature =~ m/gbFeature/);
	die "VbinElement: No initializon without a gbFile name\n" unless (defined $gbFileName);
	
  my ( $self, %enrichmentHash );

  $self = {
		gbFeature => $gbFeature,
		gbFileName => $gbFileName,
		color => color->new(),
		enrichmentData => \%enrichmentHash
  };

  bless $self, $class  if ( $class eq "VbinElement" );

  return $self;

}

sub matchWithRegion{
	my ( $self, $hmmEnriched ) =@_;
	
	my ( $enrichedRegions, $match ) ;
	$enrichedRegions = $hmmEnriched->{$self->{gbFileName}};
	
	warn "no enriched region for gbFile $self->{gbFileName}\n" unless (defined $enrichedRegions);
	foreach my $enrichedRegion ( @$enrichedRegions){
		$match = $self->{gbFeature}->Match($enrichedRegion->Start, $enrichedRegion->End);
		last if ($match);
	}
	$self->{enrichmentData}->{ "$hmmEnriched->{info}->{CellType};$hmmEnriched->{info}->{AB}" } = $match;
	return $match;
	#$self->{gbFeature}->Match(start, end);

}

sub asTableHash{
	my ( $self ) = @_;
	my $line;
	$line->{filename} = $self->{gbFileName};
	$line->{gbFamily} = $self->Family();
	$line->{featureName} = $self->{gbFeature}->Name();
	$line->{featureTag} = $self->{gbFeature}->Tag();
	$line->{position} = $self->Position();
	$line->{enrichmentData} = $self->{enrichmentData};
	return $line;
}

sub asTableLineHead{
	my ( $self ) = @_;
	my ( $string, $line);
	$string = "filename\tfetaure Tag\tV family\tsegment name\tposition [bp]\t";
	$line = $self->asTableHash();
	$line = $line->{enrichmentData};
	foreach my $ChipType ( sort keys %$line){
		$string = "$string\t$ChipType";
	}
	return "$string\n";
}

sub asTableLine{
	my ( $self ) = @_;
	my ( $string, $line);
	
	$line = $self->asTableHash();
	$string = "$line->{filename}\t$line->{featureTag}\t$line->{gbFamily}\t$line->{featureName}\t$line->{position}\t";
	
	$line = $line->{enrichmentData};
	foreach my $ChipType ( sort keys %$line){
		$string = "$string\t2" if ( $line->{$ChipType}) ;
		$string = "$string\t1" unless ( $line->{$ChipType}) ;
	}
	return "$string\n";
}

sub Family{
	my ( $self ) = @_;
	my ( $family, $color) = $self->{color}->color_and_Name($self->{gbFeature});
	return $family;
}

sub Position{
	my ( $self) = @_;
	return $self->{gbFeature}->Start();
}


1;
