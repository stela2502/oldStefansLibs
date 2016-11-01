package project_table;

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
use stefans_libs::database::grant_table;
use base "variable_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface, that is used to describe projects. Everhybody can add projects, but the have to be linked to an hypothesis, that describes the idear behind the project. In addition, this table keeps track of the original application for that project. In the future, we may want to add new functionallity here.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class project_table.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;
	my $dbh;
	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
		$dbh = root::getDBH( 'root' );
	}
	elsif ( ref($database) eq "DBI::db" ){
		$dbh = $database; 
		$database = "genomeDB";
	}
	unless ( ref($dbh) eq "DBI::db" ){
		Carp::confess ( "Sorry, but I need either an Dtabase name or a active DBI:db interface at new($database, $debug)\n");
	}
	my ($self);

	$self = {
		'debug' => $debug,
		'database_name' => $database,
		'dbh'   => $dbh
	};

	bless $self, $class if ( $class eq "project_table" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "projects";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of the project',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'grant_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the grant_id links to a grant table',
			'data_handler' => "grant_table",
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'aim',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'in short -> the aim of the project',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['name'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['name']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'data_handler'}->{'grant_table'} = grant_table->new( $self->{'database_name'}, $self->{'debug'} );
	return $dataset;
}

sub expected_dbh_type{
	return 'database_name';
}
#sub create {
#	my ($self) = @_;
#
#	if ( $self->tableExists('projects') ) {
#		## we have to get rid of all the downstream tables!
#		warn ref($self), ":create -> we try to drop the tables!\n";
#		$self->{dbh}->do("DROP table projects");
#	}
#
#	## access_right: by default only the scientist, that has entered the dataset can access it...
#	## possible should be: supervisor, group members, action group members, all
#	## by default this value has to be set to all, if the dataset has been published!
#
#	my $createString = "
#CREATE TABLE projects (
#	id  INTEGER UNSIGNED auto_increment,
#	name VARCHAR(40) NOT NULL,
#	grand_id INTEGER UNSIGNED NOT NULL,
#	aim TEXT NOT NULL,
#	PRIMARY KEY ( id),
#	UNIQUE ( name )
#); ";
#
#	if ( $self->{debug} ) {
#		print ref($self), ":create -> we would run $createString\n";
#		foreach my $downstreamTable ( @{ $self->{'downstream_Tables'} } ) {
#			unless ( $self->tableExists($downstreamTable) ) {
#				$self->{$downstreamTable}->create();
#			}
#		}
#	}
#	else {
#		$self->{dbh}->do($createString) or die $self->{dbh}->{errstr};
#		foreach my $downstreamTable ( @{ $self->{'downstream_Tables'} } ) {
#			unless ( $self->tableExists($downstreamTable) ) {
#				$self->{$downstreamTable}->create();
#			}
#		}
#		$self->{__tableNames} = undef;
#	}
#	return 1;
#}

### name, grand_id, aim
#sub check_dataset {
#	my ( $self, $dataset ) = @_;
#	$self->{error} = $self->{warning} = '';
#	$self->{error} .=
#	  ref($self) . ":check_dataset -> we do not have a dataset to check!\n"
#	  unless ( defined $dataset );
#	if ( defined $dataset->{'id'} ) {
#		my $data = $self->_select_all_for_DATAFIELD( $dataset->{'id'}, "id" );
#		foreach my $exp (@$data) {
#			return 1 if $exp->{'id'} = $dataset->{'id'};
#		}
#		$dataset->{'id'} = undef;
#	}
#
#	## name
#	$self->{error} .= ref($self) . ":check_dataset -> we got no name tag!\n"
#	  unless ( defined $dataset->{'name'} );
#	## grand_id
#	$self->{error} .=
#	  ref($self) . ":check_dataset -> we got no grand_informations hash!\n"
#	  unless ( ref( $dataset->{'grand_informations'} ) eq "HASH" );
#	$self->{error} .=
#	    ref($self)
#	  . ":check_dataset not enough info 'grand_informations':\n"
#	  . $self->{'grant_table'}->{error}
#	  unless ( $self->{'grant_table'}
#		->check_dataset( $dataset->{'grand_informations'} ) );
#	## aim
#	$self->{error} .= ref($self) . ":check_dataset -> we got no aim tag!\n"
#	  unless ( defined $dataset->{'aim'} );
#
#	return 0 if ( $self->{error} =~ m/\w/ );
#	return 1;
#}
#
#sub AddDataset {
#	my ( $self, $dataset ) = @_;
#	die $self->{error} unless ( $self->check_dataset($dataset) );
#
#	return $dataset->{'id'} if ( defined $dataset->{'id'} );
#
#	my $data = $self->_select_all_for_DATAFIELD( $dataset->{name}, "name" );
#	foreach my $exp (@$data) {
#		return $exp->{'id'};
#	}
#
#	if ( $self->{'debug'} ) {
#		print ref($self),
#		  ":AddConfiguration -> we are in debug mode! we will execute: '",
#		  $self->_getSearchString( 'insert', $dataset->{'name'},
#			$dataset->{'grand_id'},
#			$dataset->{'aim'} ),
#		  ";'\n";
#	}
#	my ($grand_id);
#	$grand_id =
#	  $self->{'grant_table'}->AddDataset( $dataset->{'grand_informations'} );
#	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
#	unless ( $sth->execute( $dataset->{'name'}, $grand_id, $dataset->{'aim'} ) )
#	{
#		die ref($self),
#		  ":AddConfiguration -> we got a database error for query '",
#		  $self->_getSearchString(
#			'insert', $dataset->{'name'}, $grand_id, $dataset->{'aim'}
#		  ),
#		  ";'\n",
#		  $self->{dbh}->errstr();
#	}
#	$data = $self->_select_all_for_DATAFIELD( $dataset->{name}, "name" );
#	foreach my $exp (@$data) {
#		return $exp->{'id'};
#	}
#}
#
#sub _select_all_for_DATAFIELD {
#	my ( $self, $value, $datafield ) = @_;
#	my $sth = $self->_get_SearchHandle(
#		{
#			'search_name'          => 'select_all_for_DATAFIELD',
#			'furtherSubstitutions' => { 'DATAFIELD' => $datafield }
#		}
#	);
#	unless ( $sth->execute($value) ) {
#		die ref($self),
#":_select_all_for_DATAFIELD ($datafield) -> we got a database error for query '",
#		  $self->_getSearchString( 'select_all_for_DATAFIELD', $value ), ";'\n",
#		  $self->{dbh}->errstr();
#	}
#	my ( @return, $id, $name, $grand_id, $aim );
#	$sth->bind_columns( \$id, \$name, \$grand_id, \$aim );
#	while ( $sth->fetch() ) {
#		push(
#			@return,
#			{
#				'id'       => $id,
#				'name'     => $name,
#				'grand_id' => $grand_id,
#				'aim'      => $aim
#			}
#		);
#	}
#	return \@return;
#}

1;
