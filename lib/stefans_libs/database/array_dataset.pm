package array_dataset;

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
use stefans_libs::database::sampleTable;
use stefans_libs::database::experiment;
use stefans_libs::database::tissueTable;
use stefans_libs::database::scientistTable;
use stefans_libs::database::array_dataset::oligo_array_values;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip;

use base qw(variable_table);

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

new returns a new object reference of the class array_dataset.

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
		'database_name' => $database,
		'possible_tasks' =>
		  { 'add nimblegene Chip on chip data' => 'nucleotideArray' },
		'get_all_tableBaseNames' =>
		  'select table_baseString from array_datasets',
		'select_id_for_subject_experiment_tissue' =>
'select id from array_datasets where subject_id =? && experiment_id = ? && tissue_id = ?'
	};

	bless $self, $class if ( $class eq "array_dataset" );

	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ($self) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "array_datasets";
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
			'name'         => 'sample_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'sampleTable',
			'description'  => 'a link to the samples table',
			'needed'       => '1'
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
			'NULL'         => '0',
			'data_handler' => 'experiment',
			'description'  => 'a link to the experiment table',
			'needed'       => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'array_type',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the same as in nucleotide_array_libs.array_type',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the table name (!!) containing the data values',
			'needed'      => '1',
		}
	);
	push(
		@{ $hash->{'UNIQUES'} },
		[
			'scientist_id', 'sample_id', 'array_id', 'experiment_id',
			'array_type'
		]
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} =
	  [ 'scientist_id', 'sample_id', 'array_id', 'experiment_id',
		'array_type' ]
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
	$self->{'data_handler'}->{'tissueTable'} =
	  tissueTable->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'nucleotide_array'} =
	  nucleotide_array->new( $self->{'database_name'}, $self->{'debug'} );
	$self->{'data_handler'}->{'sampleTable'} =
	  sampleTable->new( $self->{'database_name'}, $self->{'debug'} );
	$self->{'data_handler'}->{'scientistTable'} =
	  scientistTable->new( $self->{'database_name'}, $self->{'debug'} );

	return $self;
}

=head2 GetSearchInterface

A search interface for this dataset is a oligo2dnaDB object that contains a set of
array data objects. In order to get the object, you need to provide a reference to an array of array_dataset.id values.

What this function does:
=over

=item
1. Select the oligo2dnaDB for the 'array_id'.

=item
2. select a set of array_datasets.

=item
3. Add these arrays to the oligoDB object inside the oligo2dnaDB object.
	In order to do that it creates an array_ref at oligoDB->{'data_handler'}->{'oligo_array_values'}
	and populates this with oligo_array_values objects that have been primed with the selected table_baseNames.

=back
	
=cut

sub GetSearchInterface {
#	warn ref(@$_[0])."::GetSearchInterface ( @_ )\n";
	my ( $self, $dataset ) = @_;
	## OK now we have to take care...
	## 1. get the oligo2dnaDB
	## 2. identify all possible tables, that could be of interst
	## 3. add the tables to the oligo2dnaDB interface - could that be possible??
	## 4. enhance the linkage_info class to handle an array of reference tables!! <- DONE!
	unless ( ref($dataset) eq "ARRAY" ) {
		warn ref($self)
		  . "::GetSearchInterface - we expect an array of dataset ids, not $dataset\n";
	}
	my ( $array_id );
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".array_id" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$dataset
	);
 	warn "we did the complex search $self->{'complex_search'}\n";
	foreach my $array ( @$data ){
		$array_id = @$array[0] unless ( defined $array_id);
		Carp::confess( ref($self). "-- we have a array_id missmatch ($array_id != @$array[0]) --\n")
			if ($array_id != @$array[0]) ;
	}

	return undef unless ( defined $array_id );

	my $oligo2dnaDB =
	  $self->{'data_handler'}->{'nucleotide_array'}
	  ->get_Array_Lib_Interface( { 'id' => $array_id } );
	$data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".table_baseString" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$dataset
	);
	warn "we did the complex search $self->{'complex_search'}\n";
	foreach my $array ( @$data ){
		$oligo2dnaDB->Add_oligo_array_values_Table( @$array[0], undef, @$array[1] );
		#warn "we add the data table @$array[0]\n";
	}

#print root::get_hashEntries_as_string( $oligo2dnaDB->{'data_handler'}->{'oligoDB'}->{'data_handler'}, 4, ref($self)."do we have the right data handling objects in the \$oligo2dnaDB->{'oligoDB'}->{'data_handler'}?" );
#print root::get_hashEntries_as_string( $oligo2dnaDB->{'data_handler'}->{'oligoDB'}->{'table_definition'}->{'variables'}, 4, "and here come the variable definitions of that calss...");
	return $oligo2dnaDB->AsInterface();
}

=head3 getMinimalSearchInterface

This function can be used to get a database interface without the oligo_2_dnaDB part.
Therefore a minimal interface can not be used to mapp oligos to a genomic region.

Atributes: an array reference of array_dataset.id variables, that are used to select the data values that you are interested in.

Return Value: an oligoDB object stuffed with the array_variable_tables that correspond to the array ids you gave me - so select wisely!

=cut

sub getMinimalSearchInterface{
	my ( $self, $dataset ) = @_;
	
	unless ( ref($dataset) eq "ARRAY" ) {
		warn ref($self)
		  . "::GetSearchInterface - we expect an array of dataset ids, not $dataset\n";
	}
	my ( $array_id );
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".array_id" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$dataset
	);
 	#warn "we did the complex search $self->{'complex_search'}\n";
	foreach my $array ( @$data ){
		$array_id = @$array[0] unless ( defined $array_id);
		Carp::confess( ref($self). "-- we have a array_id missmatch ($array_id != @$array[0]) --\n")
			if ($array_id != @$array[0]) ;
	}
	return undef unless ( defined $array_id );

	my $oligoDB = $self->{'data_handler'}->{'nucleotide_array'}->Get_OligoDB_for_ID( $array_id );
	$data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".table_baseString", 'sample_lable' ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$dataset
	);
	#warn "we did the complex search $self->{'complex_search'}\n";
	foreach my $array ( @$data ){
		$oligoDB->Add_oligo_array_values_Table( @$array[0], undef, @$array[1] );
		#warn "getMinimal: we add the data table @$array[0]\n";
	}
	## and now we need to get the sample IDs for the datasets!!
	
	return $oligoDB;
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

	Carp::confess(
		ref($self)
		  . ":GetTableEntries_4_Dataset -> sorry, but this function is usable to get a sub_election for ONE array_id - and you have not provided that!\n"
	) unless ( defined $dataset->{'array_id'} );

	if (   defined $dataset->{'experiment_id'}
		&& defined $dataset->{'array_type'} )
	{
		return $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['array_dataset.table_baseString'],
				'where'          => [
					[ 'array_dataset.array_id',      '=', "my value" ],
					[ 'array_dataset.experiment_id', "=", "my value" ],
					[ 'array_dataset.array_type',    "=", "my value" ]
				],
			},
			$dataset->{'array_id'},
			$dataset->{'experiment_id'},
			$dataset->{'array_type'}
		);
	}
	elsif ( defined $dataset->{'experiment_id'} ) {
		return $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['array_dataset.table_baseString'],
				'where'          => [
					[ 'array_dataset.array_id',      '=', "my value" ],
					[ 'array_dataset.experiment_id', "=", "my value" ]
				],
			},
			$dataset->{'array_id'},
			$dataset->{'experiment_id'}
		);
	}
	elsif ( defined $dataset->{'id'} ) {
		return $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['array_dataset.table_baseString'],
				'where'          => [ [ 'array_dataset.id', '=', "my value" ] ],
			},
			$dataset->{'id'}
		);
	}
	return undef;
}

sub expected_dbh_type {

	#return 'dbh';
	#return "not a databse interface";
	return "database_name";
}

=head2 check_dataset

We check, whether we could insert the dataset into the database.
As we have a main insertion point here, the check will execute checks 
for the downstream tables in addition to the checks for the own dataset.

For this thing to work we need several entries in the dataset:

=over 3

=item name => the type of the dataset - whether it is a ChIP on chip dataset or an affymetrix expression arrayset.
Keep in mind, that we can handle only oligonucleotide DATASETS, not the library information here.

=item scientist => a hash of data that defines one scientist. 
This hash will be processed by stefans_libs::database::scientistTable using the check_dataset of that class.

=item subject => a hash of data that defines the origin of the used biological sample.
This hash will be processed by stefans_libs::database::subjectTable using the check_dataset of that class.

=item nucleotide_array => a hash that can be used to link to the library information of that particular array.
This hash will be processed by stefans_libs::database::nucleotide_array using the check_dataset of that class.

=item experiments => a hash that can be used to link to an experiment entry in the database.
This hash will be processed by stefans_libs::database::experiment using the check_dataset of that class.

=item tissues => a hash that can be used to link to an used tissue entry in the database.
This hash will be processed by stefans_libs::database::tissueTable using the check_dataset of that class.

=item data => a hash that contains the needed datasets for the database import. For the array datasets, the class 
stefans_libs::database::array_dataset::oligo_array_values is used to handle the data. 
Therefore the hash has to meet the criterias defined by that class.

=back

In addition to thiose quite complicated entries we need to know who can access these datasets.
I have not thought about that in great detail, but I think, we have to make a check using the
stefans_libs::database::scientistTable, as there might be a restriction so that 
(1) only the scientist that uploaded the dataset 
(2) the scientist and the corresponding supervisor
(3) the whole group of the scientist
(4) everyone
may execute downstream actions. Therefore we need the hash entry 'access_right' to be one of those entries:
('scientist', 'supervisor', 'group', 'all').

Please keep in mind, that the database administrator 
and most probably the whole BioInformatics group has access to the dataset.
But if you can't trust them - don't use this database!

=cut

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

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	$dataset->{'array_type'} = "UNKNOWN"
	  unless ( defined $dataset->{'array_type'} );
	$self->__create_tableBaseName_basics();

	return 1;
}

sub __create_tableBaseName_basics {
	my ( $self, $dataset ) = @_;
	$dataset->{'table_baseName_base'} = '';
	if ( defined $dataset->{'sample_id'} ) {
		$dataset->{'table_baseName_base'} .= "sample_$dataset->{'sample_id'}_";
	}
	else {
		$self->{'error'} .= ref($self)
		  . ":check_dataset -> we need the 'sample_id' to create the table base name!\n";
	}
	if ( defined $dataset->{'experiment_id'} ) {
		$dataset->{'table_baseName_base'} .= "exp_$dataset->{'experiment_id'}_";
	}
	else {
		$self->{'error'} .= ref($self)
		  . ":check_dataset -> we need the 'experiment_id' to create the table base name!\n";
	}
	if ( defined $dataset->{'array_id'} ) {
		$dataset->{'table_baseName_base'} .= "array_$dataset->{'array_id'}";
	}
	else {
		$self->{'error'} .= ref($self)
		  . ":check_dataset -> we need the 'array_id' to create the table base name!\n";
	}
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
	if (   $dataset->{'array'}->{'manufacturer'} eq "nimblegene"
		&& $dataset->{'array'}->{'array_type'} eq "Chip on chip" )
	{

		#warn "WE WILL INSERT THE OLIGO VALUES NOW!!\n";
		my $nimble =
		  NimbleGene_Chip_on_chip->new( $self->{'dbh'}, $self->{debug} );
		$dataset->{downstream_info} = $nimble->AddDataset($dataset);
		$self->{'error'} .= $nimble->{error};
	}
	else {
		warn
"we could not identify a task for '$dataset->{'array'}->{'manufacturer'}' -- '$dataset->{'array'}->{'array_type'}'\n";
		Carp::confess(
			root::get_hashEntries_as_string( $dataset, 4,
				ref($self) . ":AddDataset -> we can not handle the dataset\n" )
			  . $self->{error}
		);
	}

	foreach my $result ( @{ $dataset->{downstream_info} } ) {
		$self->{'error'} .=
		  ref($self)
		  . ":INSERT_INTO_DOWNSTREAM_TABLES -> we did not get the expected results ('table_name' is missing)"
		  unless ( defined $result->{'table_name'} );
		$self->{'error'} .=
		  ref($self)
		  . ":INSERT_INTO_DOWNSTREAM_TABLES -> we did not get the expected results ('array_type' is missing)"
		  unless ( defined $result->{'array_type'} );
	}
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;
	die $self->{error} unless ( $self->check_dataset($dataset) );

	$self->_create_insert_statement();

	## did thy only want to look for a thing?
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
	unless ( ref( $dataset->{downstream_info} ) eq "ARRAY"
		&& defined @{ $dataset->{downstream_info} }[0] )
	{
		Carp::confess(
			ref($self) . "::ddDataset -> We have nothing to insert!\n" );
	}
	## $result->{'table_name'},    $result->{'data_type'}
	foreach my $result ( @{ $dataset->{downstream_info} } ) {
		$dataset->{'table_baseString'} = $result->{'table_name'};
		$dataset->{'array_type'}       = $result->{'array_type'};
		next if ( $self->insertOK($dataset) );
		unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
			die ref($self),
			  ":AddConfiguration -> we got a database error for query '",
			  $self->_getSearchString(
				'insert', @{ $self->_get_search_array($dataset) }
			  ),
			  ";'\n", $self->{dbh}->errstr();
		}
	}
	$id = $self->_return_unique_ID_for_dataset($dataset);
	return $id if ( defined $id );
}

sub insertOK {
	my ( $self, $dataset ) = @_;
	return $self->{'IS_OK'} if ( defined $self->{'IS_OK'} );
	if ( defined $self->_return_unique_ID_for_dataset($dataset) ) {
		$self->{'IS_OK'} = 0;
	}
	else {
		$self->{'IS_OK'} = 1;
	}
	return $self->{'IS_OK'};
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
