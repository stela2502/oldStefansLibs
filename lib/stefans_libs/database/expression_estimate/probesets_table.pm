package probesets_table;

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
use base('variable_table');
use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "probesets_table" );

	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

=head1 description

This table has to be the oligoDB table for the expr_est expression estimate tables. 
Therefore it has to store some probeset id, and for the moment the gene name.
For the time beeing I will focus on the provided array libs and do no mapping against the genome.
The problems in resolving the gene names can be handled by the gene_description table.

=cut

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'probeSet_id',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gene_symbol',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'probeSet_id', 'gene_symbol' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = []
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables


## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $dataset;
}

sub check_dataset {
	my ( $self, $dataset ) = @_;

	$self->{error} .= '';
	unless ( ref( $dataset->{'description_data'} ) eq "HASH" ) {
		$self->{error} .= ref($self)
		  . ":check_dataset -> we need the oligo information ('description_data') as hash with the structure { <Probeset_ID> => <Gene_Symbol> } \n";
	}
	$self->{error} .=
	  ref($self)
	  . ":check_dataset -> we need to know the table baseName for this dataset ('baseName')!\n"
	  unless ( defined $dataset->{'baseName'} || defined $self->{_tableName} );

	return 0 if ( $self->{error} =~ m/\w/ );
	$self->TableName( $dataset->{'baseName'} );
	return 1;

}

sub AddDataTable{
	my ( $self, $table_name, $sample_lable ) =@_;
	unless ( $self->tableExists( $table_name )){
		warn "the table $table_name does not exist -therefore I can not add that table... :-(\n";
		return undef;
	}
	if ( lc($table_name) =~ m/expr_est$/ ){
		## OK the table name seams to be of the type exp_est. therefore I have to assume that everything went well....
		unless ( defined $self->{'LINK_VAR_ID'}){
			$self->{'LINK_VAR_ID'} = {
				'name' => 'id',
				'NULL' => 0,
				'description' => 'added for search purposes',
				'data_handler' => 'expr_est'
			};
			push ( @{$self->{'table_definition'}->{'variables'}}, $self->{'LINK_VAR_ID'});
			$self->{'data_handler'}->{'expr_est'} = [];
			$self->{'sample_labels'} = [];
		}
		my $interface = expr_est->new($self->{'dbh'},$self->{'debug'});
		$interface->{'_tableName'} = $table_name;
		push ( @{$self->{'data_handler'}->{'expr_est'}}, $interface);
		push ( @{$self->{'sample_labels'}},$sample_lable);
		return $interface;
	}
	else {
		Carp::confess( ref($self)."::AddDataTable -> you wanted to add a table with the name $table_name - that is not supported!\n");
	}
	return 0;
}

sub getExpression_values_4_genes{
	my ( $self, $genes) = @_;
	return undef unless ( defined $genes);
	my $data = $self->getArray_of_Array_for_search({
 		'search_columns' => [ref($self).".gene_symbol", "expr_est.value" ],
 		'where' => [[ref($self).".gene_symbol", '=','my_value']],
	},$genes);
	unless ( scalar(@$data) > 0 ){
		warn ref($self). "::getExpression_values_4_genes -> sorry, but we got no result for the query \n$self->{'complex_search'}\n";
		return undef;
	}
	my $dataset = expression_dataset->new();
	$dataset->Add_db_result ( ['Gene Symbol',@{$self->{'sample_labels'}}], $data);
	return $dataset;
}

sub getExpression_values_4_All_genes{
	my ( $self ) = @_;

	my $data = $self->getArray_of_Array_for_search({
 		'search_columns' => [ref($self).".gene_symbol", "expr_est.value" ]
	});
	unless ( scalar(@$data) > 0 ){
		warn ref($self). "::getExpression_values_4_genes -> sorry, but we got no result for the query \n$self->{'complex_search'}\n";
		return undef;
	}
	my $dataset = expression_dataset->new();
	$dataset->Add_db_result ( ['Gene Symbol',@{$self->{'sample_labels'}}], $data);
	return $dataset;
}

sub removeAllDatasets {
	my ( $self) = @_;
	if ( defined $self->{'LINK_VAR_ID'}){
		shift (  @{$self->{'table_definition'}->{'variables'}} );
	}
	$self->{'LINK_VAR_ID'} = undef;
	$self->{'data_handler'}->{'expr_est'} = undef;
	return 1;
}

sub Get_AffyID_2_dbID_hash{
	my ( $self) = @_;
	my $rv = $self->getArray_of_Array_for_search({
 		'search_columns' => [ref($self).".id",ref($self).".probeSet_id" ],
 		'order_by' => [ref($self).".id"]
 	});
 	
 	my @return;
 	foreach my $data ( @$rv ){
 		push ( @return, { 'probe_id'=> @$data[1], 'id' => @$data[1]} );
 	}
 	return \@return;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	Carp::confess( $self->{error} ) unless ( $self->check_dataset($dataset) );

	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create( $dataset->{'oligoDB'}->TableName() );
	}
	else {
		my $rv = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ ref($self) . ".id" ],
				'where' => [],
				'order_by'       => [ ref($self) . ".id" ],
				'limit'          => "limit 1"
			}
		);
		if ( defined @$rv[0]){
			print "the dataset "
			  . $self->TableName()
			  . " is already in the database! \n-> we will not import this dataset - done\n";
			return $self->TableName();
		}
	}
	$self->_create_insert_statement();
	return $dataset->{id} if ( defined $dataset->{'id'} );
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	foreach my $probe_id ( sort keys %{$dataset->{'description_data'}}){
		unless ($sth->execute($probe_id, $dataset->{'description_data'}->{$probe_id} )){
			Carp::confess( ref($self)."::AddDataset -> we have an error while inserting data:".$self->{'dbh'}->errstr()."\n".$self->_getSearchString(
				'insert', $probe_id, $dataset->{'description_data'}->{$probe_id} ) );
		}
	}
	return $self->TableName();
}


package expression_dataset;

use strict;
use warnings;

sub new{
	my ( $class ) = @_;

	my ($self);

	$self = {
	};

	bless $self, $class if ( $class eq "expression_dataset" );

	return $self;

}

sub Add_db_result{
	my ( $self, $header, $db_result) = @_;
	$self->{'header'} = $header;
	$self->{'data'} = $db_result;
	$self->{'genes_to_id'} = {};
	$self->{'id_2_gene'} = {};
	for( my $i = 0; $i < @$db_result;$i++){
		$self->{'genes_to_id'}->{ @{@$db_result[$i]}[0] } = $i;
		$self->{'id_2_gene'}->{$i} = @{@$db_result[$i]}[0];
	}
	return 1;
}

sub get_expression_4_gene {
	my ( $self, $gene) = @_;
	return undef unless ( defined $gene);
	return undef unless ( defined $self->{'genes_to_id'}->{ $gene } );
	my ( $gene_name, @values ) = @{@{$self->{'data'}}[$self->{'genes_to_id'}->{ $gene }]};
	return \@values;
}

sub get_expression_4_id {
	my ( $self, $id) = @_;
	return undef unless ( $id >= 0 );
	return undef unless ( $id < $self->max_id() );
	
	my ( $gene_name, @values ) = @{@{$self->{'data'}}[$id]};
	return \@values;
}

sub Gene_Symbol_4_id{
	my ( $self, $id) = @_;
	return $self->{'id_2_gene'}->{$id};
}

sub max_id {
	my ( $self) = @_;
	unless ( defined $self->{'max'}){
		$self->{'max'} = scalar( @{$self->{'data'}});
	}
	return $self->{'max'};
}

1;
