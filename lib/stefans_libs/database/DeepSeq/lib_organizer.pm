package stefans_libs_database_DeepSeq_lib_organizer;


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

use stefans_libs::database::DeepSeq::lib_organizer::splice_isoforms;

use strict;
use warnings;


sub new {

    my ( $class, $dbh, $debug ) = @_;
    
    Carp::confess ( "we need the dbh at $class new \n" ) unless ( ref($dbh) eq "DBI::db" );

    my ($self);

    $self = {
        debug => $debug,
        dbh   => $dbh
    };

    bless $self, $class if ( $class eq "stefans_libs_database_DeepSeq_lib_organizer" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "DS_genomes";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'version',
               'type'         => 'VARCHAR (20)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'organism_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'data_handler' >= 'organismDB',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'creationDate',
               'type'         => 'DATE',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'table_baseString',
               'type'         => 'VARCHAR (40)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'table_baseString' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'table_baseString' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     $self->{'data_handler'}->{'organismDB'} =
	  organismDB->new( $self->{dbh}, $self->{debug} );
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	$self->{'error'} .= ref($self) . "::DO_ADDITIONAL_DATASET_CHECKS we need the UCSC 'ensGene.txt' file to add this genome information\n"
	  unless ( -f $dataset->{'ensGene'});
	$dataset->{'table_baseString'} = int("DS_genome_".rand(1000));
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	my $splice_isoforms = stefans_libs_database_DeepSeq_lib_organizer_splice_isoforms->new($self->{'dbh'} );
	$splice_isoforms -> TableName( $dataset->{'table_baseString'});
	$splice_isoforms -> AddReferenceDataset ( $dataset->{'ensGene'} );
	return 1;
}

sub getGenomeHandle_for_dataset{
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';
	my ( $tableBaseName, $genomeID ) = $self->select_tableBasename_and_genomeID( $dataset);
	my $interface = stefans_libs_database_DeepSeq_lib_organizer_splice_isoforms->new( $self->{dbh}, $self->{debug} );
	if ( $interface->TableName($tableBaseName) ){
		$interface->{'genomeID'} = $genomeID;
		$interface->Database($self->Database );
		return $interface;
	}
	else { warn root::get_hashEntries_as_string( $dataset, 4, "We got no genome interface for this dataset:"); }
	return undef;
}

sub select_tableBasename_and_genomeID {
	my ( $self, $dataset ) = @_;
	my $data;
	if ( defined $dataset->{'id'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ref($self).'.table_baseString', ref($self).'.id'],
				'where'          => [ [ ref($self).'.id', '=', 'my value' ] ]
			},
			$dataset->{'id'}
		);
	}
	elsif ( defined $dataset->{'version'} && defined $dataset->{'organism_tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ref($self).'.table_baseString', ref($self).'.id'],
				'where'          => [ 
					[ ref($self).'.version', '=', 'my value' ],
					[ 'organism_tag', '=', 'my value' ],
				 ]
			},
			$dataset->{'organism_tag'},
			$dataset->{'version'}
		);
	}
	elsif ( defined $dataset->{'organism_tag'} ) {
		$data = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ref($self).'.table_baseString', ref($self).'.id'],
				'where'          => [ 
					[ 'organism_tag', '=', 'my value' ],
				 ],
				 'order_by' => [ ref($self).'.version' ]
			},
			$dataset->{'organism_tag'},
		);
	}
	else {
		Carp::confess ( ref($self).":select_tableBasename_and_genomeID -> sorry, but we can't help you with that serach dataset:\n".root::get_hashEntries_as_string($dataset, 3, "the search dataset:" ) );
	}
	#print "we executed this search $self->{complex_search}\n";
	if ( ref( @$data[0] ) eq "ARRAY" ) {
		return  @{@$data[0]};
	}
	return undef, undef;
}

sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
