package multi_axis;
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

use stefans_libs::plot::fixed_values_axis;

use strict;

sub new {

	my ( $class, $which, $min_pixels, $max_pixels, $title, $resolution ) = @_;

	my ( $self, $temp, @temp, $hash );

	#print "new multi_axis! ( $which, $min_pixels, $max_pixels, $title, $resolution ) \n";
	$resolution = "max" unless ( defined $resolution );

	#$resolution = "max" unless ( "maxminmed" =~ m/$resolution/) ;
	#$resolution = "max" unless (defined $resolution);
	$self = {
		tics          => 6,
		tic_length    => 30,
		title         => $title,
		max_pixel     => $max_pixels,
		subAxes       => \@temp,
		axes_count    => 0,
		subAxiesCount => 0,
		subRegions    => $hash,
		_max          => undef,
		_min          => undef,
		min_pixel     => $min_pixels,
		resolution    => $resolution
	};

	$self->{font} = Font->new($resolution);

	warn
"So wird hier nichts geschrieben werden koennen!\nfont wurde nicht initialisiert!\nresolution = $resolution\n"
	  unless ( defined $self->{font} );

	bless $self, $class if ( $class eq "multi_axis" );

	$self->{x_axis} = 1 == 0;
	$self->{x_axis} = 1 == 1 if ( lc($which) eq "x" );

	unless ( $self->{x_axis} ) {

		$self->{min_pixel} = $max_pixels;
		$self->{max_pixel} = $min_pixels;
	}

	return $self;

}

sub defineValues {
	my ( $self, $min_pixels, $max_pixels, $title ) = @_;
	#print "$self defineValues ($min_pixels, $max_pixels, $title )\n";
	$self->{min_pixel} = $min_pixels if ( defined $min_pixels );
	$self->{max_pixel} = $max_pixels if ( defined $max_pixels );
	$self->{title}     = $title      if ( defined $title );
	return 1 if ( defined $self->{min_pixel} && defined $self->{max_pixel} );
	return undef;
}

sub AddSubRegion {
	my ( $self, $bp_start, $bp_end, $percentOfMax ) = @_;

	$self->{_max} = undef;
	$self->{_min} = undef;
	my @array;
	$self->{subAxes}    = \@array;
	$self->{axes_count} = 0;

	#print "$self AddSubRegion: ($bp_start, $bp_end, $percentOfMax)\n";

	return 0 if ( defined $self->{subRegions}->{$bp_start} );
	$self->{subRegions}->{$bp_start} = {
		percent  => $percentOfMax,
		start    => $bp_start,
		end      => $bp_end,
		position => undef
	};
	$self->{subAxiesCount}++;

	#$self->redefineAxis();
}

sub Bp_Scale {
	my ( $self, $set ) = @_;

#print "you try to define Bp_Scale ($self->{bp_scale}) with '$set' and '$self->{x_axis}'\n";
	$self->{bp_scale} = 1 == 1 if ( defined $set && $self->{x_axis} );
	return $self->{bp_scale};
}

sub plot_simple_base_line {
	my ( $self, $image, $other_pixel, $color, $title ) = @_;
	my ( $subAxes, $temp, $prefetch, $versatz, $slashType );
	$subAxes = $self->{subAxes};
	$versatz = 10;
	$temp    = 0;
	foreach my $subAxis (@$subAxes) {
		$subAxis->plotAxis_asLine( $image, $other_pixel, $color );
		if ( defined $title ) {
			$temp++;
			next;
		}
		$image->setThickness(2);
		unless ( $temp + 1 == @$subAxes ) {
			$image->line(
				$subAxis->resolveValue( $subAxis->max_value() ) - $versatz,
				$other_pixel + $versatz,
				$subAxis->resolveValue( $subAxis->max_value() ) + $versatz,
				$other_pixel - $versatz,
				$color
			);
		}
		if ( $temp > 0 ) {
			$image->line(
				$subAxis->resolveValue( $subAxis->min_value() ) - $versatz,
				$other_pixel + $versatz,
				$subAxis->resolveValue( $subAxis->min_value() ) + $versatz,
				$other_pixel - $versatz,
				$color
			);
		}
		$image->setThickness(1);
		$temp++;
	}
	return 1;
}

sub plot_holes {
	my ( $self, $image, $upper_border, $lower_border, $color ) = @_;
	my ( $subAxes, $temp, $prefetch, $selfA, $selfB );
	$subAxes = $self->{subAxes};

	for ( my $i = 0 ; $i < @$subAxes - 1 ; $i++ ) {
		$selfA = @$subAxes[$i]->resolveValue( @$subAxes[$i]->max_value() );
		$selfB =
		  @$subAxes[ $i + 1 ]->resolveValue( @$subAxes[ $i + 1 ]->min_value() );
		if ( $self->{x_axis} ) {
			$image->filledRectangle( $selfA, $upper_border, $selfB,
				$lower_border, $color->{white} );
			$image->line( $selfA, $upper_border, $selfA, $lower_border,
				$color->{black} );
			$image->line( $selfB, $upper_border, $selfB, $lower_border,
				$color->{black} );
		}
		else {
			$image->filledRectangle(
				$upper_border, $selfA, $lower_border,
				$selfB,        $color->{white}
			);
			$image->line(
				$upper_border, $selfA, $lower_border,
				$selfA,        $color->{black}
			);
			$image->line(
				$upper_border, $selfB, $lower_border,
				$selfB,        $color->{black}
			);
		}
	}
	return 1;
}

sub plot {

	my ( $self, $image, $other_pixel, $color, $title ) = @_;

	$self->defineAxis();
	my ( $subAxes, $temp, $prefetch, $versatz, $slashType );
	## slashType 1 = first in a list of axies => suppress last tic
	## slashType 2 = middle axis => suppress first and last tic
	## slashType 3 = last in a list of axies => suppress first tic
	$subAxes = $self->{subAxes};    ## Array Ref!
	#root::print_hashEntries($self,4,"$self->plot showing the \$self structure\n");
	if ( @$subAxes == 1 ) {

		#print "muti_axis is used as normal axis!\n";
		$temp = @$subAxes[0] -> getAsNormalAxis();
		$temp->plot( $image, $other_pixel, $color, $title );
		return 1;
#		@$subAxes[0]->plot( $image, $other_pixel, $color, $title );
#		return 1;
	}

	$self->plotTitle( $image, $other_pixel, $color, $title );

	$versatz = 10;
	$temp    = 0;
	foreach my $subAxis (@$subAxes) {
		$slashType = 1;
		$slashType = 3 if ( $temp + 1 == @$subAxes );
		$subAxis->plot( $image, $other_pixel, $color, " ", $slashType );
		$image->setThickness(2);
		unless ( $temp + 1 == @$subAxes ) {
			$image->line(
				$subAxis->resolveValue( $subAxis->max_value() ) - $versatz,
				$other_pixel + $versatz,
				$subAxis->resolveValue( $subAxis->max_value() ) + $versatz,
				$other_pixel - $versatz,
				$color
			);
		}
		if ( $temp > 0 ) {
			$image->line(
				$subAxis->resolveValue( $subAxis->min_value() ) - $versatz,
				$other_pixel + $versatz,
				$subAxis->resolveValue( $subAxis->min_value() ) + $versatz,
				$other_pixel - $versatz,
				$color
			);
		}
		$image->setThickness(1);
		$slashType = 2 if ( $temp == 0 );
		$temp++;
	}
	return 1;
}

sub getMinimumPoint {

	my ($self) = @_;
	return $self->resolveValue( $self->min_value );
}

sub redefineAxis {
	my ($self) = @_;
	my (@temp);
	$self->{subAxes}    = \@temp;
	$self->{axes_count} = 0;
	return $self->defineAxis();
}

sub defineAxis {
	my ($self) = @_;
	my ( $subAxes, $subRegions, $temp, $last_end, $axisLength_pixel,
		$percentSum, $gap_in_percent );
	$gap_in_percent = 1;
	return 1 if ( $self->{axes_count} > 0 );

	$subAxes    = $self->{subAxes};      ## Array Ref!
	$subRegions = $self->{subRegions};

	#print "$self defined Axis\n";
	if ( $self->{subAxiesCount} == 0 ) {
		print "no multiple axes defined!\n";
		if ( defined $self->{_max} && defined $self->{_min} ) {

			#print "define a normal x_axis!\n";
			@$subAxes[0] =
			  fixed_values_axis->new( "x", $self->{min_pixel},
				$self->{max_pixel}, undef, $self->{resolution} );
			@$subAxes[0]->max_value( $self->{_max} );
			@$subAxes[0]->min_value( $self->{_min} );
			@$subAxes[0]->defineAxis();
			$self->{axes_count}++;
			@$subAxes[0]->Bp_Scale( $self->Bp_Scale() );
		}
		else {
			print
"massive mistake! no axis defined min = $self->{_min}; max = $self->{_max}\n";
		}
		return 1;
	}

	$temp = $percentSum = 0;
	$last_end         = $self->{min_pixel};
	$axisLength_pixel = $self->{max_pixel} - $self->{min_pixel};
	die
"The axis position in pixels was not defined in $self defineAxis! ($self->{max_pixel} - $self->{min_pixel}) \n"
	  unless ( $axisLength_pixel > 0 );
	## wie viele Teile muessen es werden?
	foreach my $regionStart ( sort keys %$subRegions ) {
		$temp++;
		$percentSum += $subRegions->{$regionStart}->{percent};
	}

	## reskalieren der Teile
#print "we rescale to a maximum of ",100 - $gap_in_percent * ($temp - 1),"% points\n";
	unless ( $percentSum == 100 - $gap_in_percent * ( $temp - 1 ) ) {
		$percentSum = $percentSum / ( 100 - $gap_in_percent * ( $temp - 1 ) );

		#print "$self: percetSum = $percentSum\n";
		foreach my $regionStart ( sort keys %$subRegions ) {

#print "subRegions: $regionStart / percent = $subRegions->{$regionStart}->{percent}\n";
			$subRegions->{$regionStart}->{percent} =
			  $subRegions->{$regionStart}->{percent} / $percentSum;
		}
	}
	$percentSum = 0;
	foreach my $regionStart ( sort keys %$subRegions ) {
		$temp++;
		$percentSum += $subRegions->{$regionStart}->{percent};
	}

	#print "result : $percentSum\n";

	## Teilaxen Definieren
	$self->{axes_count} = 0;
	foreach my $regionStart ( sort numeric keys %$subRegions ) {
		#print "$self defineAxis creating new fixedRegion Axes: starting at $regionStart\n";
		@$subAxes[ $self->{axes_count} ] = fixed_values_axis->new(
			"x",
			$last_end,
			$last_end + $axisLength_pixel *
			  $subRegions->{$regionStart}->{percent} / 100,
			undef,
			$self->{resolution}
		);
		@$subAxes[ $self->{axes_count} ]
		  ->min_value( $subRegions->{$regionStart}->{start} );
		@$subAxes[ $self->{axes_count} ]
		  ->max_value( $subRegions->{$regionStart}->{end} );
		$subRegions->{$regionStart}->{position} = $self->{axes_count};
		@$subAxes[ $self->{axes_count} ]->{tics} = 5;
		@$subAxes[ $self->{axes_count} ]->defineAxis();
		@$subAxes[ $self->{axes_count} ]->Bp_Scale( $self->Bp_Scale() );
		$last_end = $last_end + $axisLength_pixel *
		  ( $subRegions->{$regionStart}->{percent} + $gap_in_percent ) / 100;
		$self->{axes_count}++;
	}
	return 1;
}

sub numeric {
	return $a <=> $b;
}

sub resolveValue {

	my ( $self, $value ) = @_;
	my ( $subRegions, $subAxes, $temp );

	$self->defineAxis();

	$subRegions = $self->{subRegions};
	$subAxes    = $self->{subAxes};

	foreach my $subAxis (@$subAxes) {

		return $subAxis->resolveValue($value)
		  if ( $value >= $subAxis->min_value()
			&& $value <= $subAxis->max_value() );
	}

	return -100;
}

sub isOutOfRange{
	my ($self, $value) = @_;
	my ( $subRegions, $subAxes, $temp );

	$self->defineAxis();
	$subAxes    = $self->{subAxes};

	foreach my $subAxis (@$subAxes) {
		return 1 == 0		  
			if ( $value >= $subAxis->min_value()
			  && $value <= $subAxis->max_value() );
	}
	return 1 == 1;
}


sub axisLength {
	my ($self) = @_;

	return $self->{'length'} if ( defined $self->{'length'} );
	my $length;
	$self->{'length'} = ( ( $self->max_value() - $self->min_value() )**2 )**0.5;

	#	print "new Axis Length = $self->{length}\n";
	return $self->{'length'};
}

sub resetAxis {
	my ($self) = @_;
	my ( @temp, $hash );

	$self->{subAxes}    = \@temp;
	$self->{axes_count} = 0;
	$self->{subAxiesCount} = 0;
	$self->{subRegions}    = $hash;
	$self->max_value("reset");
	$self->min_value("reset");
	return 1;
}

sub max_value {
	my ( $self, $max ) = @_;

	if ( defined $max ) {
		if ( $max eq "reset" ) {
			$self->{_max} = undef;
			return 1;
		}

		#warn "probably not what you wanted! self->{_max} = $max!\n";
		$self->{_max} = $max;    # if ( $self->{_max} < $max);
		return $max;
	}
	$self->defineAxis();
	my ($subAxes);
	$subAxes = $self->{subAxes};

	return @$subAxes[ $self->{axes_count} - 1 ]->max_value()
	  if ( $self->{axes_count} > 0 );
	return $self->{_max};
}

sub min_value {
	my ( $self, $min ) = @_;

	#root::identifyCaller("$self","min_value");
	if ( defined $min ) {
		if ( $min eq "reset" ) {
			$self->{_min} = undef;
			return 1;
		}

		#warn "probably not what you wanted! self->{_min} = $min!\n";
		$self->{_min} = $min;    # if ( $min < $self->{_min});
		return $min;
	}
	$self->defineAxis();
	my ($subAxes);
	$subAxes = $self->{subAxes};
	return @$subAxes[0]->min_value() if ( $self->{axes_count} > 0 );
	return $self->{_min};
}

sub getDimensionInt {
	my ( $self, $zahl ) = @_;
	warn "Method getDimensionInt not implemented in $self\n";
	return undef;
}

sub plotTitle {
	my ( $self, $image, $other_pixel, $color, $title ) = @_;

	$self->{title} = $title if ( defined $title );
	my ( $max, $min ) = ( $self->max_value, $self->min_value );

	if ( $self->{x_axis} ) {
		my @result = $self->{font}->testLarge(
			$image,
			$self->{title},
			$self->resolveValue( ( $max + $min ) / 2 ) - 4 *
			  length( $self->{title} ),
			$other_pixel + $self->{tic_length} * 4.5,
			$color
		);

		$self->{font}->plotLargeString(
			$image,
			$self->{title},
			( $self->resolveValue( ( $max + $min ) / 2 ) ) - (
				( $result[0] - $self->resolveValue($min) ) -
				  ( $self->resolveValue($max) - $result[4] )
			  ) / 2,
			$other_pixel + $self->{tic_length} * 4.5,
			$color
		);
		return 1;
	}

	else {
		return 1;
	}

}

1;
