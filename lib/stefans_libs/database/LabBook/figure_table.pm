package figure_table;

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

use stefans_libs::database::LabBook::figure_table::subfigure_list;

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

	bless $self, $class if ( $class eq "figure_table" );
	$self->init_tableStructure();

	return $self;

}

=head2 AddFigure_To_Latex_Figure_Obj ( $figure_id, stefans_libs::Latex_Document::Figure object)

Here we will convert the figure entry $figure_id into a latex figure object dataset.

=cut

sub AddFigure_To_Latex_Figure_Obj {
	my ( $self, $figure_id, $figure_obj ) = @_;
	my $error = '';
	$error .=
	  ref($self)
	  . "::AddFigure_To_Latex_Figure_Obj - the id $figure_id is not usable!\n"
	  if ( $figure_id == 0 );
	$error .=
	  ref($self)
	  . "::AddFigure_To_Latex_Figure_Obj - I need a 'stefans_libs::Latex_Document::Figure' object\n"
	  unless ( ref($figure_obj) eq "stefans_libs::Latex_Document::Figure" );
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ ref($self) . ".figure_caption", "subfigure_table.id", 'figure_label', 'figure_placement' ],
			'where' => [ [ ref($self) . ".id", '=', 'my_value' ] ],
		},
		$figure_id
	);
	my ( @picture_files, @sub_captions, $picture_file, $sub_caption);
	## now I need to populate the two arrays!
	
	($picture_file, $sub_caption) = $self->{'data_handler'}->{'subfigure_list'}->{'data_handler'}->{'otherTable'} ->
		get_file_position_and_caption_for_id ( $data_table->getAsArray("subfigure_table.id"));
	push ( @picture_files, @$picture_file);
	push ( @sub_captions, @$sub_caption);
	
	## and finally add the figure informations to the LaTeX figure object
	my $return = $figure_obj-> AddPicture( {
		'placement' => @{@{$data_table->{'data'}}[0]}[3],
		'label' => @{@{$data_table->{'data'}}[0]}[2],
		'files' => \@picture_files,
		'caption' => @{@{$data_table->{'data'}}[0]}[0],
		'subfigure_captions' => \@sub_captions
	});
	$figure_obj ->figure_id ( $figure_id );
	return $return;
}

=head2 HTML_Figure_File ( $mode, $file_id );

This function depends on the ImageMagick command line tool convert and will return
either a 'Thumbnail' version of the figure and the caption or a 'Fullsize' version
of the figure and the caption.

Figures are returned as path to the figure file and the figure is in gif format.

=cut

sub HTML_Figure_File {
	my ( $self, $mode, $file_id ) = @_;
	## HURAY! I need gif versions of the files
	
	my $data_table = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ ref($self) . ".figure_caption", "subfigure_table.id", 'figure_label', 'figure_placement' ],
			'where' => [ [ ref($self) . ".id", '=', 'my_value' ] ],
		},
		$file_id
	);
	my ( @picture_files, @sub_captions, $picture_file, $sub_caption);
	
	($picture_file, $sub_caption) = $self->{'data_handler'}->{'subfigure_list'}->{'data_handler'}->{'otherTable'} ->
		get_file_position_and_caption_for_id ( $data_table->getAsArray("subfigure_table.id"));
	
	my $path = $self->{'data_handler'}->{'subfigure_list'}->{'data_handler'}->{'otherTable'} ->{'data_path'};
	unless ( -d $path."thumb/" ){
		Carp::confess ( "could you please ask an admin to create the path $path"."thumb/?");
	}
	unless ( -d $path."served/" ){
		Carp::confess ( "could you please ask an admin to create the path $path"."served/?");
	}
	Carp::confess ( "Sorry, but a collage of more than one figure file is not supported at the moment\n" ) 
		if ( scalar ( @$picture_file) > 1 );
	unless ( -f $path."thumb/$file_id.gif" ){
		system ( "convert -resize 200x200 -background white -gravity center -extent 200x200 @$picture_file[0] $path"."thumb/$file_id.gif");
	}
	unless ( -f $path."served/$file_id.gif" ){
		system ( "convert -background white @$picture_file[0] $path"."served/$file_id.gif");
	}
	
	unless ( ref(@{$data_table->{'data'}}[0]) eq "ARRAY"){
		Carp::confess ( "We have a seriouse server error here - you wanted to get the figure for figuure_table.id $file_id, but the search did not return a usefull value\n".
		$self->{'complex_search'});
	}
	if ( $mode eq "Thumbnail" ){
		return ($path."thumb/$file_id.gif", @{@{$data_table->{'data'}}[0]}[0]. @$sub_caption[0]);
	}
	elsif ( $mode eq "Fullsize" ) {
		return ($path."served/$file_id.gif",@{@{$data_table->{'data'}}[0]}[0]. @$sub_caption[0]);
	}
	Carp::confess ( "We do not support the mode $mode\n");
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "figures_table";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'figure_caption',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'the main figure caption',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'figure_placement',
			'type'        => 'VARCHAR (4)',
			'NULL'        => '1',
			'description' => 'the LaTeX figure placement options (htbp)',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'figure_label',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => 'an optional lable for the figure',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'figure_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'link_to' => 'list_id',
			'description'  => 'not used feature to add more than one figure to the database',
			'data_handler' => 'subfigure_list',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['md5_sum'] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'}       = ['md5_sum'];

	$self->{'table_definition'} = $hash;

	$self->{'Group_to_MD5_hash'} = ['figure_caption']
	  ;    # define which values should be grouped to get the 'md5_sum' entry
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
	$self->{'linked_list'} = $self->{'data_handler'}->{'subfigure_list'} =
	  subfigure_list->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	if ( !defined $dataset->{'figure_list_id'}
		||   $dataset->{'figure_list_id'} == 0 )
	{
		$dataset->{'figure_list_id'} = 
		  $self->{'linked_list'}->readLatestID() + 1;
		#  Carp::confess ( "we have craeted a new figure_list_id: $dataset->{'figure_list_id'}\n");
	}
	unless ( ref( $dataset->{'subfigures'}) eq "ARRAY" ){
		$self->{'error'} .= "Sorry, but without any subfigures there is no use in creating a figure_table entry!\n" ;
	}
	else {
		foreach (@{ $dataset->{'subfigures'}}){
			$self->{'error'} .= "I can not access the file '$_->{'file'}'\n" unless ( -f $_->{'file'} );
		}
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

=head2 post_INSERT_INTO_DOWNSTREAM_TABLES

In this class, we need to use that function to store the figure files with 
there optional captions in our list table.
The list data should be stored in the dataset part 'subfigures' => [ {'file' => <filename>, 'caption' => <sub caption>}, ...]

=cut

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1 unless ( ref( $dataset->{'subfigures'} ) eq "ARRAY" );
	my $data;
	#print "you try to insert some figure files - cool!\nI have the id '$id'\n";
	foreach ( @{$dataset->{'subfigures'}} ){
		$data = $self->add_to_list ( $id, $_,  'subfigure_list');
		#Carp::confess ( "post_INSERT_INTO_DOWNSTREAM_TABLES ( $id, $dataset) -> add_to_list ( $id, $_,  'subfigure_list')\n we have GOT something: '$data'\n");
	}
	return 1;
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
