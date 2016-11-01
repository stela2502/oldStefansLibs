package LabBook;

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

use stefans_libs::database::project_table;
use stefans_libs::database::scientistTable;
use stefans_libs::database::LabBook::LabBook_instance;
use stefans_libs::database::LabBook::ChapterStructure;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh
	};

	bless $self, $class if ( $class eq "LabBook" );
	$self->init_tableStructure();

	return $self;

}

=head2 AddFigure ({
	'figure_placement' 
	'figure_label' 
	'figure_caption' 
	'picture_file'
	'picture_caption' 
	'labBook_id' 
	'entry_id'
});

=cut

sub AddFigure {
	my ( $self, $hash ) = @_;
	return $self-> get_LabBook_Instance( $hash->{'labBook_id'} ) -> AddFigure ( $hash );
}

=head2 AddFile ({ 
	'comment'     => ,
	'file'        => ,
	'labBook_id'  => ,
	'entry_id'   => 
} );
	
=cut
	
sub AddFile {
	my ( $self, $hash ) = @_;
	return $self-> get_LabBook_Instance( $hash->{'labBook_id'} ) -> AddFile ( $hash );
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "labbook_organizer";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'scientist_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'scientistTable'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'project_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'project_table'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'start_data',
			'type'        => 'DATE',
			'NULL'        => '0',
			'description' => '',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'last_modified',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
			'hidden'      => 1
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => '',
			'hidden'      => 1
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'scientist_id', 'project_id' ] );
	push( @{ $hash->{'UNIQUES'} }, ['table_baseString'] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['table_baseString'];

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
	  scientistTable->new( undef, $self->{'debug'} );
	$self->{'data_handler'}->{'project_table'} =
	  project_table->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	$self->{'downstream_data_handler'} = "LabBook_instance";
	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	$dataset->{'table_baseString'} =
	  "LabBook_" . $dataset->{'scientist_id'} . "_" . $dataset->{'project_id'};
	return 1;
}

sub Get_Admin_LogBook {
	my ( $self, $adminName ) = @_;

	my $scientist_id =
	  $self->{'data_handler'}->{'scientistTable'}
	  ->_return_unique_ID_for_dataset( { 'username' => "$adminName" } );
	my $project_id = $self->{'data_handler'}->{'project_table'}->AddDataset(
		{
			'name'     => 'Maintainance',
			'grant_id' => 1,
			'aim' =>
'help to create an admin LabBook, where moast Admin modifications at the database can be logged.'
		}
	);
	Carp::confess(
"sorry, but I could not identfy the scientist_id for the username '$adminName'\n$self->{'data_handler'}->{'scientistTable'}->{'complex_search'}\n"
	) unless ( defined $scientist_id );
	my $id = $self->AddDataset(
		{
			'project_id'   => $project_id,
			'scientist_id' => $scientist_id
		}
	);

#Carp::confess ( "we try to create an automatic LabBook for the admin user $adminName and got the id '$id'\n");
	return $self->get_LabBook_Instance($id);
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	Carp::confess(
		    ref($self)
		  . "::get_LabBook_Instance -> we did not get the LabBook id for which you want to"
		  . " get a LabBook_instance for!\n" )
	  unless ( defined $id );
	my $inst =
	  $self->{'downstream_data_handler'}
	  ->new( $self->{'dbh'}, $self->{'debug'}, $self, $id );
	return 1;
}

sub Add_2_LabBook_entry {
	my ( $self, $labBook_id, $entry_id, $string ) = @_;
	return 0 unless ( defined $string );
	return $self->get_LabBook_Instance($labBook_id)
	  ->Add_2_LabBook_entry( $entry_id, $string );
}

sub get_LabBook_Instance {
	my ( $self, $my_id ) = @_;
	Carp::confess(
		    ref($self)
		  . "::get_LabBook_Instance -> we did not get the LabBook id for which you want to"
		  . " get a LabBook_instance for!\n" )
	  unless ( defined $my_id );
	return $self->{'downstream_data_handler'}
	  ->new( $self->{'dbh'}, $self->{'debug'}, $self, $my_id );
}

sub createChapter_array {
	my ( $self, $my_id ) = @_;
	return [] unless ( defined $my_id );
	my $instance      = $self->get_LabBook_Instance($my_id);
	my $Chapter_array = ChapterStructure->new( $self->{'debug'} );
	my $problems;
	$Chapter_array->Titel( $instance->{'project_name'} );
	my $data = $instance->getArray_of_Array_for_search(
		{
			'search_columns' => [
				ref($instance) . ".id",
				ref($instance) . ".header1",
				ref($instance) . ".header2",
				ref($instance) . ".header3"
			],
			'order_by' => [ ref($instance) . ".id" ]
		}
	);
	foreach my $entry (@$data) {
		$Chapter_array->add_chapter_entry(
			{
				'id'      => @$entry[0],
				'header1' => @$entry[1],
				'header2' => @$entry[2],
				'header3' => @$entry[3]
			},
			$problems
		);
	}

#Carp::confess ( "we have had some problems:\n".$problems) if ( $problems =~ m/\w/);
	$Chapter_array->print() if ( $self->{'debug'} );
#	warn root::get_hashEntries_as_string( $Chapter_array, 9,
#		"we created this chapter array - is that OK? " );
	return $Chapter_array;
}

sub may_access {
	my ( $self, $c, $labBook_id ) = @_;
	my ( $msg, $owned, $update_entry );
	unless ( $c->user =~ m/\w/ ) {
		$c->stash->{'message'} = "You are not logged in!\n";
		$c->res->redirect('/access_denied');
		$c->detach();
	}
	$owned = 0;
	$msg   = '';
	foreach (
		@{
			$c->model('LabBook')->getArray_of_Array_for_search(
				{
					'search_columns' => [ ref( $c->model('LabBook') ) . '.id' ],
					'where'          => [ [ 'username', '=', 'my_value' ] ],
				},
				$c->user
			)
		}
	  )
	{

		$msg .= "compared $_ with $labBook_id\n";
		$owned = 1 if ( @{$_}[0] == $labBook_id );
	}
	unless ($owned) {
		
	}
		
	unless ($owned) {
		$c->stash->{'message'} = $msg;
		$c->res->redirect('/access_denied');
		$c->detach();
	}
	return 1;
}

sub get_most_actual_LabBook__id_for_user {
	my ( $self, $username ) = @_;
	return undef unless ( defined $username );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ ref($self) . '.id', ref($self) . ".last_modified" ],
			'where' => [ [ 'username', '=', 'my_value' ] ],
			'order_by' =>
			  [ [ 'my_value', '-', ref($self) . ".last_modified" ] ],
			'limit' => "limit 1"
		},
		$username
	)->get_line_asHash(0);
	return undef unless ( defined $data );
	return $data->{ ref($self) . '.id' };
}

sub __getChapterStructure {
	my ( $self, $my_id ) = @_;
	return undef unless ( defined $my_id );
	my $instance      = $self->get_LabBook_Instance($my_id);
	my $Chapter_array = ChapterStructure->new( $self->{'debug'} );
	$Chapter_array->Titel( $instance->{'project_name'} );
	$Chapter_array->populate_from_DB_interface($instance);
	return $Chapter_array;
}

sub write_LaTeX_File_4_LabBook_id_to_path {
	my ( $self, $my_id, $outpath ) = @_;
	my $Chapter_array = $self->__getChapterStructure($my_id);
	my $outfile       = $outpath
	  . join( "_", ( split( /\s/, $Chapter_array->Titel() ) ) ) . ".tex";
	$outfile =~ s/\\_/_/g;
	return $self->write_LaTeX_File_4_LabBook_id( $my_id, $outfile );
}

sub write_LaTeX_File_4_LabBook_id {
	my ( $self, $my_id, $outfile ) = @_;
	my $Chapter_array;
	Carp::confess("Sorry, but the LabBook with the ID $my_id does not exist!\n")
	  unless (
		defined( $Chapter_array = $self->__getChapterStructure($my_id) ) );
	return $Chapter_array->write_LaTeX_File($outfile);
}

sub GetAs_LaTeX_book_String {
	my ( $self, $my_id ) = @_;
	my $Chapter_array;
	Carp::confess(
"Sorry, but you should try to get your file ba using the function write_LaTeX_File_4_LabBook_id,"
		  . " as we now can handle figures but we will not give you access to the figures.\n"
	);
	return ''
	  unless (
		defined( $Chapter_array = $self->__getChapterStructure($my_id) ) );
	return $Chapter_array->GetAs_LaTeX_book_String();
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
