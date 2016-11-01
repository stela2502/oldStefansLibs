package stefans_libs_database_Protein_Expression_gene_ids;

#  Copyright (C) 2010 Stefan Lang

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
use base variable_table;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_database_Protein_Expression_gene_ids" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "ENSEMBL_2_GeneSymbol";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'ENSEMBL_ID',
			'type'        => 'VARCHAR (16)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'GeneSymbol',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => '',
		}
	);

	push( @{ $hash->{'INDICES'} }, ['GeneSymbol'] );
	push( @{ $hash->{'INDICES'} }, ['ENSEMBL_ID'] );
	push( @{ $hash->{'UNIQUES'} }, ['ENSEMBL_ID','GeneSymbol'] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['ENSEMBL_ID', 'GeneSymbol'];

	$self->{'table_definition'} = $hash;

	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.
	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub get_ENSEML_2_GeneSymbol_table {
	my ( $self, $ensmbl_ids ) = @_;
	my $dbResult;
	unless ( ref($ensmbl_ids) eq "ARRAY" ) {
		$dbResult = $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . ".id",
					ref($self) . ".GeneSymbol",
					ref($self) . ".ENSEMBL_ID"
				]
			}
		);
	}
	else {
		$dbResult = $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . ".id",
					ref($self) . ".GeneSymbol",
					ref($self) . ".ENSEMBL_ID"
				],
				'where' => [[ref($self) . ".ENSEMBL_ID",'=', 'my_value']]
			}, $ensmbl_ids
		);
	}
	my ( $old, $new );
	foreach ( @{ $dbResult->{'header'} } ) {
		$old = $new = $_;
		if ( $new =~ s/stefans_libs_database_Protein_Expression_gene_ids\.// ) {
			$dbResult->Rename_Column( $old, $new );
		}

	}
	return $dbResult;
}



sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
