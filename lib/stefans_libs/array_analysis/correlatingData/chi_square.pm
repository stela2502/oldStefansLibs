package chi_square;
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

use FindBin;
use lib "/../lib/";
use strict;
use warnings;
use stefans_libs::array_analysis::correlatingData::stat_test;

use base ( 'stat_test' );

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::array_analysis::correlatingData::chi_square.pm

=head1 DESCRIPTION



=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class chi_square.

=cut

sub new{

	my ($class, $R, $debug) = @_;

	my ($self);
	unless ( defined $R){
		$R = Statistics::R->new();
	}

	$self = {
		tableHandling => tableHandling->new(),
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0,
		match2number  => '(\d?\.?\d+)'
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

  	bless $self, $class  if ( $class eq "chi_square" );

  	return $self;

}

sub chi_square_test{
	my ( $self, $seen, $expected ) = @_;
	my $error = '';
	$error .= ref($self)."::chi_square_test - the determined data has to be given as an arrray ref, not like '$seen'\n" unless (ref($seen) eq "ARRAY");
	$error .= ref($self)."::chi_square_test - the expected data has to be given as an arrray ref, not like '$expected'\n" unless (ref($expected) eq "ARRAY");
	Carp::confess($error) if ( $error =~ m/\w/);
	## chisq.test( matrix(c(  ),ncol=2))
	my $cmd =  "res <- chisq.test( matrix(c(".join(",", @$seen ).", ".join(",", @$expected ).
	"),ncol=2))\nprint ( res )\n";
	$self->forceRunningR();
	$self->{R}->send($cmd);
	unless ( $self->{R}->is_started() ) {
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	my $return = $self->{R}->read();
#"	        Chi-squared test for given probabilities
#
#data:  c(59, 20, 11, 10) 
#X-squared = 5.6711, df = 3, p-value = 0.1288";
	my ( $p, $x_squared, $df );
	$p = $1 if ( $return =~ m/p-value [=<] (\d?\.?\d+e?-?\d*)/ );
	unless ( defined $p ) {
		$self->{lastP} = undef;
		$self->add_2_log ($cmd."ERROR - could not identfy the p_value\n$return\n");
		return $return;
	}
	$x_squared = $1 if ( $return =~ m/X-squared *= *([\d\.]+)/ );
	$df = $1 if ( $return =~ m/df *= *([\d]+)/ );
	$self->add_2_log ($cmd."p_value = $p; X-squared = $x_squared; df = $df\n" );
	return { 'p_value' => $p, 'X-squared' => $x_squared, 'df' => $df};
}

1;
