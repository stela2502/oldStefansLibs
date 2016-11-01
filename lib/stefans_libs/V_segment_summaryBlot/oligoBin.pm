package oligoBin;
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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

oligoBin

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

=head3 retrun values

A object of the class oligoBin

=cut

sub new {

    my ( $class, $start, $end ) = @_;

    die "bitte noch die Start- und End-Position mit angeben!\n" unless ( @_ == 3 );

    my ( $self, @oligoValues, @pending, $oligoIDs );

    $self = {
        oligoValues => \@oligoValues,
        pending     => \@pending,
        olgioIDs    => $oligoIDs,
        position    => ( $start + $end ) / 2,
        start 	    => $start,
        end         => $end
    };

    bless( $self, $class ) if ( $class eq "oligoBin" );
    return $self;
}

sub AddOligo {

    my ( $self, $oligoValue, $oligoID ) = @_;

    #   print "OligiBin->AddOligo got $oligoValue\n";

    my ($oligoValues);
    unless ( defined $self->{olgioIDs}->{$oligoID}){
		my (@oligoValues);
		$self->{olgioIDs}->{$oligoID} = {count => 0 , oligoValues => \@oligoValues};
	}
    $self->{olgioIDs}->{$oligoID}->{count} ++;
    $oligoValues = $self->{pending};
    push( @$oligoValues, $oligoValue );
	$oligoValues = $self->{olgioIDs}->{$oligoID}->{oligoValues};
	push( @$oligoValues, $oligoValue );
    return 1;
}

sub flush_median {
    my ( $self, $withMedianCalculation ) = @_;

    my ( $pending, $median, $oligoValues );
    $pending     = $self->{pending};
    $oligoValues = $self->{oligoValues};

    if ($withMedianCalculation) {

        $median = root->median($pending);
        for ( my $i = 0 ; $i < @$pending ; $i++ ) {
            push( @$oligoValues, $median );
        }
    }
    else {
        push( @$oligoValues, @$pending );
    }
    @$pending = undef;
    return 1;
}

sub GetOligoReport{
	my ( $self) = @_;
	return $self->{position}, $self->{olgioIDs};
}

sub GetValues {

    my ($self) = @_;

    my ( $mean, $Varianz, $StandartAbweichung ) =
      root->getStandardDeviation( $self->{oligoValues} );
    my  $median  = root->median( $self->{oligoValues} );
	my ( @oligoCount, $oligos, $n, $N, $stdErrMean );
	( $mean, $N ) = root->mittelwert( $self->{oligoValues});
	$oligos = $self->{olgioIDs};
	@oligoCount = ( keys %$oligos);
	$n = int ( $N / @oligoCount) unless (@oligoCount == 0);
	$stdErrMean = $StandartAbweichung / ($N ** 0.5) unless ( $N == 0);
	$stdErrMean = $StandartAbweichung if ( $N == 0);
    my ( $oligoValues);
    $oligoValues = $self->{oligoValues};
    $oligoValues = @$oligoValues;

    $mean = 0 if ( $mean =~ m/No Values/ );
    $StandartAbweichung = 0 if ( $StandartAbweichung =~ m/Undef/ );

    return $self->{position}, $mean, $StandartAbweichung, $median, $oligoValues, $stdErrMean, $n, $self->{start}, $self->{end} ;
}

1;
