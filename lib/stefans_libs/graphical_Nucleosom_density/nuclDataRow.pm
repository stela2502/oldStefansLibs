package nuclDataRow;
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

use stefans_libs::plot::axis;

sub new{

  my ( $class, $what, $data, $filename ) = @_;

  my ( $self, @data );

  $self = {
	data => \@data,
	filename => $filename
	};

  bless $self, $class  if ( $class eq "nuclDataRow" );

	$self->AddData($what,$data);
	
  return $self;

}

sub AddData{
	my ( $self, $what, $data) = @_;
	my ( $dataArray, $insertPoint );
	$dataArray = $self->{data};
	$self->{type} = $what;
	
	while (@$data){
		unless ( defined @$dataArray[ getBinId($_->{start}) ] ){
			my @dataBin;
			@$dataArray[ getBinId($_->{start}) ] = \@dataBin;
		}
		$insertPoint = @$dataArray[ getBinId($_->{start}) ];
		if ($what eq "start"){
			push (@$insertPoint, $_->{P_start} );
			$self-> max_value ( $_->{P_start} );
			$self-> min_value ( $_->{P_start} );
		}
		if ($what eq "occupied" ){
			push (@$insertPoint, $_->{P_occupied} );
			$self->max_value( $_->{P_occupied} );
			$self->min_value( $_->{P_occupied} );
		}
	}
	return 1;
}

sub max_value {
    my ( $self, $max ) = @_;

    if ( defined $max ) {
        $self->{'length'} = undef;
        $self->{_max} = $max if ( $max > $self->{_max} || ! ( defined $self->{_max} ) );
    }
    return $self->{_max};
}

sub min_value {
    my ( $self, $min ) = @_;

    if ( defined $min ) {
        $self->{'length'} = undef;
        #$self->{_min} = $min if ( $self->{_min} > $min || !(defined $self->{_min}));
		$self->{_min} = $min if ( $self->{_min} > $min || !(defined $self->{_min}));
    }

    return $self->{_min};
}

sub getBinId{
	my ( $self, $bp ) = @_;
	return int($bp / $self->{binLength});
}

sub getMeanBp4Id{
	my ( $self, $id) = @_;
	return int($id * $self->{binLength} + $self->{binLength} / 2);
}

sub plot{
	( $self, $im, $y1, $y2, $x_axis, $color, $title, $resolution, $legend,
        $font, $min_override, $max_override ) =
		@_;
	my ($last_y, $last_x, $x, $y, $data, $usedColor);
	
	if ( $self->{what} eq "start"){
		$usedColor = $color->{purple};
	}
	if ( $self->{what} eq "occupied" ){
		$usedColor = $color->{light_blue};
	}
	
	$data = $self->{data};
	
	$y_axis = axis->new('y', $y1, $y2, $title, 'min' );
	
	$y_axis -> max_value($self->max_value($max_override) );
	$y_axis -> min_value($self->min_value($min_override) );
	
	$y_axis -> plot( $im, $x_axis->resolve($x_axis->min_value()), $color->{black}, '');
	
	for ( my $i = getBinId($x_axis->min_value()); $i <= getBinId($x_axis->max_value()); $i++){
		$x = $x_axis->resolve( getMeanBp4Id ( $i ) );
		$y = $y_axis->resolve( root->mean( @$data [$i] ));
		$im->setPixel( $x, $y, $usedColor );
		if ( defined $last_y ){
			$im->line($x, $y, $last_x, $last_y, $usedColor);
		}
	}
	return $im;
}

1;
