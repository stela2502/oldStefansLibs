package grant_table;

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
use base "variable_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a table to store information about grants. This definitely needs some additional thinking. But at the moment it will be enough to have this raw skeleton here.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class grant_table.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {

		#downstream_Tables => ['partizipatingSubjects'],
		debug => $debug,
		dbh   => root::getDBH( 'root' ),
		'insert' =>
'insert into grants ( name, description, application_file) values ( ? ,?, ?)',
		'select_all_for_DATAFIELD' => 'select * from grants where DATAFIELD = ?'
	};

	bless $self, $class if ( $class eq "grant_table" );

	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type{
	return 'database_name';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "grants";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => 'the unique name of this grant',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'a short description of that grant',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'application_file',
			'type'        => 'VARCHAR (300)',
			'NULL'        => '0',
			'description' => 'a linked file, that contains all the information for that grant',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['name'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} =
	  [ 'name' ]
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


1;
