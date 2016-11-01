package stefans_libs_database_School;

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

use stefans_libs::database::scientistTable;
use stefans_libs::database::School::math_admin;
use stefans_libs::database::School::math_test;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		'debug' => $debug,
		'dbh'   => $dbh,
		'math_admin' =>
		  stefans_libs_database_School_math_admin->new( $dbh, $debug ),
		'math_test' =>
		  stefans_libs_database_school_math_test->new( $dbh, $debug ),
	};

	bless $self, $class if ( $class eq "stefans_libs_database_School" );
	$self->init_tableStructure();

	return $self;
}

=head2 create_math_test ( $self, $c, $pupil_id )

One of the main functions to create a math test information. This test information will be 
directly placed in the $c variable, which should be the Catalyst object.

The test level will be automaticly defined inside of this function. The level might vary between different calls.

=cut

sub create_math_test {
	my ( $self, $c, $username ) = @_;

	#1 get the pupli and the actual level of the test
	my $hash = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ 'class', 'act_math_level', 'pupil_id', 'table_baseString' ],
			'where' => [ [ 'username', '=', 'my_value' ] ]
		},
		$username
	)->get_line_asHash(0);
	Carp::confess(
"I do not have a starting level for the username '$username' - please create one!"
	) unless ( defined $hash );
	$self->{'math_test'}->{'_table_name'} = $hash->{'table_baseString'};
	my $function = $self->{'math_admin'}->get_data_table_4_search(
		{
			'search_columns' => ['perl_function'],
			'where' =>
			  [ [ 'class', '<=', 'my_value' ], [ 'level', '<=', 'my_value' ] ],
			'order_by' => [ 'my_value', '-', 'level' ]
		},
		$hash->{'class'},
		$hash->{'act_math_level'}
	)->get_line_asHash(0);
	Carp::confess(
"Sorry, but I do not have any function for class <= $hash->{'class'} and level <= $hash->{'act_math_level'}"
	) unless ( defined $function );
	( $c->stash->{'aufgabe'}, $c->stash->{'ergebnis'} ) =
	  $self->_create_values( $function->{'perl_function'} );
	return ( $c->stash->{'aufgabe'}, $c->stash->{'ergebnis'} );
}

=head2 add_perl_function ( {'class' => <class>, 'username' => <admin username>, 'level' => <difficulty level>, 'perl_function' => <logics> })

I will only descibe the logiocs part here:
In the logics part you need to populate two variables, $aufgabe and $ergebnis which contain the task and the result of the mathmatical task.
You are allowed to call the function \$self->_einer() which returns a random number between 2 and 9 and $self->_return_reverse_order( $a, $b) 
which does exactly what you think.
Best Luck with that!

=cut

sub add_perl_function {
	my ( $self, $hash ) = @_;
	return $self->{'math_admin'}->AddDataset(
		{
			'level'         => $hash->{'level'},
			'class'         => $hash->{'class'},
			'perl_function' => $hash->{'perl_function'},
			'creator'       => { 'username' => $hash->{'username'} }
		}
	);
}

sub _create_values {
	my ( $self, $function_core ) = @_;
	return
	    "sub { my ( \$aufgabe, \$ergebnis ); "
	  . $function_core
	  . " return ( \$aufgabe, \$ergebnis ); }";
}

sub _einer {
	my $eins = 0;
	while ( $eins <= 1 ) {
		$eins = int( rand(10) );
	}
	return $eins;
}

sub _return_reverse_order {
	my ( $self, $a, $b ) = @_;
	return $b, $a;
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "school";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'pupil_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'scientistTable',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'class',
			'type'        => 'INTEGER',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'act_math_level',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
		}
	);

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = [];

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
	$self->{'data_handler'}->{'scientistTable'} =
	  scientistTable->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
