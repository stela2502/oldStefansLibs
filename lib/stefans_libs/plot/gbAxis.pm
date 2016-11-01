package gbAxis;
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

@ISA = qw(axis);

sub new {

    my ( $class, $which, $min_pixels, $max_pixels, $axis_title,
        $gbFeature_X_axis, $plot, $resolution )
      = @_;

    my ($self);

    die
"gbAxis muss ein Objekt der Klasse stefans_libs::V_segment_summaryBlot::gbFeature_X_axis\n",
"oder stefans_libs::V_segment_summaryBlot::gbFile_X_axis übergeben werden ($gbFeature_X_axis)!\n"
      unless ( $gbFeature_X_axis =~ m/gbFeature_X_axis/
        || $gbFeature_X_axis =~ m/gbFile_X_axis/ );

    #  if ( $gbFeature_X_axis =~ m/gbFeature_X_axis/ ){
    $self->{start}    = $gbFeature_X_axis->{min};
    $self->{end}      = $gbFeature_X_axis->{max};
    $gbFeature_X_axis = $gbFeature_X_axis->getAsPlottable();

    #  }
    #  elsif ( @$gbFeature_X_axis[0] =~ m/gbFeature/ ){
    #     my (@temp, $i);
    #     $i = 0;
    #     foreach my $gbFeature ( @$gbFeature_X_axis){
    #        $temp[$i++] = $gbFeature->getAsPlottable();
    #     }
    #     $gbFeature_X_axis = \@temp;
    #  }

    $self = {
        _plot            => $plot,
        tics             => undef,              #12
        tic_length       => undef,              #20
        max_pixel        => $max_pixels,
        min_pixel        => $min_pixels,
        axis_title       => $axis_title,
        gbFeature_X_axis => $gbFeature_X_axis
    };

    if ( $resolution eq "max" ) {
        $self->{tics}       = 10;
        $self->{tic_length} = 20;
        $self->{font}       = Font->new($resolution);
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

    bless $self, $class if ( $class eq "gbAxis" );

    $self->{x_axis} = 1 == 1 if ( lc($which) eq "x" );

    return $self;

}

sub renewTitle {
  my ( $self, $title) =@_;
  $self->{axis_title} = $title;
#  print "New bgAxis Title: $self->{axis_title}\n";
}
  

sub ShortenBP_digit{
  my ( $self, $digit) = @_;
  return undef unless (defined $digit);
  return $digit / 1e6 if ( lc($self->bpScale) eq "mb");
  return $digit / 1e3 if ( lc($self->bpScale) eq "kb");
  return $digit;
  
  if ( $digit / 1000000 > 1) {
    $digit = $digit / 1000000;
	#$digit = "$digit MB";
	return $digit;
  }
  if ( $digit / 1000 > 1) {
     $digit = $digit / 1000;
	 #$digit = "$digit KB";
	 return $digit;
  }
  return $digit;
}

sub bpScale{
    my ( $self ) = @_;
	return "Mb" if ( $self->min_value / 1e6 > 1);
	return "Kb" if ( $self->min_value / 1e3 > 1);
	return "bp";
}	
  
sub plot {

    my ( $self, $image, $other_pixel, $color, $title, $plot ) = @_;

    my ( $max, $min, $gbFeature_Plottables, $regions );

    $self->resolveValue(1);
    ( $max, $min ) = ( $self->max_value, $self->min_value );
    $self->{axis_title} = $title if ( defined $title );

    $gbFeature_Plottables = $self->{gbFeature_X_axis};

    if ( $self->{x_axis} ) {
        my @result = $self->{font}->testLarge(
            $image,
            $self->{axis_title},
            $self->resolveValue( ( $max + $min ) / 2 ) - 6 *
              length( $self->{axis_title} ),
            $other_pixel + $self->{tic_length} * 4.5 + 20,
            $color
        );
#        print "moving String from x = ",
#          $self->resolveValue( ( $max + $min ) / 2 ) - 6 *
#          length( $self->{axis_title} ), " to ",
#          ( $self->resolveValue( ( $max + $min ) / 2 ) - 6 *
#              length( $self->{axis_title} ) ) -
#          ( ( @result[0] - $self->resolveValue($min) ) -
#              ( $self->resolveValue($max) - @result[4] ) ) / 2, "\n";
#        print " lower x = @result[0], upper x = @result[4]\n";
		
        $self->{font}->plotLargeString(
            $image,
            $self->{axis_title},
            (
                $self->resolveValue( ( $max + $min ) / 2 ) - 6 *
                  length( $self->{axis_title} )
              ) - (
                ( $result[0] - $self->resolveValue($min) ) -
                  ( $self->resolveValue($max) - $result[4] )
              ) / 2,
            $other_pixel + 10 + $self->{tic_length} * 6,
            $color
        );

        #        $image->string(
        #            GD::Font->Giant,
        #            $self->resolveValue( ( $max + $min ) / 2 ) - 4 *
        #              length( $self->{axis_title} ),
        #            $other_pixel + $self->{tic_length} * 3 + 10,
        #            $self->{axis_title},
        #            $color
        #        );
        ## ruler
        $image->line(
            $self->resolveValue($min),
            $other_pixel,
            $self->resolveValue($min),
            $other_pixel + 20, $color
        );
        $image->line(
            $self->resolveValue($max),
            $other_pixel,
            $self->resolveValue($max),
            $other_pixel + 20, $color
        );
        $image->line(
            $self->resolveValue($max),
            $other_pixel, $self->resolveValue($min),
            $other_pixel, $color
        );
        $image->line(
            $self->resolveValue($max),
            $other_pixel + 20,
            $self->resolveValue($min),
            $other_pixel + 20, $color
        );
        return 1 == 0 if ( $self->{dimension} == 0 );
        for ( my $i = $min ; $i <= $max ; $i += $self->{dimension} ) {
            $image->line(
                $self->resolveValue($i),
                $other_pixel + $self->{tic_length} + 20,
                $self->resolveValue($i),
                $other_pixel + 20, $color
            );
			
            $self->{font}->plotSmallString(
                $image, $self->ShortenBP_digit($i),
                $self->resolveValue($i),
                $other_pixel + 20 + $self->{tic_length} * 3, $color
            );

            #            $image->string(
            #                GD::Font->Large,
            #                $self->resolveValue($i),
            #                $other_pixel + 10 + $self->{tic_length} * 1.5,
            #                $i, $color
            #            );
        }
        ## infos
        foreach my $regions (@$gbFeature_Plottables) {

            #          $regions = $gbFeature_Plottables->{$gbTag};
            foreach my $region (@$regions) {
                unless (
                    defined $plot->getColor4gbFeatureTag(
                        $region->{gbFeatureTag} ) )
                {
         #           print "gbAxis gbFeature type ", $region->{gbFeatureTag},
         #             " is not displayed\n";
                    next;
                }
				next if ( lc($region->{gbFeatureTag}) =~ m/unsure/);
		#		print "USED gbFeature type ", $region->{gbFeatureTag},"\n";
                $image->line(
                    $self->resolveValue( $region->{start}->{min} ),
                    $other_pixel,
                    $self->resolveValue( $region->{start}->{min} ),
                    $other_pixel + 20,
                    $plot->getColor4gbFeatureTag( $region->{gbFeatureTag} )
                );
                $image->line(
                    $self->resolveValue( $region->{end}->{max} ),
                    $other_pixel,
                    $self->resolveValue( $region->{end}->{max} ),
                    $other_pixel + 20,
                    $plot->getColor4gbFeatureTag( $region->{gbFeatureTag} )
                );
		#		print "plotting a rectangle from ",$self->resolveValue( $region->{start}->{mean} )," / $other_pixel to ",
		#		$self->resolveValue( $region->{end}->{mean} )," / ",$other_pixel + 10,"\n";
				
                $image->filledRectangle(
                    $self->resolveValue( $region->{start}->{mean} ),
                    $other_pixel,
                    $self->resolveValue( $region->{end}->{mean} ),
                    $other_pixel + 20,
                    $plot->getColor4gbFeatureTag( $region->{gbFeatureTag} )
                );
            }
        }

    }

    else {
        my @result = $self->{font}->testLarge(
            $image,
            $self->{axis_title},
            $other_pixel - $self->{tic_length} * 4,
            $self->resolveValue( ( $max + $min ) / 2 ) + 4 *
              length( $self->{axis_title} ),
            $color,
            1.570796
        );

        $self->{font}->plotLargeString(
            $image,
            $self->{axis_title},
            $other_pixel - $self->{tic_length} * 4,
            $self->resolveValue( ( $max + $min ) / 2 ) + 4 *
              length( $self->{axis_title} ) - (
                ( $result[1] - $self->reolveValue($min) ) -
                  ( $self->resolveValue($max) - $result[5] )
              ),
            $color, 1.570796
        );

        #        $image->stringUp(
        #            GD::Font->Giant,
        #            $other_pixel - $self->{tic_length} * 4,
        #            $self->resolveValue( ( $max + $min ) / 2 ) + 4 *
        #              length( $self->{axis_title} ),
        #            $self->{axis_title},
        #            $color
        #        );
        ## ruler
        $image->line(
            $other_pixel - 10,
            $self->resolveValue($min),
            $other_pixel, $self->resolveValue($min), $color
        );
        $image->line(
            $other_pixel - 10,
            $self->resolveValue($max),
            $other_pixel, $self->resolveValue($max), $color
        );
        $image->line( $other_pixel, $self->resolveValue($min),
            $other_pixel, $self->resolveValue($max), $color );
        $image->line(
            $other_pixel - 10,
            $self->resolveValue($min),
            $other_pixel - 10,
            $self->resolveValue($max), $color
        );
        for ( my $i = $min ; $i <= $max ; $i += $self->{dimension} ) {
            $image->line(
                $other_pixel - $self->{tic_length} - 10,
                $self->resolveValue($i),
                $other_pixel - 10,
                $self->resolveValue($i), $color
            );
            $self->{font}->plotSmallString(
                $image, $i,
                $other_pixel - $self->{tic_length} * 3 - 10,
                $self->resolveValue($i) - 8, $color
            );

            #            $image->string(
            #                GD::Font->Large,
            #                $other_pixel - $self->{tic_length} * 3 - 10,
            #                $self->resolveValue($i) - 8,
            #                $i, $color
            #            );
        }
        ## infos
        foreach my $gbTag ( keys %$gbFeature_Plottables ) {
            $regions = $gbFeature_Plottables->{$gbTag};
            foreach my $region (@$regions) {
                unless (
                    defined $plot->getColor4gbFeatureTag(
                        $region->{gbFeatureTag} ) )
                {
                    print "gbAxis gbFeature type ", $region->gbFeatureTag(),
                      " is not displayed\n";
                    next;
                }
				print "gbAxis gbFeature type ", $region->gbFeatureTag(),
				      " will be displayed!\n";
                $image->line(
                    $other_pixel - 10,
                    $self->resolveValue( $region->{start}->{min} ),
                    $other_pixel,
                    $self->resolveValue( $region->{start}->{min} ),
                    $plot->getColor4gbFeatureTag( $region->{gbFeatureTag} )
                );
                $image->line(
                    $other_pixel - 10,
                    $self->resolveValue( $region->{end}->{max} ),
                    $other_pixel,
                    $self->resolveValue( $region->{end}->{max} ),
                    $plot->getColor4gbFeatureTag( $region->{gbFeatureTag} )
                );
                $image->filledRectangle(
                    $other_pixel - 10,
                    $self->resolveValue( $region->{start}->{mean} ),
                    $other_pixel,
                    $self->resolveValue( $region->{end}->{mean} ),
                    $plot->getColor4gbFeatureTag( $region->{gbFeatureTag} )
                );
            }
        }

    }
    return 1 == 1;
}

1;
