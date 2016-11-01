package PubMed;


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

use stefans_libs::database::lists::list_using_table;
use base list_using_table;

use stefans_libs::database::publications::Authors_list;
use stefans_libs::database::publications::Journals;

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

    bless $self, $class if ( $class eq "PubMed" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "PubMed";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'PMID',
               'type'         => 'INTEGER',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'title',
               'type'         => 'VARCHAR (300)',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'journal_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => '',
               'data_handler' => 'Journals',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'authors_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '1',
               'description'  => '',
               'link_to' => 'list_id',
               'data_handler' => 'Authors_list'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'issue',
               'type'         => 'INTEGER',
               'NULL'         => '1',
               'description'  => 'the issue of the journal',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'pub_year',
               'type'         => 'DATE',
               'NULL'         => '0',
               'description'  => 'the publication year',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'pub_month',
               'type'         => 'VARCHAR(7)',
               'NULL'         => '1',
               'description'  => 'the publication month',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'pub_day',
               'type'         => 'DATE',
               'NULL'         => '1',
               'description'  => 'the publication day',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'pages',
               'type'         => 'VARCHAR(20)',
               'NULL'         => '1',
               'description'  => 'the publication pages',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'PMID' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'PMID' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'Journals'} = Journals->new($self->{'dbh'}, $self->{'debug'});
     $self->{'linked_list'} = $self->{'data_handler'}->{'Authors_list'} = Authors_list->new( $self->{'dbh'}, $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1 if ( $dataset -> {'autors_id'} > 0 );
	unless ( ref( $dataset->{'authors'} ) eq "ARRAY" ) {
		$self->{'error'} .= ref($self)
		  . ":post_INSERT_INTO_DOWNSTREAM_TABLES - we do not have a list of authors!\n";
	}
	else {
		my $list_id = $self->{'data_handler'} -> {'Authors_list'} -> AddDataset ($dataset->{'authors'});
		$self->UpdateDataset ( {'id' => $id, 'authors_id' => $list_id});
	}
	return 1 unless ( $self->{'error'} =~ m/\w/ );
	return 0;
}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
