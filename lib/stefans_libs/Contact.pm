package stefans_libs_Contact;
#  Copyright (C) 2011-08-25 Stefan Lang

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

use stefans_libs::Contact::Address;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_Contact

=head1 DESCRIPTION

A contact object that can be used with the database.

=head2 depends on

=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_Contact.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
		'forename' => '',
		'surname' => '',
		'company' => '',
		'title' >= '',
		'telephone_numbers' => {},
		'email' => {},
		'address' => {}
  	};

  	bless $self, $class  if ( $class eq "stefans_libs_Contact" );

  	return $self;

}

sub AddAddresses{
	my ( $self, $array ) =@_;
	unless ( ref($array) eq "ARRAY"){
		return 0;
	}
	foreach my $addr ( @$array ){
		Carp::confess ( "The array content is not an address object" ) unless ( ref($addr) eq 'stefans_libs_Contact_Address');
		$self->{'address'} ->{$addr->{'type'}} = $addr;
	}
	return 1;
}

sub Add_Tel_Numbers{
	my ( $self, $array ) =@_;
		unless ( ref($array) eq "ARRAY"){
		return 0;
	}
	foreach my $addr ( @$array ){
		Carp::confess ( print root::get_hashEntries_as_string( $addr , 3 , "The array content is not an telephone number" )) unless ( ref($addr) eq "HASH" && ( defined $addr->{'type'} && defined $addr->{'number'}));
		$self->{'telephone_numbers'} -> { lc ($addr->{'type'} ) } = $addr->{'number'};
	}
	return 1;
}

sub Add_Email{
	my ( $self, $array ) =@_;
		unless ( ref($array) eq "ARRAY"){
		return 0;
	}
	foreach my $addr ( @$array ){
		Carp::confess ( "The array content is not an email address" ) unless ( ref($addr) eq "HASH" && ( defined $addr->{'type'} && defined $addr->{'email'}));
		$self->{'email'} -> { lc ($addr->{'type'} ) } = $addr->{'email'};
	}
	return 1;
}

sub AsHTML{
	my ( $self ) = @_;
	my ( $key );
	my $html = "<table>\n";
	$html .= "<tr><td>$self->{'title'}. $self->{'forename'} $self->{'surname'} </td></tr>\n";
	$html .= "<tr><td>$self->{'company'}</td></tr>\n" if ( $self->{'company'} =~m/\w/);
	$html .= "</table>\n";
	foreach $key ( keys %{$self->{'address'}} ){
		$html .= "<p>$key address</p>". $self->{'address'}->{$key} ->AsHTML();
	}
	$html .= "<p>telephone numbers</p>\n<table>";
	foreach $key ( keys %{$self->{'telephone_numbers'}} ){
		$html .=  "<tr><td>$key number:</td> <td>$self->{'telephone_numbers'}->{$key}</td></tr>\n";
	}
	$html .= "</table>\n";
	$html .= "<p>e-mail</p>\n<table>";
	foreach $key ( keys %{$self->{'email'}} ){
		$html .=  "<tr><td>$key:</td> <td><a href=\"mailto:$self->{'email'}->{$key}\">$self->{'email'}->{$key}</td></tr>\n";
	}
	$html .= "</table>\n";
	return $html;
}

1;
