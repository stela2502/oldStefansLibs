package stefans_libs_Contact_Address;

#  Copyright (C) 2011-08-26 Stefan Lang

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

stefans_libs_Contact_Address

=head1 DESCRIPTION

An simple Adress class

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_Contact_Address.

=cut

sub new {

	my ( $class, $hash ) = @_;

	my ($self);

	$self = {
		'street'       => 'unknown',
		'house_number' => 'unknown',
		'city'         => 'unknown',
		'post_number'  => 'unknown',
		'country'      => 'unknown',
		'type'         => 'unknown'
	};

	bless $self, $class if ( $class eq "stefans_libs_Contact_Address" );

	$self->read_from_database_hash($hash);
	return $self;

}

sub read_from_database_hash {
	my ( $self, $hash ) = @_;
	my ($expected_keys);
	$expected_keys = {
		'street'       => 1,
		'house_number' => 1,
		'city'         => 1,
		'post_number'  => 1,
		'country'      => 1,
		'type' => 1
	};
	foreach my $key ( keys %$hash ){
		if ( $key =~ m/(\w+)\.(\w+)/ ) {
			$self->{$2} = $hash->{$key} if ( $expected_keys->{$2} );
		}
		else {
			$self->{$key} = $hash->{$key} if ( $expected_keys->{$key} );
		}
	}
	return 1;
}

sub AsHTML_TableLine {
	my ($self) = @_;
	return
	  "<tr><td>$self->{'street'}</td> <td>$self->{'house_number'}</td></tr>\n"
	  . "<tr><td>$self->{'post_number'}</td> <td>$self->{'city'}</td></tr>\n"
	  . "<tr><td>$self->{'country'}<td></tr>\n";
}

sub AsHTML {
	my ($self) = @_;
	return"<table>\n".
	  "<tr><td>$self->{'street'}</td> <td>$self->{'house_number'}</td></tr>\n"
	  . "<tr><td>$self->{'post_number'}</td> <td>$self->{'city'}</td></tr>\n"
	  . "<tr><td>$self->{'country'}<td></tr>\n".
	  "</table>\n"
}

1;
