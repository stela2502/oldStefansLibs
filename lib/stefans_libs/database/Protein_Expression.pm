package stefans_libs_database_Protein_Expression;

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

use stefans_libs::database::tissueTable;
use stefans_libs::database::Protein_Expression::gene_ids;

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
	  if ( $class eq "stefans_libs_database_Protein_Expression" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "Qantitative_Protein_Expresssion";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gene_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'data_handler' =>
			  'stefans_libs_database_Protein_Expression_gene_ids',
			'link_to' => 'id',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'tissue_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'tissueTable',
			'link_to'      => 'id',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'exp_level',
			'type'        => 'INTEGER',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'expression_type',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'reliability',
			'type'        => 'VARCHAR ( 20 )',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push( @{ $hash->{'INDICES'} }, ['gene_id'] );
	push( @{ $hash->{'INDICES'} }, ['tissue_id'] );
	push( @{ $hash->{'INDICES'} }, ['exp_level'] );
	push( @{ $hash->{'UNIQUES'} }, [ 'gene_id', 'tissue_id' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = [ 'gene_id', 'tissue_id' ];

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
	$self->{'data_handler'}
	  ->{'stefans_libs_database_Protein_Expression_gene_ids'} =
	  stefans_libs_database_Protein_Expression_gene_ids->new( $self->{'dbh'},
		$self->{'debug'} );
	$self->{'data_handler'}->{'tissueTable'} =
	  tissueTable->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub Add_Human_Protein_Atlas_Data {
	my ( $self, $data_table ) = @_;
	## OK - I will reformat everything
	Carp::confess("Sorry, but I need a data_table object here!\n")
	  unless ( ref($data_table) eq "data_table" );
	my ($error);
	$error = '';
	foreach (
		split(
			";;",
			"Ensembl_ID;;Tissue;;Cell type;;Level;;Expression type;;Reliability"
		)
	  )
	{
		$error .= "I miss the column $_ in the data table\n"
		  unless ( defined $data_table->Header_Position($_) );
	}
	Carp::confess("The data table does not have the right format:\n$error")
	  if ( $error =~ m/\w/ );
	## We need to ckeck all tissues and we need an extration protocol for that - unfortunately.
	$self->_create_tissues($data_table);
	## OK - now we should have the 'tissue_id' column
	Carp::confess(
"we have an error converting the Ensembl_ID to a gene_id - please check the 'ENSMBL_2_GeneSymbol' db table managed by the 'stefans_libs_database_Protein_Expression_gene_ids' class!\n"
		  . $self->{'error'} )
	  unless ( $self->_prepare_Gene_Symbols($data_table) );
	
	$data_table->Rename_Column( 'Level',           'exp_level' );
	$data_table->Rename_Column( 'Expression type', 'expression_type' );
	$data_table->Rename_Column( 'Reliability',     'reliability' );
	my $hash = {
		'Moderate' => 2,
		'Weak'     => 1,
		'Strong'   => 3,
		'Low'      => 1,
		'Medium'   => 2,
		'High'     => 3,
		'None'     => 0,
		'Negative' => 0
	};
	$data_table->calculate_on_columns(
		{
			'function'      => sub { return $hash->{ $_[0] } },
			'data_column'   => 'exp_level',
			'target_column' => 'exp_level'
		}
	);
	$data_table->define_subset(
		'DB_ADD',
		[
			'gene_id',   'tissue_id',
			'exp_level', 'expression_type',
			'reliability'
		]
	);
	return $self->BatchAddTable( $data_table->get_as_table_object('DB_ADD') );
}

=head2 expression_difference_between_2_cell_types ({
	'cell_1' => a celltype
	'cell_2' => an other celltype
	'genes' => [ gene names]
})

=cut

sub expression_difference_between_2_cell_types_4_genes {
	my ( $self, $hash ) = @_;

	my $dbResult = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'GeneSymbol', 'tissue.name', 'exp_level' ],
			'where'          => [
				[ 'tissue.name', '=', 'my_value' ],
				[ 'GeneSymbol',  '=', 'my_value' ]
			]
		},
		[ $hash->{'cell_1'}, $hash->{'cell_2'} ], $hash->{'genes'}
	);
	
	my ($data, $line);
	#print $dbResult ->AsString();
	for ( my $i = 0; $i < @{$dbResult->{'data'}}; $i ++ ){
		$line = $dbResult -> get_line_asHash($i);
		$data -> {$line->{'GeneSymbol'} } = {'A' => -1, 'B' => -1 } unless ( defined $data -> {$line->{'GeneSymbol'} });
		$data -> {$line->{'GeneSymbol'} } -> {'A'} = $line -> {'exp_level'} if ( $line -> {'tissue.name'} eq $hash->{'cell_1'});
		$data -> {$line->{'GeneSymbol'} } -> {'B'} = $line -> {'exp_level'} if ( $line -> {'tissue.name'} eq $hash->{'cell_2'});
	}
	
	my $result = data_table->new();
	$result -> Add_header_Array ( ['Gene Symbol','difference A vs B', 'numeric'] );
	$result -> Add_2_Description (" A=$hash->{'cell_1'}; B= $hash->{'cell_2'}");
	
	foreach ( sort keys %$data ){
		$line = { 'Gene Symbol' => $_, 'difference A vs B' => 'n.d.', 'numeric' => 'n.d.'} ;
		if ( $data ->{$_} ->{'A'} > $data ->{$_}->{'B'}) {
			$line -> {'difference A vs B'} = '>';
			$line -> {'numeric'} = +1;
		}
		elsif ( $data->{$_} ->{'A'} < $data->{$_} ->{'B'}) {
			$line -> {'difference A vs B'} = '<';
			$line -> {'numeric'} = -1;
		}
		elsif ( $data->{$_} ->{'A'} == $data->{$_} ->{'B'}) {
			$line -> {'difference A vs B'} = '=';
			$line -> {'numeric'} = 0;
		}
		$result -> AddDataset ( $line );
	}
	return $result;
}

sub expression_difference_between_2_cell_types {
	my ( $self, $hash ) = @_;
	my $dbResult = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'GeneSymbol', 'ENSEMBL_ID', 'tissue.name', 'exp_level' ],
			'where'          => [
				[ 'tissue.name', '=', 'my_value' ]
			]
		},
		[ $hash->{'cell_1'}, $hash->{'cell_2'} ]
	);
	
	my ($data, $line);
	#print $dbResult ->AsString();
	for ( my $i = 0; $i < @{$dbResult->{'data'}}; $i ++ ){
		$line = $dbResult -> get_line_asHash($i);
		$data -> {$line->{'GeneSymbol'} } = {'A' => -1, 'B' => -1, 'ENSEMBL_ID' =>  $line->{'ENSEMBL_ID'}} unless ( defined $data -> {$line->{'GeneSymbol'} });
		$data -> {$line->{'GeneSymbol'} } -> {'A'} = $line -> {'exp_level'} if ( $line -> {'tissue.name'} eq $hash->{'cell_1'});
		$data -> {$line->{'GeneSymbol'} } -> {'B'} = $line -> {'exp_level'} if ( $line -> {'tissue.name'} eq $hash->{'cell_2'});
	}
	
	my $result = data_table->new();
	$result -> Add_header_Array ( ['Gene Symbol','ENSEMBL_ID', 'difference A vs B', 'numeric'] );
	$result -> Add_2_Description (" A=$hash->{'cell_1'}; B= $hash->{'cell_2'}");
	
	foreach ( sort keys %$data ){
		$line = { 'ENSEMBL_ID' => $data ->{$_} ->{'ENSEMBL_ID'}, 'Gene Symbol' => $_, 'difference A vs B' => 'n.d.', 'numeric' => 'n.d.'} ;
		if ( $data ->{$_} ->{'A'} > $data ->{$_}->{'B'}) {
			$line -> {'difference A vs B'} = '>';
			$line -> {'numeric'} = +1;
		}
		elsif ( $data->{$_} ->{'A'} < $data->{$_} ->{'B'}) {
			$line -> {'difference A vs B'} = '<';
			$line -> {'numeric'} = -1;
		}
		elsif ( $data->{$_} ->{'A'} == $data->{$_} ->{'B'}) {
			$line -> {'difference A vs B'} = '=';
			$line -> {'numeric'} = 0;
		}
		$result -> AddDataset ( $line );
	}
	return $result;
}

sub process_ENSEMBLE_ID_2_GeneSymbols {
	my ( $self, $data_table ) = @_;
	Carp::confess("Sorry, but I need a data_table object here!\n")
	  unless ( ref($data_table) eq "data_table" );
	my ($error);
	$error = '';
	foreach ( split( ";;", "ENSEMBL_ID;;GeneSymbol" ) ) {
		$error .= "I miss the column $_ in the data table\n"
		  unless ( defined $data_table->Header_Position($_) );
	}
	Carp::confess("The data table does not have the right format:\n$error")
	  if ( $error =~ m/\w/ );
	my ( $dbResult, $new_data, $value );
	$dbResult =
	  $self->{'data_handler'}
	  ->{'stefans_libs_database_Protein_Expression_gene_ids'}
	  ->get_ENSEML_2_GeneSymbol_table();
	$dbResult->createIndex('ENSEMBL_ID');
	for ( my $i = 0 ; $i < @{ $data_table->{'data'} } ; $i++ ) {
		$new_data = $data_table->get_line_asHash($i);
		($value) =
		  $dbResult->get_value_for( 'ENSEMBL_ID', $new_data->{'ENSEMBL_ID'},
			'GeneSymbol' );

		unless ( defined $value ) {
			$self->{'data_handler'}
			  ->{'stefans_libs_database_Protein_Expression_gene_ids'}
			  ->AddDataset($new_data);
		}
		elsif ( !( $value eq $new_data->{'GeneSymbol'} ) ) {

		  #			warn
		  #			  "we update value for ENSEMBL_ID '$new_data->{'ENSEMBL_ID'}'!\n";
			$value = (
				$dbResult->get_value_for(
					'ENSEMBL_ID', $new_data->{'ENSEMBL_ID'}, 'id'
				)
			);

			#			warn root::get_hashEntries_as_string(
			#				{ 'GeneSymbol' => $new_data->{'GeneSymbol'}, 'id' => $value },
			#				3, "we try to update the database using this hash:" );
			$self->{'data_handler'}
			  ->{'stefans_libs_database_Protein_Expression_gene_ids'}
			  ->UpdateDataset(
				{ 'GeneSymbol' => $new_data->{'GeneSymbol'}, 'id' => $value } );
		}
		else {
#			warn "I thought we would almost never come to that stage!!\nthat: "
#			  . $value
#			  . " eq $new_data->{'GeneSymbol'}\n";
		}
	}
	return 1;
}

sub _prepare_Gene_Symbols {
	my ( $self, $data_table ) = @_;
	$data_table->createIndex('Ensembl_ID');
	my ( $hash, $dbResult );
	$dbResult =
	  $self->{'data_handler'}
	  ->{'stefans_libs_database_Protein_Expression_gene_ids'}
	  ->get_ENSEML_2_GeneSymbol_table(
		[ $data_table->getIndex_Keys('Ensembl_ID') ] );
	$hash = $dbResult->getAsHash( 'ENSEMBL_ID', 'id' );
	$self->{'error'} = $self->{'warning'} = '';
	foreach ( $data_table->getIndex_Keys('Ensembl_ID') ) {
		unless ( defined $hash->{$_} ) {
			$self->{'warning'} .= "We do not know the gene name for ENSEMBL_ID '$_'\n";
			$hash->{$_} = $_;
		}
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	$data_table->calculate_on_columns(
		{
			'function'      => sub { return $hash->{ $_[0] } },
			'data_column'   => 'Ensembl_ID',
			'target_column' => 'gene_id'
		}
	);
	return 1;
}

sub _create_tissues {
	my ( $self, $data_table ) = @_;
	## the data table has already been checked.
	## we merge 'Tissue' and 'Cell type' to get an unique tissue name
	## and then we add a new tissue_id option
	my $extraction_potocol = {
		'name' => 'Human_Protein_Atlas_tissue',
		'description' =>
'The human Protein Atlas use histological tissue section, so most probably the tissues are defined on an histological basis.',
		'version' => 1
	};
	my $organism = {
		'organism_tag'  => 'H_sapiens',
		'organism_name' => 'Homo sapiens'
	};
	my ( $hash, $line );
	for ( my $i = 0 ; $i < @{ $data_table->{'data'} } ; $i++ ) {
		$line = $data_table->get_line_asHash($i);
		next if ( defined $hash->{"$line->{'Tissue'} - $line->{'Cell type'}"} );
		$hash->{"$line->{'Tissue'} - $line->{'Cell type'}"} =
		  $self->{'data_handler'}->{'tissueTable'}->AddDataset(
			{
				'organism' => $organism,
				'name'     => "$line->{'Tissue'} - $line->{'Cell type'}",
				'extraction_protocol' => $extraction_potocol
			}
		  );
	}
	## OK - now we know the id for each tissue - and most probably have created a lot of tissues that way ;-)
	$data_table->define_subset( 'tissue name', [ 'Tissue', 'Cell type' ] );
	$data_table->calculate_on_columns(
		{
			'function'      => sub { return $hash->{"$_[0] - $_[1]"} },
			'data_column'   => 'tissue name',
			'target_column' => 'tissue_id'
		}
	);
	return 1;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
