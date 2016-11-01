package workingTable;

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

A table to store actual working processes and there work in.
All programs that use that table have to interprete the data in that table themselves.
There is only some things in that table - the PID of the process, +
the starting time and the a entry called workload, that is a text formated entry, 
where the processes can store there actual workload in.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class workingTable.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}
	my ($self);

	$self = {
		debug      => $debug,
		dbh        => root::getDBH( 'root' ),
		'database' => $database,
		select_for_program =>
		  'select * from workload where evaluation_string = ?',
		'select_for_PID' => 'select * from workload where PID = ?',
		'select_for_description' =>
		  'select * from workload where description = ?',
		delete_for_PID => 'delete from workload where PID = ?'
	};

	bless $self, $class if ( $class eq "workingTable" );
	$self->Database($database);
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "workload";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'PID',
			'type'        => 'CHAR ( 6 )',
			'NULL'        => '0',
			'description' => 'the PID of the worker process',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'jobTable_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the entry in the jobTable that is processed at the moment',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start_time',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => 'the execution start time',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'jobTable_id' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['jobTable_id']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'}        = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	return $self;

}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	return 1;
}

sub expected_dbh_type {
	return "database_name";
}

sub set_workload {
	my ( $self, $workload ) = @_;
	return $self->AddDataset($workload);
}


sub select_workloads_for_PID {
	my ( $self, $PID ) = @_;
	return $self->get_data_table_4_search({
 	'search_columns' => [ref($self).".*"],
 	'where' => [[ref($self).".PID",'=','my_value']],
 	}, $PID)->get_line_asHash(0);
}

sub delete_workload_for_PID {
	my ( $self, $PID ) = @_;
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'delete_for_PID' } );
	unless ( $sth->execute($PID) ) {
		die ref($self),
		  ":delete_workload_for_PID got a database error using the query '",
		  $self->_getSearchString( 'delete_for_PID', $PID ),
		  ";\n", $self->{dbh}->errstr;
	}
	
	return 1;
}

1;
