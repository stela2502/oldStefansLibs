package materialsTable;

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
use stefans_libs::root;
use stefans_libs::database::storage_table;

use stefans_libs::database::variable_table;

use base "variable_table";

=for comment
 
 This document is in Pod format.  To read this, use a Pod formatter,
 like "perldoc perlpod".
 
=head1 NAME
 
stefans_libs::database::antibodyTable
 
=head1 DESCRIPTION
 
 This class is a MySQL wrapper that is used to access the table antibody where all antibody informations are stored.
 
=head2 Depends on
 
=head2 Provides
 
 
 L<CreateDB|"CreateDB">
 
 L<DataExists|"DataExists">
 
 L<insertData|"insertData">
 
 L<GetAllAntibodyInfosByID|"GetAllAntibodyInfosByID">
 
 L<SelectSpecificity_ByID|"SelectSpecificity_ByID">
 
 L<SelectId_BySpecificity|"SelectId_BySpecificity">
 
=head1 METHODS
 
=head2 new
 
=head3 atributes
 
 none
 
=head3 retrun values
 
 A object of the class antibodyDB
 
=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;
	
	die "$class : new -> we need a acitve database handle at startup!, not ".ref($dbh)
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug         => $debug,
		dbh           => $dbh,
		usedData      => {},
		usedData_byID => {}
	};

	bless( $self, $class ) if ( $class eq "materialsTable" );
	
	$self->init_tableStructure();
	
	#warn root::get_hashEntries_as_string ($self, 4, "We have initialized an materialTable - equals the table_definition -> table_name 'materials'?");
	#warn ref($self)."::TableName = ". $self->TableName()." (self = $self)\n";
	return $self;
}

sub expected_dbh_type {
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "materials";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'company',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the company you bought the product from',
			'needed'      => ''
		}
	);
	push (
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the common name for this compound',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'OrderNumber',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the order number to for this product',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'LotNumber',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'the lot number to for this product sample',
			'needed'      => ''
		}
	);
	push (
		@{ $hash->{'variables'} },
		{
			'name'        => 'type',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the type of the compound (e.g. antibody, chemical, ...)',
			'needed'      => ''
		}
	);
	push (
		@{ $hash->{'variables'} },
		{
			'name'        => 'orderDate',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => 'the date you ordered/recieved this compound',
			'needed'      => ''
		}
	);
	push (
		@{ $hash->{'variables'} },
		{
			'name'        => 'storage_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the id of the storage of this compound',
			'data_handler' => 'storage_table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '1',
			'description' => 'some further description',
			'needed'      => ''
		}
	);
	$self->{'table_definition'} = $hash;
	push ( @{$hash->{'UNIQUES'}}, [ 'name','OrderNumber','LotNumber' ] );
	$self->{'UNIQUE_KEY'} = ['name','OrderNumber','LotNumber']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables
	$self->{'data_handler'}->{'storage_table'} = storage_table->new( $self->{'dbh'}, $self->{'debug'});
##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	$dataset->{'LotNumber'} = -1 unless ( defined $dataset->{'LotNumber'});
	return 1 ;
}

1;
