package gbFile_X_axis_with_NuclPos;
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

use stefans_libs::multiLinePlot::multiline_gb_Axis;
use stefans_libs::plot::color;
use stefans_libs::plot::axis;
use base ( 'multiline_gb_Axis' );

sub new{

  my ( $class, $gbFile, $start, $end, $x1, $y1, $x2, $y2, $resolution, $color, $NuclProbablilityArray ) = @_;

  root::identifyCaller("$class","new") unless (defined $x1);
	
  my ( $self, @array, $max, $min );
  unless ( $color =~ m/color/ ) {
	$color = color->new();
  }
 
  return multiline_gb_Axis->new($gbFile, $start, $end, $x1, $y1, $x2, $y2, $resolution, $color) 
	unless ( defined $NuclProbablilityArray);
	  
  for ( my $i = $start; $i <= $end; $i++){
		$array[$i] = @$NuclProbablilityArray[$i];
  }
  
  $self = {
	gb_axis			 => multiline_gb_Axis->
							new($gbFile, $start, $end, $x1, $y2 - ($y2 -$y1) / 5, $x2, $y2 , $resolution, $color),
	y_axis			 => axis->new ( "y", $y1, ($y2 - ($y2 -$y1) / 5) - 1, "Nucl Data", "min"),
	color			 => $color,
	x_axis			 => 1 == 1,
	start => $start,
	end => $end,
	#nuclArray		 => \@array
  };

  $self->{gb_axis}->resolveValue($start);

  bless $self, $class  if ( $class eq "gbFile_X_axis_with_NuclPos" );
  
  $self->{y_axis}->min_value(0);
  $self->{y_axis}->max_value(1);
  
  return $self;

}

sub NuclArray {
	my ( $self, $NuclProbablilityArray) = @_;
	my ( @array );
	
	if ( defined $NuclProbablilityArray){
	
		for ( my $i = $self->Start; $i <= $self->End; $i++){
			$array[$i] = @$NuclProbablilityArray[$i];
		}
		$self->{nuclArray} = \@array;
	}
	else {
		die "hard error: gbFile_X_axis_with_NuclPos.pl has no NuclProbabillity Array Info!\n"
			unless ( defined $self->{nuclArray});
	}
	#print "gbFile_X_axis_with_NuclPos.pm NuclArray is $self->{nuclArray}\n";
	return $self->{nuclArray};
}
	
sub plot {
	my ( $self, $im, $font) = @_;
	
	my ( $NuclArray);
	$NuclArray = $self->NuclArray;
	$self->{font} = $font if ( defined $font);
	$self->{gb_axis}->plot($im, $font);
	return $self unless ( defined $NuclArray );
	#$self->{dimension} = $self->{gb_axis}->{dimension};
	$im->rectangle($self->{min_pixel}, $self->{y1}, $self->{max_pixel},$self->{y2},$self->{color}->{black});
	#print "plot the nucleotide Array Data\n";
	$self->{y_axis}->plot($im, $self->resolveValue($self->{gb_axis}->min_value()), $self->{color}->{black}, "Nucl Data" );
	for ( my $i = $self->Start; $i <= $self->End; $i++){
		print "gbFile_X_Axis_with_NuclPos: plot nuclPos: $i bp, @$NuclArray[$i]->{P_start}, @$NuclArray[$i]->{P_occupied}\n";
		print "$im ,pixel for 0 bp",$self->resolveValue(0),", y_axis: $self->{y_axis} ,",
		#	" color: $self->{color}, red: $self->{color}->{red}\n";
		#print "We try to get the position $i in the NuclArray\n";
		$im->setPixel(
			$self->resolveValue($i), 
			$self->{y_axis}->resolveValue(@$NuclArray[$i]->{P_start}), 
			$self->{color}->{red});
		$im->setPixel(
			$self->resolveValue($i),
			$self->{y_axis}->resolveValue(@$NuclArray[$i]->{P_occupied}),
			$self->{color}->{black});
	}
	return $self;
}
1;
