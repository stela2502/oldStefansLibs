package stefans_libs_database_DeepSeq_genes;

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

use stefans_libs::database::lists::list_using_table;
use base 'list_using_table';

use stefans_libs::database::DeepSeq::genes::gene_names_list;

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

	bless $self, $class if ( $class eq "stefans_libs_database_DeepSeq_genes" );
	$self->init_tableStructure();
	$self->{'linked_list'} = $self->{'data_handler'}
	  ->{'stefans_libs_database_DeepSeq_genes_gene_names_list'};
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "GENE_NAMES";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gene_list_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'data_handler' =>
			  'stefans_libs_database_DeepSeq_genes_gene_names_list',
			'link_to' => 'list_id',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['gene_list_id'] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['gene_list_id'];

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
	  ->{'stefans_libs_database_DeepSeq_genes_gene_names_list'} =
	  stefans_libs_database_DeepSeq_genes_gene_names_list->new( $self->{'dbh'},
		$self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

=head2 get_gene_id_4_gene_name( 'gene_name')

Return the gene ID

=cut

sub get_gene_id_4_gene_name{
	my ( $self, $gene_name ) = @_;
	Carp::confess ( "Sorry without gene name I can not give you a gene_id!\n")unless ( defined $gene_name);
	my $return = $self->get_data_table_4_search ({
 	'search_columns' => [ref($self).".id"],
 	'where' => [['name', '=','my_value']] },$gene_name )->get_line_asHash(0);
 	return undef unless ( ref($return) eq "HASH");
 	return $return -> {ref($self).".id" };
}

=head2 DO_ADDITIONAL_DATASET_CHECKS

This is a very critical function, as we will handle the lists here.
We check redefine the database interface look, transparently using the list.

=cut

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	## we need to ckeck the columns 'name', 'organism', 'type'
	foreach ( 'name', 'organism' ) {
		$self->{'error'} .=
		  "Sorry, but I need a '$_' to be able to add a gene\n"
		  unless ( defined $dataset->{$_} );
	}
	if ( defined $dataset->{'name'} && defined $dataset->{'organism'} ) {
		## now we can ckeck if we already have the info about that gene
		if (
			ref(
				my $data = $self->get_data_table_4_search(
					{
						'search_columns' => [ ref($self) . '.id' ],
						'where'          => [
							[ 'GENE_IDs.name', '=', 'my_value' ],
							[ 'organism_tag',    '=', 'my_value' ]
						]
					},
					$dataset->{'name'},
					$dataset->{'organism'}
				  )->get_line_asHash(0)
			) eq "HASH"
		  )
		{
			$dataset->{'id'} = $data->{ ref($self) . '.id' };
			return 1;
		}
		elsif ( defined $dataset->{'type'} ) {
			## obviously you wanted to really add that value!
			my $data_handler =
			  $self->{'data_handler'}
			  ->{'stefans_libs_database_DeepSeq_genes_gene_names_list'};
			unless ( defined $dataset->{'gene_list_id'} ) {
				$dataset->{'gene_list_id'} = $data_handler->readLatestID() + 1;
			}
			my $others_id = $self->{'linked_list'}
	  ->add_to_list(
				$dataset->{'gene_list_id'},
				{
					'organism' => { 'organism_tag' => $dataset->{'organism'} },
					'name' => $dataset->{'name'},
					'type' => $dataset->{'type'}
				}
			);
			return 1;
		}
		else {
			$self->{'error'} .= "Sorry, but we do not know the gene name $dataset->{'name'} and you have not given me and 'type'\n";
		}
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

1;
