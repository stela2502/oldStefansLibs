package experiment;

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

use stefans_libs::database::lists::list_using_table;
use base 'list_using_table';

use stefans_libs::database::hypothesis_table;
use stefans_libs::database::protocol_table;
use stefans_libs::database::experimentTypes;
use stefans_libs::database::sampleTable::sample_list;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a database interface to store define experiments. The string will be used in each and every dataset each and every dataset.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class experiment.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {

		#downstream_Tables => ['partizipatingSubjects'],
		'debug'              => $debug,
		'dbh'                => root::getDBH( 'root' )
	};


	bless $self, $class if ( $class eq "experiment" );
	$self->init_tableStructure();
	
	return $self;
}


sub check_user_rights {
	my ( $self, $username, $experiment_id ) = @_;
	return 1;
}

sub init_tableStructure{
	my ( $self ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "experiments";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => 'The name for the experiment. This name has to be unique over all the emperiments.',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'protocol_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the id of the protocoll of the experiment',
			'data_handler' => 'protocol_table'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'samples_list_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the link to the list of used samples for this experiment',
			'data_handler' => 'sample_list',
			'link_to'     => 'list_id',
			'hidden' => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'hypothesis_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the id of the main hypothesis of this experiment',
			'data_handler' => 'hypothesis_table'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'experimentType_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the experimentType id to link all the expecutables',
			'data_handler' => 'experimentTypes'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'a informative description of the experiment - please!',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'aim',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => 'the aim of this experiment',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'conclusion',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'the final conclusion that can be drawn from this experiment',
			'needed'      => '0'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '0',
			'description' => '',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'PMID',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => '',
			'needed'      => ''
		}
	);
	push (
		@{ $hash->{'variables'} },
		{
			'name'        => 'upstream_experiment',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'where did we get the data from',
			'hidden' => 1
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['md5_sum'] );
	push( @{ $hash->{'UNIQUES'} }, ['name'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'name' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'Group_to_MD5_hash'} =
	  ['description', 'aim' ];    # define which values should be grouped to get the 'md5_sum' entry
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	$self->{'linked_list'} =  $self->{'data_handler'}->{'sample_list'} = sample_list->new($self->{'dbh'}, $self->{'debug'});
	
	$self->{'data_handler'}->{'experimentTypes'} = experimentTypes->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'hypothesis_table'} = hypothesis_table->new( '', $self->{'debug'} ),
	$self->{'data_handler'}->{'protocol_table'} = protocol_table->new($self->{'dbh'}, $self->{'debug'} );

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
}

sub expected_dbh_type {
	return "database_name";
}

1;
