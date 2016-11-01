package simpleXYgraph;

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
use GD::SVG;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use stefans_libs::plot::figure;
use base ('figure');

use strict;

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		im    => undef,
		color => undef,
		font  => undef
	};

	bless $self, $class if ( $class eq "simpleXYgraph" );

	return $self;

}

=head2 AddDataset ( {
	'title'
	'x'
	'y'
})

=cut

sub AddDataset{
	my ( $self, $dataset ) = @_;
	Carp::confess( $self->{'error'}) unless ( $self->_check_dataset($dataset));
	my ( $xyData);

	$self->__adjust_X_values_min_max ( $dataset->{x} );
	$self->__adjust_Y_values_min_max ( $dataset->{y}, $dataset->{stdAbw});
	
	unless ( ref($self->{'data'}) eq "ARRAY"){
		$self->{'data'} = [];
		$self->{'data_titles'} = [];
	}
	my @datasets;
	if ( ref($dataset->{stdAbw}) eq "ARRAY"){
		for ( my $i = 0 ; $i < @{$dataset->{x}};$i++){
			push ( @datasets, { 'x' => @{$dataset->{x}}[$i], 'y' => @{$dataset->{'y'}}[$i], 'stdAbw' => @{$dataset->{'stdAbw'}}[$i]});
		}
	}
	else {
		for ( my $i = 0 ; $i < @{$dataset->{x}};$i++){
			push ( @datasets, { 'x' => @{$dataset->{x}}[$i], 'y' => @{$dataset->{'y'}}[$i] });
		}
	}
	push ( @{$self->{'data'}}, [sort { $a->{'x'} <=> $b -> {'x'} } @datasets] );
	push ( @{$self->{'data_titles'}},$dataset->{'title'});
	return 1;
}

sub __we_contain_data{
	my ( $self ) = @_;
	return ref($self->{'data'}) eq "ARRAY";
}

sub _check_dataset {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';
	$self->{'error'} .= ref($self) ."::_check_dataset -> we need a 'title' for this dataset!\n" unless ( defined $dataset->{'title'});
	unless ( defined $dataset->{'x'}){
		$self->{'error'} .= ref($self) ."::_check_dataset -> we need a value 'x' for this dataset!\n";
	}
	elsif ( ! ref($dataset->{'x'}) eq "ARRAY"){
		$self->{'error'} .= ref($self) ."::_check_dataset -> the value 'x' has to be of the type 'ARRAY'\n";
	}
	unless ( defined $dataset->{'y'}){
		$self->{'error'} .= ref($self) ."::_check_dataset -> we need a value 'y' for this dataset!\n";
	}
	elsif ( ! ref($dataset->{'y'}) eq "ARRAY"){
		$self->{'error'} .= ref($self) ."::_check_dataset -> the value 'y' has to be of the type 'ARRAY'\n";
	}
	return 0 if ($self->{'error'} =~ m/\w/ );
	return 1;
}

sub _getDatasets{
	my ( $self ) = @_;
	Carp::confess ( "we do not have any data to plot!\n" ) unless ( $self->__we_contain_data() );
	my @data;
	for ( my $i = 0; $i < @{$self->{'data'}}; $i++ ){
		push ( @data, {'name' => @{$self->{'data_titles'}}[$i],  'data' => @{$self->{'data'}}[$i]});
	}
	return @data;
}

sub No_Data_points{
	my ( $self, $data_name, $bool ) = @_;
	$self->{'__no_data_points__'} = {} unless (ref( $self->{'__no_data_points__'}) eq "HASH" );
	if ( defined $bool){
		$self->{'__no_data_points__'}->{$data_name} = $bool;
	}
	return $self->{'__no_data_points__'}->{$data_name};
}


sub No_Line_Between {
	my ( $self, $data_name, $bool ) = @_;
	$self->{'noLineBetweenDataPoints'} = {} unless (ref( $self->{'noLineBetweenDataPoints'}) eq "HASH" );
	if ( defined $bool){
		$self->{'noLineBetweenDataPoints'}->{$data_name} = $bool;
	}
	return $self->{'noLineBetweenDataPoints'}->{$data_name};
}

=head2 plot_Data ( 
	[ { 'x', 'y', <stdAbw> } ], # all are arrays of values!
	<color>, #this color you need to get from a color object!
	[ 'The dataset name' ], #only one dataset name will be used here!
} )

=cut

sub plot_Data {
	my ( $self, $data, $color, @dataset_name ) = @_;
	
	print root::get_hashEntries_as_string ( [ $data, $color, @dataset_name] , 3 , ref($self)."->plot_Data()" );
	
	my $dataset_name = pop ( @dataset_name );
	## Daten plotten!
	my ( $lastx, $lasty, $x, $y, $stdAbw, $dataset );

	

	foreach $dataset ( @$data ) {
		( $x, $y, $stdAbw ) = ( $dataset->{'x'}, $dataset->{'y'}, $dataset->{'stdAbw'} );

		print "we plot $x -> $y with stdAbw = $stdAbw\n";
		unless ( defined $y ){
			warn "we miss a y value in ".ref($self)."::plot_Data\n";
			next;
		}
		unless (  $self->No_Data_points( $dataset_name ) ){
		$self->{im}->filledRectangle(
			$self->{xaxis}->resolveValue($x) - 2,
			$self->{yaxis}->resolveValue($y) - 2,
			$self->{xaxis}->resolveValue($x) + 2,
			$self->{yaxis}->resolveValue($y) + 2,
			$color
		);
		}
		$self->plotStdAbw( $x, $y, $stdAbw, $color )
		  if ( defined $stdAbw );

		next if ( $self->No_Line_Between( $dataset_name ) );
		if ( defined $lastx ) {
			$self->{im}->line(
				$self->{xaxis}->resolveValue($lastx),
				$self->{yaxis}->resolveValue($lasty),
				$self->{xaxis}->resolveValue($x),
				$self->{yaxis}->resolveValue($y),
				$color
			);
		}
		$lastx = $x;
		$lasty = $y;
	}
	return 1;
}

sub plotStdAbw {
	my ( $self, $x, $y, $stdAbw, $color ) = @_;

	#print "$self plotStdAbw got $x, $y, $stdAbw, $color\n";
	$self->{im}->line(
		$self->{xaxis}->resolveValue($x),
		$self->{yaxis}->resolveValue( $y + $stdAbw ),
		$self->{xaxis}->resolveValue($x),
		$self->{yaxis}->resolveValue( $y - $stdAbw ),
		$color
	);
	$self->{im}->line(
		$self->{xaxis}->resolveValue($x) + 4,
		$self->{yaxis}->resolveValue( $y - $stdAbw ),
		$self->{xaxis}->resolveValue($x) - 4,
		$self->{yaxis}->resolveValue( $y - $stdAbw ),
		$color
	);
	$self->{im}->line(
		$self->{xaxis}->resolveValue($x) + 4,
		$self->{yaxis}->resolveValue( $y + $stdAbw ),
		$self->{xaxis}->resolveValue($x) - 4,
		$self->{yaxis}->resolveValue( $y + $stdAbw ),
		$color
	);
	return 1;
}

sub X_axis {
	my ( $self, $xaxis ) = @_;
	if ( defined $xaxis ) {
		$self->{xaxis} = $xaxis if ( ref($xaxis) =~ m/[Aa]xis/ );
	}
	return $self->{xaxis};
}


1;
