package multiline_HMM_Axis;
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
	
	my ( $class, $data, $y1, $y2, $multiLineGBaxis, $color, $colorObject ) = @_;
	
	my ( $self );
	
	$self = {
		x_axis => $multiLineGBaxis,
		y1 => $y1,
		y2 => $y2,
		data => $data,
		color => $color,
		colorObject => $colorObject
	};
	#print "\t\tmultiline_HMM_Axis new data = $self->{data}\n";
	bless $self, $class  if ( $class eq "multiline_HMM_Axis" );
	
	return $self;
	
}

sub plot{
	my ( $self, $im, $gbAxis ) = @_;
	my ( $data );
	if ( defined $gbAxis) {
		$self->{x_axis} = $gbAxis;
	}
	else {
		die "multiLine_HMM_Axis needs a x_axis to get the right x pixel values!\n" unless (defined $self->{x_axis});
	}
	$im->line($self->{x_axis}->resolveValue($self->{x_axis}->min_value()), $self->{y1}, $self->{x_axis}->resolveValue($self->{x_axis}->max_value()),
	          $self->{y1}, $self>{colorObject}->{grey});
	$im->line($self->{x_axis}->resolveValue($self->{x_axis}->min_value()), $self->{y2}, $self->{x_axis}->resolveValue($self->{x_axis}->max_value()),
	          $self->{y2}, $self>{colorObject}->{grey});
	#$im->setThickness(2);
	my $center = int( ($self->{y2} + $self->{y1}) /2 );
	for ( my $i = $self->{x_axis}->resolveValue($self->{x_axis}->min_value()); 
			$i < $self->{x_axis}->resolveValue($self->{x_axis}->max_value());
			$i += 12){
		$im->line($i, $center, $i + 3, $center, $self->{color});
	}
	#$im->setThickness(1);
			  
	$data = $self->{data};
	#my $i = @$data;
	#print "multiline_HMM_Axis got $i data regions\n";
	foreach my $gbFeature ( @$data){
		#print "multiline_HMM_Axis tries to plot a enriched region in the color $self->{color}\n";
		$self->drawSmallBox( $im,$gbFeature, $self->{color});
	}
	
}

sub drawSmallBox{
	my ( $self, $im, $gbFeature, $color) = @_;
	
	return 1 if ( $gbFeature->Start > $self->{x_axis}->max_value || $gbFeature->End < $self->{x_axis}->min_value());
	die "multiline_HMM_Axis wurde nicht richtig initialisiert! es fehlt die Farbe!!\n" unless ( defined $color);
	my ( $region_for_drawing, $start, $end);
	$region_for_drawing = $gbFeature->getRegionForDrawing();
	foreach my $region ( @$region_for_drawing) {
		next if ( $region->{start} > $self->{x_axis}->max_value || $region->{end} < $self->{x_axis}->min_value());
		$start = $region->{start};
		$start = $self->{x_axis}->min_value() if ( $start < $self->{x_axis}->min_value());
		$end = $region->{end};
		$end = $self->{x_axis}->max_value() if ( $end > $self->{x_axis}->max_value);
		$im->filledRectangle($self->{x_axis}->resolveValue($start), $self->{y1} + ($self->{y2} - $self->{y1}) / 5 ,
							 $self->{x_axis}->resolveValue($end), $self->{y2} - ($self->{y2} - $self->{y1}) / 5,
							 $color);
		
	}
}	

1;
