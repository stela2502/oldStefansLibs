package stefans_libs_database_Company;


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

use stefans_libs::database::Company::Employee;
use stefans_libs::database::Contacts::addr_list;
use stefans_libs::database::Company::Bills;
use stefans_libs::database::Company::Invoices;

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

    bless $self, $class if ( $class eq "stefans_libs_database_Company" );
    $self->init_tableStructure();
	
    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "Company";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'owner_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'stefans_libs_database_Company_Employee',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'name',
               'type'         => 'VARCHAR (100)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'Tax_ID',
               'type'         => 'VARCHAR (30)',
               'NULL'         => '1',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'address_list_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'stefans_libs_database_Contacts_addr_list',
               'link_to'      => 'list_id',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'description',
               'type'         => 'TEXT',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'WebPage',
               'type'         => 'VARCHAR (100)',
               'NULL'         => '1',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'labbook_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'LabBook',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'DEFAULT_currency',
               'type'         => 'VARCHAR (4)',
               'NULL'         => '0',
               'description'  => '',
          }
     );

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [  ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'LabBook'} = LabBook->new($self->{'dbh'}, $self->{'debug'});
     $self->{'data_handler'}->{'stefans_libs_database_Contacts_addr_list'} = stefans_libs_database_Contacts_addr_list->new($self->{'dbh'}, $self->{'debug'});
     $self->{'data_handler'}->{'stefans_libs_database_Company_Employee'} = stefans_libs_database_Company_Employee->new($self->{'dbh'}, $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
