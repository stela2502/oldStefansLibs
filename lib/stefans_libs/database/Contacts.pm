package Contacts;

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

use stefans_libs::database::lists::list_using_table;
use base list_using_table;

use stefans_libs::database::Contacts::addr_list;
use stefans_libs::database::Contacts::email_list;
use stefans_libs::database::Contacts::tel_list;
use stefans_libs::database::Contacts::labbook_list;
use stefans_libs::Contact;

##use some_other_table_class;

use strict;
use warnings;

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

	bless $self, $class if ( $class eq "Contacts" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}   = [];
	$hash->{'UNIQUES'}   = [];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'forename',
			'type'        => 'VARCHAR (30)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'surname',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'title',
			'type'        => 'VARCHAR (10)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'company',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'tel_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'data_handler' => 'stefans_libs_database_Contacts_tel_list',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'addr_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'data_handler' => 'stefans_libs_database_Contacts_addr_list',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'mail_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'data_handler' => 'stefans_libs_database_Contacts_email_list',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'labbook_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'data_handler' => 'stefans_libs_database_Contacts_labbook_list',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'forename', 'surname' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = [ 'forename', 'surname' ];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	#     unless ( $self->tableExists( $self->TableName() ) ) {
	#     	$self->create();
	#     }
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	$self->{'data_handler'}->{'stefans_libs_database_Contacts_labbook_list'} =
	  stefans_libs_database_Contacts_labbook_list->new( $self->{'dbh'},
		$self->{'debug'} );
	$self->{'data_handler'}->{'stefans_libs_database_Contacts_addr_list'} =
	  stefans_libs_database_Contacts_addr_list->new( $self->{'dbh'},
		$self->{'debug'} );
	$self->{'data_handler'}->{'stefans_libs_database_Contacts_email_list'} =
	  stefans_libs_database_Contacts_email_list->new( $self->{'dbh'},
		$self->{'debug'} );
	$self->{'data_handler'}->{'stefans_libs_database_Contacts_tel_list'} =
	  stefans_libs_database_Contacts_tel_list->new( $self->{'dbh'},
		$self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub ContactDetails_4_ID {
	my ( $self, $id ) = @_;
	## OK simple thing - I need a new class to represent a contact and this contact should not make any problems
	## to e.g. import it into a database (this database) or print it on a web page or export it as LaTex or as
	## any other contact type. Oh, and it should be able to be created from a AddressBook.
	my ( $data_table, $contact, $hash, $table_class_name, @columns );
	foreach my $var ( @{$self->{'table_definition'}->{'variables'}}) {
		push (@columns, ref($self) . ".$var->{'name'}");
	}
	$data_table = $self->get_data_table_4_search(
		{
			'search_columns' => [ @columns ],
			'where'          => [ [ ref($self) . '.id', '=', 'my_value' ] ]
		},
		$id
	);
	$contact = stefans_libs_Contact->new();
	$hash    = $data_table->get_line_asHash(0);
	foreach (qw(forename surname title company)) {
		$contact->{$_} = $hash->{ ref($self) . ".$_" };
	}
	#Carp::confess ( print root::get_hashEntries_as_string ( $hash , 3 , "How do the keys look like in the hash?" ));
	$contact->AddAddresses(
		$self->{'data_handler'}->{'stefans_libs_database_Contacts_addr_list'}
		  ->getAddresses_4_list_id( $hash->{ref($self) . ".addr_list_id"} ) )
	  ;
	$contact->Add_Tel_Numbers (
		$self->{'data_handler'}->{'stefans_libs_database_Contacts_tel_list'}
		  ->getTelNumbers_4_list_id ($hash->{ref($self) . ".addr_list_id"} )
	);
	$contact->Add_Email (
		$self->{'data_handler'}->{'stefans_libs_database_Contacts_email_list'}
		  ->getEmail_4_list_id ($hash->{ref($self) . ".mail_list_id"} )
	);
	
	return $contact;

}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
