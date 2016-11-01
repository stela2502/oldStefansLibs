package Affymetrix_expression_lib;


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

use stefans_libs::database::external_files;

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

    bless $self, $class if ( $class eq "Affymetrix_expression_lib" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "affy_exp_lib";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'name',
               'type'         => 'VARCHAR (100)',
               'NULL'         => '0',
               'description'  => 'the name of the expression array',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'version',
               'type'         => 'VARCHAR (20)',
               'NULL'         => '0',
               'description'  => 'the version of the expression array',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'source',
               'type'         => 'VARCHAR (200)',
               'NULL'         => '1',
               'description'  => 'where did you get that from',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'cdf_file_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '1',
               'data_handler'=>'external_files',
               'description'  => 'the cdf file',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'pgf_file_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '1',
               'data_handler'=>'external_files',
               'description'  => 'the pdf file',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'clf_file_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '1',
               'data_handler'=>'external_files',
               'description'  => 'the clf file',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'name', 'version' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'name', 'version' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'external_files'} = external_files->new($self->{'dbh'}, $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub get_lib_files_for_id {
	my ( $self, $id ) = @_;
	unless ( defined $id){
		$self->{'warning'} = "Sorry, but you can not get files if I do not get an ID!\n";
		return undef;
	}
	my $data = $self->getArray_of_Array_for_search({
 	'search_columns' => [ref($self).".name",ref($self).'.cdf_file_id', ref($self).".pgf_file_id", ref($self).".clf_file_id"],
 	'where' => [[ref($self).".id", '=', 'my_value']]
 	}, $id) ;
 	unless ( ref( @$data[0]) eq "ARRAY" ) {
 		$self->{'warning'} = "Sorry, but we can not find any files for the ID $id!\n";
		return undef;
 	}
 	my $return;
 	$return -> {'name'} = @{@$data[0]}[0];
 	if ( @{@$data[0]}[1] > 0 ){
 		$return -> {'cdf'} = $self->{'data_handler'}->{'external_files'} ->get_fileHandle ( {'id' => @{@$data[0]}[1]});
 	}
 	if ( @{@$data[0]}[2] > 0 ){
 		$return -> {'pgf'} = $self->{'data_handler'}->{'external_files'} ->get_fileHandle ( {'id' => @{@$data[0]}[2]});
 	}
 	if ( @{@$data[0]}[3] > 0 ){
 		$return -> {'clf'} = $self->{'data_handler'}->{'external_files'} ->get_fileHandle ( {'id' => @{@$data[0]}[3]});
 	}
 	my $OK = 0;
 	$OK = 1 if ( ref($return -> {'cdf'}) eq "GLOB" );
 	$OK = 1 if ( ref($return -> {'clf'}) eq "GLOB" &&  ref($return -> {'pgf'}) eq "GLOB" );
 	Carp::confess ( ref($self)."::get_lib_files_for_id( $id ) -> we have no complete set!") unless ( $OK );
	return $return;
}

sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
