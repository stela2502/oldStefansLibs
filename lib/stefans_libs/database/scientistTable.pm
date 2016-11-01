package scientistTable;

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
use stefans_libs::database::lists::list_using_table;
use stefans_libs::database::scientistTable::role_list;
use stefans_libs::database::scientistTable::action_group_list;

use Digest::MD5 qw(md5_hex);

use base "list_using_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store scientist information. The table inherits from the person tableset. In contrast to the person entry, the family tree is exchanged into a scientific connections tree. That information is (in the beginning) only used to manage the access rights to specific datasets.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class scientistTable.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {
		'dbh'   => root::getDBH( 'root' ),
		'debug' => $debug,
		'get_id_for_name' => "select id from scientists where name = ?",
		'get_ids_for_position' =>
		  "select id from scientists where position = ?",
		'get_info_for_ids' =>
"select name, workgroup, position, email from scientists where id IN ( LIST )",
		'get_scientistEntries_for_COLUMNHEADER' =>
		  'select * from scientists where COLUMNHEADER = ?'
	};

	bless $self, $class if ( $class eq "scientistTable" );
	$self->init_tableStructure();
	return $self;

}

sub check_pw {
	my ( $self, $c, $user, $pw ) = @_;
	my $hash = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".id" ],
			'where'          => [
				[ ref($self) . ".username", '=', 'my_value' ],
				[ ref($self) . ".PW",       '=', 'my_value' ]
			]
		},
		$user,
		md5_hash($pw)
	)->get_line_asHash(0);
	if ( defined $hash ) {
		return 1;
	}
	return 0;
}

sub expected_dbh_type {

	#return 'dbh';
	return "database_name";
}

sub init_tableStructure {
	my ($self) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "scientists";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'username',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'a unique identifier for you',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of the scientif (you)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'workgroup',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of your group leader',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'position',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'your position (PhD student, postdoc, .. )',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'email',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '1',
			'description' => 'your e-mail address',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'action_gr_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'the link to the action groups',
			'data_handler' => 'action_group_list',
			'link_to' => 'list_id'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'roles_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'which roles you might be able to use',
			'data_handler' => 'role_list',
			'link_to' => 'list_id'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'pw',
			'type'        => 'VARCHAR(32)',
			'NULL'        => '1',
			'description' => 'the PW'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['username'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['username']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	$self->{'data_handler'}->{'action_group_list'} =
	  action_group_list->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'role_list'} =
	  role_list->new( $self->{'dbh'}, $self->{'debug'} );

	$self->{'linked_list'} = $self->{'data_handler'}->{'action_group_list'};

	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	# $self->{'data_handler'}->{''} =->new();

	return 1;
}

sub AddRole {
	my ( $self, $dataset ) = @_;
	my $error = '';
	$error .=
	  ref($self)
	  . '::AddRole - we need a username to know where to add the role to!\n'
	  unless ( defined $dataset->{'username'} );
	$error .=
	  ref($self)
	  . '::AddRole - we need a role to know where to add the role to!\n'
	  unless ( defined $dataset->{'role'} );
	Carp::confess($error) if ( $error =~ m/\w/ );
	
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.id', ref($self) . '.roles_list_id' ],
			'where' => [ [ ref($self) . '.username', '=', 'my_value' ] ],
		},
		$dataset->{'username'}
	)->get_line_asHash(0);
	Carp::confess( ref($self)."::AddRole -> the user with the username $dataset->{'username'} is unknown!\n") unless ( defined $data);
	if ( $data-> { ref($self) . '.roles_list_id'}  == 0 ){
		$data-> { ref($self) . '.roles_list_id'} =  $self->{'data_handler'}->{'role_list'} -> readLatestID() +1;
		#warn ref($self)."::AddRole - we have changed the role_list_id fro user $dataset->{'username'} to ".$data-> { ref($self) . '.roles_list_id'}."\n";
		$self->UpdateDataset( { 'id' => $data-> { ref($self) . '.id'}, 'roles_list_id' => $data-> { ref($self) . '.roles_list_id'}} );
	}
	return $self->{'data_handler'}->{'role_list'}
	  ->add_to_list( $data-> { ref($self) . '.roles_list_id'}, { 'name' => $dataset->{'role'} } );
}

sub user_has_role {
	my ( $self, $user, $role ) = @_;
	return 0 unless ( $user =~ m/\w/ );
	
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.roles_list_id' ],
			'where'          => [
				[ ref($self) . '.username', '=', 'my_value' ],
				[ 'roles.name',             '=', 'my_value' ]
			],
		},
		$user, $role
	)->get_line_asHash(0);
	unless ( defined $data ){
	#warn "we could not get a result for $self->{'complex_search'}\n";
	return 0 ;
	}
	return 1;
}

sub select_ScientistEntries_for_COLUMNHEADER {
	my ( $self, $value, $column_name ) = @_;

	my $sth = $self->_get_SearchHandle(
		{
			'search_name'          => 'get_scientistEntries_for_COLUMNHEADER',
			'furtherSubstitutions' => { 'COLUMNHEADER' => $column_name }
		}
	);
	unless ( $sth->execute($value) ) {
		die ref($self),
":_select_all_for_COLUMNHEADER ($column_name) -> we got a database error for query '",
		  $self->_getSearchString(
			'get_scientistEntries_for_COLUMNHEADER', $value
		  ),
		  ";'\n",
		  $self->{dbh}->errstr();
	}
	my ( @return, $id, $name, $group, $position, $email );
	$sth->bind_values( \$id, \$name, \$group, \$position, \$email );
	while ( $sth->fetch() ) {
		push(
			@return,
			{
				'id'       => $id,
				'name'     => $name,
				'group'    => $group,
				'position' => $position,
				'email'    => $email
			}
		);
	}
	return \@return;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	$dataset->{'action_gr_id'} = 0
	  unless ( defined $dataset->{'action_gr_id'} );
	$dataset->{'roles_list_id'} = 0
	  unless ( defined $dataset->{'roles_list_id'} );
	unless ( defined $dataset->{'pw'}){
		$dataset->{'pw'} = 0 ;
	}
	else {
		$dataset->{'pw'} = md5_hex($dataset->{'pw'});
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub Get_id_for_name {
	my ( $self, $name ) = @_;
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'get_id_for_name' } );
	$sth->execute($name);
	my $id;
	$sth->bind_columns( \$id );
	$sth->fetch();
	return $id;
}

sub Get_info_for_ids {
	my ( $self, @IDs ) = @_;

	my $str = $self->_getSearchString('get_info_for_ids');
	my $to_do = join( ", ", @IDs );
	$str =~ s/LIST/$to_do/;
	#print "we try : ", $str, "\n";
	my $sth = $self->_get_SearchHandle(
		{
			'search_name'          => "get_info_for_ids",
			'furtherSubstitutions' => { 'LIST' => join( ", ", @IDs ) }
		}
	);
	$sth->execute()
	  or warn ref($self), ":Get_info_for_ids -> we got no result for query '",
	  $self->_getSearchString('get_info_for_ids'), ";'\n";
	my ( $name, $group, $position, $email, @return );
	$sth->bind_columns( \$name, \$group, \$position, \$email );

	while ( $sth->fetch() ) {
		push( @return, [ $name, $group, $position, $email ] );
	}
	return \@return;
}

1;
