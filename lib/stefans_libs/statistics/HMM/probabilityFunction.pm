package probabilityFunction;
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


use stefans_libs::statistics::new_histogram;
use base qw(new_histogram);

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a histogram to harbor the probability function for the HMM calculation.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class probabilityFunction.

=cut

sub new{

	my ( $class, $title ) = @_;

	my ( $self );

	$self = {
		debug => 0,
		title => $title,
		root  => root->new(),
		logged => 0,
		scale21 => 0,
		minAmount => undef,
		maxAmount => undef,
		noNull => 0,
		duringReestimation => 0
  	};

  	bless $self, $class  if ( $class eq "probabilityFunction" );

  	return $self;

}

sub initReestimation{
	my ( $self ) = 	@_;
	return 1 if ($self->{duringReestimation} == 1 );
	my $data;
	$self->{new_data} = $data;
	$self->{duringReestimation} = 1;
	$self->{'reestimated values'} = 0;
	return 1;
}

=head3 Reestimate

Caution - if $self->{logged} is set, the log will be removed before adding of the data!
But dont mind - it will be recalculated during the call to finalizeReestimation!

=cut

sub Reestimate {
	my ( $self, $category, $value ) = @_;

	unless ( $self->{duringReestimation} == 1 ) {
		die "we have no right to recalculate yet! $!\n";
	}
	
	if ( defined $value ) {
		$self->{'reestimated values'} ++;
		$value = exp($value) if ( $self->{logged} );
		#print "$self reestimation $category, ",$value,"\n";
		unless (
			defined $self->{new_data}->{ $self->getCategoryOfTi($category) } )
		{
			$self->{new_data}->{ $self->getCategoryOfTi($category) } = 0;
		}
		$self->{new_data}->{ $self->getCategoryOfTi($category) } += $value;
	}
	return 1;
}

sub summary_P_value{
	my ( $self ) = @_;
	## most probably, we are during reestimation and the user wants to get the new P_value summary
	if ( $self->{duringReestimation} == 1 ){
		return $self->_sum($self->{new_data});
	}
	else { warn "hey! we are not in a Reestimation - no usefull data will be returned!\n";}
	## as we are a probability function the values always scale to one - we do not have to calculate that!
	return 1 unless ( $self->{logged}  );
	return log(1);
}

sub finalizeReestimation {
	my ($self) = @_;
	
	my $sum = $self->summary_P_value();
	
	foreach my $key ( keys %{$self->{data}}){
		#print "we move histogram value $self->{new_data}->{$key} at position $key ($self->{data}->{$key})\n";
		$self->{data}->{$key} = $self->{new_data}->{$key} / $sum;
	}
	$self->{new_data} = undef;
	
	if ( $self->{logged} ){
		$self->{logged} = 0;
		$self->LogTheHash();
	}

	$self->{duringReestimation} = 0;
	return $self->{data};
}

sub createFixedDataset{
	my ( $self, $hash ) = @_;
	
	if ( defined %$hash ){
		$self->{data} = undef;
		$self->{bins} = undef;
		$self->{data} = {};
		$self->{bins} = [];
		while ( my ( $id, $value) = each %$hash ){
			$self->Max($id);
			$self->Min($id);
			push (@{$self->{bins}}, { min => $id, max => $id, category => $id });
			$self->{data}->{$id} = $value;
		}
	}
	$self->{logged} = 0;
	$self->ScaleSumToOne();

	$self->Category_steps ( scalar ( (keys %$hash) ) );

	return ;
}

sub export {
	my ( $self ) = @_;
	
	my @werte = qw( title logged min max category_steps minAmount maxAmount scale21 stepSize noNull duringReestimation);
	my $string = "";
	foreach my $v( @werte){
		$string .= "$v\t".$self->{$v}."\n" if ( defined $self->{$v});
	}
	
	$string .= "data\n";
	my ( $data, $values );
	$data   = $self->{bins};
	$values = $self->{data};
	foreach my $hash ( sort { $a->{min} <=> $b->{min} } @$data ) {
			$string .= join( "\t", ($hash->{min}, $hash->{max}, $hash->{category}, $values->{ $hash->{category} } ) )."\n";
	}
	return $string;
}

1;
