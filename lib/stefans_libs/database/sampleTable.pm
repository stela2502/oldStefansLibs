package sampleTable;

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
use stefans_libs::database::subjectTable;
use stefans_libs::database::storage_table;
use stefans_libs::database::tissueTable;
use stefans_libs::database::protocol_table;
use stefans_libs::database::sampleTable::sample_types;

use base ('variable_table');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a database interface to store and recieve sample information

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class sampleTable.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self, $dbh);
	$dbh = $database;
	unless ( ref($dbh) eq "DBI::db" ) {
		$dbh = root->getDBH( $database);
	}
	$self = {
		'dbh'           => $dbh,
		'database_name' => $database,
		'debug'         => $debug
	};

	bless $self, $class if ( $class eq "sampleTable" );

	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "samples";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'sample_lable',
			'type'        => 'VARCHAR ( 100 )',
			'NULL'        => '0',
			'description' => 'the lable of the storage tubes',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'subject_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the subjects table',
			'data_handler' => 'subjectTable',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'storage_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'the link to the possible storage places',
			'data_handler' => 'storage_table',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'initial_amount',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the initial amount of purified sample material',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'tissue_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the tissues table',
			'data_handler' => 'tissue_table',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'aliquots',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'how many aliquots are available',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'extraction_protocol_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the protocols table',
			'data_handler' => 'protocol_table',
			'needed'       => 'how you prepared the sample'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'extraction_date',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => 'the date of the sample extraction',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'type_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
'the type of this sample (DNA, RNA, protein or something else )',
			'data_handler' => 'sample_types',
			'needed' => ''
		}
	);

	push(
		@{ $hash->{'UNIQUES'} },
		[ 'sample_lable', 'subject_id', 'tissue_id' ]
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'sample_lable', 'storage_id' ] );
	push( @{ $hash->{'INDICES'} }, ['extraction_protocol_id'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'sample_lable', 'subject_id', 'tissue_id' ]
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
## subject_table storage_table tissue_table protocol_table

	$self->{'data_handler'}->{'subjectTable'} =
	  subjectTable->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'storage_table'} =
	  storage_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'tissue_table'} =
	  tissueTable->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'protocol_table'} =
	  protocol_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'sample_types'} =
	  sample_types->new( $self->{'dbh'}, $self->{'debug'} );

	return $dataset;
}

sub expected_dbh_type {
	return 'database_name';
}

1;
