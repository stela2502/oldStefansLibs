package fixed_values_axis;
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

use stefans_libs::plot::Font;
use strict;

sub new {
	my ( $class, $which, $min_pixels, $max_pixels, $title, $resolution ) = @_;

	my ( $self, $temp );

	$self = {
		tics       => 6,             #12
		tic_length => 20,            #20
		title      => $title,
		max_pixel  => $max_pixels,
		min_pixel  => $min_pixels,
		resolution => $resolution
	};

	if ( $resolution eq "max" ) {
		$self->{tics}              = 6;
		$self->{tic_length}        = 20;
		$self->{font}              = Font->new($resolution);
		$self->{tokenX_correction} = 8;
		$self->{tokenY_correction} = -6;
	}
	if ( $resolution eq "med" ) {
		$self->{tics}       = 8;
		$self->{tic_length} = 13;
		$self->{font}       = Font->new($resolution);
	}
	if ( $resolution eq "min" ) {
		$self->{tics}       = 6;
		$self->{tic_length} = 7;
		$self->{font}       = Font->new($resolution);
	}

	#unless ( defined $self->{font} ) {
	#	warn root::identifyCaller( $class, "new" );
	#}
	die
"So wird hier nichts geschrieben werden koennen!\nfont wurde nicht initialisiert!\nresolution = $resolution\n"
	  unless ( defined $self->{font} );
	bless $self, $class if ( $class eq "fixed_values_axis" );

	#warn root::identifyCaller( $self, "new" );

	$self->{x_axis} = 1 == 0;
	$self->{x_axis} = 1 == 1 if ( lc($which) eq "x" );

	unless ( $self->{x_axis} ) {

		$self->{min_pixel} = $max_pixels;
		$self->{max_pixel} = $min_pixels;
	}

	return $self;

}

sub plotLabel {
	my ( $self, $image, $other_pixel, $color, $font ) = @_;

	my ( $max, $min ) = ( $self->max_value, $self->min_value );

	$self->{font} = $font unless ( defined $self->{font} );

	if ( $self->{x_axis} ) {

#print "$self: plot the label at ",$self->resolveValue($max - 0.5 * $self->{dimension}),", ",
#    $other_pixel + $self->{tic_length} ,", ", $self->resolveValue($max - 1.5 * $self->{dimension}),", ",
#    $other_pixel + $self->{tic_length} ," color: $color\n";
		my ($dimension);
		$dimension = $self->{dimension} / 2;
		$image->line(
			$self->resolveValue( $max - 0.5 * $dimension ),
			$other_pixel + 2 * $self->{tic_length},
			$self->resolveValue( $max - 1.5 * $dimension ),
			$other_pixel + 2 * $self->{tic_length},
			$color
		);
		$image->line(
			$self->resolveValue( $max - 1.5 * $dimension ),
			$other_pixel + 1.5 * $self->{tic_length},
			$self->resolveValue( $max - 1.5 * $dimension ),
			$other_pixel + 2.5 * $self->{tic_length},
			$color
		);
		$image->line(
			$self->resolveValue( $max - 0.5 * $dimension ),
			$other_pixel + 1.5 * $self->{tic_length},
			$self->resolveValue( $max - 0.5 * $dimension ),
			$other_pixel + 2.5 * $self->{tic_length},
			$color
		);
		my $string;
		$string = $self->ShortenBP_digit($dimension). " ".
		  $self->bpScale($dimension);

		# $self, $im, $string, $x, $y, $color, $type, $angle)
		$self->{font}->plotDigitCenteredAtXY(
			$image, $string,
			$self->resolveValue( $max - $dimension ),
			$other_pixel + 2.5 * $self->{tic_length},
			$color, "gbFeature", 0
		);
	}
	else {
		warn "$self: plotLable not defined for an y-axis!\n";
		return 0;
	}
	return 1;
}

sub ShortenBP_digit {
	my ( $self, $digit ) = @_;
	return undef unless ( defined $digit );
	return $digit / 1e6 if ( lc( $self->bpScale($digit) ) eq "mb" );
	return $digit / 1e3 if ( lc( $self->bpScale($digit) ) eq "kb" );
	return $digit;

	if ( $digit / 1000000 > 1 ) {
		$digit = $digit / 1000000;

		#$digit = "$digit MB";
		return $digit;
	}
	if ( $digit / 1000 > 1 ) {
		$digit = $digit / 1000;

		#$digit = "$digit KB";
		return $digit;
	}
	return $digit;
}

sub bpScale {
	my ( $self, $digit ) = @_;
	return "Mb" if ( $digit / 1e6 > 1 );
	return "Kb" if ( $digit / 1e3 > 1 );
	return "bp";
}

sub Bp_Scale {
	my ( $self, $set ) = @_;

#print "$self : you try to define Bp_Scale ($self->{bp_scale}) with '$set' and '$self->{x_axis}'\n";

	$self->{bp_scale} = 1 == 1 if ( defined $set );
	return $self->{bp_scale};
}

sub plotAxis_asLine {
	my ( $self, $image, $other_pixel, $color ) = @_;

	$image->line(
		$self->resolveValue( $self->min_value() ),
		$other_pixel, $self->resolveValue( $self->max_value() ),
		$other_pixel, $color
	) if ( $self->{x_axis} );
	$image->line( $other_pixel, $self->resolveValue( $self->min_value() ),
		$other_pixel, $self->resolveValue( $self->max_value() ), $color )
	  unless ( $self->{x_axis} );
	return 1;
}

sub getAsNormalAxis {
	my ($self) = @_;
	my $returnAxis =
	  axis->new( "x", $self->{min_pixel}, $self->{max_pixel}, $self->{title},
		$self->{resolution} );
	$returnAxis->max_value( $self->max_value() );
	$returnAxis->min_value( $self->min_value() );
	return $returnAxis;
}

sub isOutOfRange {
	my ( $self, $value ) = @_;

	#return undef unless ( defined $value);
	return !( $value >= $self->min_value() && $value <= $self->max_value() );

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
			$other_pixel + $self->{tic_length} * 4,
			$color
		);

		$self->{font}->plotLargeString(
			$image,
			$self->{title},
			( $self->resolveValue( ( $max + $min ) / 2 ) ) - (
				( $result[0] - $self->resolveValue($min) ) -
				  ( $self->resolveValue($max) - $result[4] )
			  ) / 2,
			$other_pixel + $self->{tic_length} * 4,
			$color
		);
	}

	else {

		my @result = $self->{font}->testLarge(
			$image,
			$self->{title},
			$other_pixel - $self->{tic_length} * 6,
			$self->resolveValue( ($min) )

			  #+ 4.5 * length( $self->{title} )
			,
			$color,
			1.570796
		);

		$self->{font}->plotLargeString(
			$image,
			$self->{title},
			$other_pixel - $self->{tic_length} * 6,
			$self->resolveValue( ($min) ) - (
				( ( $result[1] + $result[3] ) / 2 ) -
				  ( $self->resolveValue( ( $max + $min ) / 2 ) )
			),
			$color, 1.570796
		);
	}

}

sub redefineDigit {
	my ( $self, $i ) = @_;

	#print "redefineDigit:\n";
	return $i unless ( $self->Bp_Scale() );
	my @string = ( $self->ShortenBP_digit($i), " ", $self->bpScale($i) );

	#print "$self redefineDigit: ",join("",@string),"\n";
	return join( "", @string );
}

sub plot_without_digits {

	my ( $self, $image, $other_pixel, $color, $title, $type ) = @_;
	## type 1 = first in a list of axies => suppress last tic
	## type 2 = middle axis => suppress first and last tic
	## type 3 = last in a list of axies => suppress first tic
	my ( $string, @string );
	my $test = $self->resolveValue(1);

	$self->plotTitle( $image, $other_pixel, $color, $title );

	#$self->plotLabel($image, $other_pixel, $color, $title );
	#  return 1 == 0 if ( $test < 0);
	my ( $max, $min ) = ( $self->max_value, $self->min_value );

	if ( $self->{x_axis} ) {
		$image->line(
			$self->resolveValue($max),
			$other_pixel, $self->resolveValue($min),
			$other_pixel, $color
		);
		return 1 == 0 if ( $self->{dimension} == 0 );
		for ( my $i = $min ; $i <= $max ; $i += $self->{dimension} ) {
			$self->{font}->plotStringAtY_leftLineEnd(    #TinyString(
				$image, $self->redefineDigit($i),
				$self->resolveValue($i),
				$other_pixel + $self->{tic_length} * 2,
				$color, "gbFeature"
			) if ( $i == $min || $i == $self->{wanted_axis_start} );
			$self->{font}->plotStringAtY_rightLineEnd(    #TinyString(
				$image, $self->redefineDigit($i),
				$self->resolveValue($i),
				$other_pixel + $self->{tic_length} * 2,
				$color, "gbFeature"
			) if ( $i == $max );

#next unless ( $i >= $self->{wanted_axis_start} && $i <= $self->{wanted_axis_end});
			if ( $i == $min && $type == 1 ) {
				$image->line(
					$self->resolveValue($i),
					$other_pixel + $self->{tic_length},
					$self->resolveValue($i),
					$other_pixel, $color
				);
			}
			if ( $i > $min && $i < $max ) {
				$image->line(
					$self->resolveValue($i),
					$other_pixel + $self->{tic_length},
					$self->resolveValue($i),
					$other_pixel, $color
				);
			}
			if ( $i == $max && $type == 3 ) {
				$image->line(
					$self->resolveValue($i),
					$other_pixel + $self->{tic_length},
					$self->resolveValue($i),
					$other_pixel, $color
				);
			}
		}
	}

	else {

		$image->line( $other_pixel, $self->resolveValue($min),
			$other_pixel, $self->resolveValue($max), $color );
		return 1 == 0 if ( $self->{dimension} == 0 );
		for ( my $i = $min ; $i <= $max ; $i += $self->{dimension} ) {
			$image->line(
				$other_pixel - $self->{tic_length},
				$self->resolveValue($i),
				$other_pixel, $self->resolveValue($i), $color
			);
		}
	}
	return 1 == 1;
}

sub plot {

	my ( $self, $image, $other_pixel, $color, $title, $type ) = @_;

	my $test = $self->resolveValue(1);

	#$self->max_value ( $self->{wanted_axis_end} );
	#$self->min_value( $self->{wanted_axis_start});

	$self->plotTitle( $image, $other_pixel, $color, $title );

	#  return 1 == 0 if ( $test < 0);
	my ( $max, $min ) = ( $self->max_value, $self->min_value );

	if ( $self->{x_axis} ) {
		$self->plotAxis_asLine( $image, $other_pixel, $color );

		#print "$self plot type = $type\n";
		return 1 == 0 if ( $self->{dimension} == 0 );
		for ( my $i = $min ; $i <= $max ; $i += $self->{dimension} ) {

#print "$self plot do ew ever reach max? actual = $i ; max = $max\n";
#next unless ( $i >= $self->{wanted_axis_start} && $i <= $self->{wanted_axis_end});
			$image->line(
				$self->resolveValue($i),
				$other_pixel + $self->{tic_length},
				$self->resolveValue($i),
				$other_pixel, $color
			  )
			  if ( ( $i == $min && $type == 1 ) || ( $i > $min && $i < $max ) );
			$image->line(
				$self->resolveValue($i),
				$other_pixel + $self->{tic_length},
				$self->resolveValue($i),
				$other_pixel, $color
			) if ( $i == $max && $type == 3 );

			if ( $type == 3 ) {
				$self->{font}->plotStringCenteredAtX(
					$image,
					$self->redefineDigit($i),
					$self->resolveValue($i),
					$other_pixel + $self->{tic_length},
					$color, "gbFeature"
				) if ( $i > $min && $i + $self->{dimension} / 2 < $max );
			}
		}
		$self->{font}->plotStringAtY_leftLineEnd(    #TinyString(
			$image, $self->redefineDigit($min),
			$self->resolveValue($min),
			$other_pixel + $self->{tic_length},
			$color, "gbFeature"
		);
		$self->{font}->plotStringAtY_rightLineEnd(    #TinyString(
			$image, $self->redefineDigit($max),
			$self->resolveValue($max),
			$other_pixel + $self->{tic_length},
			$color, "gbFeature"
		);
	}

	else {

		$image->line( $other_pixel, $self->resolveValue($min),
			$other_pixel, $self->resolveValue($max), $color );
		return 1 == 0 if ( $self->{dimension} == 0 );
		for ( my $i = $min ; $i <= $max ; $i += $self->{dimension} ) {
			$image->line(
				$other_pixel - $self->{tic_length},
				$self->resolveValue($i),
				$other_pixel, $self->resolveValue($i), $color
			);

			$self->{font}->plotDigitCenteredAtY_rightLineEnd(    #TinyString(
				$image, $self->redefineDigit($i),
				$other_pixel - $self->{tic_length} * 1.5,
				$self->resolveValue($i), $color, "gbFeature"
			);
		}
	}
	return 1 == 1;
}

sub getMinimumPoint {

	my ($self) = @_;
	return $self->resolveValue( $self->min_value );
}

sub defineAxis {
	my ($self) = @_;

	return $self->{PixelForValue} if ( defined $self->{PixelForValue} );

	my ( $max, $min, $dimension, $add, $temp );
	( $max, $min ) = ( $self->max_value(), $self->min_value() );
	if ( $min > $max ) {
		$self->{_max} = $min;
		$self->{_min} = $max;
		( $max, $min ) = ( $self->max_value(), $self->min_value() );
	}

	$dimension = $self->getDimensionInt( $self->axisLength() );

	return $dimension if ( $dimension == -1 );

	#print $self->axisLength(), " dimesion = $dimension\n";

	while ( $self->axisLength / $dimension <= $self->{tics} / 2 ) {

		#	print "adjust dimension $dimension = ",$dimension / 2,"\n";
		$dimension = $dimension / 2;
	}
	while ( $self->axisLength / $dimension > $self->{tics} ) {

		#	print "adjust dimension $dimension = ",$dimension * 2,"\n";
		$dimension = $dimension * 2;
	}

	$add = 1;

	#    print
	#"defineAxis min = $min max = $max - modified (?) dimension = $dimension\n";

	$add = 0
	  if ( $min / $dimension == int( $min / $dimension )
		|| $min / $dimension > int( $min / $dimension ) );
	$min = ( int( $min / $dimension ) - $add ) * $dimension;
	$self->{wanted_axis_start} = $min;
	$add                       = 1;
	$add                       = 0
	  if ( $max / $dimension == int( $max / $dimension )
		|| $max / $dimension < int( $max / $dimension ) );
	$max                     = ( int( $max / $dimension ) + $add ) * $dimension;
	$self->{wanted_axis_end} = $max;
	$self->{dimension}       = $dimension;
	( $max, $min ) = ( $self->max_value(), $self->min_value() );

	#print "Define X Axis dimension = $dimension\n" if ( $self->{x_axis});
	#print "Define Y Axis dimension = $dimension\n" unless ( $self->{x_axis});

	return -1 if ( $dimension == 0 );

	#print "defineAxis modified ?  min = $min max = $max\n";
	#print "\$self->{dimension} = $self->{dimension}\n";
	$self->{PixelForValue} =
	  ( $self->{min_pixel} - $self->{max_pixel} ) / $self->axisLength();
	return $self->{PixelForValue};
}

sub resolveValue {

	my ( $self, $value ) = @_;
	return
	  int( $self->{max_pixel} +
		  ( ( $self->max_value() - $value ) * $self->defineAxis() ) );
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
	$self->max_value("reset");
	$self->min->value("reset");
	return 1;
}

sub max_value {
	my ( $self, $max ) = @_;

	if ( defined $max ) {
		if ( $max eq "reset" ) {
			$self->{_max} = undef;
			return 1;
		}
		$self->{'length'} = undef;

#$self->{_max} = $max if ( $max > $self->{_max} || ! ( defined $self->{_max} ) );
		$self->{_max} = $max;
		$self->{_min} = $self->{_max} unless ( defined $self->{_min} );
	}
	return $self->{_max};
}

sub min_value {
	my ( $self, $min ) = @_;

	if ( defined $min ) {
		if ( $min eq "reset" ) {
			$self->{_min} = undef;
			return 1;
		}
		$self->{'length'} = undef;

   #$self->{_min} = $min if ( $self->{_min} > $min || !(defined $self->{_min}));
		$self->{_min} = $min;
	}

	return $self->{_min};
}

sub getDimensionInt {
	my ( $self, $zahl ) = @_;

	#    print "getDimension $zahl\n";

	return -1 if ( $zahl == 0 );

	my ($i);
	if ( $zahl > 1 ) {
		for ( $i = 0 ; int( $zahl / 10 ) > 1 ; $i++ ) {
			$zahl = $zahl / 10;
		}
		return 10**$i    #; * int( $zahl + .5 );
	}
	if ( $zahl <= 1 ) {
		for ( $i = 1 ; int( $zahl * 10 ) < 1 ; $i++ ) {
			$zahl = $zahl * 10;
		}
		return 10**-$i;    #* (int($zahl* 10) /10) ;
	}

}

1;
