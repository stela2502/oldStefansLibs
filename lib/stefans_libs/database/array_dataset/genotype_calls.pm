package genotype_calls;

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

	bless $self, $class if ( $class eq "genotype_calls" );

	$self->init_tableStructure();

	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

## MYSQL CREATE TABEL
#my $sql = "CREATE TABLE genotype_calls_variable (
#  id INTEGER UNSIGNED auto_increment,
#  rsID VARCHAR(20) NOT NULL,
#  call_val char(1) NOT NULL,
#  INDEX ( rsID )
#  );";
sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'call_val',
			'type'        => 'CHAR (1)',
			'NULL'        => '0',
			'description' => 'the value returned by the command line tool apt-probeset-genotype',
			'needed'      => ''
		}
	);
	$self->{'table_definition'} = $hash;

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

=head2 create

Creates a new table to store the affymetrix genotype calls for one array experiment.
In order to get all information, we need to use the MYSQL FOREIGN_TABLE_NAME statement.
Therefore we need the 'master table' object we want to link this one to.
This method automatically deletes all stored information in a old table!

=head3 arguments

none

=cut

sub create {
	my ( $self, $FOREIGN_TABLE_NAME ) = @_;

	$FOREIGN_TABLE_NAME = $self->{'FOREIGN_TABLE_NAME'} unless (defined $FOREIGN_TABLE_NAME );
	Carp::confess(
		ref($self)
		  . ":create -> we definitely need an \$FOREIGN_TABLE_NAME '$FOREIGN_TABLE_NAME' to create the linked table structure!\n"
	) unless ( defined $FOREIGN_TABLE_NAME );

	my $table_baseName = $self->TableName();
	$self->{dbh}->do("DROP TABLE IF EXISTS $table_baseName")
	  or die $self->{dbh}->errstr();

	$self->{'table_definition'}->{'table_name'} = "$table_baseName";

	$self->{'table_definition'}->{'FOREIGN KEY'} = {
		'foreignColumn' => 'id',
		'foreignTable'  => $FOREIGN_TABLE_NAME,
		'myColumn'      => 'id'
	};

	my $createString =
	  $self->create_String_mysql( $self->{'table_definition'} );

	if ( $self->{debug} ) {
		print ref($self), ":create -> we would run $createString\n";
	}
	else {
		$self->{dbh}->do($createString)
		  or die
"we tried to craete the table structure: \n$createString\n But we got that error: ",
		  $self->{dbh}->errstr;
		$self->{__tableNames} = undef;
	}
	return 1;
}

1;
