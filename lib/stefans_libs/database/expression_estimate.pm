package expression_estimate;

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

#use stefans_libs::database::external_files;
use stefans_libs::database::expression_estimate::expr_est;
use stefans_libs::database::expression_estimate::probesets_table;
use stefans_libs::database::sampleTable;

use base ('variable_table');

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}

	my ($self);

	$self = {
		debug => $debug,
		dbh   => root::getDBH( 'root', $database )
	};

	bless $self, $class if ( $class eq "expression_estimate" );

	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return "database_name";
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "expression_estimates";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'sample_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the samples table',
			'data_handler' => 'sample_table'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'expr_exper_id',
			'do_not_check' => 1,
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description' => 'the id expression experiment',
			'hidden' => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '0',
			'description' => 'not to be used by the user - only by the system',
			'hidden' => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'probesets_tableString',
			'type' => 'VARCHAR (100)',
			'NULL' => '0',
			'description' =>
			  'the table base string to identify probeset information',
			'hidden' => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'table_baseString',
			'type' => 'VARCHAR (100)',
			'NULL' => '0',
			'description' =>
			  'the table base string to identify the downstream datasets',
			'hidden' => 1
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['md5_sum'] );
	$self->{'table_definition'} = $hash;
	$self->{'Group_to_MD5_hash'} =
	  [ 'sample_id', 'program_call', 'expr_exper_id' ];
	$self->{'UNIQUE_KEY'} = ['md5_sum']
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
	$self->{'data_handler'}->{'probesets_table'} =
	  probesets_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'sample_table'} =
	  sampleTable->new('', $self->{'debug'} );

	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	
	if ( defined $dataset->{'probesets_tableString'} ) {
		$self->{'error'} .=
		  ref($self)
		  . "::DO_ADDITIONAL_DATASET_CHECKS - sorry, but we do not know a table named $dataset->{'probesets_tableString'}!\n"
		  unless ( $self->tableExists($dataset->{'probesets_tableString'}) );
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;

	$self->{'error'} .= '';

#	unless ( ref( $dataset->{'affy_desc_id'} ) eq "probesets_table" ) {
#		$dataset->{'affy_desc_id'} =
#		  $self->{'data_handler'}->{'Affy_description'}
#		  ->GetLibInterface( $dataset->{'affy_desc_id'} );
#	}

	my $interface = expr_est->new( $self->{'dbh'}, $self->{'debug'} );
	$dataset->{'table_baseString'} =
	  $interface->TableName( "EX_" . $dataset->{'md5_sum'} );
	$interface->AddDataset($dataset);
	$self->{'error'} .= $self->{'data_handler'}->{'sample_table'}->{'error'};
	$self->{__tableNames} = undef;
	unless ( $self->tableExists( $dataset->{'table_baseString'} ) ) {
		$self->{'error'} .= ref($self)
		  . "::INSERT_INTO_DOWNSTREAM_TABLES -> the data was not inserted into table '$dataset->{'table_baseString'}'\n";
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;

}

sub GetInterface {
	my ( $self, $where_array, $bindArray ) = @_;
	$where_array = [] unless ( defined $where_array);
	$bindArray = [] unless ( defined $bindArray);
	
	unless ( ref( $where_array ) eq "ARRAY" || ref( $bindArray ) eq "ARRAY" ){
		Carp::confess ( ref($self) ."::GetInterface -> we need an array pof where statements and an array of bind values, NOT this:\n ".
			root::get_hashEntries_as_string ($where_array, 3, "The where array "). root::get_hashEntries_as_string ($bindArray, 3, "the bind dataset ") );
	}
	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				ref($self) . ".affy_desc_id",
				ref($self) . ".table_baseString",
				"sampleTable.sample_lable"
			],
			'where' => $where_array
		},
		@$bindArray
	);
	return undef unless ( defined @{ @$rv[0] }[0] );
	my $array_desc_id = @{ @$rv[0] }[0];
	my $interface =
	  $self->{'data_handler'}->{'Affy_description'}
	  ->GetLibInterface($array_desc_id);
	foreach my $table_array (@$rv) {
		Carp::confess(
			ref($self)
			  . "::GetInterface -> we got a aff_desc_id mismatch between the queried datasets: $array_desc_id is not @$table_array[0]"
		) unless ( $array_desc_id == @$table_array[0] );
		$interface->AddDataTable( @$table_array[1], @$table_array[2] );
	}
	return $interface;
}

1;
