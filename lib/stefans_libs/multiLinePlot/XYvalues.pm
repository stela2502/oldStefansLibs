package XYvalues;
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

  my ( $self, @adat );

  $self = {
	 data => \@adat,
	 max => undef,
	 min => undef
  };

  bless $self, $class  if ( $class eq "XYvalues" );

  return $self;

}

sub AddValues{
	my ( $self, $hash, $key ) = @_;
	my $data = $self->{data};
	$self->{type} = $key;
	push ( @$data,$hash);
	$self->Max($hash->{mean}, $hash->{stdError} );
	$self->Min($hash->{mean}, $hash->{stdError});
	# hash = { std => <float>, position=> <int>, stdError => <float>, mean => <float>};
	return $data;
}

sub getData_withSEM{
	my ( $self ) = @_;
	my ( $data, $returnhash );
	$data = $self->{data};
	foreach my $values (@$data){
		$returnhash ->{ $values ->{position} } = { mean => $values ->{mean}, sem => $values->{stdError} };
	}
	return $returnhash;
}

sub Max{
	my ( $self, $max, $stdErr ) = @_;
	if ( defined $max ){
		$self->{max} = $max unless (defined $self->{max});
		$self->{max} = $max if ( $self->{max} < $max);
	}
	if ( defined $stdErr){
		$self->Max_StdErr($max, $stdErr);
	}
	return $self->{max};
}

sub Min{
	my ( $self, $min, $stdErr ) = @_;
	if ( defined $min ){
		$self->{min} = $min unless (defined $self->{min});
		$self->{min} = $min if ( $self->{min} > $min);
	}
	if ( defined $stdErr){
		$self->Min_StdErr($min, $stdErr);
	}
	return $self->{min};
}

sub Min_StdErr{
	my ( $self, $min, $stdErr ) = @_;
	if ( defined $min ){
		$self->{min_std} = $min - $stdErr unless (defined $self->{min_std});
		$self->{min_std} = $min - $stdErr if ( $self->{min_std} > $min - $stdErr);
	}
	return $self->{min_std};
}

sub Max_StdErr{
	my ( $self, $max, $stdErr ) = @_;
	if ( defined $max ){
		$self->{max_std} = $max + $stdErr unless (defined $self->{max_std});
		$self->{max_std} = $max + $stdErr if ( $self->{max_std} < $max + $stdErr);
	}
	return $self->{max_std};
}

sub getAsPlottable{
	my ($self) = @_;
	return $self;
}

1;
