package LabBook_instance;

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
use Date::Simple ('date');
use stefans_libs::database::external_files::file_list;
use stefans_libs::database::experiment;
use stefans_libs::database::LabBook::figure_table;
use stefans_libs::database::LabBook::file_list;

##use some_other_table_class;

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug, $LabBook_obj, $LabBook_id ) = @_;

	Carp::confess("we need the dbh at $class new \n")
	  unless ( ref($dbh) eq "DBI::db" );
	Carp::confess("we need a LabBook object at startup!\n")
	  unless ( ref($LabBook_obj) eq "LabBook" );
	Carp::confess("we need the id of our labbook at startup!\n")
	  unless ( defined $LabBook_id && $LabBook_id > 0 );

	my ($self);

	$self = {
		debug       => $debug,
		dbh         => $dbh,
		LabBook_id  => $LabBook_id,
		LabBook_obj => $LabBook_obj
	};

	bless $self, $class if ( $class eq "LabBook_instance" );
	$self->init_tableStructure();
	my $data = @{
		$LabBook_obj->getArray_of_Array_for_search(
			{
				'search_columns' => [
					ref($LabBook_obj) . ".table_baseString",
					ref( $LabBook_obj->{'data_handler'}->{'project_table'} )
					  . '.name'
				],
				'where' => [ [ ref($LabBook_obj) . ".id", "=", "my_value" ] ]
			},
			$LabBook_id
		)
	  }[0];
	$self->TableName( @$data[0] );
	$self->{'project_name'} = @$data[1];
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}   = [];
	$hash->{'UNIQUES'}   = [];
	$hash->{'variables'} = [];
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'text',
			'type'        => 'TEXT',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'creation_date',
			'type'        => 'DATE',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'header1',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'header2',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'header3',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR (32)',
			'NULL'        => '0',
			'description' => '',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'experiment_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
'a link to the experiments used together with this LabBook section',
			'data_handler' => 'experiment'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'figure_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'this LabBook entry might have a figure',
			'data_handler' => 'figure_table'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'files_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
'the link to the file_list table in case the LabBook entry has a file attached',
			'data_handler' => 'file_list'
		}
	);
	push( @{ $hash->{'INDICES'} }, ['md5_sum'] );
	push( @{ $hash->{'INDICES'} }, ['header1'] );
	push(
		@{ $hash->{'UNIQUES'} },
		[ 'creation_date', 'header1', 'header2', 'header3' ]
	);

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} =
	  [ 'creation_date', 'header1', 'header2', 'header3' ];

	$self->{'table_definition'} = $hash;

	$self->{'Group_to_MD5_hash'} = ['text']
	  ;    # define which values should be grouped to get the 'md5_sum' entry
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

	##now we need to check if the table already exists. remove that for the variable tables!

	## Table classes, that are linked to this class have to be added as 'data_handler',
	## both in the variable definition and here to the 'data_handler' hash.
	## take care, that you use the same key for both entries, that the right data_handler can be identified.

	$self->{'data_handler'}->{'experiment'} =
	  experiment->new( '', $self->{'debug'} );
	$self->{'data_handler'}->{'figure_table'} =
	  figure_table->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'file_list'} =
	  stefans_libs_LabBook_file_list->new( $self->{'dbh'}, $self->{'debug'} );

	#$self->{'data_handler'}->{''} = some_other_table_class->new( );
	return $dataset;
}

=head2 AddFile ({ 
	'comment'     => ,
	'file'        => ,
	'labBook_id'  => ,
	'entry_id'}   => 
);
	
=cut

sub AddFile {
	my ( $self, $hash ) = @_;
	my ( $error, $labBook_entry, $data, $headers, $files_list_id );
	foreach (qw/comment file labBook_id entry_id/) {
		$error .= "I miss the hash key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess(
		root::get_hashEntries_as_string(
			$hash, 3, ref($self) . "::AddFigure("
		  )
		  . ")\n$error"
	) if ( $error =~ m/\w/ );
	## now I need to check whether I already had an uploaded
	## file in this LabBook section - I would need to add to that list!

	$files_list_id = $self->get_file_list_id_4_my_id( $hash->{'entry_id'} );
	unless ( $files_list_id > 0 ) {
		$files_list_id =
		  $self->{'data_handler'}->{'file_list'}->readLatestID() +
		  1;    ## new files_list id!
	}
	$self->{'data_handler'}->{'file_list'}->add_to_list( $files_list_id,
		{ 'comment' => $hash->{'comment'}, 'file' => $hash->{'file'} } );
	$self->UpdateDataset(
		{ 'id' => $hash->{'entry_id'}, 'files_id' => $files_list_id } )
	  ;
	return $files_list_id;
}

=head2 get_file_list_id_4_my_id (  $id )

This function will return the file_list id or 0 if that one is not defined

=cut

sub get_file_list_id_4_my_id {
	my ( $self, $id ) = @_;
	Carp::confess(
		ref($self)
		  . "::get_file_list_id_4_my_id('$self', '$id') ->I did not get an ID!!\n"
	) unless ( defined $id );

	my ( $headers, $data, $files_list_id );
	$headers = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'header1', 'header2', 'header3' ],
			'where' => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$id
	)->get_line_asHash(0);
	$data = $self->get_data_table_4_search(
		{
			'search_columns' => ['files_id'],
			'where'          => [
				[ ref($self) . ".header1", '=', 'my_value' ],
				[ ref($self) . ".header2", '=', 'my_value' ],
				[ ref($self) . ".header3", '=', 'my_value' ]
			]
		},
		$headers->{'header1'},
		$headers->{'header2'},
		$headers->{'header3'}
	);
	$files_list_id = 0;
	foreach ( @{ $data->getAsArray('files_id') } ) {
		$files_list_id = $_ if ( $_ > 0 );
	}
	return $files_list_id;
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
	my ( $error, $labBook_entry, $subfigures );
	foreach (
		qw/figure_placement figure_label figure_caption picture_file labBook_id entry_id/
	  )
	{
		$error .= "I miss the hash key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess(
		root::get_hashEntries_as_string(
			$hash, 3, ref($self) . "::AddFigure("
		  )
		  . ")\n$error"
	) if ( $error =~ m/\w/ );
	unless ( ref( $hash->{'picture_file'} eq "ARRAY" ) ) {
		$hash->{'picture_file'} = [ $hash->{'picture_file'} ];
	}
	unless ( ref( $hash->{'picture_caption'} eq "ARRAY" ) ) {
		$hash->{'picture_caption'} = [ $hash->{'picture_caption'} ];
	}
	$subfigures = [];
	for ( my $i = 0 ; $i < @{ $hash->{'picture_file'} } ; $i++ ) {
		@{ $hash->{'picture_caption'} }[$i] = ''
		  unless ( defined @{ $hash->{'picture_caption'} }[$i] );
		push(
			@{$subfigures},
			{
				'file'    => @{ $hash->{'picture_file'} }[$i],
				'caption' => @{ $hash->{'picture_caption'} }[$i]
			}
		);
		Carp::confess(
"Sorry, but I could not access the picture file '@{$hash->{'picture_file'}}[$i]'\n"
			  . root::get_hashEntries_as_string( $hash, 3, "the data hash " ) )
		  unless ( -f @{ $hash->{'picture_file'} }[$i] );
	}
	$labBook_entry = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".*" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$hash->{'entry_id'}
	)->get_line_asHash(0);
	if ( defined $labBook_entry->{ ref($self) . ".figure_id" } ) {
		## OK we should add to that figure - or?
		return $self->{'data_handler'}->{'figure_table'}->AddDataset(
			{
				'id'         => $labBook_entry->{ ref($self) . ".figure_id" },
				'subfigures' => $subfigures
			}

		);
	}
	else {
		return $self->UpdateDataset(
			{
				'id' => $hash->{'entry_id'},
				'figure_id' =>
				  $self->{'data_handler'}->{'figure_table'}->AddDataset(
					{
						'figure_placement' => $hash->{'figure_placement'},
						'figure_label'     => $hash->{'figure_label'},
						'figure_caption'   => $hash->{'figure_caption'},
						'subfigures'       => $subfigures
					}
				  )
			}
		);
	}
}

=head2 get_html_diary

=head3 Atributes

[0] = 'LabBook_id' (important to create the links to the MakeLabBook_Entry page)
the following atributes are optional:
[1] = 'start_date'
[2] = 'end_date'

=head3 function

This function will return the last two days as an array of dates, containing hashes with the keys 'date' and 'info'.
The date is what you would expect, whereas the info is an array of hashes 
with the keys 'chapter_str', 'last_entry_id'and 'text'.
The data will be sorted from most actual till the least actual entry.

If we do not get a date range, I will read from the last mentioned date two days in the past.

=cut

sub get_html_diary {
	my ( $self, $labBook_id, $start_date, $end_date ) = @_;
	unless ( defined $start_date ) {
		my $temp = $self->getArray_of_Array_for_search(
			{
				'search_columns' => ['creation_date'],
				'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ],
			},
			$self->readLatestID()
		);
		unless ( ref( @$temp[0] ) eq "ARRAY" ) {
			Carp::confess(
"Sorry, but we do not have any entries in the LabBook, as we did not get anything for the search \n"
				  . $self->{'complex_search'}
				  . root::get_hashEntries_as_string(
					$temp, 3, "\nthe return values are "
				  )
			);
		}
		$end_date   = date( @{ @$temp[0] }[0] );
		$start_date = $end_date - 2;
	}

	my @data = @{
		$self->getArray_of_Array_for_search(
			{
				'search_columns' => [
					ref($self) . ".id",
					ref($self) . ".text",
					ref($self) . ".creation_date",
					ref($self) . ".header1",
					ref($self) . ".header2",
					ref($self) . ".header3"
				],
				'where' => [
					[ ref($self) . ".creation_date", '>=', 'my_value' ],
					[ ref($self) . ".creation_date", '<=', 'my_value' ]
				],
				'order_by' => [
					[ 'my_value', '-', ref($self) . ".creation_date" ],
					ref($self) . ".id"
				]
			},
			$start_date,
			$end_date
		)
	  };
	Carp::confess( "Sorry, but we got an internal error:\n"
		  . $self->{'complex_search'}
		  . "\ndid not give me any data"
		  . root::get_hashEntries_as_string( \@data, 3, "the return values " ) )
	  unless ( ref( $data[0] ) eq "ARRAY" );
	## And now I need to create the return dataset!
	my ( @return, $used, $chapter_str );
	foreach my $data_line (@data) {
		unless ( ref( $used->{ @$data_line[2] } ) eq "ARRAY" ) {
			my $info = [];
			my $hash = { 'date' => @$data_line[2], 'info' => $info };
			$used->{ @$data_line[2] } = $info;
			push( @return, $hash );
		}
		$chapter_str = '';
		$chapter_str .= "@$data_line[3] "   if ( @$data_line[3] =~ m/\w/ );
		$chapter_str .= "- @$data_line[4] " if ( @$data_line[4] =~ m/\w/ );
		$chapter_str .= "- @$data_line[5]"  if ( @$data_line[5] =~ m/\w/ );
		push(
			@{ $used->{ @$data_line[2] } },
			{
				'last_entry_id' => @$data_line[0],
				'href' => "/labbook/LabBook_Reader/$labBook_id/@$data_line[0]",
				'text' => @$data_line[1],
				'chapter_str' => $chapter_str
			}
		);
	}
	return \@return;
}

sub changes_after_check_dataset {
	my ( $self, $dataset ) = @_;
	unless ( $dataset->{'text'} =~ m/\w/ ) {
		## OhOh - you perhaps want to add a dummy entry??
		## That is not necessary if we already have one - you know?
		my $hash = $self->get_data_table_4_search(
			{
				'search_columns' => [ ref($self) . ".id" ],
				'where'          => [
					[ ref($self) . ".header1", '=', 'my_value' ],
					[ ref($self) . ".header2", '=', 'my_value' ],
					[ ref($self) . ".header3", '=', 'my_value' ]
				],
				'limit' => "limit 1"
			},
			$dataset->{'header1'},
			$dataset->{'header2'},
			$dataset->{'header3'}
		)->get_line_asHash(0);
		$dataset->{'id'} = $hash->{ ref($self) . ".id" } if ( defined $hash );
	}
	return 1;
}

sub Add_2_LabBook_entry {
	my ( $self, $my_id, $string ) = @_;
	return 0 unless ( defined $string );
	my $dataset = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.text' ],
			'where'          => [ [ ref($self) . '.id', '=', 'my_value' ] ]
		},
		$my_id
	)->get_line_asHash(0);
	Carp::confess(
		ref($self)
		  . "::Add_2_LabBook_entry - Sorry, but we do not have a labbook entry with the id $my_id\n"
	) unless ( defined $dataset );
	$self->UpdateDataset(
		{
			'id'   => $my_id,
			'text' => $dataset->{ ref($self) . '.text' }
			  . "\n$string\n\n"
		}
	);
	$self->TouchMaster();
	return 1;
}

sub TouchMaster {
	my ($self) = @_;
	my $now = $self->getActual_timestamp();
	return $self->{LabBook_obj}->UpdateDataset(
		{ 'id' => $self->{'LabBook_id'}, 'last_modified' => "$now" } );
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

sub Add_Data_Link {
	my ( $self, $my_id, $dataset_id ) = @_;
	my $list_id = @{
		@{
			$self->getArray_of_Array_for_search(
				{
					'search_columns' => [ ref($self) . ".dataset_list_id" ],
					'where' => [ [ ref($self) . ".id", "=", "my_value" ] ]
				},
				$my_id
			)
		  }[0]
	  }[0];
	if ( $list_id == 0 ) {
		$list_id =
		  $self->{'data_handler'}->{'dataset_list'}->readLatestID() + 1;
		$self->{'dbh'}->do( "update "
			  . $self->TablName()
			  . " set dataset_list_id = $list_id where id = $my_id" )
		  or Carp::Confess(
			    ref($self)
			  . "::Update columns 'update "
			  . $self->TablName()
			  . "set dataset_list_id = $list_id where id = $my_id' did fail \n$!\n"
		  );
	}
	return $self->{'data_handler'}->{'dataset_list'}
	  ->add_to_list( $list_id, { 'id' => $dataset_id } );
}

sub readLatestID {
	my ($self) = @_;
	my ( $sql, $sth, $rv );
	$sql = $self->create_SQL_statement(
		{
			'search_columns' => [ ref($self) . '.id' ],
			'where'          => [],
			'order_by'       => [ [ 'my_value', '-', ref($self) . '.id' ] ],
			'limit'          => "limit 1"
		}
	);

	#	print "the original sql $sql\n";
	$sql =~ s/\?//;

#	print
#"we try to get the lastest ID from the database unsing this sql statement:\n$sql\n";
	unless ( $sth = $self->{'dbh'}->prepare($sql) ) {
		Carp::confess(
			ref($self)
			  . "::readLatestID -> we had an error creating the sql query: '$sql;'\n"
		);
	}
	unless ( $sth->execute() ) {
		Carp::confess(
			ref($self)
			  . "::readLatestID -> we execute failed for sql query: '$sql;'\n"
		);
	}
	$rv = $sth->fetchall_arrayref()
	  or Carp::confess(
		ref($self)
		  . "::readLatestID -> we can not fecth any data for sql query '$sql;'\n"
	  );
	if ( ref( @$rv[0] ) eq "ARRAY" ) {
		return @{ @$rv[0] }[0];
	}
	return 0;
}
1;
