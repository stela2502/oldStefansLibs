package expression_net_data;

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
use base "variable_table";

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "expression_net_data" );
	$self->init_tableStructure();
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
	$hash->{'table_name'} = "expression_net";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gene_name_1',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'gene_name_2',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'p_value',
			'type'        => 'FLOAT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'r_square',
			'type'        => 'FLOAT',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'gene_name_1', 'gene_name_2' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['gene_name_1', 'gene_name_id_2' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
#	$self->{'data_handler'}->{''} =->new();
#	< - you have to check that !$self->{'data_handler'}->{''} =->new();
	return $dataset;
}

1;
