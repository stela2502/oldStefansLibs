package SubPlot_element;
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


sub new{

	my ( $class ) = @_;

	my ( $self, @ab, @cells, @plottableDataSets );

	@plottableDataSets = (
		"XY_array", "HMM_array"
	);
	$self = {
		AB => \@ab,
		cells => \@cells,
		plottables => \@plottableDataSets
  	};

  	bless $self, $class  if ( $class eq "SubPlot_element" );

  	return $self;

}


sub match2AB{
	my ( $self, $ab_str) = @_;
	return 1 == 0 unless (defined $ab_str);
	my ( $abArray );
	$abArray = $self->{AB};
	foreach my $ab (@$abArray){
		return 1==1 if ( $ab eq $ab_str);
	}
	return 1 == 0;
}

sub match2cells{
	my ( $self, $cell_str) = @_;
	return 1 == 0 unless (defined $cell_str);
	my ( $cellArray );
	$cellArray = $self->{cells};
	foreach my $cell (@$cellArray){
		return 1==1 if ( $cell eq $cell_str);
	}
	return 1 == 0;
}
sub match2plottables{
	my ( $self, $plottable_str) = @_;
	return 1 == 0 unless (defined $plottable_str);
	my ( $plottableArray );
	$plottableArray = $self->{plottables};
	foreach my $plottable (@$plottableArray){
		return 1==1 if ( $plottable eq $plottable_str);
	}
	return 1 == 0;
}

sub cellArray {
	my ( $self, $cell_str) = @_;
	my $cellArray = $self->{cells};
	if ( defined $cell_str ){
		push ( @$cellArray,$cell_str) unless ( $self->match2cells($cell_str));
	}
	return @$cellArray;
}

sub AB_Array {
	my ( $self, $AB_str) = @_;
	my $ABArray = $self->{AB};
	if ( defined $AB_str ){
		push ( @$ABArray,$AB_str) unless ( $self->match2AB($AB_str));
	}
	return @$ABArray;
}

sub getListOfPlottables{
	my $self = shift;
	warn "$self->getListOfPlottables is not implemented yet!\n";
	return undef;
}

sub addDataSet{
	my ( $self, $dataSet ) =@_;
	## da muss ich mich noch schlau machen, was für daten da eigentlich rein sollen!!
	return 1;
}

1;
