package LinkList;

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

use stefans_libs::database::system_tables::LinkList::object_list;
use stefans_libs::database::scientistTable;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class if ( $class eq "LinkList" );
	$self->init_tableStructure();

	#	unless (
	#		defined $self->get_data_table_4_search(
	#			{
	#				'search_columns' => ['LinkList.name'],
	#				'where'          => [ [ 'LinkList.name', '=', 'my_value' ] ]
	#			},
	#			'Administration'
	#		)
	#	  )
	#	{
	##now I need to update the standard entries in the database!
	## 1. The LabBook
	my ( $id, @link_ids );
	$id = $self->AddDataset(
		{
			'name' => 'Change my profile',
			'link' => '/administration/ModifyUser',
			'role' => 'user'
		}
	);
	$id = $self->AddDataset(
		{
			'name' => 'My Labbook',
			'link' => '/labbook/index',
			'role' => 'user'
		}
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Select a LabBook',
				'link_position' => '/labbook/SelectLabBook'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Select a Read Only LabBook',
				'link_position' => '/labbook/SelectForeignLabBook'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Grant read access to LabBook',
				'link_position' => '/labbook/Grant_Read_Access'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Create a LabBook',
				'link_position' => '/labbook/CreateLabBook'
			}
		)
	);
	$self->Add_2_list(
		{
			'my_id'     => $id,
			'var_name'  => 'object_list_id',
			'other_ids' => \@link_ids
		}
	);
	## 2. The to_do_list
	$id = $self->AddDataset(
		{
			'name' => 'My TO_DO list',
			'link' => '/to_do_list/',
			'role' => 'user'
		}
	);
	@link_ids = undef;
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Add an entry',
				'link_position' => '/to_do_list/AddTask/'
			}
		)
	);
	$self->Add_2_list(
		{
			'my_id'     => $id,
			'var_name'  => 'object_list_id',
			'other_ids' => \@link_ids
		}
	);

	## 3. The Administrative stuff
	$id = $self->AddDataset(
		{
			'name' => 'Administration',
			'link' => '/administration/index',
			'role' => 'admin'
		}
	);
	@link_ids = undef;
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Add a user',
				'link_position' => '/administration/AddUser/'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name' => 'Add role',
				'link_position' =>
				  '/add_2_model/index/ACL/role_list/otherTable/'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name' => 'Add Action Group',
				'link_position' =>
				  '/add_2_model/index/ACL/action_group_list/action_groups/'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Upload a script',
				'link_position' => '/formdef_xml_extract'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Add to web news',
				'link_position' => '/add_2_model/index/web_news'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Mail to all users',
				'link_position' => '/administration/Mail_2_all_users'
			}
		)
	);

#Carp::confess( root::get_hashEntries_as_string ({ 'my_id' => $id , 'var_name' => 'object_list_id', 'other_ids' => \@link_ids}, 3, "we try to to the list the hash") );
	$self->Add_2_list(
		{
			'my_id'     => $id,
			'var_name'  => 'object_list_id',
			'other_ids' => \@link_ids
		}
	);
	@link_ids = undef;
	$id       = $self->AddDataset(
		{ 'name' => 'Plugins', 'link' => '/datasets/index', 'role' => 'user' }
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'View table contents',
				'link_position' => '/datasets/View_Datasets'
			}
		)
	);
	$self->Add_2_list(
		{
			'my_id'     => $id,
			'var_name'  => 'object_list_id',
			'other_ids' => \@link_ids
		}
	);
	$id = $self->AddDataset(
		{
			'name' => 'My TO_DO list',
			'link' => '/to_do_list/',
			'role' => 'user'
		}
	);
	@link_ids = undef;
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'Add a task',
				'link_position' => '/add_2_model/index/to_do_list'
			}
		)
	);
	push(
		@link_ids,
		$self->Add_managed_Dataset(
			{
				'name'          => 'View your do list',
				'link_position' => '/add_2_model/List_Table/to_do_list'
			}
		)
	);

	#	}
	return $self;
}

=head2 GetSidbar_4

This function will return a hash containing the values, that can be used to create the sidebar.
The variable is {
	
	'container' => [ 
	 
	 {'link' => <a www link extension>, 'name' => the name of the link, 'objects' => [
	 	
	 	{'link' => <a www link extension>, 'name' => the name of the link },
	 	..
	 	],
	 }
	 ..
	 ] }

=cut

sub GetSidbar_4 {
	my ( $self, $name, $owner ) = @_;

   #Carp::confess ( ref($self)."::GetSidbar_4 - we got $self, $name, $owner\n");
	my $return = { 'container' => [] };
	my $entries = {};

	if ( $owner eq "system" ) {
		return {};
	}
	$name =~ s/Genexpress_catalist::Controller:://;
	## we need to search for owner and system!

	#	$owner = [ $owner, 'system' ];

	## now I need to get the important things...

	## I may in the end need some values using an authentication part
	## but that are things to come...
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				'LinkList.name',         'LinkList.link',
				'www_object_table.name', 'www_object_table.link_position'
			],
			'where' => [ [ 'LinkList.role', '=', 'my_value' ] ]
		},
		$self->{'data_handler'}->{'scientistTable'}->get_data_table_4_search(
			{
				'search_columns' => [ 'roles.name' ],
				'where'          => [
					[
						ref( $self->{'data_handler'}->{'scientistTable'} )
						  . '.username',
						'=',
						'my_value'
					]
				]
			},
			$owner
		  )->get_column_entries('roles.name')
	);

	#	Carp::confess ( ref($self)."--Get_Sidebar: you need to fix me!! "
	#	."I have executed the search $self->{'complex_search'}\nAnd the search ".
	#	$self->{'data_handler'}->{'scientistTable'}->{'complex_search'}
	#	."\nusing the container '$name' and the user '$owner'\n ");

	foreach my $data_array (@$data) {
		$entries->{ @$data_array[0] } = {
			'name' => @$data_array[0],
			'link' => @$data_array[1]    #"/container/@$data_array[0]"
		  }
		  unless ( defined $entries->{ @$data_array[0] } );
		if ( $name eq @$data_array[0] ) {
			$entries->{ @$data_array[0] }->{'objects'} = []
			  unless (
				ref( $entries->{ @$data_array[0] }->{'objects'} ) eq "ARRAY" );
			push(
				@{ $entries->{ @$data_array[0] }->{'objects'} },
				{ 'name' => @$data_array[2], 'link' => @$data_array[3] }
			);
		}
	}

	#	unless ( defined $entries->{'Administration'} ) {
	#		$entries->{'Administration'} = {
	#			'name' => 'Administration',
	#			'link' => '/container/Administration'
	#		};
	#	}
	#
	#	if ( $name eq "Administration" ) {
	#		unless ( ref( $entries->{'Administration'}->{'objects'} ) eq "ARRAY" ) {
	#			$entries->{'Administration'}->{'objects'} = [
	#				{
	#					'name' => 'Add a user',
	#					'link' => '/administration/AddUser/'
	#				},
	#				{
	#					'name' => "Add role",
	#					'link' => '/add_2_model/index/ACL/role_list/otherTable/'
	#				},
	#				{
	#					'name' => "Add ActionGroup",
	#					'link' =>
	#					  '/add_2_model/index/ACL/action_group_list/action_groups/'
	#				},
	#				{
	#					'name' => 'Upload a script',
	#					'link' => '/formdef_xml_extract'
	#				}
	#			];
	#		}
	#	}
	foreach ( values %$entries ) {
		push( @{ $return->{'container'} }, $_ );
	}

	#	if ( defined $entries->{'My Labbook'} ) {
	#		push( @{ $return->{'container'} }, $entries->{'My Labbook'} );
	#		delete $entries->{'My Labbook'};
	#	}
	#	foreach my $name ( sort keys %$entries ) {
	#		next if ( $name eq "Administration" );
	#		push( @{ $return->{'container'} }, $entries->{$name} );
	#	}
	#	push( @{ $return->{'container'} }, $entries->{"Administration"} );

#Carp::confess( ref($self).":: sorry I was killed after searching for \n$self->{'complex_search'}!\n".root::get_hashEntries_as_string ($return , 5, "the returned data structure was "));
	return $return;

}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	$dataset->{'object_list_id'} = 0
	  unless ( defined $dataset->{'object_list_id'} );
	return 1 unless ( $self->{'error'} =~ m/\w/ );
	return 0;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "link_container";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the name of the Object handler',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'object_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'data_handler' => 'object_list',
			'link_to'      => 'list_id',
			'NULL'         => '1',
			'description'  => 'a list to the links',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'link',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'role',
			'type'        => 'VARCHAR(100)',
			'NULL'        => '0',
			'description' => 'the name of the role to use',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['name'] );
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
	$self->{'data_handler'}->{'object_list'} =
	  object_list->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'linked_list'} = $self->{'data_handler'}->{'object_list'};
	$self->{'data_handler'}->{'scientistTable'} =
	  scientistTable->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
