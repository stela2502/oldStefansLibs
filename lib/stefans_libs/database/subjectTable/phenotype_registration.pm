package phenotype_registration;

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

use stefans_libs::database::variable_table;
use base 'variable_table';
use stefans_libs::database::protocol_table;
use stefans_libs::database::subjectTable::phenotype::ph_age;
use stefans_libs::database::subjectTable::phenotype::familyHistory;
use stefans_libs::database::subjectTable::phenotype::binary_mono;
use stefans_libs::database::subjectTable::phenotype::binary_multi;
use stefans_libs::database::subjectTable::phenotype::continuose_mono;
use stefans_libs::database::subjectTable::phenotype::continuose_multi;

use strict;
use warnings;

sub new {

	my ( $class, $database, $debug ) = @_;

	my ($self);
	unless ( defined $database ) {
		$database = "genomeDB";
		warn "no db name given -> name set to genomeDB\n";
	}

	$self = {
		'debug' => $debug,
		'dbh'   => root::getDBH( 'root', $database ),
	};

	bless $self, $class if ( $class eq "phenotype_registration" );

	$self->Database($database);
	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

## My sample sql CREATE string:
#"CREATE TABLE phenotype_registration (
#   id INTEGER unsigned auto_increment,
#   name VARCHAR(100) NOT NULL,
#   description TEXT NOT NULL,
#   data_table_description TEXT,
#   connection_type VARCHAR(40) default 'mysql',
#   PRIMARY KEY ( id ),
#   UNIQUE ( name )
#   )";

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "phenotype_registration";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'protocol_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
'the link to the protocol table entry describing the protocol for the phenotype generation',
			'needed'       => '',
			'data_handler' => 'protocol_table'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'perl_module_name',
			'type' => 'varchar(50)',
			'NULL' => '0',
			'description' =>
'the name of the perl module, that is able to handle the datatype',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'connection_type',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'table_name',
			'type' => 'VARCHAR (100)',
			'NULL' => '0',
			'description' =>
'this value will be automatically creates as pheno_\$this->name and will be the table name for the dataset',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'module_spec_restr',
			'type' => 'VARCHAR (200)',
			'NULL' => '1',
			'description' =>
'a data string, that is interpreted by the data handling perl module and defines further restrictions',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'min_val',
			'type' => 'VARCHAR (20)',
			'NULL' => '1',
			'description' =>
'a data string, that is either a number for the continuose modules or a string for the binary modules',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'max_val',
			'type' => 'VARCHAR (20)',
			'NULL' => '1',
			'description' =>
'a data string, that is either a number for the continuose modules or a string for the binary modules',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'unit',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => 'which unit is used to store a value',
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

	$self->{'data_handler'}->{'protocol_table'} =
	  protocol_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'activated'} = {};
	$self->{'registered_modules'}->{'age'} = 'ph_age';
	#  ph_age->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'registered_modules'}->{'familyHistory'} = 'familyHistory';
	#  familyHistory->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'registered_modules'}->{'binary_mono'} = 'binary_mono';
	#  binary_mono->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'registered_modules'}->{'binary_multi'} = 'binary_multi';
	#  binary_multi->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'registered_modules'}->{'continuose_mono'} = 'continuose_mono';
	#  continuose_mono->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'registered_modules'}->{'continuose_multi'} = 'continuose_multi';
	#  continuose_multi->new( $self->{'dbh'}, $self->{'debug'} );

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	$self->{registered_phenotypes} = undef;
	$dataset->{'table_name'} = 'pheno_' . $dataset->{'name'};

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub supports {
	my ( $self, $type ) = @_;
	## 1. we get all the possible phenotypes from our table
	my ( @wanted_columns, $data, $colName, $array );
	@wanted_columns = (
		ref($self).'.name',              ref($self).'.perl_module_name',
		ref($self).'.connection_type',   ref($self).'.table_name',
		ref($self).'.module_spec_restr', ref($self).'.min_val',
		ref($self).'.max_val'
	);
	$data = $self->getArray_of_Array_for_search(
		{ 'search_columns' => \@wanted_columns, } );
	@wanted_columns = (
		'name', 'perl_module_name',
		'connection_type',   'table_name',
		'module_spec_restr', 'min_val',
		'max_val'
	);
	#print $self->{'complex_search'}."\n";
	#print ref($self)."::supports -> we got this result:\n".root::get_hashEntries_as_string ($data, 3, " ");
	foreach $array (@$data) {
		$self->{registered_phenotypes}->{ @$array[0] } = {};
		for ( my $i = 0 ; $i < @wanted_columns ; $i++ ) {
			$self->{registered_phenotypes}->{ @$array[0] }
			  ->{ $wanted_columns[$i] } = @$array[$i];
		}
	}
	if ( defined $type ) {
		return ( defined $self->{registered_phenotypes}->{$type} );
	}
	return [ sort( keys %{ $self->{registered_phenotypes} } ) ];
}

sub getDownstreamTable_4_type {
	my ( $self, $type ) = @_;
#	Carp::confess(
#		ref($self)
#		  . "::activate_connection -> sorry, but I do not support the data type '$type'"
#	) unless ( defined $self->{'registered_phenotypes'}->{$type} );
	return $self->{'activated'}->{$type}
	  if ( ref( $self->{'activated'}->{$type} ) =~ m/\w/ );
	unless ( defined $self->{'var_id'} ) {
		$self->{'var_id'} = {
			'name'         => 'id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'multiple',
			'description' =>
			  'The id links to multiple other table objects e.g. '
		};
		push(
			@{ $self->{'table_definition'}->{'variables'} },
			$self->{'var_id'}
		);
		$self->{'data_handler'}->{'multiple'} = [];
	}
	return $self->__activate_dataHandler($type);

}

sub __activate_dataHandler {
	my ( $self, $type ) = @_;
	unless ( join( " ", @{ $self->supports() } ) =~ m/$type/ ) {
		Carp::confess(
			ref($self)
			  . "::__activate_dataHandler ( $type ) -> sorry, but we do not know what you wanted -> the type is not defined!\n"
		);
	}

	$self->{'activated'}->{$type} =
	  $self->{'registered_modules'}
	  ->{ $self->{'registered_phenotypes'}->{$type}->{'perl_module_name'} }
	  ->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'activated'}->{$type}
	  ->setRestriction( $self->{'registered_phenotypes'}->{$type} );

	push(
		@{ $self->{'data_handler'}->{'multiple'} },
		$self->{'activated'}->{$type}
	);
	return $self->{'activated'}->{$type};
}

1;
