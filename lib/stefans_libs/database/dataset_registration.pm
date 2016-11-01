package dataset_registration;

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
use stefans_libs::root;
use stefans_libs::database::variable_table;
use base qw(variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A Database interface, that stores information about datasets and there handlers. 
This class can be used to get datahandler objects.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class dataset_registaration.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {
		debug => $debug,
		dbh   => root::getDBH( 'root'),
		'insert' =>
"insert into dataset_register ( description, identifier, module_name) values ( ?, ?, ? )"
	};

	bless $self, $class if ( $class eq "dataset_registration" );

	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "tasks";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'describes the function of that program',
			'needed'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'plugin_name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => 'the name of the dataset plugin (has to be unique)',
			'needed'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'group_name',
			'type' => 'VARCHAR (100)',
			'NULL' => '0',
			'description' =>
'the perl include string so you can identify the main data handler',
			'needed' => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'data_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' => 'the id of the dataset',
			'needed' => 1
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['name'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['name']
	  ; # add here the values you would take to select a single value from the database
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $self;

}

sub expected_dbh_type {

	#return 'dbh';
	return "database_name";
}

=head2 check_dataset

We need some information to create a usable database entry:

=over 3

=item description => a free text description of the dataset 
e.g. "A Affymetrix expression array dataset". 
This string can be used as a help for the identifcation of the right data module to use.

=item identifier => a identifier without ' ' that has to be 
included as 'data_type' string in order to insert the dataset using the AddDataset function of the datahandling object.

=item  module_name => the name of the data module that has to be used in the new function call.

=item lib_string => the perl include string that can be used to include the data handlicg module.

=back

=cut

1;
