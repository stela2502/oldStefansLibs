package to_do_list;


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

    bless $self, $class if ( $class eq "to_do_list" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "to_do";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'scientists_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => 'the link to the scientists table',
               'data_handler' =>'scientistTable'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'information',
               'type'         => 'TEXT',
               'NULL'         => '0',
               'description'  => 'describe the task',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'send_time',
               'type'         => 'DATE',
               'NULL'         => '0',
               'description'  => 'when should I start to remind you?',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'creation_time',
               'type'         => 'TIMESTAMP',
               'NULL'         => '0',
               'description'  => '',
               'hidden'       => 1
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'done',
               'type'         => 'VARCHAR (1)',
               'NULL'         => '1',
               'description'  => '',
               'hidden' => 1
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'md5_sum',
               'type'         => 'VARCHAR (32)',
               'NULL'         => '1',
               'description'  => '',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'md5_sum' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'md5_sum' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'Group_to_MD5_hash'} = [ 'scientists_id' , 'information']; # define which values should be grouped to get the 'md5_sum' entry
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

sub __owns{
	my ( $self, $my_id, $username) = @_;
	return 0 unless ( defined $username);
	return 0 unless ( defined $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . ".id"
				],
				'where' => [ 
					[ ref($self) . ".id", '=', 'my_value' ],
					[ "username", '=','my_value']
				 ],
			},
			$my_id, $username
		)->get_line_asHash(0));
	return 1;
}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
