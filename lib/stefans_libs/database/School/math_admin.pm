package stefans_libs_database_School_math_admin;


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

##use some_other_table_class;

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

    bless $self, $class if ( $class eq "stefans_libs_database_School_math_admin" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "math_admin";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'creator_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'scientistTable',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'perl_function',
               'type'         => 'TEXT',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'level',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'class',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'md5_sum',
               'type'         => 'VARCHAR (32)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'md5_sum' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'md5_sum' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'Group_to_MD5_hash'} = [ 'function_core']; # define which values should be grouped to get the 'md5_sum' entry
     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'scientistTable'} = scientistTable->new($self->{'dbh'}, $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS{
	my ( $self, $dataset ) = @_;
	$self->{'error'} .= $self->_check_function_core( $dataset->{'perl_function'});
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub _check_function_core {
	my ( $self, $function_core ) = @_;
	my $error = '';
	$error .= "you need to assigne the task to the 'aufgabe' variable!\n"
	  unless ( $function_core =~ m/\$aufgabe/ );
	$error .=
	  "you need to assigne the expected result to the 'ergebnis' variable!\n"
	  unless ( $function_core =~ m/\$aufgabe/ );
	$error .= "you must not call a function using the '::' expression\n"
	  if ( $function_core =~ m/::/ );
	foreach ( $function_core =~ m/\$self *-> *(\w+)/g ) {
		$error .= "function '$_' must not be called in the function core!\n"
		  unless ( $_ =~ m/_einer/ || $_ =~ m/_return_reverse_order/ );
	}
	return $error;
}

sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
