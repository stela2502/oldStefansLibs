package array_calculation_results;

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
use File::HomeDir;
use stefans_libs::root;
use stefans_libs::database::nucleotide_array;
use stefans_libs::database::variable_table;
use stefans_libs::database::experiment;
use stefans_libs::database::scientistTable;
use stefans_libs::database::array_dataset::oligo_array_values;

use base qw(variable_table);

our $VERSION = "1.000";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface comparable to nucleotideArrays,
that is a wrapper around all the possible datasets in the database.
Most importantly the chip on Chip dataset, but also the mRNA expression chips.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class array_calculation_results.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}
	my ($self);

	$self = {
		debug => $debug,

		#		downstream_Tables => [
		#			'scientists',        'subjects',
		#		 	'experiments',
		#			'tissues'
		#		],
		tempDir         => File::HomeDir->my_home() . "/temp",
		dbh             => root::getDBH( 'root', $database ),
		'database_name' => $database
	};

	bless $self, $class if ( $class eq "array_calculation_results" );
	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return 'database_name';
}

sub init_tableStructure {
	my ($self) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "array_calculation_results";
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'name',
			'type' => 'VARCHAR (60)',
			'NULL' => '0',
			'description' =>
'a name for this calculation - has to be unique with the version of the program',
			'needed' => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'scientist_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'scientistTable',
			'description'  => 'a link to the scientists table',
			'needed'       => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'work_description',
			'type' => 'TEXT',
			'NULL' => '0',
			'description' =>
			  'description of the calculation in order to get the data',
			'needed' => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'program_name',
			'type' => 'VARCHAR(400)',
			'NULL' => '0',
			'description' =>
			  'the name of the calculation module used to generate the data',
			'needed' => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'program_version',
			'type' => 'VARCHAR(20)',
			'NULL' => '0',
			'description' =>
			  'the version of the calculation module used to generate the data',
			'needed' => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'access_right',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'a access right (scientis, group, all)',
			'needed'      => '1',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'array_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'nucleotide_array',
			'description'  => 'a link to the nucleotides array',
			'needed'       => '1'

		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'experiment_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'data_handler' => 'experiment',
			'description'  => 'a link to the experiment table',
			'needed'       => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the table name (!!) containing the data values',
			'needed'      => '1',
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = [ 'name', 'program_version' ]
	  ; # add here the values you would take to select a single value from the database
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	$self->{'data_handler'}->{'experiment'} =
	  experiment->new( $self->{'database_name'}, $self->{'debug'} );
	$self->{'data_handler'}->{'nucleotide_array'} =
	  nucleotide_array->new( $self->{'database_name'}, $self->{'debug'} );
	$self->{'data_handler'}->{'scientistTable'} =
	  scientistTable->new( $self->{'database_name'}, $self->{'debug'} );

	return $self;
}

=head2 get_Array_Lib_Interface

This function can be used to get an oligo2dnaDB of the nucleotide array, that is described by \$array_id.

=cut

sub get_Array_Lib_Interface {
	my ( $self, $array_id ) = @_;
	if ( ref($array_id) eq "HASH" ) {
		$array_id = $array_id->{'id'};
	}
	return $self->{'data_handler'}->{'nucleotide_array'}
	  ->get_Array_Lib_Interface( { 'id' => $array_id } );
}

=head2 GetSearchInterface

A search interface for this dataset is a oligo2dnaDB object that contains a set of
array data objects. To be onest - you should NOT use this method, as it is not flexible enough
in adding the array datasets.

What this function does:
1. Select the oligo2dnaDB for the 'array_id'.
2. select a set of array_datasets.
3. Add these arrays to the oligoDB object inside the oligo2dnaDB object.
	In order to do that it creates an array_ref at oligoDB->{'data_handler'}->{'oligo_array_values'}
	and populates this with oligo_array_values objects that have been primed with the selected table_baseNames.
	
=cut

sub GetSearchInterface {
	my ( $self, $dataset ) = @_;
	## OK now we have to take care...
	## 1. get the oligo2dnaDB
	## 2. identify all possible tables, that could be of interst
	## 3. add the tables to the oligo2dnaDB interface - could that be possible??
	## 4. enhance the linkage_info class to handle an array of reference tables!! <- DONE!
	my $small_report = '';
	my $dataDescription = [];
	
	if ( ref($dataset) eq "ARRAY" ) {
		my ( $sql, $sth, $rv, $data, $dataLine, $array_id );
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [
					$self->TableName() . ".name",
					$self->TableName() . ".array_id",
					$self->TableName() . ".table_baseString",
					$self->TableName() . ".experiment_id",
					$self->TableName() . ".program_name"
				],
				'where' => [ [ $self->TableName() .'.id', '=', 'my_value' ] ]
			},
			$dataset
		);


		$array_id = @{@$data[0]}[1];
		
		my $nucleotide_array_lib =
		  nucleotide_array->new( $self->{'database_name'}, $self->{'debug'} );
		my $oligo2dnaDB = $nucleotide_array_lib->get_Array_Lib_Interface({ 'id' => $array_id });
		foreach my $array ( @$data ){
			$oligo2dnaDB->Add_oligo_array_values_Table( @$array[2]);
			$small_report .= " @$array[0]";
			push(
				@$dataDescription,
				{
					'name'                 => @$array[0],
					'array_id'             => @$array[1],
					'experiment_id'        => @$array[3],
					'summary_program_name' => @$array[4]
				}
			);
		}
		
		return $oligo2dnaDB, $dataDescription;
	}
	warn ref($self)."::GetSearchInterface - sorry, but we need a array of dataset ids to perform this task...\n";
	return undef;
}

=head2 GetTableEntries_4_Dataset

We have a set of selection types:
=over 1

=item 1. Select all array datasets with the same 'array_id', 'experiment_id' and 'array_type'.
Here we could get all array datasets that were generated using the array design descibed by 'array_id',
have a connection to the experiment described by 'experiment_id' and finally are all of the same 'array_type' (e.g. 'IP' or 'INPUT').

=item 2. Select all array datasets that were produced using a single tissue from a single individual.

=cut

sub GetTableEntries_4_Dataset {
	my ( $self, $dataset ) = @_;

	Carp::confess("Do not use this function - it is completely useless!!\n");

	Carp::confess(
		ref($self)
		  . ":GetTableEntries_4_Dataset -> sorry, but this function is usable to get a sub_election for ONE array_id - and you have not provided that!\n"
	) unless ( defined $dataset->{'array_id'} );

	return undef;
}

sub _getAll_downstream_base_table_names {
	my ($self) = @_;
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'get_all_tableBaseNames' } );
	my ( $name, @return );

	if ( $sth->execute() ) {
		$sth->bind_columns( \$name );
		while ( $sth->fetch() ) {
			push( @return, $name );
		}
	}

	return \@return;
}

sub __create_tableBaseName_basics {
	my ( $self, $dataset ) = @_;
	$dataset->{'table_baseName_base'} = '';
	if ( defined $dataset->{'name'} ) {
		$dataset->{'table_baseName_base'} .= "$dataset->{'name'}_";
	}
	else {
		$self->{'error'} .= ref($self)
		  . ":check_dataset -> we need the 'name' to create the table base name!\n";
	}
	if ( defined $dataset->{'program_version'} ) {
		$dataset->{'table_baseName_base'} .=
		  "vers_$dataset->{'program_version'}";
	}
	else {
		$self->{'error'} .= ref($self)
		  . ":check_dataset -> we need the 'program_version' to create the table base name!\n";
	}
	$dataset->{'table_baseName_base'} =~ s/ /_/g;
	$dataset->{'table_baseName_base'} =~ s/'//g;
	$dataset->{'table_baseName_base'} =~ s/"//g;
	$dataset->{'table_baseName_base'} =~ s/-/_/g;
	return 1;
}

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';

#print ref($self)
#  . ":INSERT_INTO_DOWNSTREAM_TABLES -> the table_baseName_base = $dataset->{table_baseName_base}\n";

	$dataset->{'oligoDB'} =
	  $self->{'data_handler'}->{'nucleotide_array'}
	  ->Get_OligoDB_for_ID( $dataset->{'array_id'} );

	$dataset->{'array'} =
	  @{ $self->{'data_handler'}->{'nucleotide_array'}
		  ->Select_by_ID( $dataset->{'array_id'} ) }[0];
	$self->_get_search_array($dataset)
	  ; ## that will take care of all modifications of the dataset prior to the _real_insert statement

	my $oligo_array_values =
	  $dataset->{'oligoDB'}->get_downstreamTable(
		{ 'tableBaseName' => $dataset->{'table_baseName_base'} } );
	$dataset->{'table_baseString'} = $oligo_array_values->TableName();
	$oligo_array_values->AddDataset($dataset);
	$self->{error} .= $oligo_array_values->{'error'};

	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;
	die $self->{error} unless ( $self->check_dataset($dataset) );

	$self->_create_insert_statement();

	## did you only want to look for a thing?
	return $dataset->{id} if ( defined $dataset->{'id'} );
	$self->__create_tableBaseName_basics($dataset);
	Carp::confess( $self->{error} )
	  unless ( $self->INSERT_INTO_DOWNSTREAM_TABLES($dataset) );

	## do we already have that dataset
	## in case we know previously which arre subtype was meant...

	my $id = $self->_return_unique_ID_for_dataset($dataset);
	return $id if ( defined $id );

	if ( $self->{'debug'} ) {
		print ref($self),
		  ":AddConfiguration -> we are in debug mode! we will execute: '",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n";
	}

	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	## $result->{'table_name'},    $result->{'data_type'}
	unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
		die ref($self),
		  ":AddConfiguration -> we got a database error for query '",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n", $self->{dbh}->errstr();
	}
	$id = $self->_return_unique_ID_for_dataset($dataset);
	return $id if ( defined $id );
}

sub get_id_for_subject_experiment_tissue {
	my ( $self, $subject_id, $experiment_id, $tissue_id ) = @_;
	my $sth = $self->_get_SearchHandle(
		{ 'search_name' => 'select_id_for_subject_experiment_tissue' } );
	unless ( $sth->execute( $subject_id, $experiment_id, $tissue_id ) ) {
		warn ref($self),
":get_id_for_subject_experiment_tissue -> we got an sql error while executing'",
		  $self->_getSearchString(
			'select_id_for_subject_experiment_tissue',
			$subject_id, $experiment_id, $tissue_id
		  ),
		  ",'\n", $self->{dbh}->errstr();    #
		return 0;
	}
	my ($id);
	$sth->bind_columns( \$id );
	$sth->fetch();
	return $id;
}

1;
