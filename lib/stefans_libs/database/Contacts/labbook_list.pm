package stefans_libs_database_Contacts_labbook_list;

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

use stefans_libs::database::lists::basic_list;
use stefans_libs::database::LabBook;

use base ('basic_list');

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_database_Contacts_labbook_list

=head1 DESCRIPTION

A list table that links to the table LabBook.

=head2 depends on

stefans_libs::database::LabBook

=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_database_Contacts_labbook_list.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh)
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug           => $debug,
		dbh             => $dbh,
		'my_table_name' => "labbook_list"
	};

	bless $self, $class if ( $class eq "stefans_libs_database_Contacts_labbook_list" );

	$self->init_tableStructure();
	$self->{'data_handler'}->{'otherTable'} =
	  LabBook->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'__actualID'} = $self->readLatestID();

	return $self;

}

1;
