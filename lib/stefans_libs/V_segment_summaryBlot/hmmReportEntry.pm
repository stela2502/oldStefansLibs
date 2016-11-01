package hmmReportEntry;
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

sub new{

	my ( $class, $gbFileString, $gbFeature ) = @_;

	die unless ( $gbFeature =~ m/gbFeature/ );
	die unless ( defined $gbFileString);
	
	my ( $self, @enrched, @infos, @count );

	$self = {
		gbFileString => $gbFileString,
		gbFeature => $gbFeature,
		infos => \@infos,
		enrichemntStates => \@enrched,
		amountOfMatchingHMMregions => \@count,
		iterator => 0
  	};

  	bless $self, $class  if ( $class eq "hmmReportEntry" );

  	return $self;

}

sub AddSearchResult{
	my ( $self, $hmmInfo, $enrichmentState, $timesEnriched ) = @_;
	if ( defined $hmmInfo){
		$self->{infos}[$self->{iterator}] = $hmmInfo;
		$self->{enrichemntStates}[$self->{iterator}] = $enrichmentState;
		$self->{amountOfMatchingHMMregions}[$self->{iterator}] = $timesEnriched;
		$self->{iterator}++;
		return 1;
	}
	return 0;
}

sub getTableHeaderLine{
	my ( $self) = @_;
	my ( $hash, $string, $i, $cell, $ab);
	for ( my $i = 0; $i < $self->{iterator}; $i++){
		$hash->{"$self->{infos}[$i]->{Organism} $self->{infos}[$i]->{CellType} $self->{infos}[$i]->{AB}"} = $i;
	}
	$string = "";
	$string = "gb File\tfeature type\tfeature name\tstart\tend";
	foreach my $key (sort keys %$hash){
		$cell = $self->{infos}[$hash->{$key}]->{CellType};
		$ab = $self->{infos}[$hash->{$key}]->{AB};
		$string = "$string\t$cell $ab";
	}
	$string = "$string\n";
	return $string;
}

sub getAsTableLine{
	my ( $self) = @_;
	my ( $hash, $string, $i, $start, $end);
	for ( my $i = 0; $i < $self->{iterator}; $i++){
		$hash->{"$self->{infos}[$i]->{Organism} $self->{infos}[$i]->{CellType} $self->{infos}[$i]->{AB}"} = $i;
	}
	$start = $self->{gbFeature}->Name();
	$end = $self->{gbFeature}->Tag();
	$string = "$self->{gbFileString}\t$start\t$end";
	$start = $self->{gbFeature}->Start();
	$end = $self->{gbFeature}->End();
	$string = "$string\t$start\t$end";
	
	foreach my $key (sort keys %$hash){
		if ( $self->{enrichemntStates}[$hash->{$key}] == 1 ){
			$string = "$string\tenriched ($self->{amountOfMatchingHMMregions}[$hash->{$key}])";
		}
		else{
			$string ="$string\tnot enriched"
		}
	}
	$string = "$string\n";
	return $string;
}

1;
