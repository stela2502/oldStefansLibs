package binary_multi;

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
use stefans_libs::database::subjectTable::phenotype::phenotype_base_class;
use base 'phenotype_base_class';

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless (  ref($dbh) eq "DBI::db" );

	my $self = {
		'debug' => $debug,
		'dbh'   => $dbh,
	};

	bless $self, $class if ( $class eq "binary_multi" );

	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return 'dbh';

	#return "not a databse interface";
	#return "database_name";
}


sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = ['subject_id', 'date'];
	$hash->{'variables'}  = [];

	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'subject_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => 'the link to the subjects table',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'value',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'either 0 or 1 - the binary value...',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'date',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => 'the date the value was determined',
			'needed'      => ''
		}
	);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['subject_id', 'date']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!

## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	#$self->{'data_handler'}->{''} =->new();
	return $dataset;
}

1;
