package marcowChain;

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
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

with this class you can calculate HMM statistics

=head2 depends on

stefans_libs::root

=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class marcowChain.
we absolutel need an array of state_values at startup!

=cut

sub new {

	my ( $class, $hmmStates, $debug ) = @_;

	my ($self);

	die "marcowChain needs an array of state_values objects at startup\n"
	  unless ( defined $hmmStates );
	die "marcowChain needs an array of state_values objects at startup\n"
	  unless ( defined @$hmmStates );
	die "marcowChain needs an array of state_values objects at startup\n"
	  unless ( ref( @$hmmStates[1] ) eq "state_values" );

	my $states;
	foreach my $state (@$hmmStates) {
		$states->{ $state->{name} } = $state;
	}

	$self = {
		'states'        => $states,
		'values'        => [],
		'debug'         => $debug,
		forwardResults  => undef,
		backwardResults => undef,
		p_H             => undef,
		C               => undef

		  #		G_H1_to_H0      => 0,
		  #		G_H1_to_H1      => 0,
		  #		G_H0_to_H0      => 0,
		  #		G_H0_to_H1      => 0,
	};

	bless $self, $class if ( $class eq "marcowChain" );

	return $self;

}

sub getState_P_values {
	my ($self) = @_;
	return $self->{p_H};
}

sub get_P_values_for_state{
	my ( $self, $stateName ) = @_;
	return $self->{p_H}->{$stateName};
}

=head2 addValue

add a new value to the marcow chain - the position is stored

=cut

sub addValue {
	my ( $self, $value ) = @_;
	unless ( defined $value ) {
		return undef;
	}
	push( @{ $self->{'values'} }, $value );
	return 1;
}

sub Length {
	my ( $self ) = @_;
	return scalar(@{ $self->{'values'} } );
}

=head2 addValueArray

add a new values array to the marcow chain - the old array is deleted

=cut

sub addValueArray {
	my ( $self, $arrayRef ) = @_;
	unless ( ref($arrayRef) eq "ARRAY" ) {
		warn "marcowChain addValueArray - not an array! ($arrayRef)\n";
		return 0;
	}
	warn "marcowChain old values array becomes deleted (addValueArray)\n"
	  if ( defined @{$arrayRef} && defined @{ $self->{'values'} } );
	if ( defined @$arrayRef[0] ) {
		@{ $self->{'values'} } = undef;
		$self->{'values'} = $arrayRef;
	}
	return 1;
}

sub Add2Logs {
	my ( $self, $logA, $logB ) = @_;
	return $logB unless ( defined $logA );
	return $logA unless ( defined $logB );
	return $logA + log( 1 + exp( $logB - $logA ) );
}

sub _init {
	my ($self) = @_;

	my ( @entries, @stateNames );
	@entries = qw(forwardResults backwardResults p_H);

	@stateNames = $self->_stateNames();

	foreach my $entry (@entries) {
		my $hash;
		foreach my $state (@stateNames) {
			$hash->{$state} = [];
		}
		$self->{$entry} = $hash;
	}
	$self->{C} = [];
	return 1;
}

sub _stateNames {
	my ($self) = @_;
	return keys %{ $self->{'states'} };
}

=head2 CalculateForwardProbability

There should be no need for an explanation!
Use it without any arguments...

=cut

sub CalculateForwardProbability {
	my ($self) = @_;

	#print "is there a prblem!\n";
	#print "$self->CalculateForwardProbability:\n";
	#root::print_hashEntries($self->{F0},4);
	#print "Evaluating value at position 0 ($self->{TStat}[0]):\n";

	my ($state);

	$self->_init();

	foreach $state ( values %{ $self->{'states'} } ) {
		$self->{forwardResults}->{ $state->{name} }[0] =
		  $state->{startProbability} +
		  $state->prob_for_observed( $self->{'values'}[0] );
	}

	for ( my $i = 1 ; $i < scalar( @{ $self->{'values'} } ) ; $i++ ) {

		foreach $state ( values %{ $self->{'states'} } ) {
			## we have to initialize the array position $self->{forwardResults}->{ $state->{name} }[$i]

			$self->{forwardResults}->{ $state->{name} }[$i] =
			  $self->{forwardResults}->{ $state->{name} }[ $i - 1 ] +
			  $state->probability_for_change_to_state( $state->{name} );

			## before we can add the others to that....
			foreach ( $state->OtherStateNames() ) {
				$self->{forwardResults}->{ $state->{name} }[$i] =
				  $self->Add2Logs(
					$self->{forwardResults}->{ $state->{name} }[$i],
					$self->{forwardResults}->{$_}[ $i - 1 ] +
					  $state->probability_for_change_to_state($_)
				  );

					##print
#"we calculated the forward probability for the other state $_ (pos $i => ",
	#				   $self->{forwardResults}->{ $state->{name} }[$i] ,
	#				  ") using values $self->{forwardResults}->{$_}[ $i - 1 ] and ",$state->probability_for_change_to_state($_),"\n";
			}
			$self->{forwardResults}->{ $state->{name} }[$i] =
			  $self->{forwardResults}->{ $state->{name} }[$i] +
			  $state->prob_for_observed( $self->{'values'}[$i] );

	   #			print
	   #"\t the final forward probability for state $state->{name} (pos $i => ",
	   #				  exp( $self->{forwardResults}->{ $state->{name} }[$i] ),
	   #				  ")\n";
		}
	}
	return 1;
}

sub _backward_4_state {
	my ( $self, $masterState, $slaveState, $i ) = @_;

#	print "$self->{'states'}\n";
#	print "$self->{'states'}->{$masterState}\n";
#	print " $self->{'states'}->{$masterState}->probability_for_change_to_state($masterState)\n";
#	print " $self->{backwardResults}->{$masterState}[$i+1] \n";
#	print " $self->{'states'}->{$masterState}->prob_for_observed( $self->{'values'}[$i] )\n";
	#print "we try to update state $masterState\n";
	return $self->{'states'}->{$masterState}
	  ->probability_for_change_to_state($slaveState) +
	  $self->{backwardResults}->{$masterState}[ $i + 1 ] +
	  $self->{'states'}->{$masterState}
	  ->prob_for_observed( $self->{'values'}[ $i + 1 ] );
}

sub _backward {
	my ( $self, $masterState, $i ) = @_;
	$self->{backwardResults}->{$masterState}[$i] =
	  $self->_backward_4_state( $masterState, $masterState, $i );
	foreach ( $self->{'states'}->{$masterState}->OtherStateNames() ) {
		$self->{backwardResults}->{$masterState}[$i] = $self->Add2Logs(
			$self->{backwardResults}->{$masterState}[$i],
			$self->_backward_4_state( $_, $masterState, $i )
		);
	}
}

sub CalculateBackwardProbability {

	my ($self) = @_;

	#endProbability
	my ( $state, @otherStateNames, @states );

	@states = ( values %{ $self->{'states'} } );

	foreach $state (@states) {
		$self->{backwardResults}
		  ->{ $state->{name} }[ @{ $self->{'values'} } - 1 ] =
		  $state->{endProbability};
	}
	for ( my $i = @{ $self->{'values'} } - 2 ; $i >= 0 ; $i-- ) {
		foreach $state (@states) {
			$self->_backward( $state->{name}, $i );
		}
	}
	return 1;
}

sub CalculateTotalProbabilityFromStartToEnd {
	my ($self) = @_;

	my ( $A_H, $state, $probability_for_change_to_state_ARRAY,
		$C, @a_H, @states );

	@states = ( values %{ $self->{'states'} } );

	#print "$self->CalculateTotalProbabilityFromStartToEnd\n";
	$self->{p_value_summ} = undef;

	if ( $self->{debug} ) {
		$self->{A_H} = {};
		foreach $state (@states) {
			$self->{A_H}->{ $state->{name} } = [];
		}

		for ( my $i = 0 ; $i < @{ $self->{'values'} } ; $i++ ) {
			@a_H = ();
			foreach $state (@states) {
				$self->{A_H}->{ $state->{name} }[$i] =
				  $self->{forwardResults}->{ $state->{name} }[$i] +
				  $self->{backwardResults}->{ $state->{name} }[$i];
				push( @a_H, $self->{A_H}->{ $state->{name} }[$i] );
			}

			$self->{C}[$i] = $a_H[0];

			for ( my $a = 1 ; $a < @a_H ; $a++ ) {
				$self->{C}[$i] = $self->Add2Logs( $self->{C}[$i], $a_H[$a] );
			}

			foreach $state (@states) {
				$self->{p_H}->{ $state->{name} }[$i] =
				  $self->{A_H}->{ $state->{name} }[$i] - $self->{C}[$i];

			}
		}
	}
	else {
		for ( my $i = 0 ; $i < @{ $self->{'values'} } ; $i++ ) {

			@a_H = ();
			foreach $state (@states) {
				$A_H->{ $state->{name} } =
				  $self->{forwardResults}->{ $state->{name} }[$i] +
				  $self->{backwardResults}->{ $state->{name} }[$i];
				push( @a_H, $A_H->{ $state->{name} } );
			}

			$self->{C}[$i] = $a_H[0];

			for ( my $a = 1 ; $a < @a_H ; $a++ ) {
				$self->{C}[$i] = $self->Add2Logs( $self->{C}[$i], $a_H[$a] );
			}

			foreach $state (@states) {
				$self->{p_H}->{ $state->{name} }[$i] =
				  $A_H->{ $state->{name} } - $self->{C}[$i];
			}
		}
	}
	return 1;
}

sub sumOf_P_values {
	my ($self) = @_;
	my ( $state, @states );

	@states = ( values %{ $self->{'states'} } );

	foreach $state (@states) {
		$self->{p_H}->{ $state->{name} }[0] =
		  $self->{p_H}->{ $state->{name} }[0];
	}
	for ( my $i = 1 ; $i < @{ $self->{'values'} } ; $i++ ) {
		foreach $state (@states) {
			$self->{p_H}->{ $state->{name} }[$i] =
			  $self->{p_H}->{ $state->{name} }[$i];
		}
	}
}

sub _calculateNewTransitionValue {
	my ( $self, $i, $stateA, $stateB ) = @_;

#
#	if ( $i == 14  && $stateB->{name} eq "C" ){
#print "$self -> _calculateNewTransitionValue";
#print  "\nforwardResults_$stateA->{name} ($i-1) = ", exp( $self->{forwardResults}->{$stateA->{name}}[ $i - 1 ]);
#print  "\nprobability_for_change_to_state_$stateB->{name} ($stateA->{name}) = ", exp( $stateB->probability_for_change_to_state($stateA->{name}));
#print  "\nbackwardResults_$stateB->{name} ($i) = ", exp( $self->{backwardResults}->{$stateB->{name}}[ $i ]);
#print  "\nprob_for_observed_$stateB->{name} (",@{$self->{'values'}} [$i],") = ",exp ( $stateB->prob_for_observed(@{$self->{'values'}} [$i]) );
#print "\nC (i) [should be unimportant which one to take...]= ", exp($self->{C}[$i]),"\n\n";
#}
	
	my $return = $self->{forwardResults}->{ $stateA->{name} }[ $i - 1 ] +
	  $stateB->probability_for_change_to_state( $stateA->{name} ) +
	  $self->{backwardResults}->{ $stateB->{name} }[$i] +
	  $stateB->prob_for_observed( @{ $self->{'values'} }[$i] ) -
	  $self->{C}[$i];
	  @{ $self->{ "$stateA->{name} to $stateB->{name}" } } [$i] = $return if ( $self->{debug});
	  return $return;
}

sub CalculateProbOfTransitions {
	my ($self) = @_;

#die "Warum kommte eigentlich diese Warnung??\n" if ( $self->{G_H1_to_H1} > 0 );

	## das wird extremst komplex!!
	## 1. Wir brauchen nur die Summen (A_to_a)!
	## 2. nehmen wir an, wir haben sie Zustaende ( A, B, C)
	##	  dann muss fuer jeden Zusand der Uebergang zu jedem anderen Sustand errechnet werden (a, b, c).
	##    last_forward( A ) * a->probability_for_change_to_state ( A ) * this_revers ( a ) * a -> prob_for_observed ( this ) / self->{C}
	##    der Knackpunkt danach:
	##    A-> probability_for_change_to_state ( a ) = a->( a_to_A ) / sum_P_a

	## so das sollte verstaendlich und umsetzbar sein!

	#print "$self->CalculateProbOfTransitions\n";
	## da wir mit Logarythmen arbeiten erst mal den Grundwert eintragen (log(0) ist nicht definiert!)
	my ( $stateA, $stateB, @states, $start );

	@states = ( values %{ $self->{'states'} } );
	
	if ( $self->{debug}){
		foreach $stateA (@states) {
			foreach $stateB (@states) {
				$self->{ '$stateA->{name} to $stateB->{name}'} = [];
			}
		}
	}

	unless ( defined $states[0]->sumOf( $states[0]->{name} ) ) {
		if ( @{ $self->{'values'} } > 0 ) {
			foreach $stateA (@states) {
				$stateA->initReestimation();
				foreach $stateB (@states) {
					#warn "craete new prob estimate $stateA->{name} to $stateB->{name} ";
					$stateA->sumOf(
						$stateB->{name},
						$self->_calculateNewTransitionValue(
							1, $stateA, $stateB
						)
					);
					#warn " ( ", $stateA->sumOf($stateB->{name}), " )\n";
				}
			}
		}
		$start = 2;
	}
	else {
		$start = 1;
	}
	
	foreach $stateA ( @states) {
		$stateA->reestimate_startProbability ( $self->{p_H}->{ $stateA->{name} }[0] );
		$stateA->reestimate_endProbability ($self->{p_H}->{ $stateA->{name} }[ @{ $self->{'values'} } -1] );
	}
	
	for ( my $i = 0 ; $i < $start ; $i++ )
	{    ## we have to update the probability functions for each value!
		foreach $stateA ( @states) {
			#print ref($self) ,": CalculateProbOfTransitions -> here comes the state $stateA->{name}\n";
			$stateA->Reestimate( @{ $self->{'values'} }[$i],
				$self->{p_H}->{ $stateA->{name} }[$i] );
		}
	}
	for ( my $i = $start ; $i < @{ $self->{'values'} } ; $i++ ) {
		foreach $stateA (sort @states) {
			## create the transmission probabilities
			foreach $stateB (@states) {
				$stateA->sumOf(
					$stateB->{name},
					$self->Add2Logs(
						$stateA->sumOf( $stateB->{name} ),
						$self->_calculateNewTransitionValue(
							$i, $stateA, $stateB
						)
					)
				);
			}
			## reestimate the probability function
			$stateA->Reestimate( @{ $self->{'values'} }[$i],
				$self->{p_H}->{ $stateA->{name} }[$i] );
		}
	}
	return 1;
}

1;
