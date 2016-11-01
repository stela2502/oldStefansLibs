package basic_list;

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
use base ('variable_table');

sub new {

	my ( $class, $debug ) = @_;

	Carp::confess(
"FOOL - this is an interface - you con not create an object from that!\n"
	  )
	  unless ($debug);

	#$self->{'data_handler'}->{'otherTable'} =
	#   SOME_OTHER_TABLE_OBJECT->new( $dbh, $debug );
	my $self = {};
	bless $self, $class if ($class);
	return $self;
}

sub expected_dbh_type {
	return 'dbh';
}

sub readLatestID {
	my ($self) = @_;
	my ( $sql, $sth, $rv );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.list_id' ],
			'where'          => [],
			'order_by' => [ [ 'my_value', '-', ref($self) . '.list_id' ] ],
			'limit'    => "limit 1"
		}
	)->get_line_asHash(0);
	return 0 unless ( defined $data );
	return $data->{ ref($self) . '.list_id' };
}

sub UpdateList {
	my ( $self, $dataset ) = @_;
	Carp::confess(
		ref($self)
		  . "::UpdateList - we need a list_id in order to know which liots to update!"
	  )
	  unless ( defined $dataset->{'list_id'} );
	Carp::confess(
		ref($self)
		  . "::UpdateList - we need an array of other_ids in order to update the list!"
	  )
	  unless ( ref( $dataset->{'other_ids'} ) eq "ARRAY" );
	## 1. get our old list
	my ( $oldList, @temp, $new_list );
	foreach ( @{ $dataset->{'other_ids'} } ) {
		$new_list->{$_} = 1;
	}

	@temp = @{
		$self->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ ref($self) . ".id", ref($self) . ".others_id" ],
				'where' => [ [ ref($self) . ".list_id", "=", "my_value" ] ]
			},
			$dataset->{'list_id'}
		)
	  };
	foreach (@temp) {
		$oldList->{ @$_[1] } = @$_[0];
	}
	## 2. check if we need to remove entries
	foreach ( keys %$oldList ) {
		$self->DropEntry( $oldList->{$_} ) unless ( $new_list->{$_} );
	}
	## 3. check if we need to add entries
	foreach ( keys %$new_list ) {
		$self->add_to_list( $dataset->{'list_id'}, { 'id' => $_ } )
		  unless ( defined( $oldList->{$_} ) );
	}
	return 1;
}

sub DropEntry {
	my ( $self, $id ) = @_;
	return $self->{'dbh'}
	  ->do( 'delete from ' . $self->TableName() . " where id = $id" )
	  or Carp::confess(
		"I could not delete the id $id!\n" . $self->{'dbh'}->errstr() . "\n" );
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = $self->{'my_table_name'};
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'list_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'others_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'otherTable',
			'description'  => '',
			'needed'       => ''
		}
	);

	push( @{ $hash->{'UNIQUES'} }, [ 'list_id', 'others_id' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} =
	  [ 'list_id', 'others_id' ]
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

	return $dataset;
}

sub remove_from_list {
	my ( $self, $list_id, $managed_dataset ) = @_;
	my $managed_id =
	  $self->{'data_handler'}->{'otherTable'}
	  ->_return_unique_ID_for_dataset($managed_dataset);
	return undef unless ( defined $managed_id );
	$self->delete_entry(
		{ 'list_id' => $list_id, 'others_id' => $managed_id } );
}

sub add_to_list {
	my ( $self, $list_id, $managed_dataset ) = @_;

#print root::get_hashEntries_as_string ( {'managed dataset' => $managed_dataset, 'list_id' => $list_id, 'otherTable' => $self->{'data_handler'}->{'otherTable'} } , 3 , "The data and data handlers" );
#print "now we try to add the managed dataset!\n";
	my $managed_id =
	  $self->{'data_handler'}->{'otherTable'}->AddDataset($managed_dataset);

	#print "we got a managed ID = '$managed_id' (listID = $list_id)\n";
	unless (
		defined $self->SUPER::_return_unique_ID_for_dataset(
			{ 'list_id' => $list_id, 'others_id' => $managed_id }
		)
	  )
	{

#warn "we could not get a touple'list_id'=> $list_id,'others_id'=> $managed_id with this search\n".$self->{'complex_search'}."\n";
		$self->_create_insert_statement();
		my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
		unless ( $sth->execute( $list_id, $managed_id ) ) {
			Carp::confess(
				ref($self),
				":AddConfiguration -> we got a database error for query'",
				$self->_getSearchString( 'insert', $list_id, $managed_id ),
				";'\n"
			);
		}
	}
	return 1;
}

sub Add_managed_Dataset {
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . "::Add_managed_Dataset -> we need a hash as argument, not'$dataset'\n "
	  unless ( ref($dataset) eq "HASH" );

	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	return $self->{'data_handler'}->{'otherTable'}->AddDataset($dataset);
}

sub Get_List_Of_Other_IDS {
	my ( $self, $datasets ) = @_;
	unless ( ref($datasets) eq "ARRAY" ) {
		$datasets = [$datasets];
	}
	my @return;
	foreach my $data (@$datasets) {
		push( @return,
			$self->{'data_handler'}->{'otherTable'}->AddDataset($data) );
	}
	return \@return;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	if ( defined $dataset->{'linked_datasets'} ) {
		$dataset->{'others_id'} =
		  $self->Get_List_Of_Other_IDS( $dataset->{'linked_datasets'} );
	}
	$dataset->{'list_id'} = 0 unless ( defined $dataset->{'list_id'} );
	if ( $dataset->{'list_id'} > 0 && !defined( $dataset->{'others_id'} ) ) {
		if (
			defined @{
				$self->_select_all_for_DATAFIELD( $dataset->{'list_id'},
					'list_id' )
			}[0]
		  )
		{
			$dataset->{'id'} =
			  $dataset->{ 'list_id'
			  }; ## that is a completely unseless modification here, but needed to come accross the variables_table::check_dataset
			return 1;
		}
		$self->{'error'} .=
		  ref($self) . " ::DO_ADDITIONAL_DATASET_CHECKS->we have no'list_id'
		  and unfortunately also no'others_id'ids array \n ";
		return 0;
	}
	elsif ( $dataset->{'list_id'} > 0 ) {
		if (
			$self->_list_contains_only_these_IDs(
				$dataset->{'list_id'}, $dataset->{'others_id'}
			)
		  )
		{
			return 1;
		}
		else {
			$dataset->{'list_id'} = 0;
		}
	}
	elsif ( $dataset->{'list_id'} > 0
		&& ref( $dataset->{'others_id'} ) eq 'ARRAY' )
	{
		## OK - perhaps we want to add a value to a list...
		my $data_array = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ ref($self) . " . others_id " ],
				'where' => [ [ ref($self) . " . list_id ", '=', 'my_value' ] ]
			},
			$dataset->{'list_id'}
		);
		my $add = 1;
		my @array;
		foreach my $other_id ( @{ $dataset->{'others_id'} } ) {
			foreach (@$data_array) {
				$add = 0 if ( @$_[0] == $other_id );
			}
			if ($add) {
				push( @array, $other_id );
			}
		}
		$dataset->{'others_id'} = \@array;
		return 1;
	}

#print ref($self)." ::DO_ADDITIONAL_DATASET_CHECKS->we would expect, that \$dataset->{'others_id'} is an array ref( $dataset->{'others_id'} ) \n ";
	if ( ref( $dataset->{'others_id'} ) eq "ARRAY" ) {

		if ( scalar( @{ $dataset->{'others_id'} } ) == 0 ) {
			$self->{'error'} .=
			  ref($self)
			  . " ::DO_ADDITIONAL_DATASET_CHECKS->we do not have a others_id
		  and we do not have a list_id->so we can do nothing !\n ";
			return 0;
		}

#print ref($self)."::DO_ADDITIONAL_DATASET_CHECKS->we got an array of data entries(as expected ! ) \n ";;
		my ( $materialList_ids, $dataRow, $materialList_id, $others_id );
		@{ $dataset->{'others_id'} } =
		  sort { $a <=> $b } @{ $dataset->{'others_id'} };
		## OK 1. do we have a list with this ids
		my $data_array = $self->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ ref($self) . ".list_id", ref($self) . ".others_id" ],
				'where' => [ [ ref($self) . ".others_id ", '=', 'my_value' ] ]
			},
			$dataset->{'others_id'}
		);

		## now we have to create a list of possible IDs
		foreach $dataRow (@$data_array) {

#print ref($self)." ::DO_ADDITIONAL_DATASET_CHECKS->list_id = @$dataRow[0]; others_id = @$dataRow[1] \n ";
			$materialList_ids->{ @$dataRow[0] } = {}
			  unless ( defined $materialList_ids->{ @$dataRow[0] } );
			$materialList_ids->{ @$dataRow[0] }->{ @$dataRow[1] } = 1;
		}

		## and now we have to check, whether we have a list that corresponds to the query
		foreach $materialList_id ( keys %$materialList_ids ) {
			if (
				$self->_list_contains_only_these_IDs(
					$materialList_id, $dataset->{'others_id'}
				)
			  )
			{
				$dataset->{'list_id'} = $materialList_id;
				return 1;
			}
		}
		## OK - we do not have a list, that contains all the materials needed here
		## therefore we need to check, if at least all the materials are are defined
		## in the database. Otehrwise we have to thorow an error!
		foreach $others_id ( @{ $dataset->{'others_id'} } ) {
			unless (
				defined @{
					$self->{'data_handler'}->{'otherTable'}
					  ->Select_by_ID($others_id)
				}[0]
			  )
			{
				$self->{'error'} .=
				  ref($self)
				  . " ::DO_ADDITIONAL_DATASET_CHECKS->we do not know the material
		  for this id $others_id\n ";

			}
		}
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );

	return 1;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	if ( ref($dataset) eq "ARRAY" ) {
		## oh shit - should we really be able to do that??
		## I have to admit that you want to have a new list!
		my $hash = { 'others_id' => [], 'list_id' => 0 };
		foreach my $dat (@$dataset) {
			next unless ( ref($dat) eq "HASH" );

			#print "we try to add a managaed dataset:\n";
			push( @{ $hash->{'others_id'} }, $self->Add_managed_Dataset($dat) );
		}
		shift @{ $hash->{'others_id'} }
		  unless ( defined @{ $hash->{'others_id'} }[0] );
		unless ( scalar( @{ $hash->{'others_id'} } ) > 0 ) {
			Carp::confess(
"You wanted to create a new list entry using an empty array - that can not be accepted!\n"
				  . root::get_hashEntries_as_string( $dataset, 3, "the array " )
			);
		}
		$dataset = $hash;
	}
	unless ( ref($dataset) eq "HASH" ) {
		Carp::confess(
			ref($self)
			  . ": AddDataset->didn't you want to get a result? - we have no dataset to add!!\n"
		);
		return undef;
	}
	my $my_id = $self->_return_unique_ID_for_dataset($dataset);
	if ( defined $my_id ) {
		## you only tried to identfy the list - cool
		return $my_id;
	}

#	;    ## perhaps this value is not needed for the downstream table...
#	Carp::confess( root::get_hashEntries_as_string ($dataset, 3,"we have tried to check a dataset to insert into a list and got the error:\n".  $self->{error} ))
#	  unless ( $self->check_dataset($dataset) );

	## did thy only want to look for a thing?

	if ( $dataset->{'list_id'} > 0 ) {
		$dataset->{'id'} = $dataset->{'list_id'};
		return $dataset->{'list_id'};
	}

#	print
#"suprise suprise -  we do not have a list with the list_id'$dataset->{'list_id'}'?\n";

	#	Carp::confess $self->{error}
	#	  unless ( $self->INSERT_INTO_DOWNSTREAM_TABLES($dataset) );

	## print "And we are still alive HarHarHar!\n";

	$self->_create_insert_statement();

	#print "we have an sample insert statement: $self->{'insert'}\n";
	if ( $self->{'debug'} ) {
		print ref($self),
		  ":AddConfiguration -> we are in debug mode! we will execute:'",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n";
	}
	$self->{'__actualID'} = $self->readLatestID();
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	my $already_processed;
	foreach my $others_id ( @{ $dataset->{'others_id'} } ) {
		next if ( $already_processed->{$others_id} );
		unless ( $sth->execute( $self->{'__actualID'} + 1, $others_id ) ) {
			Carp::confess(
				ref($self),
				":AddConfiguration -> we got a database error for query'",
				$self->_getSearchString(
					'insert', @{ $self->_get_search_array($dataset) }
				),
				";'\n",
				root::get_hashEntries_as_string(
					$dataset,
					4,
					"the dataset we tried to insert into the table structure:"
				  )
				  . "And here are the database errors:\n"
				  . $self->{dbh}->errstr()
			);
		}
		$already_processed->{$others_id} = 1;
	}
	$self->{'__actualID'} = $self->readLatestID();
	return $self->{'__actualID'};

}

sub _list_contains_only_these_IDs {
	my ( $self, $list_id, $others_ids_Array ) = @_;
	my ( $data_array, $searchHash, $materialID );
	Carp::confess(
"Sorry, but we need an array of others_ids to search for a list (NOT $others_ids_Array)!"
	  )
	  unless ( ref($others_ids_Array) eq "ARRAY" );

	$data_array = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".others_id" ],
			'where'          => [ [ ref($self) . ".list_id", '=', 'my_value' ] ]
		},
		$list_id
	);
	foreach my $dataRow (@$data_array) {
		$searchHash->{ @$dataRow[0] } = 1;
	}
	my $return = 1;
	foreach $materialID (@$others_ids_Array) {
		if ( $searchHash->{$materialID} ) {
			$searchHash->{$materialID} = 0;
		}
		else {
			## we do not have an entry in that list that should be there
			$return = 0;
		}
	}

	foreach $materialID (@$others_ids_Array) {
		if ( $searchHash->{$materialID} ) {
			## oops - we do not have an entry in that list for this material and therefore this list does not match the requirements - sorry
			$return = 0;
		}
	}
	unless ( @$others_ids_Array == keys(%$searchHash) ) {
		$return = 0;
	}
	return $return;
}

sub _return_unique_ID_for_dataset {
	my ( $self, $dataset ) = @_;

	my ( $searchArray, $where, $rv );

	$where       = [ [ $self->TableName() . ".others_id", "=", "my_value" ] ];
	$searchArray = [ $dataset->{'others_id'} ];

	return undef
	  unless ( ref( $dataset->{'others_id'} ) eq "ARRAY" );
	return undef unless ( defined @{ $dataset->{'others_id'} }[0] );

	$rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				$self->TableName() . '.list_id',
				$self->TableName() . '.others_id'
			],
			'where' => $where
		},
		@$searchArray
	);

#	print ref($self)
#	  . "->_return_unique_ID_for_dataset : we executed the sql $self->{'complex_search'}\n";
	$searchArray = {};

	foreach $where (@$rv) {
		$searchArray->{ @$where[0] } = []
		  unless ( defined $searchArray->{ @$where[0] } );
		push( @{ $searchArray->{ @$where[0] } }, @$where[1] );
	}
	foreach my $id ( keys %$searchArray ) {

		#		print "we try to find the full list comparing "
		#		  . join( ";", sort @{ $dataset->{'others_id'} } )
		#		  . " with "
		#		  . join( ";", sort @{ $searchArray->{$id} } ) . "\n";
		return $id
		  if (
			join( ";", sort @{ $dataset->{'others_id'} } ) eq
			join( ";", sort @{ $searchArray->{$id} } ) );
	}
	return undef;
}

sub Get_IDs_for_ListID {
	my ( $self, $list_id ) = @_;
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".others_id" ],
			'where'          => [ [ ref($self) . ".list_id", '=', 'my_value' ] ]
		},
		$list_id
	);
	my @return;
	foreach my $array (@$data) {
		push( @return, @$array[0] );
	}
	return \@return;
}

sub _getLinkageInfo {
	my ($self) = @_;
	## we need to create a hash of the structure:
	##{
	##	class_name  => ref($self),
	##	'variables' => { class.name => TableName.name },
	##	'links'     => { <join statement> => { this hash other class } }
	##}
	my $linkage_info = linkage_info->new();
	$linkage_info->ClassName( ref($self) );
	$linkage_info->AddVariable( $self, 'id' );
	$linkage_info->AddVariable( $self, 'list_id' );
	$linkage_info->myVariableName_linksTo_otherObj_id( $self, 'others_id',
		$self->{'data_handler'}->{'otherTable'} );
	return $linkage_info;
}
1;
