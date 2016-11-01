package legendPlot;
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

use stefans_libs::NimbleGene_config;

sub new {

    my ($class, ) = @_;

    my ( $self, %data );

    $self = { 
	   'data'      =>  undef,
	   'linespace' =>  1.5
	};

    bless $self, $class if ( $class eq "legendPlot" );

    return $self;

}

sub AddEntry {

    my ( $self, $antibodySpec, $cellType, $String, $color ) = @_;

    my ( $data, $hash, @cellType );
    @cellType = split (":", $cellType);
    return undef unless ( @_ == 5 );

    $data = $self->{data};
    $hash = {
        antibody => $antibodySpec,
        cellType => $cellType[1],
		organism => $cellType[0],
        char     => $String,
        color    => $color
    };
    $data->{"$cellType$antibodySpec"} = $hash;

}

sub _check_plot_2_image_hash {
	my ( $self, $hash ) = @_; 
	$self->{'error'} = $self->{'warning'} = '';
	$self->{'error'} .=  ref($self)." we need an image to plot to" unless ( defined $hash->{im} || defined $self->{im} );
	
	$self->{'error'} .=  ref($self).":plot_2_image - no x_axis and no possibillity to create one!"
		unless ( (defined ($hash->{x_min}) && defined ( $hash->{x_max})) || defined $hash->{xaxis} || defined $self->{'x_axis'} );
	unless ( (defined ($hash->{y_min}) && defined ( $hash->{y_max})) ){
		$self->{'error'} .=  ref($self).":plot_2_image - no y_axis and no possibillity to create one!";
	}
	else{
		$self->{'y1'} = $hash->{'x_max'};
		$self->{'y2'} = $hash->{'y_min'};
	}
	$self->{'error'} .=  ref($self).":plot_2_image - we need an color object!\n" unless ( defined $hash->{color} || defined $self->{color} );
	$self->{'error'} .=  ref($self).":plot_2_image - we need an external font object\n" unless ( defined $hash->{font} || defined $self->{font});
	$self->{'error'} .=  ref($self).":plot_2_image - we have no data to plot - funny you!\n" unless ( defined $self->{'data'});	
	return 0 if ( $self->{error} =~ m/\w/);
	return 1;
}

sub Plot_2_image {

    my ( $self, $x, $y, $im, $black ) = @_;

##  @bounds = $image->stringFT($fgcolor,$fontname,$ptsize,$angle,$x,$y,$string)
    my ( $Label_count, @bounds, $data, $font, $X, $Y, $information );

    $data = $self->{data};
    $X    = $x;

    # try to estimate the informative part of the label data
	my $count = { antibody => 0, celltype => 0, organism => 0};
	my $last = { antibody => 0, celltype => 0, organism => 0};
	$Label_count = 0;
	
	foreach my $value ( values %$data) {
	   $Label_count ++;
	   unless ( $value->{antibody} eq $last->{antibody} ){
	      $last->{antibody} = $value->{antibody};
		  $count->{antibody} ++;
	   }
	   unless ( $value->{cellType} eq $last->{cellType} ){
	      $last->{cellType} = $value->{cellType};
		  $count->{cellType} ++;
	   }
	   unless ( $value->{organism} eq $last->{organism} ){
	      $last->{organism} = $value->{organism};
		  $count->{organism} ++;
	   }
	}
	   
    foreach my $key ( sort keys %$data ) {
        next unless ( lc( $data->{$key} ) =~ m/hash/ );
        $information = $data->{$key};

#         @bounds = $im->stringFT($information->{color},$font,14,0,$x, $y, $information->{char});
#        $im->string( GD::Font->Large, $x, $y, $information->{char},
#            $information->{color} );
		@bounds = $self->{font}->plotSmallString($im, $information->{char}, $x, $y,
			  $information->{color}, 0);
		my ( $deltaX, $deltaY );
		$deltaX = $bounds[2] - $bounds[0];
		$deltaY = ($bounds[1] - $bounds[5]) * $self->{linespace};
		
		print "X word space in pixel = $deltaX ($bounds[2] - $bounds[0])\n",
		      "linespace in pixel $deltaY (($bounds[5] - $bound[1]) * $self->{linespace})\n";
		 	  
        #         ($x, $y ) = @bounds[4,5];
        $x = $x + $deltaX;
		if ( $count->{antibody} > 1 || $Label_count == 1){
		    @bounds = $self->{font}->plotSmallString($im, $information->{antibody}, $x, $y,
			   $black, 0);
            #$im->string( GD::Font->Large, $x, $y, $information->{antibody},
            #   $black );
            $x = $bounds[4] + $deltaX;
		}
		if ( $count->{cellType} > 1 || $Label_count == 1) {
		   @bounds = $self->{font}->plotSmallString($im, $information->{cellType}, $x, $y,
			   $black, 0);
           #$im->string( GD::Font->Large, $x, $y, $information->{cellType},
           # $black ) if ( $count->{cellType} > 1 || $Label_count == 1);
           $x = $bounds[4] + $deltaX;
		}
		if ( $count->{organism} > 1 || $Label_count == 1) {		
             @bounds = $self->{font}->plotSmallString($im, $information->{organism}, $x, $y,
			   $black, 0);
#        $im->string( GD::Font->Large, $x, $y, $information->{organism},
#            $black ) if ( $count->{organism} > 1 || $Label_count == 1);
#         @bounds = $im->stringFT($black, $font,14,0,$x, $y, "$information->{antibody}\t$information->{cellType}" );
		}
        $x = $X;
        $y = $y + $deltaY;    #@bounds[3];
    }
    return 1;
}

1;
