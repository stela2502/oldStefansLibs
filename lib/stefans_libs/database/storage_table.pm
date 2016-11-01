package storage_table;

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
use stefans_libs::database::variable_table;
use base 'variable_table' ;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A table to store the possible storgare positions for something.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class storage_table.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless ( defined $dbh );

	my ($self);

	$self = {
		'dbh'   => $dbh,
		'debug' => $debug
	};

	bless $self, $class if ( $class eq "storage_table" );

	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "storages";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'temperature',
			'type'        => 'FLOAT',
			'NULL'        => '0',
			'description' => 'the temperatore of the storage',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'building',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the building the storgae is placed in',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'floor',
			'type'        => 'VARCHAR (3)',
			'NULL'        => '0',
			'description' => 'the floor the storage is located',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'room',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the room of the storage',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'box_label',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the lable of the box in the storage',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'a description of the storage (e.g. small white fridge)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'UNIQUES'} },
		[ 'building', 'floor', 'room', 'description' ]
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'building', 'floor', 'room', 'description' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $dataset;
}



sub expected_dbh_type {
	return 'dbh';
	#return "not a databse interface";
	#return "database_name";
}

1;
