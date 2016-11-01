package HMM;

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
use stefans_libs::statistics::HMM::UMS;

#suse stefans_libs::statistics::newGFFtoSignalMap;
use Date::Simple;
use stefans_libs::NimbleGene_config;
use stefans_libs::statistics::HMM::marcowChain;
use stefans_libs::plot::simpleXYgraph;
use warnings;

sub new {

	my ( $class, $debug ) = @_;

	my $self = {
		'debug' => $debug,

		#	    UMS_test => 1,
		arrayData => undef
	};

	bless( $self, "HMM" ) if ( $class eq "HMM" );

	return $self;
}

sub LogInfo {
	my ( $self, $path, $file_base ) = @_;

	$self->{path}     = $path      if ( defined $path );
	$self->{filebase} = $file_base if ( defined $file_base );
	unless ( -d $self->{path} ) {
		warn "we try to create path $self->{path}\n";
		mkdir( $self->{path} );
	}
	return $self->{path} . "/" . $self->{filebase};
}

sub _check_and_prepareStates {
	my ( $self, $states ) = @_;
	my @temp;
	$self->{error} = undef;
	foreach my $state (@$states) {
		push( @temp, $state->{name} );
	}

	foreach my $state (@$states) {
		return "you have to set the startProbability for state $state->{name}\n"
		  unless ( defined $state->{startProbability} );
		return "you have to set the endProbability for state $state->{name}\n"
		  unless ( defined $state->{endProbability} );
		foreach my $otherStateName (@temp) {
			return
"you have to set the probability for a change from $state->{name} to $otherStateName\n"
			  unless (
				defined $state->probability_for_change_to_state($otherStateName)
			  );
		}
	}
	foreach my $state (@$states) {
		$state->_setLogState2(1);
		return $state->{error} if ( defined $state->{error} );
	}
	$self->{states} = $states;
	return undef;
}

=head3 CalculateHMM

You have to use a hash of values to run this method.
states => [ a list of state_value objects ]
values => [ an array of observed values or an array of hashes ]
value_tag => if values is an array of hashes, the hash tag that contains the observed value
order_tags => if values is an array of hashes, the hash tags that contain the order info 
             ( that info will not be stored inside the class!)
splitFunction => an object that contains the function 'Sort'
	The sort function as to return either 
	true  (1,  a break in the marcow chain) or 
	false (0, no break in the marcow chain
	the array of order_tags will be given to this function. 
path => the path where the probabilitystates should be stored
file_base => the base filename to store the markov states in
=cut

sub CalculateHMM {

	my ( $self, $hash ) = @_;

	## reconstruction!
	## 1. we only want to calculate here!!!
	## 2. the estimates have to be built somewhere else
	## therefore all we ned is
	##  a) the dataset ( either a array of values [NO grouping only one chain] or an array of hashes { value, odering })
	##  b) the info how to order the data values into several marcow chains
	##  c) the different states we want to search for (object from state_values)

	die
"the class has changed! we need a list of state_values (states => [<list>])!\n"
	  unless ( defined( @{ $hash->{states} }[1] ) );
	die
"the class has changed! we need a list of state_values (states => [<list>])!\n"
	  unless ( ref( @{ $hash->{states} }[1] ) eq "state_values" );
	## the split function has to be a normal perl function that returns 0 -> no split
	## or 1 -> a split when the $hash->{order_tags} values are presented to the function
	#	   package mySorter;
	#
	#		sub new {
	#		        my  $self = {};
	#		        bless $self, 'mySorter';
	#		        return $self;
	#		}
	#
	#		sub Sort {
	#		        my ( $self, $old_value1, $old_value2, $value1, $value2 ) = @_;
	#
	#		        print "$old_value1 eq $value1 \n";
	#		        return 1 if ( ! ( $old_value1 eq $value1 ) );
	#		        print "$value2  - $old_value2 > 500\n";
	#		        return 1 if ( $value2  - $old_value2 > 500 );
	#		        return 0;
	#		};

	## now the state values have to be checked!

	$self->initMarcowChains($hash);
	die "we have ", scalar( @{ $self->{'Markov_Table'} } ),
	  " markow chains!\n$self->{error}\n"
	  if ( scalar( @{ $self->{'Markov_Table'} } ) == 0 );
	die $self->{error} if ( defined $self->{error} );

	$self->LogInfo( $hash->{path}, $hash->{file_base} );
	$self->Presets( $hash->{states} );

	if ( defined $self->LogInfo() ) {
		$self->PrintReestimate("firstEstimation");
	}
	$hash->{iterations} = 1 unless ( defined $hash->{iterations} );

	for ( my $i = 1 ; $i <= $hash->{iterations} ; $i++ ) {
		$self->_calculateOneIteration($i);

		$self->plotFirst_MarkowChain_2_image($i);

		unless ( $i == $hash->{iterations} ) {
			$self->ReestimateMarkowModel( $i, $hash->{path} )
			  ;    ## das muss ich noch nachsehen!!!!
			$self->PrintReestimate("iteration_$i");
		}
	}
	## das muss hier noch definiert werden, wie wir mit den Daten weiter verfahren!!
	## warscheinlich waere ein Hash of arrays ganz nett... $p_H = {stateName1 => \@arrayOf_P_values, stateName1 => ... }

	## should be easy!!
	#	my ( $return, $temp );
	#	$return = @{ $self->{'Markov_Table'} }[0]->getState_P_values();
	#	for ( my $i = 1 ; $i < @{ $self->{'Markov_Table'} } ; $i++ ) {
	#		$temp = @{ $self->{'Markov_Table'} }[$i]->getState_P_values();
	#		foreach my $state ( keys %$temp ) {
	#			push( @{ $return->{$state} }, ( @{ $temp->{$state} } ) );
	#		}
	#	}
	print "HMM calculation -> ready!\n";
	return 1;
}

sub plotFirst_MarkowChain_2_image {
	my ( $self, $iteration ) = @_;
	my ( $xy_plot, $data );
	$xy_plot = simpleXYgraph->new();

	#	$xy_plot->plotData(
	#		$self->getAsPlottable($Markov_Table),
	#		800, 600,
	#		"day", "p value",
	#		"HMM iteration $iteration",
	#		$self->LogInfo() . "iteration_$iteration.svg"
	#	);
	#	return 1;

	$xy_plot->createPicture( 800, 600 );
	$xy_plot->{xaxis} = undef;
	$xy_plot->{yaxis} = undef;

	#$self->{'plotThisChain'} = 0 unless ( defined $self->{'plotThisChain'});
	print ref($self)
	  . "::plotFirst_MarkowChain_2_image -> we use the marcov chain nr. $self->{'plotThisChain'}\n";

	$xy_plot->plot_2_image(
		{
			'data' => $self->getAsPlottable(
				@{ $self->{'Markov_Table'} }[ $self->{'plotThisChain'} ]
			),
			'x_min'  => 80,
			'x_max'  => 720,
			'y_min'  => 60,
			'y_max'  => 240,
			'xTitle' => "day",
			'yTitle' => 'p value',
			'size'   => 'small'
		}
	);

	foreach my $state ( sort @{ $self->{states} } ) {
		$data->{ $state->{name} } = $state->getAs_XY_plottable();
	}
	$xy_plot->{xaxis}              = undef;
	$xy_plot->{yaxis}              = undef;
	$xy_plot->{color}->{nextColor} = 0;

	$xy_plot->plot_2_image(
		{
			'data'   => $data,
			'x_min'  => 80,
			'x_max'  => 360,
			'y_min'  => 360,
			'y_max'  => 540,
			'xTitle' => "probability functions",
			'yTitle' => 'p value',
			'size'   => 'small'
		}
	);
	my $xaxis = axis->new( "x", 440, 760, "transmission probabilities", "min" );
	$xaxis->min_value(0);
	$xaxis->max_value(10);
	$xaxis->resolveValue(0);
	my $y_lines = 15;
	my $yaxis = axis->new( "y", 360, 540, "transmission probabilities", "min" );
	$yaxis->min_value(0);
	$yaxis->max_value($y_lines);
	$yaxis->resolveValue(0);

	$data = {};

	$xy_plot->{font}->plotString(
		$xy_plot->{im}, "Probability Functions",
		100, 340, $xy_plot->{color}->{black},
		undef, "gbFeature"
	);
	$xy_plot->{font}->plotString(
		$xy_plot->{im}, "Transmission Probabilities",
		500, 340, $xy_plot->{color}->{black},
		undef, "gbFeature"
	);

	foreach my $state ( @{ $self->{states} } ) {

#print "the probability (log scale!) to change from $state->{name} to $state->{name} =",
#$state->probability_for_change_to_state($state->{name}), "\n";
		$data->{"$state->{name} to $state->{name}"} =
		  exp( $state->probability_for_change_to_state( $state->{name} ) );
		foreach my $otherName ( $state->OtherStateNames() ) {
			$data->{"$state->{name} to $otherName"} =
			  exp( $state->probability_for_change_to_state($otherName) );
		}
	}
	my $i = 0;

	foreach my $trans_prob_name ( sort keys %$data ) {
		$xy_plot->{font}->plotString(
			$xy_plot->{im},             $trans_prob_name,
			$xaxis->resolveValue(0),    $yaxis->resolveValue( $y_lines - $i ),
			$xy_plot->{color}->{black}, undef,
			"small"
		);
		$xy_plot->{font}->plotString(
			$xy_plot->{im},
			sprintf( "%.2e", $data->{$trans_prob_name} ),
			$xaxis->resolveValue(4),
			$yaxis->resolveValue( $y_lines - $i ),
			$xy_plot->{color}->{black},
			undef,
			"small"
		);
		$i++;
	}

	$xy_plot->plot_title("HMM iteration $iteration");
	$xy_plot->writePicture(
		$self->LogInfo() . "_new_iteration_$iteration.svg" );
	return 1;
}

=head3 getAsPlottable

returns the p values from the first markow chain as a plottable that can be plotted using the simpleXYgraph class.

=cut

sub getAsPlottable {
	my ( $self, $marcovChain ) = @_;
	unless ( ref($marcovChain) eq "marcowChain" ) {
		die "we have no markow chains here !\n$!\n"
		  unless ( defined @{ $self->{'Markov_Table'} }[0] );
		$marcovChain = @{ $self->{'Markov_Table'} }[0];
	}
	my $hash;
	foreach my $stateName ( keys %{ $marcovChain->{p_H} } ) {
		$hash->{"state $stateName"} = { 'x' => [], 'y' => [] };
		for ( my $i = 0 ; $i < @{ $marcovChain->{'p_H'}->{$stateName} } ; $i++ )
		{
			push( @{ $hash->{"state $stateName"}->{'x'} }, $i );
			push(
				@{ $hash->{"state $stateName"}->{'y'} },
				exp(
					@{
						$marcovChain->{'p_H'}->{$stateName}
					  }[$i]
				)
			);
		}
	}
	return $hash;
}

sub get_hiddenState_as_array {
	my ( $self, $stateName ) = @_;
	my $return = [];
	foreach my $marcow_chain ( @{ $self->{'Markov_Table'} } ) {
		push( @$return, $marcow_chain->{'p_H'}->{$stateName} );
	}
	print "HMM::get_hiddenState_as_array -> we return an array of "
	  . scalar(@$return)
	  . " arrays ";
	print "with "
	  . scalar( @{ @$return[0] } ) . " and "
	  . scalar( @{ @$return[1] } )
	  . " entries in the array 1 and the array 2\n";
	return $return;
}

=head2 get_P_values_for_internalState

Be careful - you will NOT get an array of p_values, but an array of arrays of p_values.
That is due to the fact, that I want to ceep the memeory usage as low as possible and I do not want to compy all values into a new array.
The order of the p_values in the arrays is the same as in the original observed states array you used to calculate the HMM 
exept that the value 0 in your observed values is in the first array at position 0.
To iterate over the p_values use this function:

my $position = 0;
my $return_value = $hmm->get_P_values_for_internalState('your internal state name');
for ( my $marcov_chain_id = 0; $marcov_chain_id < @$return_value ; $marcov_chain_id ++ ){
	for ( $position = 0 ; $position < @$marcov_p_values; $position ++){
		## do something with the p_value @$marcov_p_values[$position];
	}
}

I hope this may help!

=cut

sub get_P_values_for_internalState {
	my ( $self, $stateName ) = @_;
	my @return;
	foreach my $markowChain ( @{ $self->{'Markov_Table'} } ) {
		push( @return, $markowChain->get_P_values_for_state($stateName) );
	}
	return \@return;
}

sub PrintReestimate {
	my ( $self, $iteration ) = @_;

	return $self->exportPresets($iteration);
}

sub _calculateOneIteration {
	my ($self) = @_;

	foreach my $marcovChain ( @{ $self->{'Markov_Table'} } ) {

		#print "$self->_calculateOneIteration\n";
		$marcovChain->CalculateForwardProbability();

		#print "\tCalculateBackwardProbability\n";
		$marcovChain->CalculateBackwardProbability();

		#print "\tCalculateTotalProbabilityFromStartToEnd\n";
		$marcovChain->CalculateTotalProbabilityFromStartToEnd();

		#$marcovChain->CalculateProbOfTransitions();
	}
	return 1;
}

sub Presets {
	my ( $self, $presets ) = @_;

	$self->{presets} = $presets if ( defined @$presets[0] );

	#foreach ( @{$self->{presets}} ){
	#	print $_->print();
	#}
	return $self->{presets};
}

sub LogTheHash {
	my ( $self, $hashRef ) = @_;

	$hashRef->LogTheHash;

	#foreach my $rv (keys %$hashRef){
	#  $hashRef->{$rv} = log($hashRef->{$rv});
	#}
	#  foreach my $rv (sort keys %$hashRef){
	#     print "$rv -> ",exp($hashRef->{$rv}),"\n";
	#  }
	return $hashRef;
}

=head3 ReestimateMarkowModel

If not in debug mode, this function andles all the reestimation calculations.
You can look into the code if you want to know the details.

If in debug mode, this function returns an has of values important for the recalculation:
Inside the hash, the p_values->{<state name>} hashes include the summarized p_values separated for the different value groups.
Take care, as only these values are alwas in a linear scale. All other values are either in a log or linar scale depending on the internal sacle of the state_values.
But as the whole HMM calculation is based on log values the most probably will be in log scale!
Namely we have the probabilities, that a state changes to another state in the hash entries of the format '<state name> to <state name>',
and the summary p_values in a hash (entry 'p_summary_values') of the structure {'<state name>' => <summary value>}.

=cut  

sub ReestimateMarkowModel {
	my ( $self, $iteration, $path ) = @_;

	my ( $marcowChain, $p_summaries, $allStates, $actual );

	foreach $marcowChain ( @{ $self->{'Markov_Table'} } ) {
		## calculate the sum of probabilities, that a given state changes to another one for each marcowChain
		$marcowChain->CalculateProbOfTransitions();
	}

	$p_summaries = {};
	$allStates   = {};
	##we have to get the p_value summary for each dataset!
	foreach my $state ( @{ $self->{states} } ) {

#print "p summary for state $state->{name} ($state->{probHist}) = ",$state->summary_P_value(),"\n";
		$p_summaries->{ $state->{name} } = $state->summary_P_value();
		$allStates->{ $state->{name} }   = $state;
	}

	## if we are in debug mode, we have to store the internal summary values and report them back
	if ( $self->{debug} ) {
		my (@otherStates);
		$self->{sum_over_reestimations} = {
			'p_values'         => {},
			'p_summary_values' => $p_summaries,
			'old p_values'     => {},
			'reestimations'    => {},
		};
		foreach my $state ( @{ $self->{states} } ) {
			## get the new p_value summaries
			$self->{sum_over_reestimations}->{'p_values'}->{ $state->{name} } =
			  {};
			while ( my ( $key, $value ) =
				each %{ $state->{probHist}->{new_data} } )
			{
				$self->{sum_over_reestimations}->{'p_values'}
				  ->{ $state->{name} }->{$key} = $value;
			}
			$self->{sum_over_reestimations}->{'old p_values'}
			  ->{ $state->{name} } = {};
			while ( my ( $key, $value ) =
				each %{ $state->{probHist}->{new_data} } )
			{
				$self->{sum_over_reestimations}->{'old p_values'}
				  ->{ $state->{name} }->{$key} = $value;
			}

			@otherStates = $state->OtherStateNames();
			push( @otherStates, $state->{name} );

			#print "other states for state $state->{name} = @otherStates\n";
			foreach my $otherStateName (@otherStates) {

		   #print "we create a hash entry '$state->{name} to $otherStateName' ";
				$self->{sum_over_reestimations}
				  ->{"$state->{name} to $otherStateName"} =
				  $state->sumOf($otherStateName);

#print "with the value ",$self->{sum_over_reestimations}->{"$state->{name} to $otherStateName"},"\n";
			}
		}
	}

	## now all transmission states should be calculated in our $self->{states} object array
	## we can access the states using the $state->sumOf('other state name') funcion
	foreach my $state ( @{ $self->{states} } ) {
		$actual =
		  $state->reestimateTransmisionProbabilities( $p_summaries,
			$allStates );
		if ( $self->{debug} ) {
			foreach my $key (%$actual) {
				$self->{sum_over_reestimations}->{reestimations}->{$key} =
				  $actual->{$key};
			}
		}
	}
	foreach my $state ( @{ $self->{states} } ) {
		$state->finalizeReestimation( $p_summaries, $allStates );
	}

	#	foreach my $state ( @{$self->{states}}){
	#		warn $state->export();
	#	}

	return $self->{sum_over_reestimations} if ( $self->{debug} );

	#	die;
	return $self->{sum_over_reestimations};
}

sub Log_median($) {
	my ( $self, $Werte ) = @_;
	my ( @Werte, $wert );    #@_;
	my $i = 0;
	foreach $wert (@$Werte) {
		$Werte[ $i++ ] = $wert if ( defined $wert );
	}
	@Werte = ( sort { $a <=> $b } @Werte );
	my $max = @Werte;
	return $Werte[0] if ( $max <= 1 );

	return $Werte[ int( ( $max + 0.5 ) / 2 ) ]
	  if ( int( $max / 2 ) != $max / 2 );
	return $self->Add2Logs( $Werte[ int( $max / 2 ) - 1 ],
		$Werte[ int( $max / 2 ) ] ) - log(2);
}

sub Add2Logs {
	my ( $self, $logA, $logB ) = @_;
	return $logB unless ( defined $logA );
	return $logA unless ( defined $logB );
	return $logA + log( 1 + exp( $logB - $logA ) );
}

sub exportPresets {
	my ( $self, $iteration ) = @_;

	my $filebase = $self->LogInfo();

	return 0 if ( $filebase eq "/" );

	open( Reestimate, ">$filebase-$iteration.csv" )
	  or die "could not craete file '$filebase-$iteration.csv'\n";
	print Reestimate "presets\n";

	foreach ( @{ $self->{presets} } ) {

		#print "new presets set\n";
		print Reestimate $_->export();

		#print "//";
	}
	close Reestimate;
}

sub importPresets {
	my ( $self, $filename ) = @_;

	open( IN, "<$filename" ) or die "could not open presets file $filename\n";
	my $line = 0;
	my ( @lines, @presets );
	while (<IN>) {
		$line++;
		if ( $line == 1 ) {
			unless ( $_ eq "presets\n" ) {
				close(IN);
				die "not a valid presets file ($filename)\n";
			}
			next;
		}
		if ( $line == 2 ) {
			unless ( $_ eq "new presets set\n" ) {
				close(IN);
				die "not a valid presets file ($filename)\n";
			}
			next;
		}
		if ( $_ eq "//\n" ) {
			$line = 1;
			my $preset = state_values->new();
			$preset->import_from_line_array( \@lines );
			push( @presets, $preset );
			@lines = ();
			next;
		}
		push( @lines, $_ );
	}
	return $self->Presets( \@presets );
}

sub getMarcowID4oligoPosition {
	my ( $self, $oligoPosition ) = @_;
	my $data = $self->{marcowChain2OligoNr};
	foreach my $cutoff ( sort { $b <=> $a } keys %$data ) {
		return $data->{$cutoff} if ( $oligoPosition <= $cutoff );
	}
	root::print_hashEntries( $data, 2,
		"HMM->getMarcowID4oligoPosition $oligoPosition was not found!" );
	die;
}

sub initMarcowChains {
	my ( $self, $hash ) = @_;

	$self->{error} = "";

	unless ( defined @{ $hash->{values} } ) {
		$self->{error} =
"the class has changed! we need an array of values to calculate on ( values => [] )\n";
		return [];
	}
	unless ( @{ $hash->{values} }[0] =~ m/\d/
		|| ref( @{ $hash->{values} }[0] ) eq "HASH" )
	{
		$self->{error} =
"the class has changed! we need either an array of values or an array of hashes!\n";
		return [];
	}

	if ( ref( @{ $hash->{values} }[0] ) eq "HASH" ) {
		unless ( defined $hash->{value_tag} ) {
			$self->{error} =
			  "the class has changed! we need a value_tag and order_tags\n";
			return [];
		}
	}
	if ( defined $hash->{order_tags} ) {
		if ( defined @{ $hash->{order_tags} }[0] ) {
			unless ( defined $hash->{splitFunction} ) {
				$self->{error} =
"together with an oder_tag, we need the info how to split the dataset into marcow lines! (splitFunction)\n";
				return [];
			}
		}
	}

	$self->_check_and_prepareStates( $hash->{states} );
	die $self->{error} if ( defined $self->{error} );

	my ( $tag, @oldValues, $values, @Markov_Table );

	## create the marcow chain!
	if ( defined $hash->{order_tags} ) {
		@oldValues = ();
		foreach my $dataset ( @{ $hash->{values} } ) {
			@$values = ();
			foreach $tag ( @{ $hash->{order_tags} } ) {
				push( @$values, $dataset->{$tag} );
			}
			if ( $hash->{splitFunction}->Sort( @oldValues, @$values ) ) {
				push( @Markov_Table,
					marcowChain->new( $hash->{states}, $self->{debug} ) );
			}
			@oldValues = (@$values);
			@Markov_Table[ @Markov_Table - 1 ]
			  ->addValue( $dataset->{ $hash->{value_tag} } );
		}
	}
	elsif ( defined $hash->{value_tag} ) {
		my $marcowChain = marcowChain->new( $hash->{states}, $self->{debug} );
		foreach my $dataset ( @{ $hash->{values} } ) {
			$marcowChain->addValue( $dataset->{ $hash->{value_tag} } );
		}
		push( @Markov_Table, $marcowChain );
	}
	else {
		## we should have gotten a simple array of values!
		#  or an array of arrays if we have multiple marcow lines...
		if (   ref( $hash->{'values'} ) eq "ARRAY"
			&& ref( @{ $hash->{'values'} }[0] ) eq "ARRAY" )
		{
			foreach my $dataset ( @{ $hash->{'values'} } ) {

				#print "we here in HMM.pm create a new marcow chain with "
				#  . scalar(@$dataset)
				#  . " values!\n";
				my $marcowChain =
				  marcowChain->new( $hash->{states}, $self->{debug} );
				$marcowChain->addValueArray($dataset);
				push( @Markov_Table, $marcowChain );
			}
		}
		elsif ( ref( $hash->{'values'} ) eq "ARRAY" ) {

			#print "we here in HMM.pm create a single new marcow chain!\n";
			my $marcowChain =
			  marcowChain->new( $hash->{states}, $self->{debug} );
			$marcowChain->addValueArray( $hash->{values} );
			push( @Markov_Table, $marcowChain );
		}
		else {
			Carp::confess(
				ref($self)
				  . "::initMarcowChains -> sorry, but we can not handle the dataset $hash->{values}!"
			);
		}

	}
	my ( $max, $max_chain );
	$max = 0;
	for ( my $i = 0 ; $i < @Markov_Table ; $i++ ) {
		if ( $Markov_Table[$i]->Length() > $max ) {
			$max       = $Markov_Table[$i]->Length();
			$max_chain = $i;
		}
	}
	print
"during the initiation of the marcow chains we identified the chain nr. $max_chain to conatin the most entries ( $max) \n";
	$self->{'plotThisChain'} = $max_chain;

	#die "Created ", scalar(@Markov_Table) , " chains\n";
	$self->{'Markov_Table'} = \@Markov_Table;
	return \@Markov_Table;
}

1;

