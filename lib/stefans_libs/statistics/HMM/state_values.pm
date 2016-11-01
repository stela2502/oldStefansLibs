package state_values;

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

use stefans_libs::statistics::HMM::probabilityFunction;

sub new {

	my ( $class, $stateName ) = @_;

	die "state_values -> new absolutely needs a name of the state!"
	  unless ( defined $stateName );

	my ($self);

	$self = {
		name             => $stateName,
		log_state        => 0,
		otherStates      => my $hash,
		probHist         => undef,
		startProbability => undef,
		endProbability   => undef,
		reestimations    => my $temp
	};

	bless $self, $class if ( $class eq "state_values" );

	return $self;

}

=head3 reestimate_startProbability reestimate_endProbability

For the usage of the HMM statistics package this info is useless, as this functions are called internally!

This function is called during reestimation of the HMM probability functions.
It soud be called with the first/last p_value of every markow chain.
The provisional data is stored in $self->{reest_startProbability} and $self->{reest_endProbability},
but that should be read only by the test scripts, as it is not in log scale - even if the values are in log scale.
The log nature will be reapplied during the finalizeReestimation function call.

=cut

sub reestimate_startProbability {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( $value eq "start" ) {
			$self->{reest_startProbability_N} = 0;
			$self->{reest_startProbability}   = 0;
			return 0;
		}

		if ( $self->{log_state} ) {
			$value = exp($value);
		}

		$self->{reest_startProbability} += $value;
		$self->{reest_startProbability_N}++;
	}
	return
	  log( $self->{reest_startProbability} / $self->{reest_startProbability_N} )
	  if ( $self->{log_state} );
	return $self->{reest_startProbability} / $self->{reest_startProbability_N};
}

sub initReestimation {
	my ($self) = @_;
	$self->reestimate_startProbability("start");
	$self->reestimate_endProbability("start");
	$self->{probHist}->initReestimation();
}

sub reestimate_endProbability {
	my ( $self, $value ) = @_;

	if ( defined $value ) {
		if ( $value eq "start" ) {
			$self->{reest_endProbability_N} = 0;
			$self->{reest_endProbability}   = 0;
			return 0;
		}

		if ( $self->{log_state} ) {
			$value = exp($value);
		}
		$self->{reest_endProbability} += $value;
		$self->{reest_endProbability_N}++;

	}
	return
	  log( $self->{reest_endProbability} / $self->{reest_endProbability_N} )
	  if ( $self->{log_state} );
	return $self->{reest_endProbability} / $self->{reest_endProbability_N};
}

sub OtherStateNames {
	my ($self) = @_;
	return @{ $self->{otherNames} } if ( defined $self->{otherNames} );
	my @return;
	foreach my $key ( keys %{ $self->{otherStates} } ) {
		push( @return, $key ) unless ( $key eq $self->{name} );
	}
	$self->{otherNames} = \@return;
	return @return;
}

sub Log_state {
	my ( $self, $state ) = @_;
	if ( defined $state ) {
		if ( $self->{log_state} != $state ) {
			$self->_setLogState2($state);
		}
	}
	return $self->{log_state};
}

sub createFixedDataset {
	my ( $self, $hash ) = @_;
	my $hist;
	if ( defined $hash ) {
		$hist = probabilityFunction->new();
		$hist->createFixedDataset($hash);
		$hist->ScaleSumToOne();
		$self->ProbabilityDistribution($hist);
	}
	return $self->ProbabilityDistribution();
}

sub _setLogState2 {
	my ( $self, $state ) = @_;
	$self->{error} = undef;
	unless ( defined $self->{probHist} ) {
		$self->{error} = "no probabilityFunction available!\n";
		return "error";
	}
	if ( $self->{log_state} == 0 ) {
		return 1 if ( $state == 0 );
		foreach my $state ( keys %{ $self->{otherStates} } ) {
			if ( defined $self->{otherStates}->{$state}
				&& $self->{otherStates}->{$state} > 0 )
			{
				$self->{otherStates}->{$state} =
				  log( $self->{otherStates}->{$state} );

			}
			else {
				warn
"had to remove entry self->{otherStates}->{$state} (no loggable data)!";
				delete( $self->{otherStates}->{$state} );
			}
		}
		$self->{startProbability} = log( $self->{startProbability} )
		  if ( defined $self->{startProbability}
			&& $self->{startProbability} > 0 );
		$self->{endProbability} = log( $self->{endProbability} )
		  if ( defined $self->{endProbability} && $self->{endProbability} > 0 );
		$self->{probHist}->ScaleSumToOne();
		$self->{probHist}->LogTheHash();
		$self->{log_state} = 1;
	}
	else { ## $self->{log_state} == 1
		return 1 if ( $state == 1 );
		foreach my $state ( keys %{ $self->{otherStates} } ) {
			$self->{otherStates}->{$state} =
			  exp( $self->{otherStates}->{$state} );
		}
		$self->{startProbability} = exp( $self->{startProbability} )
		  if ( defined $self->{startProbability} );
		$self->{endProbability} = exp( $self->{endProbability} )
		  if ( defined $self->{endProbability} );
		$self->{probHist}->RemoveLogNature();
		$self->{log_state} = 0;
	}
	return 1;
}

sub summary_P_value {
	my ($self) = @_;
	return log( $self->{probHist}->summary_P_value() )
	  if ( $self->{log_state} == 1 );
	return $self->{probHist}->summary_P_value();
}


sub ProbabilityDistribution {
	my ( $self, $hist ) = @_;
	if ( defined $hist ) {
		die ref($self),
":ProbabilityDistribution ->we need a object of the class probabilityFunction as probability distribution, Not '$hist'\n$!\n"
		  unless ( ref($hist) eq "probabilityFunction" ) ;
		$self->{probHist} = $hist;
	}
	return $self->{probHist};
}

sub Reestimate {
	my ( $self, @arg ) = @_;
	return $self->{probHist}->Reestimate(@arg);
}

sub reestimateTransmisionProbabilities {
	my ( $self, $p_summaries, $allStates ) = @_;
	die "we need a list of the summary p values\n"
	  unless ( defined $p_summaries->{ $self->{name} } );
	die
	  "we need all state objects ( $self reestimateTransmisionProbabilities)\n"
	  unless ( $self->{name} eq $allStates->{ $self->{name} }->{name} );
	die
"the transmission probabilities were already reestimated in that HMM iteration\n"
	  if ( $self->{transmissionProbabilities_reestimated} );

	my $dataInfo;
	foreach my $state_name ( keys %{ $self->{reestimations} } ) {
		unless ( defined $allStates->{$state_name}->sumOf( $self->{name} ) ) {
			warn
"that should not have happened!!!! reestimated probability $state_name -> $self->{name} is not defined in ",
			  ref($self), " '$self->{name}' other state = ",
			  ref( $allStates->{$state_name} ), "\n";
		}
		#print ref($self),":reestimateTransmisionProbabilities p summar value for state $self->{name} =  ",exp($p_summaries->{ $self->{name} }),"\n";# if ( $self->{debug});
		#print "\t and the summary of the transmission probabilities $state_name to $self->{name} = ", exp($allStates->{$state_name}->sumOf( $self->{name} )) ,"\n";
		$dataInfo->{ "$state_name to $self->{name}" } = $self->probability_for_change_to_state( $state_name,
			$allStates->{$state_name}->sumOf( $self->{name} ) -
			   $p_summaries->{ $self->{name} } );
	}

	$self->{transmissionProbabilities_reestimated} = 1;
	return $dataInfo;
}

sub finalizeReestimation {
	my ( $self, @arg ) = @_;

	die "you first have to reestimate the transmission probabiliteis using the function reestimateTransmisionProbabilities\n"
	unless ( $self->{transmissionProbabilities_reestimated} == 1 );
	$self->{startProbability} = $self->reestimate_startProbability();
	$self->{endProbability}   = $self->reestimate_endProbability();
	
	$self->{transmissionProbabilities_reestimated} = 0;
	$self->{reestimations}                         = undef;
	$self->{reestimations}                         = my $temp;
	return $self->{probHist}->finalizeReestimation(@arg);
}

sub prob_for_observed {
	my ( $self, $observed ) = @_;
	return $self->{probHist}->getHistoValue($observed);
}

sub sumOf {
	my ( $self, $othersName, $sumValue ) = @_;
	if ( defined $sumValue ) {
		$self->{reestimations}->{$othersName} = $sumValue;
	}
	return $self->{reestimations}->{$othersName};
}

sub get_probability_for_change_to_state_ARRAY {
	my ($self) = @_;
	return $self->{changeProbs} if ( defined $self->{changeProbs} );
	my @return;
	foreach my $key ( keys %{ $self->{otherStates} } ) {
		push( @return, $self->{otherStates}->{$key} );
	}
	$self->{changeProbs} = \@return;
	return $self->{changeProbs};
}

=head 3 probability_for_change_to_state

This function is used to set and to recieve the probabilities to change from one (HMM)state to another.
You man only use none logged values to add here. They will automatically be converted to the log state 
if the overall state of the class is in log state!

=cut

sub probability_for_change_to_state {
	my ( $self, $state, $probability_of_transition ) = @_;

	die "we need a \$state in state_values -> otherState ($state)\n"
	  unless ( defined $state );
	$self->{error} = undef;

	if ( defined $probability_of_transition ) {
		unless ( $probability_of_transition > 0
			&& $probability_of_transition < 1 )
		{
			unless ( $self->{log_state} ) {
				$self->{error} =
				  "probability_of_transition out of bounds - discarded!!";
				warn $self->{error};
				return $self->{otherStates}->{$state};
			}
		}
		#warn "we set probabilities of transition (from $self->{name} to $state) to ",$probability_of_transition,"\n";
		$self->{otherStates}->{$state} = $probability_of_transition;
	}
	$self->{error} =
"the probability_of_transition from $self->{name} to $state is not defined\n"
	  unless ( $self->{otherStates}->{$state} );
	return $self->{otherStates}->{$state};
}

sub export {
	my ($self) = @_;

	my @werte  = qw( name log_state startProbability endProbability error duringReestimation);
	my $string = "";
	foreach my $v (@werte) {
		$string .= "$v\t" . $self->{$v} . "\n" if ( defined $self->{$v} );
	}

	$string .= "probability_for_change_to_state\n";
	foreach my $key ( keys %{ $self->{otherStates} } ) {
		$string .= "$key\t$self->{otherStates}->{$key}\n";
	}
	$string .= "probability distribution\n";
	$string .= $self->{probHist}->export();
	return $string;
}

sub import_from_file {
	my ( $self, $file ) = @_;
	open( IN, "<$file" ) or die "could not open file $file \n$!\n";
	my @lines = (<IN>);
	close(IN);
	return $self->import_from_line_array( \@lines );
}


sub getAs_XY_plottable{
	my ( $self) = @_;
	return $self->{probHist}->getAs_XY_plottable();
}

sub import_from_line_array {
	my ( $self, $array ) = @_;
	my ( $probFunct, $probability_for_change_to_state, @line, @probability );
	$probability_for_change_to_state = $probFunct = 0;
	@probability = ();

	foreach (@$array) {
		if ($probFunct) {
			push( @probability, $_ );
			next;
		}
		if ( $_ eq "probability distribution" ) {
			$probFunct                       = 1;
			$probability_for_change_to_state = 0;
			next;
		}
		chomp $_;
		@line = split( "\t", $_ );
		if ($probability_for_change_to_state) {
			$self->{otherStates}->{ $line[0] } = $line[1];
			next;
		}
		if ( $_ eq "probability_for_change_to_state" ) {
			$probability_for_change_to_state = 1;
			next;
		}
		$self->{ $line[0] } = $line[1];
	}
	$self->{probHist} = new_histogram->new();
	$self->{probHist}->import_from_line_array( \@probability );
	return $self;
}

1;
