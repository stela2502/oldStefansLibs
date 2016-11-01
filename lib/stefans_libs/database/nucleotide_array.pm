package nucleotide_array;

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
use stefans_libs::database::nucleotide_array::nimbleGeneArrays;
use stefans_libs::database::nucleotide_array::Affymetrix_SNP_array;

#use stefans_libs::database::oligo2dna_register;
use stefans_libs::database::genomeDB;

use File::HomeDir;
use stefans_libs::database::variable_table;
use base qw( variable_table);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store and retrieve nucleotide array informations.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class nucleotide_array.

=cut

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
		warn "$class:new -> got no DB name => dbName set to 'genomeDB'\n";
	}
	my ($self);

	$self = {
		'database_name' => $database,
		debug           => $debug,
		tempDir         => File::HomeDir->my_home() . "/temp",
		dbh             => root::getDBH( 'root', $database ),
		oligo2dna       => undef,
		'restrictions'  => {
			'companies'  => { 'nimblegene'   => 1 },
			'array_type' => { 'ChIP on chip' => 1 }
		},
		'known companies' => "nimblegene ",    # "affymetrix",
		'get_tableBaseName_for_identifier' =>
"select manufacturer, table_baseString from nucleotide_array_libs where identifier = ?",
		'get_all_tableBaseNames' =>
		  'select table_baseString from nucleotide_array_libs',
		'get_id_for_identifier' =>
		  "select id from nucleotide_array_libs where identifier = ?",
	};

	bless $self, $class if ( $class eq "nucleotide_array" );

	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "nucleotide_array_libs";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'identifier',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'a identifier for this particular array design',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'manufacturer',
			'type' => 'VARCHAR (40)',
			'NULL' => '0',
			'description' =>
'the manufacturer of that array ->only (\"nimblegene\") is supported',
			'needed' => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'array_type',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the name of the array type (\"ChIP on chip\")',
			'needed'      => '1'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'table_baseString',
			'type' => 'VARCHAR (100)',
			'NULL' => '0',
			'description' =>
'the table name where to find the datasets. This name has to be given to the data_handler class',
			'needed' => '1'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['identifier'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['identifier']
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
	$self->{'downstream_data_handler'}->{'nimblegene'} =
	  nimbleGeneArrays->new( $self->{dbh}, $debug );
	$self->{'downstream_data_handler'}->{'Affymetrix_SNP_array'} =
	  Affymetrix_SNP_array->new( $self->{dbh}, $debug );

	$self->{'unique_data_handler'}->{'oligo2dna_register'} =
	  oligo2dna_register->new( $self->{'database_name'}, $self->{'debug'} );
	foreach ( values %{ $self->{'downstream_data_handler'} } ) {
		$_->{'oligo2dna_register'} =
		  $self->{'unique_data_handler'}->{'oligo2dna_register'};
	}

	#$self->create() unless ( $self->tableExists('nucleotide_arrays') );
	return $self;

}

sub expected_dbh_type {

	#return 'dbh';
	return "database_name";
}

sub get_Array_Lib_Interface {
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';
	my ( $data, $interface );

	if ( defined $dataset->{'id'} ) {
		my $array = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [
					ref($self) . ".id",
					ref($self) . ".identifier",
					ref($self) . ".manufacturer",
					ref($self) . ".array_type",
					ref($self) . ".table_baseString"
				],
				'where' => [ [ref($self) . ".id",'=','my_value'] ],
			}, $dataset->{'id'}
		);
		$data->{'id'} = @{@$array[0]}[0];
		$data->{'identifier'} = @{@$array[0]}[1];
		$data->{'manufacturer'} = @{@$array[0]}[2];
		$data->{'array_type'} = @{@$array[0]}[3];
		$data->{'table_baseString'} = @{@$array[0]}[4];
	}
	else{
		$data = $self->GET_entries_for_UNIQUE(
		[
			'id', 'identifier', 'manufacturer', 'array_type', 'table_baseString'
		],
		$dataset
	);
	}
	

	Carp::confess(
		    ref($self)
		  . ":get_Array_Lib_Interface -> "
		  . "we could not get the result for the dataset "
		  . root::get_hashEntries_as_string( $dataset, 3, "$dataset" )
		  . "- we expected to get an HASH not:"
		  . root::get_hashEntries_as_string( $data, 3, "$data" ) )
	  unless ( ref($data) eq "HASH" );

	#$data->{'id'} = undef;
	if (
		defined $self->{'downstream_data_handler'}
		->{ $data->{'manufacturer'} } )
	{
		$interface =
		  $self->{'downstream_data_handler'}->{ $data->{'manufacturer'} }
		  ->get_Array_Lib_Interface( $dataset, $data );
		$self->{'error'} .=
		  $self->{'downstream_data_handler'}->{ $data->{'manufacturer'} }
		  ->{'error'};
	}
	$self->{'error'} .=
	  ref($self)
	  . ":get_Array_Lib_Interface -> I absolutely need to know either the 'id' or the 'identifier' of the array where you want to get your lib for\n"
	  unless ( defined $data );
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	return $interface;
}

sub _getAll_downstream_base_table_names {
	my ($self) = @_;
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'get_all_tableBaseNames' } );
	$sth->execute();
	my ( $name, @return );
	$sth->bind_columns( \$name );
	while ( $sth->fetch() ) {
		push( @return, $name );
	}
	return \@return;
}

=head2 Get_OligoDB_for_ID

This function has to be implemented in all classes that want to store 
some information into a oligo2dna_register handled oligo2dnaDB.
With that function the oligo2dna_register can get the oligoDB that is connected to this ID.

=cut

sub Get_OligoDB_for_ID {
	my ( $self, $ID ) = @_;
	$self->{'error'} = '';
	my ( $table_base_name, $company ) =
	  $self->Get_table_basename_and_company_for_id($ID);
	unless ( defined $company ) {
		$self->{'error'} .= ref($self)
		  . ":Get_OligoDB_for_ID -> we got no company info for the id '$ID'\n";
		Carp::cluck( $self->{error} );
		return undef;
	}
	else {

		return $self->{'downstream_data_handler'}->{$company}
		  ->Get_OligoDB_4_table_baseString($table_base_name);
	}
}

sub Match_NucleotideArray_to_Genome {
	my ( $self, $nucleotideArray_hash, $genome_hash ) = @_;

	Carp::confess(
		ref($self)
		  . ":Match_NucleotideArray_to_Genome -> we need the identifier for the oligo array you want to match to the genome!\n"
	) unless ( defined $nucleotideArray_hash->{'identifier'} );

	my ( $table_base_name, $company ) =
	  $self->Get_table_basename_and_company_for_unique(
		$nucleotideArray_hash->{'identifier'} );
	unless ( defined $company ) {
		Carp::confess(
			ref($self)
			  . ":Match_NucleotideArray_to_Genome -> sorry, but we do not have the information for this nucleotide array: $nucleotideArray_hash->{'identifier'}\n"
		);
	}
	$nucleotideArray_hash->{'manufacturer'}     = $company;
	$nucleotideArray_hash->{'table_baseString'} = $table_base_name;

	$nucleotideArray_hash->{'id'} = $self->AddDataset($nucleotideArray_hash);
	$nucleotideArray_hash->{'describing_table_name'} = $self->TableName();

	return $self->{'downstream_data_handler'}->{$company}
	  ->Match_NucleotideArray_to_Genome( $nucleotideArray_hash, $genome_hash );
}

sub getPosition_for_oligoIDs {
	my ( $self, $arrayID, $oligoIDs, $genomeObject ) = @_;
}

sub getSequence_for_oligoIDs {
	my ( $self, $arrayID, $oligoIDs, $genomeObject ) = @_;
}

sub get_array_oligos_as_fastaDB {
	my ( $self, $identifier ) = @_;
	my ( $name, $company ) =
	  $self->Get_table_basename_and_company_for_unique($identifier);
	if ( $self->{debug} ) {
		print ref($self),
":get_array_oligos_as_fastaDB -> DEBUG we got $name, $company for \$self->Get_table_basename_and_company_for_identifier($identifier)\n";
	}
	unless ( defined $company ) {
		Carp::confess(
			    ref($self)
			  . "::get_array_oligos_as_fastaDB -> we did not get a "
			  . "\$company information for sql query\n'"
			  . $self->{'select_unique_manufacturer_table_baseString'}
			  . ";'\n" );
	}
	return $self->{'downstream_data_handler'}->{$company}
	  ->Get_OligoDB_4_table_baseString($name)->Get_as_fastaDB();
}

sub _error_if_company_is_not_supported {
	my ( $self, $company ) = @_;
	$company = lc($company);
	$self->{error} .=
	  ref($self)
	  . ":AddDataset -> the manufacturer $company is unknown\nWe know these companies: $self->{'known companies'}\n$!\n"
	  unless ( $self->{'known companies'} =~ m/$company/ );
	return $company;
}

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;

	Carp::confess(
		ref($self)
		  . ":INSERT_INTO_DOWNSTREAM_TABLES -> we have no downstream_data_handler for manufacturer $dataset->{manufacturer} \n"
	  )
	  unless (
		defined $self->{'downstream_data_handler'}
		->{ $dataset->{manufacturer} } );
	$self->{'downstream_data_handler'}->{ $dataset->{manufacturer} }
	  ->AddDataset($dataset);
	$dataset->{'table_baseString'} =
	  $self->{'downstream_data_handler'}->{ $dataset->{manufacturer} }
	  ->tableBaseName();
	return 1;
}

sub getDescription {
	my ($self) = @_;
	return "This class is a \\textit{MASTER TABLE} class. 
	Therefore, this class simply pushes the main work during the insert process to the downstream modules.
	This class chooses the downstream handler according to the 'manufacturer' hash~key.
	At the moment "
	  . scalar( ( keys %{ $self->{'data_handler'} } ) )
	  . " data_handlers are registered.
	They have the name(s): '"
	  . join( "', '", ( keys %{ $self->{'data_handler'} } ) ) . "'.
	These data~handlers are also described in this document.\n\n";
}

sub printReport {
	my ($self) = @_;
	return $self->_getLinkageInfo()
	  ->Print( $self->{'downstream_data_handler'} );
}

sub Get_table_basename_and_company_for_id {
	my ( $self, $id ) = @_;
	my $hash_ref = $self->_select_all_for_DATAFIELD( $id, 'id' );
	return undef unless ( ref( @$hash_ref[0] ) eq "HASH" );
	return @$hash_ref[0]->{'table_baseString'}, @$hash_ref[0]->{'manufacturer'};
}

sub Get_table_basename_and_company_for_unique {
	my ( $self, $identifier ) = @_;
	my $hash_ref = $self->GET_entries_for_UNIQUE(
		[ 'manufacturer', 'table_baseString' ],
		{ 'identifier' => $identifier }
	);
	$self->{last_tableBaseName} = $hash_ref->{'table_baseString'};
	print ref($self)
	  . "::Get_table_basename_and_company_for_unique -> perhaps we have an problem with the hash keys in DB2?\n"
	  . " we searched for the identifier $identifier and got a table_baseString '$hash_ref->{'table_baseString'}' and a TABLE_BASE_STRING '$hash_ref->{'table_baseString'}'\n";
	return ( $hash_ref->{'table_baseString'}, $hash_ref->{'manufacturer'} );
}

sub getID_for_identifier {
	my ( $self, $identifier ) = @_;
	my $sth =
	  $self->_get_SearchHandle( { 'search_name' => 'get_id_for_identifier' } );
	$sth->execute($identifier)
	  or warn $self->_getSearchString( 'get_id_for_identifier', $identifier );
	my ($id);
	$sth->bind_columns( \$id );
	$sth->fetch();
	return $id;
}

=head2 check_dataset

A method to check the integrity of the dataset.
This method has to be implemented in every class, that can be used downstream of the dataset table class.

here we need:

=item manufacturer: 

The name of the company that sells the array. That also defines the datasets, that are obtained from that company.
At the moment, only NimbleGene is supported. The name of the manufacturer leads to the possible tasks. 
These will be defined according to the available datasets.

=item identifier

A unique identifier that describes the actual dataset. The first 40 chars in that string are used to identify the dataset in the database.
It would be good, if that id would mean anything to the scientist, as this id is used to describe the dataset in the report tables (that have to be implemented...).

=item <the data values> possibilities are:

	- 'ndf_file' => you want to insert the oligo sequences that are stored in that file\n".
	- 'gff_file' => you want to insert a array experiment using the enrichment factors that are created by NimbleGene\n".
	- 'IP_file'  => you want to insert a array experiment using the raw reads of a NimbleGene Chip on chip experiment\n";

=cut

1;

