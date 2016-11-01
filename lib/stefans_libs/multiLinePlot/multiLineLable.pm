package multiLineLable;
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

  my ( $class, $font ) = @_;

  my ( $self, %lineLables, %coordinateTags );

  $self = {
    font => $font,
  	lineLables => \%lineLables,
	coordinateTags  => \%coordinateTags
  };

  die "class multiLineLable has to be initialized with a Font object!\n" unless defined $self->{font};
  bless $self, $class  if ( $class eq "multiLineLable" );

  return $self;

}

=head2 LineLable

=head3 Atributes

[0]: A free defined Lable Tag

[1]: The String to lable the line with

[2]: the y1_tag for the lable location as used in multiLinePlot lineCoordinates

[3]: the y2_tag for the lable location as used in multiLinePlot lineCoordinates

[4]: The line the lable has to be plotted

=head3 return value

the string to lable the line with

=cut

sub LineLable {
  my ( $self, $line, $lable, $y1_tag, $y2_tag, $titleLine ) = @_;
  
  if ( defined $titleLine ) {
	unless ( defined $self->{lineLables}->{$line} ){
		my %hash;
		$self->{lineLables}->{$line} = \%hash;
	}
	if ( defined $titleLine){
		$self->{lineLables}->{$line}->{$titleLine} = $lable;
		$self->LineCoordinateTags($line, $y1_tag, $y2_tag ) ;
		return $self->{lineLables}->{$line}->{$titleLine};
	}
	else {
		return $self->{lineLables}->{$line}->{$lable};
	}
  }
  if ( lc($self->{lineLables}->{$line}) =~ m/hash/){
	return $self->{lineLables}->{$line}->{$lable};
  }
  $self->{lineLables}->{$line} = $lable if ( defined $y1_tag && defined $lable);
  $self->LineCoordinateTags($line, $y1_tag, $y2_tag ) ;
  return $self->{lineLables}->{$line};
}

sub LineCoordinateTags{
  my ( $self, $line, $y1, $y2) = @_;
  if ( defined $y1 && defined $y2){
     my $temp = {y1 => $y1, y2 => $y2};
	 $self->{coordinateTags}->{$line} = $temp;
  }
  return $self->{coordinateTags}->{$line}->{y1}, $self->{coordinateTags}->{$line}->{y2};
}

sub _getLineLables{
   my ( $self ) = @_;
   my ( $temp);
   $temp = $self->{lineLables};
   return keys %$temp;
}

sub plot {
	my ( $self, $im, $lineCoordinates, $x1, $x2, $color) = @_;
	
	my ( @LineLables, $y1, $y2, $width,$height);
	@LineLables = $self->_getLineLables();
    ($width,$height) = $im->getBounds();

	foreach my $i ( keys %$lineCoordinates) {

		foreach my $lineLable ( @LineLables ){
#			print "\$lineLable  = $lineLable\n";
			( $y1, $y2 ) = $self->LineCoordinateTags($lineLable, $i);
			

			$y1 = $lineCoordinates->{$i}->{$y1};
			$y2 = $lineCoordinates->{$i}->{$y2};

			$self->{font}->drawStringInRegion_Ycentered_rightLineEnd( 
				$im, $self->LineLable($lineLable, $i),
				$x1, $y1, $x2, $y2, $color
			) unless ( $lineLable eq "title");
			$self->{font}->drawStringInRegion_Ycentered_rightLineEnd( 
				$im, $self->LineLable($lineLable, $i),
				$x1 + $width / 30 , $y1, $x2 + $width / 30, $y2, $color
			) if ( $lineLable eq "title");
		}
	}
}



1;
