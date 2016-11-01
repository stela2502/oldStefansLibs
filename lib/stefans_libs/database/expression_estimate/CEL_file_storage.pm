package CEL_file_storage;

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

The cell file storage does only store the CEL file in a save position. It does NOT check the CEL file. THe scientist is responsible for adding only useful cel files.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class CEL_file_storage.

=cut

use stefans_libs::database::sampleTable;
use stefans_libs::database::external_files;
#use stefans_libs::database::expression_estimate::Affy_description;
use stefans_libs::database::Affymetrix_expression_lib;

use base ('variable_table');

sub new {

	my ( $class, $database, $debug ) = @_;

	unless ( defined $database ) {
		$database = "genomeDB";
	}

	my ($self);

	$self = {
		'dbh'           => root::getDBH( 'root', $database ),
		'database_name' => $database,
		'debug'         => $debug
	};

	bless $self, $class if ( $class eq "CEL_file_storage" );

	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'database_name';
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	## I need to check if I have at least one Library definition file to handle these CEL files!
	my $Affy_description = $self->{'data_handler'}->{'Affymetrix_expression_lib'};
	my $temp = $Affy_description->getArray_of_Array_for_search(
		{
			'search_columns' => [ 'affy_exp_lib' . '.id' ],
			'where' => [ [ 'affy_exp_lib.name', '=', 'my_value' ] ]
		},
		$dataset->{'array_name'}
	);

	$self->{'error'} .=
	  ref($self)
	  . "::DO_ADDITIONAL_DATASET_CHECKS - we have no library information for the affymetrix array $dataset->{'array_type'}\n"
	  unless ( ref( @$temp[0] ) eq "ARRAY" );
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "cel_files";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'cel_file_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the id of the stored file',
			'data_handler' => 'external_files',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'sample_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the sample information',
			'data_handler' => 'sampleTable'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'array_name',
			'type' => 'VARCHAR (100)',
			'NULL' => '0',
			'description' =>
			  'Which array',
			'data_handler' => 'Affymetrix_expression_lib',
			'link_to' => 'name'
		}
	);
	push( @{ $hash->{'INDICES'} }, ['sample_id'] );
	push( @{ $hash->{'INDICES'} }, ['array_name'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['sample_id','array_name']
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
	$self->{'data_handler'}->{'sampleTable'} =
	  sampleTable->new( '', $self->{'debug'} );
	$self->{'data_handler'}->{'external_files'} =
	  external_files->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'Affymetrix_expression_lib'} = Affymetrix_expression_lib->new( $self->{'dbh'} , $self->{'debug'});
	return $dataset;
}

1;
