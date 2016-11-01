package affy_SNP_info;

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
use stefans_libs::database::array_dataset::genotype_calls;
use base ('variable_table');

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "affy_SNP_info" );

	$self->init_tableStructure();

	return $self;
}

sub expected_dbh_type {
	return 'dbh';
}

my $sql = " CREATE TABLE affy_SNP_info_var ( 
   id INTEGER UNSIGNED auto_increment,
   rsID VARCHAR(20) NOT NULL,
   major_nucleotide char(1) NOT NULL,
   minor_nulceotide char(1) NOT NULL,
   CEPH_ma FLOAT NOT NULL,
   Han_Chinese_ma FLOAT NOT NULL,
   Japanese_ma float NOT NULL,
   Yoruba_ma float NOT NULL,
   UNIQUE ( rsID )
   );
   ";

=head2 get_downstreamTable

This function can be used to get a downstream table object.
Here it will be a 'genotype_calls' object.
In addition to that this function can be used to 'stuff' 
data tables into this 'affy_SNP_info' object to execute queries including 
this downstream dataset.

=cut

sub get_downstreamTable {
	my ( $self, $hash ) = @_;

	my ( $tableName, $tableBaseName );

	unless ( ref( $self->{'data_handler'}->{'genotype_calls'} ) eq "ARRAY" ) {
		push(
			@{ $self->{'table_definition'}->{'variables'} },
			{
				'name'         => 'id',
				'data_handler' => 'genotype_calls',
				'type'         => 'INTEGER',
				'description'  => "this is an artefact of process $$",
				'NULL'         => 0
			}
		);
		$self->{'data_handler'}->{'genotype_calls'} = [];
	}

	my $genotype_calls;
	foreach $genotype_calls ( @{ $self->{'data_handler'}->{'genotype_calls'} } )
	{
		return $genotype_calls
		  if ( $genotype_calls->{'_tableName'} eq $hash->{'tableBaseName'}
			|| $genotype_calls->TableName() eq $hash->{'tableName'} )
		  ;
	}

	$genotype_calls = genotype_calls->new( $self->{'dbh'}, $self->{'debug'} );
	if ( defined $hash->{'tableBaseName'}){
		$genotype_calls->TableName($hash->{'tableBaseName'});
	}
	elsif( defined $hash->{'tableName'} ){
		$genotype_calls->{'_tableName'}         = $tableName;
	}
	$genotype_calls->{'FOREIGN_TABLE_NAME'} = $self->TableName();
	push( @{ $self->{'data_handler'}->{'genotype_calls'} }, $genotype_calls );
	
	return $genotype_calls;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "affy_SNP_info_var";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'Affy_id',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the Affymetrix probeset id for this rsID',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'rsID',
			'type' => 'VARCHAR (20)',
			'NULL' => '0',
			'description' =>
'the SNP_db rs id -> this column can be made to link to a SNP_table instance',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'major_nucleotide',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'the major nucleotide',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'minor_nulceotide',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'the minor nucleotide',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'CEPH_ma',
			'type' => 'FLOAT',
			'NULL' => '0',
			'description' =>
			  'the major allele frequency for the CEPH population',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'Han_Chinese_ma',
			'type' => 'FLOAT',
			'NULL' => '0',
			'description' =>
			  'the major allele frequency for the Han Chinese population',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'Japanese_ma',
			'type' => 'FLOAT',
			'NULL' => '0',
			'description' =>
			  'the major allele frequency for the Japanese population',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'Yoruba_ma',
			'type' => 'FLOAT',
			'NULL' => '0',
			'description' =>
			  'the major allele frequency for the Yoruba population',
			'needed' => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['rsID'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = []
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

sub initDataUpload {
	my ($self) = @_;
	unless ( ref( $self->{'affyID_2_rsID'} ) eq "ARRAY" ) {
		$self->{'affyID_2_rsID'} = $self->getArray_of_Array_for_search(
			{ 'search_columns' => [ ref($self) . ".Affy_id" ] } );
	}
	$self->{'counter'} = 0;
	return 1;
}

sub getNextAffyID {
	my ($self) = @_;
	Carp::confess(
		ref($self)
		  . "::getNextAffyID -> you have to initialize the DataUpload (initDataUpload) to get this info!"
	) unless ( ref( $self->{'affyID_2_rsID'} ) eq "ARRAY" );
	return @{ @{ $self->{'affyID_2_rsID'} }[ $self->{'counter'}++ ] }[0];
}

1;
