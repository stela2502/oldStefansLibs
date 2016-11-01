package protocol_table;

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
use stefans_libs::database::external_files;
use stefans_libs::database::materials::materialList;
use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface that is used to handle protocol data. 
A protocol can be a collection of other protocols. 
That may be a little bit of a problem, but is gives the scientits a huge flexibility!


=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class protocol_table.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess( "$class : new -> we need a acitve database handle at startup!, not ".ref($dbh))
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug,
		'select_all_for_DATAFIELD' =>
		  'select * from protocols where DATAFIELD = ?',
	};

	bless $self, $class if ( $class eq "protocol_table" );

	$self->init_tableStructure();
	
	return $self;

}

sub expected_dbh_type {
	return 'dbh';

	#return "not a databse interface";
	#return "database_name";
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "protocols";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of the protocol',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'a (long) description of the protocol',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'version',
			'type'        => 'TINYINT',
			'NULL'        => '0',
			'description' => 'the version of that protocol',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'working_copy',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'The working copy of the protocol - it should be possible to print that',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'original_protocol_description_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the link to the file',
			'data_handler' => 'external_files',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'PMID',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => 'An optional link to pubmed - if the protocol was published',
			'needed'      => ''
		}
	);
	push (
		@{ $hash->{'variables'} },
		{
			'name'        => 'materialList_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'a needed link to the used materials table',
			'data_handler' => 'materialList',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '0',
			'description' => 'ony for internal use',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['md5_sum'] );
	push( @{ $hash->{'UNIQUES'} }, ['name'] );
	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = ['name']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'Group_to_MD5_hash'} =
	  ['description'];
##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	$self->{'data_handler'}->{'external_files'} = external_files->new( $self->{'dbh'}, $self->{'debug'});
	$self->{'data_handler'}->{'materialList'} = materialList->new( $self->{'dbh'}, $self->{'debug'});
	return $dataset;
}

sub get_rooted_to{
		my ( $self, $root_str) = @_;
	if ( $root_str eq ref($self)){
		return $self ;
	}
	elsif ( $root_str eq 'materialList' ){
		foreach my $variable ( @{$self->{'table_definition'}->{'variables'}}){
			if ( $variable->{'name'} eq "materialList"){
				$variable->{'data_handler'} = undef;
			}
		}
		my $temp = $self->{'data_hanlder'}->{'materialList'};
		$self->{'data_hanlder'}->{'materialList'} = undef;
		return $temp -> makeMaster ( $self) ;
	}
	else {
		Carp::confess ( ref($self).":get_rooted_to -> I cant root to \$root_str '$root_str'\n");
	}
}

sub makeMaster{
	my ( $self, $materialList ) = @_;
	unless ( ref($materialList) eq "materialList" ){
		Carp::confess ( "sorry, but we need a 'materialList' object to make ourselves master!");
	}
	foreach my $variable ( @{$self->{'table_definition'}->{'variables'}}){
		if ( $variable->{'name'} eq "materialList"){
			$variable->{'data_handler'} = 'materialList';
		}
	}
	$self->{'data_hanlder'} -> {'materialList'} = $materialList;
	return $self;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	unless ( defined $dataset->{'materialList'}){
	}
	elsif ( ref ( $dataset->{'materialList'} ) eq "ARRAY"){
		## oops - we have a string and this string has to represent the materialsTable.id of the component
		## this is equivalent to the fact, that you can NOT use this function to store new data in the materialsTable!
		$self->{'data_handler'} -> {'materialList'} -> AddDataset ( $dataset->{'materialList'});
		$self->{'error'} .= $self->{'data_handler'} -> {'materialList'} -> {'error'} ;
	}	
	return 1 unless ( $self->{'error'} =~ m/\w/ );
	return 0;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1;
}

1;
