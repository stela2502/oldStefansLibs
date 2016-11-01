package stefans_libs_database_DeepSeq_lib_organizer_splice_isoforms;

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

use stefans_libs::database::DeepSeq::genes;
use stefans_libs::database::DeepSeq::lib_organizer::exon_list;
use stefans_libs::file_readers::UCSC_ens_Gene;

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
	  if ( $class eq
		"stefans_libs_database_DeepSeq_lib_organizer_splice_isoforms" );
	$self->init_tableStructure();
	$self->{'linked_list'} =
	  $self->{'data_handler'}
	  ->{'stefans_libs_database_DeepSeq_lib_organizer_exon_list'};
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	#$hash->{'table_name'} = "UNKNOWN";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the ENSMBL transcript name',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chr',
			'type'        => 'VARCHAR (4)',
			'NULL'        => '0',
			'description' => 'the chromosome',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'transcription start',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'end',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'transcription end',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'orientation',
			'type'        => 'VARCHAR (1)',
			'NULL'        => '0',
			'description' => 'the orientation (+ or -)',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'exon_list_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the exon list table',
			'data_handler' =>
			  'stefans_libs_database_DeepSeq_lib_organizer_exon_list',
			'link_to' => 'list_id',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'gene_id', 'exon_list_id' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = [ 'gene_id', 'exon_list_id' ];

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
	$self->{'data_handler'}->{'stefans_libs_database_DeepSeq_genes'} =
	  stefans_libs_database_DeepSeq_genes->new( $self->{'dbh'},
		$self->{'debug'} );
	$self->{'data_handler'}
	  ->{'stefans_libs_database_DeepSeq_lib_organizer_exon_list'} =
	  stefans_libs_database_DeepSeq_lib_organizer_exon_list->new(
		$self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

=head2 AddReferenceDataset({
	'ensGene' => the ensGene.txt file from http://hgdownload.cse.ucsc.edu/goldenPath/XXYY/database/
	'version' => the XXYY part of the path
	'organism_tag' => should most of the time be 'H_Sapiens'
})

This function will read the definition file and create the table structure.

=cut

sub AddReferenceDataset {
	my ( $self, $filename ) = @_;
	my $file_reader = stefans_libs_file_readers_UCSC_ens_Gene->new();
	$file_reader -> read_file ( $filename );
	my $hash;
	## OK now we need to do something about the data in the file!!
	for ( my $i = 0; $i < @{$file_reader->{'data'}}; $i++ ){
		$hash = $file_reader->get_line_asHash($i);
		#TODO add gene names where necessary, create the exons, add the splice isoform
		
	}
	
}

sub expected_dbh_type {
	return 'dbh';
}

1;
