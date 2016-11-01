package PluginRegister;

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
use stefans_libs::database::system_tables::PluginRegister::exp_functions_list;
use base list_using_table;

##use some_other_table_class;

use strict;
use warnings;

our $VERSION;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class if ( $class eq "PluginRegister" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "PluginRegister";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => 'the plugin name',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'model',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => 'the internal model name to be used',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'version',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the version string',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'type',
			'type' => 'VARCHAR (10)',
			'NULL' => '0',
			'description' =>
			  'the type of the plugin ( helper, labbook, dataset )',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'a necessary description of the plugin',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'export_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'the link to the exports list',
			'data_handler' => 'exp_functions_list',
			'link_to'      => 'list_id'
		}
	);

	push( @{ $hash->{'UNIQUES'} }, ['name'] );
	push( @{ $hash->{'INDICES'} }, ['version'] );
	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['name'];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	$self->{'data_handler'}->{'exp_functions_list'} =
	  exp_functions_list->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'linked_list'} = $self->{'data_handler'}->{'exp_functions_list'};
	return $dataset;
}

sub get_Table_for_All_Plugins {
	my ($self) = @_;
	my $data_table = $self->get_data_table_4_search(
		{ 'search_columns' => [ ref($self) . ".name",   ref($self) . ".description", ref($self) . '.model' ], } );
	#<a href="[% c.uri_for(pageData.readEntry) %]">"model"/p></a>
	$data_table -> set_HeaderName_4_position ( 'name', 0);
	$data_table -> set_HeaderName_4_position ( 'description', 1);
	$data_table -> set_HeaderName_4_position ( 'model', 2);
	$data_table -> define_subset( 'DATA', ['name','model'] );
	$data_table -> calculate_on_columns ( {
		'function' => sub{ return "<a href=\"/$_[1]/index\">$_[0]</a>"}, 
		'data_column' => 'DATA', 
		'target_column' => 'LINK'
	});
	$data_table ->define_subset( 'HTML', ['LINK','description']);
	$data_table -> Rename_Column( 'LINK' , 'plugin name');
	return $data_table->get_as_table_object('HTML');
}

sub Check_Plugin {
	my ( $self, $name, $version ) = @_;
	my $hash = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".version" ],
			'where' =>
			  [ [ "name", '=', 'my_value' ], [ 'version', '>=', 'my_value' ] ]
		},
		$name, $version
	)->get_line_asHash(0);
	return $hash->{ ref($self) . '.version' }
	  if ( defined $hash );
	return undef;
}

sub Add_2_Plugin {
	my ( $self, $plugin_id ) = @_;
	my $return = $self->get_data_table_4_search(
		{
			'search_columns' => ['exportables.link'],
			'where'          => [
				[ ref($self) . ".id", '=', 'my_value' ],
				[ 'exportables.name', '=', 'my_value' ]
			]
		},
		$plugin_id,
		'AddDataset'
	)->get_line_asHash(0);
	return $return->{'exportables.link'} if ( defined $return );
	Carp::confess(
"Sorry, but I can not identfy the link to the addDataset for plugin_id $plugin_id\n"
	);
}

sub register_plugin {
	my ( $self, $name, $version, $description, $type ) = @_;
	my $id = $self->AddDataset(
		{
			'name'        => $name,
			'version'     => $version,
			'description' => $description,
			'type'        => $type
		}
	);
	return $self->UpdateDataset(
		{
			'id',         => $id,
			'version'     => $version,
			'description' => $description,
			'type'        => $type
		}
	);
}

sub expected_dbh_type {
	return 'dbh';
}

1;

