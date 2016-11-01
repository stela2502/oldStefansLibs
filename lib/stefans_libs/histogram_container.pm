package histogram_container;

use strict;

use stefans_libs::statistics::new_histogram;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use GD;
use stefans_libs::plot::axis;

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

sub new {

	my ( $class, $spread ) = @_;

	my ( $self, @data, @titles );

	$spread = 1 unless ( defined $spread);

	print "DEBUG histogram_container was created using spread $spread\n";
	$self = {
		titles     => \@titles,
		'colors' => ['black', 'red', 'dark_blue','green' ],
		spread     => $spread,
		histograms => \@data
	};

	bless $self, $class if ( $class eq "histogram_container" );

	return $self;

}

sub createPicture {
	my ( $self, $x, $y ) = @_;
	my $size;
	return $self->{im} if ( defined $self->{im} );
	$x = 1000 unless ( defined $x );
	$y = 600  unless ( defined $y );
	$size = "large" if ( $x * $y >= 600000 );
	$size = "small" if ( $x * $y < 600000 );
	$size = "tiny"  if ( $x * $y < 120000 );
	$self->{x} = $x;
	$self->{y} = $y;

	#print "simpleXYgraph creates a picture ($x:$y)\n";
	$self->{im} = new GD::SVG::Image( $x, $y );
	$self->{color} = color->new( $self->{im} );
	$self->{xaxis} =
	  axis->new( "x", $x * 0.2, $x * 0.9, $self->Xtitle(), "$size" )
	  unless ( defined $self->{xaxis} );
	$self->{yaxis} =
	  axis->new( "y", $y * 0.1, $y * 0.8, $self->Ytitle(), "$size" )
	  unless ( defined $self->{yaxis} );
	$self->{font} = Font->new($size);
	return $self->{im};
}

sub scaleSum21 {
	my ($self) = @_;
	my $ref = $self->{histograms};
	$self->{scaleSum21} = 1 == 1;
	foreach my $hist (@$ref) {
		$hist->ScaleSumToOne();
	}
	return 1;
}

sub CreateHistogram{
	my ($self, $title, @array ) = @_;
	my $histogram = $self->getNewHistogram($title);
	$histogram->CreateHistogram ( @array );
	return $histogram;
}

sub AddDataArray {
	my ( $self, $title, $dataArray ) = @_;

	#print "$self -> AddDataArray $title, $dataArray";
	#print "@$dataArray\n";
	my $histogram = $self->getNewHistogram($title);
	$histogram->CreateHistogram (  $dataArray, undef, $self->{spread});
	#$histogram->AddDataArray( $dataArray, $self->{spread} );
	return $histogram->getAsDataMatrix();
}

sub Mark_position{
	my ( $self, $value, $color ) = @_;
	$color = 'red' unless (defined $color);
	if ( defined $self->{'marks'} ->{$value} ){
		warn "we will already set a makr at x position $value!\n";
		return 0;
	}
	$self->{'marks'} ->{$value} = $color;
	return 1;
}

sub getNewHistogram {
	my ( $self, $title, $color ) = @_;
	warn "new historgram dataset in $self without title information\n"
	  unless ( defined $title );
	push( @{$self->{titles}}, $title );
	if ( defined $color){
		@{$self->{colors}}[@{$self->{histograms}}] =  $color;
	}
	
	my $histogram = new_histogram->new();
	push( @{$self->{histograms}}, $histogram );
	$histogram ->{'bins'} = @{$self->{histograms}}[0]->{'bins'} if ( scalar(@{$self->{histograms}}) > 1);
	return $histogram;
}

sub plot {
	my ( $self, $filename, $x_res, $y_res ) = @_;
	my ( $im, $ref, @dataMatrixes, $min, $max, $temp, $color, @color,$group_title,$x_title );
	
	if ( ref($filename) eq "HASH" ){
		$x_res = $filename->{'x_resolution'};
		$y_res = $filename->{'y_resolution'};
		$x_res = 600 unless ( defined $x_res );
		$y_res = 400 unless ( defined $y_res );
		$im = $self->createPicture( $x_res, $y_res );
		$x_title = $filename->{'x_title'};
		$self->Xtitle($filename->{'x_title'});
		$self->{xaxis}->Title($filename->{'x_title'});
		$filename = $filename->{'outfile'};
	}
	else {
		$x_res = 600 unless ( defined $x_res );
		$y_res = 400 unless ( defined $y_res );
		$im = $self->createPicture( $x_res, $y_res );
	}

	$ref = $self->{histograms};
	unless ( $self->{scaleSum21} ) {
		foreach my $histo (@{$self->{histograms}}) {
			$temp = $histo->getAsDataMatrix();
			next unless ( defined @$temp[0] );
			push( @dataMatrixes, $temp );
			$self->{xaxis}->Max( @$temp[ @$temp - 1 ]->[1] );
			$self->{xaxis}->Min( @$temp[0]->[0] );
			$self->{yaxis}->Max( $histo->maxAmount() );
			$self->{yaxis}->Min( $histo->minAmount() );
		}
		$self->{xaxis}->max_value( $self->{xaxis}->Max );
		$self->{xaxis}->min_value( $self->{xaxis}->Min );
		$self->{yaxis}->max_value( $self->{yaxis}->Max );
		$self->{yaxis}->min_value( $self->{yaxis}->Min  );
	}
	else {
		my $max_y;
		foreach my $histo (@{$self->{histograms}}) {
			$temp = $histo->getAsDataMatrix();
			next unless ( defined @$temp[0] );
			push( @dataMatrixes, $temp );
			foreach my $array (@$temp){
				$self->{yaxis}->Max( @$array[2] );
				print "could be the max value @$array[2]\n";
			}
			$self->{xaxis}->Max( @$temp[ @$temp - 1 ]->[1] );
			$self->{xaxis}->Min( @$temp[0]->[0] );
		}
		$self->{xaxis}->max_value( $self->{xaxis}->Max );
		$self->{xaxis}->min_value( $self->{xaxis}->Min );
		$self->{yaxis}->max_value($self->{yaxis}->Max()) ;
		$self->{yaxis}->min_value(0);
	}
	$self->{xaxis}->resolveValue(0);
	$self->{yaxis}->resolveValue(0);

#print "creating x and y axis with x min = ",$self->{xaxis}->min_value()," max = ",
# 	 $self->{xaxis}->max_value()," y axis min = ",$self->{yaxis}->min_value()," max = ",
# 	 $self->{yaxis}->max_value(),"\n";
	$group_title = "x_axis_".rand();
	$im->newGroup($group_title);

	$self->{xaxis}->plot(
		$im,
		$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
		$self->{color}->{black},
		$self->Xtitle
	);
#	if ( defined $x_title) {
#		$self->{xaxis}->plotTitle( $im, $self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),$self->{color}->{black},
#		$x_title );
#	}
	$im->endGroup($group_title);
	$group_title = "y_axis".rand();
	$im->newGroup($group_title);
	$self->{yaxis}->plot(
		$im,
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{color}->{black},
		$self->Xtitle
	);
	$im->endGroup($group_title);

	for ( my $i = 0 ; $i < @dataMatrixes ; $i++ ) {
		$group_title = "dataset $self->{titles}[$i]".rand();
		$im->newGroup($group_title);
		$temp  = $dataMatrixes[$i];
		$color = $self->{color}->{@{$self->{colors}}[$i]};
		$color = $self->{color}->getNextColor() unless ( defined $color);
		
		$self->barGraph2im( $im, $temp, $color );
		$im->endGroup($group_title);
		$self->legend( $im, $self->{titles}[$i], $color, $i );
	}
	if ( defined $self->{'marks'} ){
		$group_title = 'Marks'.rand();
		$im->newGroup(  $group_title) ;
		foreach my $x_value ( keys %{$self->{'marks'}}){
			print "we mark the value $x_value\n";
			$im->line(
			$self->{xaxis}->resolveValue( $x_value ),
			$self->{yaxis}->resolveValue( $self->{yaxis}->min_value ),
			$self->{xaxis}->resolveValue( $x_value ),
			$self->{yaxis}->resolveValue( $self->{yaxis}->max_value ),
			$self->{color}->{$self->{'marks'}->{$x_value}}
		);
		}
		$im->endGroup( $group_title ) ;
	}
	if ( $self->Title() ){
		$self->{font}->plotStringCenteredAtXY( $im, $self->Title(), $x_res / 2 , 20 , $self->{color}->{black}, 'large', 0  );
	}
	$self->writePicture($filename);
}

sub Title{
	my ( $self, $title) = @_;
	return $self->{'title'} unless ( defined $title);
	return $self->{'title'}  = $title;
}

sub barGraph2im {
	my ( $self, $im, $dataset, $color ) = @_;
	foreach my $dataArray (@$dataset) {
		#print "we plot the matrix ".join("; ", @$dataArray)."\n";
		$im->line(
			$self->{xaxis}->resolveValue( @$dataArray[0] ),
			$self->{yaxis}->resolveValue( $self->{yaxis}->min_value ),
			$self->{xaxis}->resolveValue( @$dataArray[0] ),
			$self->{yaxis}->resolveValue( @$dataArray[2] ),
			$color
		);
		$im->line(
			$self->{xaxis}->resolveValue( @$dataArray[1] ),
			$self->{yaxis}->resolveValue( $self->{yaxis}->min_value ),
			$self->{xaxis}->resolveValue( @$dataArray[1] ),
			$self->{yaxis}->resolveValue( @$dataArray[2] ),
			$color
		);
		$im->line(
			$self->{xaxis}->resolveValue( @$dataArray[0] ),
			$self->{yaxis}->resolveValue( @$dataArray[2] ),
			$self->{xaxis}->resolveValue( @$dataArray[1] ),
			$self->{yaxis}->resolveValue( @$dataArray[2] ),
			$color
		);
	}
	return $im;
}

sub legend {
	my ( $self, $im, $title, $color, $i ) = @_;

#print "try to execute {font}->plotString($im, $title, $self->{x} * 0.66, 20 * ($i +1) , $color)\n";
	$self->{font}
	  ->plotString( $im, $title, $self->{x} * 0.66, 20 * ( $i + 1 ), $color );

	#warn "no legend is plotted as the function is only rudimentary!\n";
	return $im;
}

sub Xtitle {
	my ( $self, $title ) = @_;
	$self->{x_title} = $title if ( defined $title );
	$self->{x_title} = 'values' unless ( defined $self->{x_title});
	return $self->{x_title};
}

sub Ytitle {
	my ( $self, $title ) = @_;
	$self->{y_title} = $title if ( defined $title );
	$self->{y_title} = 'sum' unless ( defined $self->{y_title});
	return $self->{y_title};
}

sub writePicture {
	my ( $self, $pictureFileName ) = @_;

	# Das Bild speichern
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );
	print "We print to path $path\n";
	mkdir($path) unless ( -d $path );
	$pictureFileName .=  ".svg" unless ( $pictureFileName =~ m/\.svg$/);
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n$!\n";

	binmode PICTURE;

	print PICTURE $self->{im}->svg;
	close PICTURE;
	print "Bild als $pictureFileName gespeichert\n";
	return 1;
}

1;
