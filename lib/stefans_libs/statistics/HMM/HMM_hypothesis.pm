package HMM_hypothesis;

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
use stefans_libs::statistics::HMM::state_values;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A new package to sum up a hypothesis concerning a HMM calculation. 
Used together with the UMS package to generate state_values objects. 
These in turn can be used with the HMM calss to calculate the HMM statistics on a dataset.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class HMM_hypothesis.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {};

	bless $self, $class if ( $class eq "HMM_hypothesis" );

	return $self;

}

=head2 add_internalState_hypotheis

This method is used to give regions in a dataset names. 
These names are used by the UMS and HMM classes as internal state names.
After a HMM calculation, the probabilities for that state can be retrieved 
from an HMM object using its 'get_P_values_for_internalState(<name>)' function.

Typical hypoteses would be 

item hypothesis => { more_than => 0.9 }

The observed data value comming after a observed data value that is higher that 90% of all data values is likely to be part of this state

item hypothesis => { less_than => 0.1 }

The observed data value comming after a observed data value that is lower that 10% of all data values is likely to be part of this state

item hypothesis => { in_between => [ <min value>, <max value> ] }

select all values between <min value> and <max value>

item hypothesis => { regions => [objects of calls stefans_libs::gbFile::gbRegion] }

The hypotheses are used in that order. If more than one criteria is given, that only that criteria that comes first in this list is used!

=cut

sub add_internalState_hypotheis {
	my ( $self, $hash ) = @_;
	die ref($self),
":add_internalState_hypotheis -> I definitely need a name for that internal HMM state (entry 'name')\n"
	  unless ( defined $hash->{'name'} );
	die ref($self),
":add_internalState_hypotheis -> I definitely need a hypothesis (entry 'hypothesis')\n$!\n"
	  unless ( defined $hash->{'hypothesis'} );

	## now we can start!
	$self->getStateName( $hash->{'name'} );
	$self->{'hypothesis'} = $hash->{'hypothesis'};
	## OK - this method is used only for the test if a hypothesis is usefull...
	return 1;
}

=head2 getStateName

Use this function to get the Name of that hypthesis

=cut

sub getStateName {
	my ( $self, $name ) = @_;
	die "OOPS this hypothesis $self has no name!!\n"
	  unless ( defined $self->{'name'} || defined $name );
	$self->{'name'} = $name if ( defined $name );
	return $self->{'name'};
}

=head2 getHypothesis

use this function to get the hypothesis

=cut

sub getHypothesis {
	my ( $self, $hyp ) = @_;

	if ( defined $hyp && !defined $self->{hypothesis} ) {
		my $hypotheis_OK = $self->hypothesisTest($hyp);
		$self->{hypothesis} = $hyp;
	}
	return $self->{hypothesis};
}

sub getHypType {
	my ($self) = @_;
	return $self->{hypType} if ( defined $self->{hypType} );
	my @return = ( keys %{ $self->{hypothesis} } );
	$self->{hypType} = $return[0];
	return $self->{hypType};
}

sub getHypEntry {
	my ($self) = @_;
	return $self->{hypValue} if ( defined $self->{hypValue} );
	my @return = ( values %{ $self->{hypothesis} } );
	$self->{hypValue} = $return[0];
	$self->{hypValue};
}

sub getStateValues_obj {
	my ($self) = @_;
	return $self->{state_values} if ( defined $self->{state_values} );
	$self->{state_values} = state_values->new( $self->getStateName() );
	return $self->{state_values};
}

sub _is_List_of_regions {
	my ( $self, $list ) = @_;
	return 0 unless ( defined $list );
	return 0 unless ( defined @$list[0] );
	foreach my $ref (@$list) {
		return 0 unless ( ref($ref) eq "gbRegion" );
	}
	return 1;
}

sub hypothesisTest {
	my $self = shift;
	my $hyp  = shift;

	my $hypotheis_OK = 0;
	die ref($self),
":hypotheis_test -> we need a expected frequency for each internal hmm state (entry 'exp_feq') \n"
	  unless ( defined $hyp->{'exp_freq'} || defined $hyp->{'regions'} );
	$hypotheis_OK++
	  if (
		defined $hyp->{'more_than'}
		&& (   $hyp->{'more_than'} > 0
			&& $hyp->{'more_than'} < 1 )
	  );
	$hypotheis_OK++
	  if (
		defined $hyp->{'less_than'}
		&& (   $hyp->{'less_than'} > 0
			&& $hyp->{'less_than'} < 1 )
	  );
	$hypotheis_OK++
	  if ( $self->_is_List_of_regions( $hyp->{'regions'} ) );
	$hypotheis_OK++
	if ( defined $hyp->{'in between'} && @{$hyp->{'in between'}} == 2 );
	  
	die ref($self),
	  ":add_internalState_hypotheis -> got no usefull hypothesis! ",
"read perldoc stefans_libs::statisctics::HMM::HMM_hypothesis for a description of possible values\n"
	  if ( $hypotheis_OK == 0 );
	warn ref($self),
":add_internalState_hypotheis -> you have specified mor than one hypothesis. ",
"Only the first in the list ( 'more_than', 'less_than', 'regions') will be used!\n"
	  if ( $hypotheis_OK > 1 );
	return ($hypotheis_OK);
}

1;
