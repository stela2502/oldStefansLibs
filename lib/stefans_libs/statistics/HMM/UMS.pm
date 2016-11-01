package UMS;

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
use warnings;
use stefans_libs::plot::simpleXYgraph;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A new package to gernerate the state_values used for the HMM calculation.
At the moment, this class can handle only floar data sets. 
It is able to select two probable groups from a dataset alone.
Whenever regions in the dataset are defined, that should correlate with one state, 
it is possible, to create more that two state_values objects.
So give it a try! By the way, FDR is not implemented!

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class UMS.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = { debug => $debug };

	bless $self, $class if ( $class eq "UMS" );

	$self->ProbabilityStates(10);
	return $self;

}

sub get_stateValues_for_dataset {
	my ( $self, $hash ) = @_;
	die ref($self),
":get_stateValues_for_dataset -> you have to give me some data to work on (entry 'data' has to be an array of arrays containing the datasets)\n"
	  unless ( defined $hash->{data}
		&& ref( @{ $hash->{data} }[0] ) eq "ARRAY" );
	die "I need get propper hypothesis datasets (entry 'hypothesies')\n"
	  unless ( defined $hash->{'hypothesies'}
		&& ref( @{ $hash->{'hypothesies'} }[0] ) eq "HMM_hypothesis" );

	my ( @return, $summary );
	$self->{allHist} = undef;
	foreach my $hyp ( @{ $hash->{'hypothesies'} } ) {
		$self->_getDistributions( $hash->{data}, $hyp );
	}
	die "why didnt we get the main distribution ($self->{allHist})?"
	  unless ( $self->{allHist}->isa('probabilityFunction') );

	## now we have to match the histograms against the overall distribution and scale them to one.
	foreach my $histoPosition ( sort keys %{ $self->{allHist}->{data} } ) {
		$summary = 0;
		foreach my $hyp ( @{ $hash->{'hypothesies'} } ) {
			$summary +=
			  $hyp->getStateValues_obj()->ProbabilityDistribution()->{data}
			  ->{$histoPosition};
		}
		foreach my $hyp ( @{ $hash->{'hypothesies'} } ) {
			  $hyp->getStateValues_obj()->ProbabilityDistribution()->{data}
			  ->{$histoPosition} =
			  $self->{allHist}->{data}->{$histoPosition} *
			  $hyp->getStateValues_obj()->ProbabilityDistribution()->{data}
			  ->{$histoPosition} /
			  $summary;
		}

	}
	foreach my $hyp ( @{ $hash->{'hypothesies'} } ) {
		$hyp->getStateValues_obj()->ProbabilityDistribution()->{scale21} = 0;
		$hyp->getStateValues_obj()->ProbabilityDistribution()->ScaleSumToOne();
		push( @return, $hyp->getStateValues_obj() );
	}
	## now the probability functions should be perfectly matched against the overall distribution.
	## we are left with the transition probabilities - perhaps this should be guessed outside of this class?!

	$self->{states} = \@return;
	return \@return;
}

=head2 calculate_components

This function can be used to calculate the influence of the first probability state on the overall distribution

=cut

sub calculate_components {
	my ( $self, $stateValues ) = @_;
	## probelm: we have several functions, that describe the overall dataset.
	#  now we want to estimate the overall mass of datapoints, that would be
	#  represented using one of these functions
	Carp::confess(
"sorry, but that can only be calculated (by me) if there are only two hypothesies! (we got "
		  . scalar(@$stateValues)
		  . ")" )
	  unless ( scalar(@$stateValues) == 2 );
	my $R = 1;
	my ( $sum, $temp_sum );

   #die root::get_hashEntries_as_string ( $stateValues, 3, "the state values" );
	for ( my $r = 0.001 ; $r < 1 ; $r += 0.001 ) {
		$temp_sum = 0;
		foreach my $dataVal ( keys %{ @$stateValues[0]->{probHist}->{data} } ) {
			$temp_sum +=
			  ( $self->{allHist}->{data}->{$dataVal} -
				  @$stateValues[0]->{probHist}->{data}->{$dataVal} *
				  $r +
				  ( 1 - $r ) *
				  @$stateValues[1]->{probHist}->{data}->{$dataVal} )**2;
		}
		#print "calculate_components -> r = $r; temp_sum = $temp_sum\n";
		if ( !defined $sum || $temp_sum < $sum ) {
			$sum = $temp_sum;
			$R   = $r;
		}
	}
	return $R;
}

sub _populateStateHash_from_hyp {
	my ( $self, $data, $hyp ) = @_;
	## first we need to know the name of the hmm internal state

}

sub Max {
	my ( $self, $max ) = @_;
	if ( defined $max ) {
		unless ( defined $self->{max} ) {
			$self->{max} = $max;
			$self->{min} = $max;
		}
		elsif ( $self->{max} < $max ) {
			$self->{max} = $max;
		}
		else {
			$self->Min($max);
		}
	}
	return $self->{max};
}

sub Min {
	my ( $self, $min ) = @_;
	if ( defined $min ) {
		if ( $self->{min} > $min ) {
			$self->{min} = $min;
		}
	}
	return $self->{min};
}

sub _quantilCutoff {
	my ( $self, $data, $quantile ) = @_;
	if ( lc($data) =~ m/hash/ ) {
		my @temp = ( values %$data );
		return $self->quantilCutoff( $data, $quantile );
	}
	my ( @sorted, $rank );
	@sorted = sort { $a <=> $b } @$data;
	$rank = int( ( $quantile * (@$data) ) );

	#	$rank = @$data - $rank;
	my $count = @$data;
	print
"max value = $sorted[0] min value = $sorted[$count-1] percentil $quantile = $sorted[$rank]\n";
	return $sorted[$rank];
}

sub ProbabilityStates {
	my ( $self, $probabilityStates ) = @_;
	$self->{probabilityStates} = $probabilityStates
	  if ( defined $probabilityStates );
	return $self->{probabilityStates};
}

sub _getDistributions {

	my ( $self, $data_arrays, $hyp ) = @_;

	## we will use histograms to summ up the data!
	## for a hmm 10 internal states should be enough
	## therefore, we will keep track only for those values step width
	## possibly we are not at the first run through the datatset and the overall distribution has been craeted?

	my ( $cutoff, $last_value, $hypoType, @data );
	foreach my $data (@$data_arrays) {
		push ( @data, @$data );
	}
	my $data = \@data;
		unless ( defined $self->{allHist} ) {
			$self->{allHist} = probabilityFunction->new();
			$self->{allHist}
			  ->CreateHistogram( $data, undef, $self->ProbabilityStates() );
			$self->{allHist}->removeNullstellen();
			$self->{allHist}->ScaleSumToOne();
		}

		$hypoType = $hyp->getHypType;
		print "we gt a hypothesis of type '", $hypoType, "'\n";

		if ( $hyp->getHypType eq "more_than" ) {
			print "we analyze type ", $hyp->getHypType, "\n";
			$cutoff = $self->_quantilCutoff( $data, $hyp->getHypEntry() );
			$hyp->getStateValues_obj()
			  ->ProbabilityDistribution(
				probabilityFunction->new( "", $self->{debug} ) );
			$hyp->getStateValues_obj()->ProbabilityDistribution()
			  ->copyLayout( $self->{allHist} );
			$last_value = @$data[0];
			for ( my $i = 1 ; $i < @$data ; $i++ ) {
				$hyp->getStateValues_obj()->ProbabilityDistribution()
				  ->AddValue( @$data[$i] )
				  if ( $last_value > $cutoff );
				$last_value = @$data[$i];
			}
		}
		elsif ( $hyp->getHypType eq "less_than" ) {
			print "we analyze type ", $hyp->getHypType, "\n";
			$cutoff = $self->_quantilCutoff( $data, $hyp->getHypEntry() );
			$hyp->getStateValues_obj()
			  ->ProbabilityDistribution(
				probabilityFunction->new( "", $self->{debug} ) );
			$hyp->getStateValues_obj()->ProbabilityDistribution()
			  ->copyLayout( $self->{allHist} );
			$last_value = @$data[0];
			for ( my $i = 1 ; $i < @$data ; $i++ ) {
				$hyp->getStateValues_obj()->ProbabilityDistribution()
				  ->AddValue( @$data[$i] )
				  if ( $last_value < $cutoff );
				$last_value = @$data[$i];
			}
		}
		elsif ( $hyp->getHypType eq "regions" ) {
			print "

 ", $hyp->getHypType, "\n";
			$hyp->getStateValues_obj()
			  ->ProbabilityDistribution( probabilityFunction->new() );
			$hyp->getStateValues_obj()->ProbabilityDistribution()
			  ->copyLayout( $self->{allHist} );
			foreach my $gbRegion ( @{ $hyp->getHypEntry() } ) {
				for (
					my $i = $gbRegion->Start() ;
					$i <= $gbRegion->End() ;
					$i++
				  )
				{
					$hyp->getStateValues_obj()->ProbabilityDistribution()
					  ->AddValue( @$data[$i] );
				}
			}
		}
		elsif ( $hyp->getHypType eq "in_between" ) {
			print "we analyze type ", $hyp->getHypType, "\n";
			my $cutoff_low =
			  $self->_quantilCutoff( $data, @{ $hyp->getHypEntry() }[0] );
			my $cutoff_high =
			  $self->_quantilCutoff( $data, @{ $hyp->getHypEntry() }[1] );
			$hyp->getStateValues_obj()
			  ->ProbabilityDistribution(
				probabilityFunction->new( "", $self->{debug} ) );
			$hyp->getStateValues_obj()->ProbabilityDistribution()
			  ->copyLayout( $self->{allHist} );
			$last_value = @$data[0];
			for ( my $i = 1 ; $i < @$data ; $i++ ) {
				$hyp->getStateValues_obj()->ProbabilityDistribution()
				  ->AddValue( @$data[$i] )
				  if ( $last_value < $cutoff_high
					&& $last_value > $cutoff_low );
				$last_value = @$data[$i];
			}
		}
	
	unless (
		ref( $hyp->getStateValues_obj()->ProbabilityDistribution() ) eq
		"probabilityFunction" )
	{
		die "we did not get the probability functions for the HMM_hypothesis  ",
		  $hyp->getHypType(), "\n$!\n";
	}
	$hyp->getStateValues_obj()->ProbabilityDistribution()->removeNullstellen();
	$hyp->getStateValues_obj()->ProbabilityDistribution()->ScaleSumToOne();
	@data = undef;
	return 1;
}

sub plot_states {
	my ( $self, $states, $filename ) = @_;
	my ( $xy_plot, $data );

	unless ( ref($states) eq "ARRAY" || ref( $self->{states} ) eq "ARRAY" ) {
		die ref($self), ":plot_states -> there are no states to plot!\n";
	}

	$self->{states} = $states
	  if ( defined @$states && ref($states) eq "state_values" );

	$xy_plot = simpleXYgraph->new();

	$xy_plot->createPicture( 800, 600 );
	$xy_plot->{xaxis} = undef;
	$xy_plot->{yaxis} = undef;

	foreach my $state ( @{ $self->{states} } ) {
		$data->{ $state->{name} } = $state->getAs_XY_plottable();
	}
	$data->{"all data"} = $self->{allHist}->getAs_XY_plottable();

	$xy_plot->{color}->{nextColor} = 0;

	$xy_plot->plot_2_image(
		{
			'x_min'  => 80,
			'x_max'  => 720,
			'y_min'  => 60,
			'y_max'  => 540,
			'data'   => $data,
			'xTitle' => "probability functions",
			'yTitle' => 'p value',
			'size'   => 'small'
		}
	);

	$xy_plot->plot_title("probabilities for the internal HMM states");
	$filename = "$filename.svg" unless ( $filename =~ m/.svg$/ );
	$xy_plot->writePicture("$filename");
	return 1;
}

1;
