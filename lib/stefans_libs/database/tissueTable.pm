package tissueTable;

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
use base qw(variable_table);
use stefans_libs::database::protocol_table;
use stefans_libs::database::organismDB;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store the tissue information in.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class tissueTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess( "$class : new -> we need a acitve database handle at startup! not '$dbh'" )
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug,
		'select_id_for_tissue_organism' =>
		  "select id from tissue where tissue_name = ? && organism_id = ?"
	};

	bless $self, $class if ( $class eq "tissueTable" );

	$self->init_tableStructure();
	
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "tissue";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'organism_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the organism table',
			'data_handler' => 'organismDB',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (60)',
			'NULL'        => '0',
			'description' => 'the name of the tissue type',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'extraction_protocol_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the extraction protocol for this tissue type',
			'data_handler' => 'protocol_table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'UNIQUES'} },
		[ 'organism_id', 'name', 'extraction_protocol_id' ]
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['organism_id', 'name', 'extraction_protocol_id']
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
	$self->{'data_handler'}->{'organismDB'} = organismDB->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'protocol_table'} =
	  protocol_table->new( $self->{'dbh'}, $self->{'debug'});
	return $dataset;
}

sub expected_dbh_type {
	return 'dbh';

	#return "not a databse interface";
	#return "database_name";
}

#
#
#=head2 check_dataset
#
#In order to pass the test we need an hash with these entries:
#
#=over 3
#
#=item organism_id => The id of the organism the tissue comes from - that might affest the extratction protiocol...
#
#=item tissue_name => the name of that tissue (max 40 chars)
#
#=item extraction_protocol => h hash that either refers to a protocol or can be used to craete a protocol.
#
#=cut
#
#sub check_dataset {
#	my ( $self, $dataset ) = @_;
#	$self->{error} = '';
#
#	if ( defined $dataset->{'id'} ) {
#		my $data = $self->_select_all_for_DATAFIELD( $dataset->{'id'}, "id" );
#		foreach my $exp (@$data) {
#			return 1 if $exp->{'id'} = $dataset->{'id'};
#		}
#		$dataset->{'id'} = undef;
#	}
#
#	## check the organism information
#	$self->{error} .=
#	    ref($self)
#	  . ":check_dataset the organism info 'organism' can not be processed!\n"
#	  . $self->{'organismDB'}->{error}
#	  unless ( $self->{'organismDB'}->check_dataset( $dataset->{'organism'} ) );
#
#	## check the tissue_name
#	$self->{error} .=
#	  ref($self) . ":check_dataset -> we need an 'tissue_name'\n"
#	  unless ( defined $dataset->{'tissue_name'} );
#
#	## check the extraction protocol
#	$self->{error} .=
#	    ref($self)
#	  . ":check_dataset the organism info 'extraction_protocol' can not be processed!"
#	  . $self->{protocol_table}->{error}
#	  unless ( $self->{protocol_table}
#		->check_dataset( $dataset->{'extraction_protocol'} ) );
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
#	my $organism_id =
#	  $self->{'organismDB'}->AddDataset( $dataset->{'organism'} );
#	my $id =
#	  $self->get_id_for_tissue_organism( $dataset->{'tissue_name'},
#		$organism_id );
#	return $id if ( defined $id );
#
#	my $protocolID =
#	  $self->{protocol_table}->AddDataset( $dataset->{'extraction_protocol'} );
#
#	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
#	unless (
#		$sth->execute( $dataset->{'tissue_name'}, $organism_id, $protocolID ) )
#	{
#		die ref($self), ":AddDataset -> we could not execute '",
#		  $self->_getSearchString( 'insert', $dataset->{'tissue_name'},
#			$organism_id, $protocolID ),
#		  ";\n", $self->{dbh}->errstr, "\n";
#	}
#	return $self->get_id_for_tissue_organism( $dataset->{'tissue_name'},
#		$organism_id );
#}

#sub get_id_for_tissue_organism {
#	my ( $self, $tissue_name, $organism_id ) = @_;
#	my $sth = $self->_get_SearchHandle(
#		{ 'search_name' => 'select_id_for_tissue_organism' } );
#	unless ( $sth->execute( $tissue_name, $organism_id ) ) {
#		warn ref($self),
#		  ":get_id_for_tissue_organism -> we could not execute '",
#		  $self->_getSearchString( 'select_id_for_tissue_organism',
#			$tissue_name, $organism_id ),
#		  ";\n", $self->{dbh}->errstr, "\n";
#		return 0;
#	}
#	my $id;
#	$sth->bind_columns( \$id );
#	$sth->fetch();
#	return $id;
#}


1;
