package subjectTable;

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
use stefans_libs::database::organismDB;
use stefans_libs::database::variable_table;
use stefans_libs::database::subjectTable::phenotype_registration;
use stefans_libs::database::project_table;
use base "variable_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store information concerning the source of a experimental datatse. That can be either a person, or a creature.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class subjectTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless (  ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug,
		'select_id_for_dentifier' =>
		  'select id from subjects where identifier = ?',
		'activated' => {},
		'phenotype_registration' => phenotype_registration->new()
	};

	bless $self, $class if ( $class eq "subjectTable" );

	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "subjects";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'identifier',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'an unique identifier for that individual',
			'needed'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'organism_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'DEFAULT'      => '',
			'data_handler' => 'organism',
			'description' =>
'this value can be recieved using the variable organism together with the data_handler organism',
			'needed' => 0
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'project_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'DEFAULT'      => '',
			'data_handler' => 'projects',
			'description' =>
'the link to the projects table',
			'needed' => 0
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['identifier'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['identifier']
	  ; # add here the values you would take to select a single value from the database
	$self->{'_tableName'} = $hash->{ 'table_name'
	  }; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists($self->TableName()) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'data_handler'}->{'organism'} =
	  organismDB->new( $self->{dbh}, $self->{debug} );
	$self->{'data_handler'}->{'projects'} = project_table->new(  $self->{dbh}, $self->{debug} );

	return $self;

}

sub connect_2_otherTable{
	my ( $self, $otherObj, $other_Var ) = @_;
	Carp::confess ( "we need a table objects that implements a variable_table structure\n") unless ($otherObj->isa('variable_table') );
	unless ( defined $other_Var ){
		$other_Var = 'sample_id';
	}
	unless ( defined $self->{'var_id'}){
		$self->{'var_id'} = {
			'name'        => 'id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'data_handler' => 'multiple',
			'link_to' => $other_Var,
			'description' => 'The id links to multiple other table objects e.g.'
		};
		push ( @{$self->{'table_definition'}->{'variables'}}, $self->{'var_id'});
		$self->{'data_handler'}->{'multiple'} = [];
	}
	push ( @{$self->{'data_handler'}->{'multiple'}},$otherObj );
	return 1;
}

sub expected_dbh_type {
	return 'dbh';
	#return "database_name";
}

sub activated{
	my ( $self ) =@_;
	return [ keys %{$self->{'activated'}}]
}

sub connect_2_phenotype{
	my ( $self, $type ) = @_;
	return ref($self)."::activate_connection -> sorry, but I do not support the data type '$type'\n"
		unless (  $self->{'phenotype_registration'}->supports($type) );
	return $self->{'registered_phenotypes'}->{$type} if ( defined $self->{'registered_phenotypes'}->{$type});
	
	unless ( defined $self->{'var_id'}){
		$self->{'var_id'} = {
			'name'        => 'id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'data_handler' => 'multiple',
			'link_to' => 'subject_id',
			'description' => 'The id links to multiple other table objects e.g.'
		};
		push ( @{$self->{'table_definition'}->{'variables'}}, $self->{'var_id'});
		$self->{'data_handler'}->{'multiple'} = [];
	}
	$self->{'registered_phenotypes'}->{$type} = $self->{'phenotype_registration'}->getDownstreamTable_4_type( $type);
	push ( @{$self->{'data_handler'}->{'multiple'}}, $self->{'registered_phenotypes'}->{$type});
	$self->{'activated'} -> {$type} = 1;
	$self->{'var_id'}->{'description'} .= " $type";
	return $self->{'registered_phenotypes'}->{$type};
}

=head2 check_dataset

We need some information to create a usable database entry:

=over 3

=item identifier => the identifier that names the subject - 
please do not use a anme here, as we do not want to have a ethical problem.

=item organism_id => the id of the organism as stored in the organism table.
We will dye id the organism_id is defined in the dataset, but not in the database!

=item organism_tag => instead of organism_id -> the organism_id will be resolved using this string.
If the organism_tag is unknown to the database we add a new entry to the database - so be careful what you do here!
Once a unusable organism_tag and you will screw up the database quite some bit....

=back

=cut

1;
