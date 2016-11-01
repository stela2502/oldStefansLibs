package ruler_x_axis;
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

use stefans_libs::plot::gbAxis;
use stefans_libs::plot::Font;

@ISA = qw(gbAxis);

sub new{

  my ( $class, $multiLineGBaxis, $color, $resolution, $x1, $y1, $x2, $y2, $start ) = @_;
	return undef;
  my ( $self );

  $self = {
     x_axis     => $multiLineGBaxis,
	 max_length => $start,
	 min_pixel  => $x1,
	 max_pixel  => $x2,
	 y1         => $y1,
	 y2         => $y2,
	 resolution => $resolution,
	 tic_length => int(($y2- $y1) / 2),
 	 color      => $color,
	 noTilte	=> undef
  };

    if ( $resolution eq "max" ) {
        $self->{tics}       = 10;
        $self->{font}       = Font->new($resolution);
    }
    if ( $resolution eq "med" ) {
        $self->{tics}       = 8;
        $self->{font}       = Font->new($resolution);
    }
    if ( $resolution eq "min" ) {
        $self->{tics}       = 6;
        $self->{font}       = Font->new($resolution);
    }
	die "Ruler wurde nicht richtig initialisiert! keine passende tics_length gefunden! ($self->{y1}, $self->{y2}â)\n" unless (defined $self->{tic_length});
	
  bless $self, $class  if ( $class eq "ruler_x_axis" );
#  print "Das ist ein Test!\n ruler_X_axis max_length = $max_length\n",
#      "aktuell ist ",$self->{x_axis}->max_value()," die max lŠnge der zeile\n",
#	  "und diese Zeile wird in ",$self->bpScale()," Abschnitten ausgegeben!\n";
  $self->min_value( $self->{x_axis}->min_value());
  $self->max_value( $self->{x_axis}->max_value());
  $self->{dimension} = $self->{x_axis}->Dimension($end - $start);
  
  print "MultilieGB_Axis:: start = $start, end = $end\n";
  
  die "ruler_x_axis: dimension == 0! $self->{min}, $self->{max}\n" if ( $self->{dimension} == 0);
  
  return $self;

}

sub noTitle{
	my ($self, $true) = @_;
	$self->{noTitle} = 1 == 1 if ( defined $true);
	return $self->{noTitle};
}

sub plot{
	my ( $self, $image, $color, $title) = @_;
	my @temp;
	my ( $max, $min ) = ( $self->max_value, $self->min_value );
	$color = $self->{color} unless (defined $color);
	die "ruler plot needs a color to plot the ruler!\n" unless (defined $color);
#	$image->line(
#				 $self->{x_axis}->resolveValue($self->{x_axis}->min_value()),
#				 $self->{y1},
#				 $self->{x_axis}->resolveValue($self->{x_axis}->min_value()),
#				 $self->{y1} + $self->{tic_length} , $color
#				 );
#	$image->line(
#				 $self->{x_axis}->resolveValue($self->{x_axis}->max_value()),
#				 $self->{y1},
#				 $self->{x_axis}->resolveValue($self->{x_axis}->max_value()),
#				 $self->{y1} + $self->{tic_length}, $color
#				 );
	$image->line(
				 $self->{x_axis}->resolveValue($self->{x_axis}->min_value()),
				 $self->{y1}, $self->{x_axis}->resolveValue($self->{x_axis}->max_value()),
				 $self->{y1}, $color
				 );
	die "ruler_x_axis hat ein problem! (dimension = $self->{dimension}; x_axis = $self->{x_axis} )\n" if ( $self->{dimension} == 0);
	return 1 == 0 if ( $self->{dimension} == 0 );
	for ( my $i = 0 ; $i < $max ; $i += $self->{dimension} ) {
	    next if ( $i < $self->min_value());
		$image->line(
					 $self->{x_axis}->resolveValue($i),
					 $self->{y1} ,
					 $self->{x_axis}->resolveValue($i),
					 $self->{y1} + $self->{tic_length}, $color
					 );
		$temp[0] = $self->ShortenBP_digit($i);
		$temp[1] = $self-> bpScale ();
		$self->{font}->drawStringInRegion_Ycentered_leftLineEnd(
			$image, join (" ", @temp),$self->{x_axis}->resolveValue($i) +5 , $self->{y1},
			$self->{x_axis}->resolveValue($i + $self->{dimension}) - 5 , $self->{y2},$color , "small"
		);
		
	#	$self->{font}->plotSmallString(
	#								   $image, join (" ", @temp),
	#								   $self->{x_axis}->resolveValue($i) +5 ,
	#								   $self->{y1} + $self->{tic_length} + 2, $color
	#								   );
	
	}
		##plot the axis title
	return 2 if ( $self->{noTitle});
	$title = "genomic position [bp]" unless (defined $title); 
	$self->{font}->plotStringCenteredAtXY(
            $image,
            $title,
            ( $self->{max_pixel} + $self->{min_pixel} ) / 2,
            $self->{y2} +  ($self->{y2} - $self->{y1})  / 2,
            $color, "large" #, 1.570796
        );
	return 1;
}

sub bpScale{
    my ( $self ) = @_;
	return "Mb" if ( $self->{max_length} / 1e6 > 1);
	return "Kb" if ( $self->{max_length} / 1e3 > 1);
	return "bp";
}

1;
