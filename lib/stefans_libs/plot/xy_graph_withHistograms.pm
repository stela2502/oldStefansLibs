package xy_graph_withHistograms;

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

use stefans_libs::statistics::new_histogram;
use stefans_libs::plot::simpleXYgraph;
use GD::SVG;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;

use warnings;

sub new {

	my ($class) = @_;

	my ($self);

	$self = {};

	bless $self, $class if ( $class eq "xy_graph_withHistograms" );

	return $self;

}

sub plotData {
	my ( $self, $matrix, $filename, $xres, $yres, $xTitle, $yTitle ) = @_;

	unless ( ( defined @$matrix && @$matrix > 1 )
		&& ( ref( @$matrix[0] ) eq "ARRAY" && ref( @$matrix[1] ) eq "ARRAY" ) )
	{
		warn "sorry, we ($self) need at least two arrays of values\n";
		return 0;
	}

	$xres = $yres = 800 unless ( defined $xres );
	$xres = $yres unless ( $xres == $yres );

	my (
		$dataBins, $x_array, $y_array,   $im,     $xyGraph,
		$x_histo,  $yHisto,  $locations, @xrange, @yrange
	);
	$x_array = @$matrix[0];
	$y_array = @$matrix[1];
	die "error: not the same amount of x and y values"
	  unless ( @$x_array == @$y_array );

	$self->createPicture( $xres, $yres );

	print "we got a picture of the size $self->{x}x$self->{y}?\n";

	$locations->{XY_y_max} = $self->{y} * 0.90;
	$locations->{XY_y_min} = $self->{y} * 0.30;
	$locations->{XY_x_max} = $self->{x} * 0.70;
	$locations->{XY_x_min} = $self->{x} * 0.10;

	$locations->{xHist_x_min} = $locations->{XY_x_min};
	$locations->{xHist_x_max} = $locations->{XY_x_max};
	$locations->{xHist_y_min} = $self->{y} * 0.05;
	$locations->{xHist_y_max} = $locations->{XY_y_min};

	$locations->{yHist_x_min} = $locations->{XY_x_max};
	$locations->{yHist_x_max} = $self->{x} * 0.90;
	$locations->{yHist_y_min} = $locations->{XY_y_min};
	$locations->{yHist_y_max} = $locations->{XY_y_max};

	print "We create a simpleXYgraph object!\n";
	$xyGraph = simpleXYgraph->new();
	$xyGraph ->{'color'} = $self->{'color'};
	$xyGraph ->{'font'} = $self->{'font'};
	$xyGraph->{noLineBetweenDataPoints} = 1;
	$xyGraph->AddDataset(
		{
			'title' => 'just a test',
			'x'     => @$matrix[0],
			'y'     => @$matrix[1]
		}
	);
	print root::get_hashEntries_as_string ( $self, 3,
		"where is the font object? " );
	$xyGraph->plot_2_image(
		{
			'im'      => $self->{im},
			'color'   => $self->{color},
			'font'    => $self->{'font'},
			'x_min'   => $locations->{XY_x_min},
			'x_max'   => $locations->{XY_x_max},
			'y_min'   => $locations->{XY_y_min},
			'y_max'   => $locations->{XY_y_max},
			'x_title' => $xTitle,
			'y_title' => $yTitle
		}
	);
	print "simpleXygraph sollte geschrieben sein!\n";

	## how many plots do we want in the histograms? ( 100 or 10)
	$dataBins = 10;
	$dataBins = 100 if ( @$x_array > 1000 );
	@xrange   = ( 0, 0 );
	@yrange   = ( 0, 0 );
	for ( my $i = 0 ; $i < @$x_array ; $i++ ) {
		$xrange[0] = @$x_array[$i] if ( @$x_array[$i] < $xrange[0] );
		$xrange[1] = @$x_array[$i] if ( @$x_array[$i] > $xrange[1] );
		$yrange[0] = @$y_array[$i] if ( @$y_array[$i] < $yrange[0] );
		$yrange[1] = @$y_array[$i] if ( @$y_array[$i] > $yrange[1] );
	}

	my $x_hist = new_histogram->new();
	$x_hist->CreateHistogram( $x_array, undef, $dataBins );
	my $temp = $x_hist->minAmount(0);
	print "we set the min hist value to $temp\n";
	root::print_hashEntries( $x_hist, 5,
		"the new_histogram internals after the adition of the array values!" );
	$x_hist->plot_2_image(
		{
			'im'            => $self->{im},
			'x_min'         => $locations->{xHist_x_min},
			'y_min'         => $locations->{xHist_y_min},
			'x_max'         => $locations->{xHist_x_max},
			'y_max'         => $locations->{xHist_y_max},
			'color'         => $self->{color}->{black},
			'fillColor'     => $self->{color}->{grey},
			'x_title'       => "",
			'y_title'       => "",
			'portrait'      => 0,
			'fixed_axis'    => $xyGraph->X_axis(),
			'fixed_axis_is' => "X"
		}
	);

	print "#1 is OK\n";

	my $y_hist = new_histogram->new();
	$y_hist->CreateHistogram( $y_array, undef, $dataBins );
	$temp = $y_hist->minAmount(0);
	print "we set the min hist value to $temp (2)\n";
	print $y_hist->getAsString();
	$y_hist->plot_2_image(
		{
			'im'            => $self->{im},
			'x_min'         => $locations->{yHist_x_min},
			'y_min'         => $locations->{yHist_y_min},
			'x_max'         => $locations->{yHist_x_max},
			'y_max'         => $locations->{yHist_y_max},
			'color'         => $self->{color}->{black},
			'fillColor'     => $self->{color}->{grey},
			'x_title'       => "",
			'y_title'       => "",
			'portrait'      => 1,
			'fixed_axis'    => $xyGraph->Y_axis(),
			'fixed_axis_is' => "Y"
		}
	);
	print "#2 is OK\n";
	$self->writePicture($filename);
	return 1;
}

sub createPicture {
	my ( $self, $x, $y ) = @_;
	my $size;
	return $self->{im} if ( defined $self->{im} );
	$x = 800 unless ( defined $x );
	$y = 800 unless ( defined $y );
	$size = "large" if ( $x * $y >= 600000 );
	$size = "small" if ( $x * $y < 600000 );
	$size = "tiny"  if ( $x * $y < 120000 );
	$self->{x} = $x;
	$self->{y} = $y;

	#print "simpleXYgraph creates a picture ($x:$y)\n";
	$self->{im}     = new GD::SVG::Image( $x, $y );
	$self->{color}  = color->new( $self->{im} );
	$self->{'font'} = Font->new($size);
	return $self->{im};
}

sub Color {
	my ( $self, $color ) = @_;
	$self->{color} = $color if ( ref($color) eq "color" );
	return $self->{color};
}

sub writePicture {
	my ( $self, $pictureFileName ) = @_;

	# Das Bild speichern
	print "bild unter $pictureFileName speichern:\n";
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );

	#print "We print to path $path\n";
	mkdir($path) unless ( -d $path );
	$pictureFileName = "$pictureFileName.svg"
	  unless ( $pictureFileName =~ m/\.svg$/ );
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n$!\n";

	binmode PICTURE;

	print PICTURE $self->{im}->svg;
	close PICTURE;
	print "Bild als $pictureFileName gespeichert\n";
	$self->{im} = undef;
	return 1;
}

1;
