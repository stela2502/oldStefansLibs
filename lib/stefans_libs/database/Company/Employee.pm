package stefans_libs_database_Company_Employee;


#  Copyright (C) 2010 Stefan Lang

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


use stefans_libs::database::Contacts;
use base Contacts;


sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug         => $debug,
		dbh           => $dbh,
		'linked_list' => 'stefans_libs_database_Contacts_addr_list'
	};

	bless $self, $class if ( $class eq "stefans_libs_database_Company_Employee" );
	$self->init_tableStructure();
	$self->TableName( 'Company' );

	return $self;

}


1;