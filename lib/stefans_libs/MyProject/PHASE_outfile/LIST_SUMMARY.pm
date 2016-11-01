package LIST_SUMMARY;
#  Copyright (C) 2010-09-01 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::MyProject::PHASE_outfile::LIST_SUMMARY.pm

=head1 DESCRIPTION

A class to store the LIST_SUMMARY part of a PHASE outfile

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class LIST_SUMMARY.

=cut

sub new{

	my ( $class, $upper, $debug ) = @_;

	my ( $self );

	$self = {
		'debug' => $debug,
		'data' => {}
  	};

  	bless $self, $class  if ( $class eq "LIST_SUMMARY" );

  	return $self;

}

sub AddLine{
	my ( $self, $line ) = @_;
	## lines look like "         1      AAACTC    3.000000"
	if ( $line =~ m/ +(\d+) +([AGCT]+) +([\d\.]+)/){
		$self->{'data'} ->{$1} = { 'sequence' => $2, 'amount' => $3};
	}
	else { 
		Carp::confess ("I can not parse this line '$line'\n");
	}
	return 1;
}

sub describe_entry{
	my ( $self, $chr_id ) = @_;
	return "Chromosome $chr_id is unknown\n" unless ( ref($self->{'data'}->{$chr_id}) eq "HASH");
	return "Allele: $self->{'data'}->{$chr_id}->{'sequence'}\tamount: $self->{'data'}->{$chr_id}->{'amount'}\n";
}

sub get_data_keys {
	my ( $self ) = @_;
	return (sort keys %{$self->{'data'}});
}

1;
