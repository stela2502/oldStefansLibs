package SNP_calls;


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

    bless $self, $class if ( $class eq "SNP_calls" );
    $self->init_tableStructure();

    return $self;

}

sub init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     
     push ( @{$hash->{'variables'}},  {
               'name'         => 'value',
               'type'         => 'TINYINT',
               'NULL'         => '0',
               'description'  => '',
          }
     );
     push ( @{$hash->{'UNIQUES'}}, [ 'id' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'id' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
#     unless ( $self->tableExists( $self->TableName() ) ) {
#     	$self->create();
#     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

=head2 create

Creates a new table to store the SNP calls for each rsID.
This method automatically deleted all stored information in a old table!

=head3 arguments

none

=cut

sub create {
	my ( $self, $FOREIGN_TABLE_NAME ) = @_;

	my $createString;

	$FOREIGN_TABLE_NAME = $self->linked_table_name()
	  unless ( defined $FOREIGN_TABLE_NAME );
	Carp::confess(
		ref($self)
		  . ":create -> we definitely need an \$FOREIGN_TABLE_NAME '$FOREIGN_TABLE_NAME' to create the linked table structure!\n"
	) unless ( defined $FOREIGN_TABLE_NAME );

	my $table_baseName = $self->TableName();

	$self->_dropTable($table_baseName);

	$self->{'table_definition'}->{'table_name'} = "$table_baseName";

	$self->{'table_definition'}->{'FOREIGN KEY'} = {
		'foreignColumn' => 'id',
		'foreignTable'  => $FOREIGN_TABLE_NAME,
		'myColumn'      => 'id'
	};

	if ( $self->{'connection'}->{'driver'} eq "mysql" ) {
		$createString =
		  $self->create_String_mysql( $self->{'table_definition'} );
	}
	elsif ( $self->{'connection'}->{'driver'} eq "DB2" ) {
		$createString = $self->create_String_DB2( $self->{'table_definition'} );
	}
	else {
		Carp::confess(
			ref($self)
			  . " - variableTable -> we can not create a CREATE statement for this database driver '$self->{'connection'}->{'driver'}'\n"
		);
	}

	if ( $self->{debug} ) {
		print ref($self), ":create -> we would run $createString\n";
	}
	else {
		$self->{dbh}->do($createString)
		  or die
"we tried to craete the table structure: \n'$createString;'\n But we got that error: ",
		  $self->{dbh}->errstr;
		$self->{__tableNames} = undef;
	}
	return 1;
}

sub Sample_Lable{
	my ( $self, $sample_lable )= @_;
	$self->{'sample_lable'} = $sample_lable if ( defined $sample_lable);
	return $self->{'sample_lable'} if ( defined $self->{'sample_lable'});
	return $self->TableName();
}

sub linked_table_name {
	my ( $self, $name ) = @_;
	return $self->{'FOREIGN_TABLE_NAME'} unless ( defined $name);
	if ( $name =~ m/\w/ ) {
		$self->{'FOREIGN_TABLE_NAME'} = $name;
	}
	return $self->{'FOREIGN_TABLE_NAME'};
}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
