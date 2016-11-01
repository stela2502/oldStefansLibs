package partizipatingSubjects;

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
use stefans_libs::database::experiment;
use stefans_libs::database::subjectTable;
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a database interface to stre which subjects can be groupt into which experiment.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class partizipatingSubjects.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {
		dbh   => root::getDBH( 'root', $database ),
		debug => $debug
	};

	bless $self, $class if ( $class eq "partizipatingSubjects" );
	## table definition
	# add output of create_hashes_from_mysql_create.pl here
	# take care for the variable table names!!
	my $hash;
	$hash->{'INDICES'}    = [ ['experiment_id'], ['subject_id'] ];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "partizipatingSubjects";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'experiment_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'experiment',
			'description' =>
'this value can be recieved using the variable experiment together with the data_handler experiment',
			'needed' => 0
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'subject_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'subjectTable',
			'description' =>
'this value can be recieved using the variable subject together with the data_handler subjectTable',
			'needed' => 0
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'experiment_id', 'subject_id' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'experiment_id', 'subject_id' ];
	$self->{'_tableName'} = $hash->{'table_name'};

	unless ( $self->tableExists( $hash->{'table_name'} ) ) {
		$self->create();
	}

	$self->{'data_handler'}->{'experiment'} =
	  experiment->new( $database, $self->{debug} );
	$self->{'data_handler'}->{'subjectTable'} =
	  subjectTable->new( $self->{dbh}, $self->{debug} );

	return $self;

}

sub expected_dbh_type {
	#return 'dbh';
	return "database_name";
}

1;
