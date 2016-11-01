package stefans_libs_database_sequenome_data_sequenome_chips;


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

    bless $self, $class if ( $class eq "stefans_libs_database_sequenome_data_sequenome_chips" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "sequenome_chips";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'customer',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'project',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'project_id',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'project_table'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'plate',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'experiment',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'chip',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'customer', 'project', 'plate', 'experiment', 'chip' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'customer', 'project', 'plate', 'experiment', 'chip' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'project_table'} = project_table->new($self->{'dbh'}, $self->{'debug'});
     return $dataset;
}




sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
