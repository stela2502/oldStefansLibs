package nucleotidePositioningData;
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

use stefans_libs::graphical_Nucleosom_density::nuclDataRow;

sub new{

  my ( $class ) = @_;

  my ( $self, $data );

  $self = {
	data => $data,
	binLength => 10
  };

  bless $self, $class  if ( $class eq "nucleotidePositioningData" );

  return $self;

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

sub AddData{
	my ( $self, $data, $filename) = @_;
	die "nucleotidePositioningData::AddData : data for filename $filename is already inserted!\n" 
		if ( defined $self->{data}->{$filename} );
	$self->{data}->{$filename} = { 
		start => nuclDataRow->new('start', $data), 
		occupied => nuclDataRow->new('occupied', $data)
	};
	$self->max_value($self->{data}->{$filename}->{start}->max_value());
	$self->max_value($self->{data}->{$filename}->{occupied}->max_value());
	
	$self->min_value($self->{data}->{$filename}->{start}->min_value());
	$self->min_value($self->{data}->{$filename}->{occupied}->min_value());
	
	return 1;
}

sub plot{
	( $self, $im, $y1, $y2, $x_axis, $color, $resolution, $legend,
        $font, $min_override, $max_override ) =
		@_;
	return 0 unless (defined  $self->{data}->{$filename} );
	$self->{data}->{$filename}->{start}->plot($im, $y1, $y2, $x_axis, $color, $title, $resolution, $legend,
        $font, $min_override, $max_override);
	$self->{data}->{$filename}->{occupied} -> plot($im, $y1, $y2, $x_axis, $color, $resolution, $legend,
        $font, $min_override, $max_override);
	return $im;
}

1;
