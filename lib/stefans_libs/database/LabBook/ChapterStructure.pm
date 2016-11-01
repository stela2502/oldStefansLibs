package ChapterStructure;

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
use stefans_libs::Latex_Document;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A class that can represent a LabBook_instance chapter structure.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class ChapterStructure.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug' => $debug,
		'chapters' =>
		  { '__this__data__object__' => stefans_libs::Latex_Document->new() },
		'chapter_order' => [],
		'section_1'     => 0,
		'section_2'     => 0,
		'section_3'     => 0
	};
	$self->{'document'} = $self->{'chapters'}->{'__this__data__object__'};
	bless $self, $class if ( $class eq "ChapterStructure" );

	return $self;

}

=head2 populate_from_DB_interface ( LabBook_instance.obj )

=cut

sub Add_LabBook_Hash {
	my ( $self, $hash ) = @_;
	my ( $error, $latex_section );
	$error = '';
	foreach (
		'text',
		'creation_date',
		'header1',
		'header2',
		'header3',
		'experiment_id',
		'figure_id',
		'id'
	){
		$error .= "missing '$_'\n" unless ( defined $hash->{$_});
	}
	Carp::confess ( "Sorry, but you tried to add a not usable data hash:\n$error") if ( $error =~ m/\w/ );
	## now we need to identify the right section in the LaTeX_Document!
	$latex_section = $self->get_Latex_Section_4_headers ($hash->{'id'}, $hash->{'header1'},  $hash->{'header2'},  $hash->{'header3'});
	return $self->__ADD_db_array(
				$latex_section,
				$hash
			);
}

sub get_Latex_Section_4_headers {
	my ( $self, $id, $header1, $header2, $header3 ) = @_;
	## all latex sections will be accessible using hash $self->{'chapters'}, 
	## that will save the headers for the sections and the Latex_Sections objects
	my $return = $self->{'chapters'};
	my $i = 0;
	my $section = 'sec';
	foreach ( $header1, $header2, $header3 ){
		last unless ( $_ =~ m/\w/ );
		unless ( defined $return->{$_} ){
			$return->{$_}->{'__this__data__object__'} = $return->{'__this__data__object__'}
					  ->Section( $_, "$section" ."::". (scalar (keys %$return) )  );
		}
		$return = $return->{$_};
	#	print "we go from lable $section ";
		$section = $return->{'__this__data__object__'} -> Lable();
	#	print "to lable $section\n";
		$i ++;
	}
	return $return->{'__this__data__object__'};
}

sub populate_from_DB_interface {
	my ( $self, $LabBook_instance ) = @_;
	Carp::confess(
"Sorry, but in order to use the DB as source I need an initializes LabBook_interface object not '$LabBook_instance'\n"
	) unless ( ref($LabBook_instance) eq "LabBook_instance" );
	## I need to keep add the chapters as they have been added into the database
	my ( $text, $figure, $table, $hash );
	$self->{'LabBook_database_object'} = $LabBook_instance;

	my $section = my $sub_section = my $subsub_section = 1;

	foreach my $line_array (
		@{
			$LabBook_instance->getArray_of_Array_for_search(
				{
					'search_columns' => [
						ref($LabBook_instance) . '.text',
						ref($LabBook_instance) . '.creation_date',
						ref($LabBook_instance) . '.header1',
						ref($LabBook_instance) . '.header2',
						ref($LabBook_instance) . '.header3',
						ref($LabBook_instance) . '.experiment_id',
						ref($LabBook_instance) . '.figure_id',
						ref($LabBook_instance) . '.id'
					],
					'order_by' => [ ref($LabBook_instance) . '.id' ],
				}
			)
		}
	  )
	{
		$hash -> {'text' } = @$line_array[0];
		$hash -> {'creation_date'} = @$line_array[1];
		$hash -> {'header1'} = @$line_array[2];
		$hash -> {'header2'} = @$line_array[3];
		$hash -> {'header3'} = @$line_array[4];
		$hash -> {'experiment_id'} = @$line_array[5];
		$hash -> {'experiment_id'} = 0 unless ( defined $hash -> {'experiment_id'});
		$hash -> {'figure_id'} = @$line_array[6];
		$hash -> {'figure_id'} = 0 unless ( defined $hash -> {'figure_id'});
		
		$hash -> {'id'} = @$line_array[7];
		
		
		$self->Add_LabBook_Hash ($hash);
		next;
		
		foreach ( my $sec_id = 3 ; $sec_id < 6 ; $sec_id++ ) {
			@$line_array[$sec_id] = undef if ( @$line_array[$sec_id] eq " " );
		}
		if ( !@$line_array[3] =~ m/\w/ ) {
			## I need to remember that section
			unless ( defined $self->{'chapters'}->{ @$line_array[2] } ) {
				$self->{'chapters'}->{ @$line_array[2] } =
				  { '__this__data__object__' =>
					  $self->{'chapters'}->{'__this__data__object__'}
					  ->Section( @$line_array[2], "sec0::" . @$line_array[7] )
				  };
			}
			$self->__ADD_db_array(
				$self->{'chapters'}->{ @$line_array[2] }
				  ->{'__this__data__object__'},
				$line_array
			);
		}
		elsif ( !@$line_array[4] =~ m/\w/ ) {
			## OK we have a section - and there might be an issue with the chapter!
			unless ( defined $self->{'chapters'}->{ @$line_array[2] } ) {
				$self->{'chapters'}->{ @$line_array[2] } = {
					'__this__data__object__' =>
					  $self->{'chapters'}->{'__this__data__object__'}
					  ->Section( @$line_array[2] ),
					"sec0::" . @$line_array[7]
				};
			}
			unless (
				defined $self->{'chapters'}->{ @$line_array[2] }
				->{ @$line_array[3] } )
			{
				$self->{'chapters'}->{ @$line_array[2] }->{ @$line_array[3] } =
				  { '__this__data__object__' =>
					  $self->{'chapters'}->{ @$line_array[2] }
					  ->{'__this__data__object__'}
					  ->Section( @$line_array[3], "sec1::" . @$line_array[7] )
				  };
			}
			$self->__ADD_db_array(
				$self->{'chapters'}->{ @$line_array[2] }->{ @$line_array[3] }
				  ->{'__this__data__object__'},
				$line_array
			);
		}
		else {
			## OK we have a section - and there might be an issue with the chapter!
			unless ( defined $self->{'chapters'}->{ @$line_array[2] } ) {
				$self->{'chapters'}->{ @$line_array[2] } =
				  { '__this__data__object__' =>
					  $self->{'chapters'}->{'__this__data__object__'}
					  ->Section( @$line_array[2], "sec0::" . @$line_array[7] )
				  };
			}
			## or with the section
			unless (
				defined $self->{'chapters'}->{ @$line_array[2] }
				->{ @$line_array[3] } )
			{
				$self->{'chapters'}->{ @$line_array[2] }->{ @$line_array[3] } =
				  { '__this__data__object__' =>
					  $self->{'chapters'}->{ @$line_array[2] }
					  ->{'__this__data__object__'}
					  ->Section( @$line_array[3], "sec1::" . @$line_array[7] )
				  };
			}
			## or with the subsection ;-)
			unless (
				defined $self->{'chapters'}->{ @$line_array[2] }
				->{ @$line_array[3] }->{ @$line_array[4] } )
			{
				$self->{'chapters'}->{ @$line_array[2] }->{ @$line_array[3] }
				  ->{ @$line_array[4] } =
				  { '__this__data__object__' =>
					  $self->{'chapters'}->{ @$line_array[2] }
					  ->{ @$line_array[3] }->{'__this__data__object__'}
					  ->Section( @$line_array[4], "sec2::" . @$line_array[7] )
				  };
			}
			$self->__ADD_db_array(
				$self->{'chapters'}->{ @$line_array[2] }->{ @$line_array[3] }
				  ->{ @$line_array[4] }->{'__this__data__object__'},
				$line_array
			);
		}
	}
}

sub __ADD_db_array {
	my ( $self, $section_object, $hash ) = @_;
	my ($text, $error);
	$error = '';
	foreach (
		'text',
		'creation_date',
		'header1',
		'header2',
		'header3',
		'experiment_id',
		'figure_id',
		'id'
	){
		$error .= "missing '$_'\n" unless ( defined $hash->{$_});
	}
	$error .= "I miss the 'stefans_libs::Latex_Document::Section' object\n"
		unless (
		ref($section_object) eq "stefans_libs::Latex_Document::Section" );
	
	Carp::confess( ref($self)."::__ADD_db_array\n$error". root::get_hashEntries_as_string ($hash, 3, "In the data hash")) if ( $error =~ m/\w/);
	$section_object->Database_ID( $hash->{'id'} );
	
	$text = $section_object->AddText( $hash->{'text'} )
	  if ( $hash->{'text'} =~ m/\w/ );
	  
	if ( $hash->{'figure_id'} > 0 ) {
		## Oh we have an figure attached to that text section!
		unless ( defined $text ) {
			$text = $section_object->AddText(
				"AUTOMATIC TEXT: Today you have added a figure but no text." );
		}
		$self->{'LabBook_database_object'}->{'data_handler'}->{'figure_table'}
		  ->AddFigure_To_Latex_Figure_Obj( $hash->{'figure_id'},
			$text->Add_Figure() );
	}
	
	if ( $hash->{'experiment_id'} > 0 ) {
		## Oh we have an experiment attached to that text section!
		unless ( defined $text ) {
			$text = $section_object->AddText(
"AUTOMATIC TEXT: Today you have added an experiment that got the internal id '$hash->{'experiment_id'}' but no text."
			);
		}
		else {
			$text->AddText(
"Today you have added an experiment that got the internal id '$hash->{'experiment_id'}'.\n"
			);
		}
	}
	if ( defined $text ) {
		$text->CreationDate( $hash->{'creation_date'} . "(DB_ID=$hash->{'id'})" );
	}
	return $section_object;
}

sub Titel {
	my ( $self, $title ) = @_;
	return $self->{'document'}->Title($title);
}

sub Title {
	my ( $self, $title ) = @_;
	return $self->{'document'}->Title($title);
}

sub __encode_html {
	my ( $self, $text ) = @_;
	$text =~ s/\n\n/<\/p> <p>/g;

	#$text =~ s/\n/<BR>/g;
	return $text;
}

sub get_html_chapter {
	my ( $self, $chapter_id, $link, $add_2_chapter ) = @_;
	Carp::confess(
		ref($self)
		  . "::get_html_chapter ( $self, $chapter_id, $link, $add_2_chapter ) -> we did not get a chapter_id?"
	) unless ( defined $chapter_id );
	Carp::confess(
		ref($self)
		  . "::get_html_chapter ( $self, $chapter_id, $link, $add_2_chapter ) -> we did not get a chapter_id?"
	) unless ( defined $add_2_chapter );
	my ( $array_ref, $index, $next_id, $last_id );

	$array_ref = $self->{'document'}->get_sections_asArrayref($chapter_id);

	$index = $link;
	$index =~ s /(\d+)&/index/;

	for ( my $i = 0 ; $i < @$array_ref ; $i++ ) {
		if ( @$array_ref[$i]->Database_ID() == $chapter_id ) {
			if (
				ref( @$array_ref[ $i + 1 ] ) eq
				"stefans_libs::Latex_Document::Section" )
			{
				$next_id = @$array_ref[ $i + 1 ]->Database_ID();
			}
			else {
				$next_id = 'index';
			}
			if ( $i == 0 ) {
				$last_id = 'index';
			}
			else {
				$last_id = @$array_ref[ $i - 1 ]->Database_ID();
			}

			return {
				'last'       => $index . "/" . $last_id,
				'next'       => $link . "/" . $next_id,
				'addChapter' => $add_2_chapter . "/"
				  . @$array_ref[$i]->Database_ID(),
				'text'  => @$array_ref[$i]->As_simple_HTML(),
				'index' => $index
			};
		}
	}
	my $str = root::get_hashEntries_as_string( $array_ref, 3,
"Sorry, we do not have a Section that has the Database_ID '$chapter_id'\n"
	);
	$str =~ s/\n/<BR>\n/g;
	return { 'text' => "<h1>ERROR</h1>" . $str };
}

## the fucking add_chapter_entry is buggy without end!
## why does that thing add multiple entries for the same data??
## because it does not search through the old data - that is a bug!

sub add_chapter_entry {
	my ( $self, $hash, $problems ) = @_;
	#Carp::confess ( "you should not use this function any more!!\n");
	my $exists = 0;
	$$problems |= '';
	unless ( defined $hash->{'chapter_order'} ) {
		$hash->{'chapter_order'} = $self->{'chapter_order'};
	}
	unless ( defined $hash->{'header1'} ) {
		return 0;
	}
	unless ( $hash->{'header1'} =~ m/\w/ ) {
		return 0;
	}
	my $already_existing;
	## search through all the old data
	foreach my $level1 ( @{ $hash->{'chapter_order'} } ) {
		$$problems .= "compare '$hash->{'header1'}' to '$level1->{'name'}'\n";
		$already_existing->{ $level1->{'name'} } = 1;
		if ( $hash->{'header1'} eq $level1->{'name'} ) {
			$exists = $self->add_chapter_entry(
				{
					'chapter_order' => $level1->{'subchapter'},
					'header1'       => $hash->{'header2'},
					'header2'       => $hash->{'header3'},
					'id'            => $hash->{'id'},
					'text'          => $hash->{'text'},
					'creation_date' => $hash->{'creation_date'}
				},
				$problems
			);
		}
	}
	## Oh oh we have to create an entry!

	unless ($exists) {

		my $temp = [];
		unless ( $already_existing->{ $hash->{'header1'} } ) {
			$exists = $self->add_chapter_entry(
				{
					'chapter_order' => $temp,
					'header1'       => $hash->{'header2'},
					'header2'       => $hash->{'header3'},
					'id'            => $hash->{'id'},
					'text'          => $hash->{'text'},
					'creation_date' => $hash->{'creation_date'}
				},
				$problems
			);
			push(
				@{ $hash->{'chapter_order'} },
				{ 'name' => $hash->{'header1'}, 'subchapter' => $temp }
			);
			$$problems .=
			  "we create a new entry (name = '$hash->{'header1'}') \n"
			  unless ($exists);
		}
	}
	$hash->{'header2'} |= '';
	unless ( $hash->{'header2'} =~ m/\w/ ) {
		foreach my $level1 ( @{ $hash->{'chapter_order'} } ) {
			if ( $hash->{'header1'} eq $level1->{'name'} ) {
				$level1->{'id'} = $hash->{'id'};
				if ( defined $hash->{'text'} ) {
					$level1->{'text'} = []
					  unless ( ref( $level1->{'text'} ) eq "ARRAY" );
					push( @{ $level1->{'text'} }, $hash->{'text'} );
					$level1->{'creation_date'} = []
					  unless ( ref( $level1->{'creation_date'} ) eq "ARRAY" );
					push(
						@{ $level1->{'creation_date'} },
						$hash->{'creation_date'}
					);
				}
				return 1;
			}
		}
	}
	return $exists;
}

sub __encode_latex {
	my ( $self, $text ) = @_;
	$text =~ s/\$/\\\$/g;
	$text =~ s/>/\$>\$ /g;
	$text =~ s/{//g;
	$text =~ s/}//g;
	$text =~ s/_/\\_/g;
	$text =~ s/ä/\\"a/g;
	$text =~ s/Ä/\\"A/g;
	$text =~ s/ö/\\"o/g;
	$text =~ s/Ö/\\"O/g;
	$text =~ s/ü/\\"u/g;
	$text =~ s/Ü/\\"U/g;
	return $text;
}

=head2 write_LaTeX_File ($outfile)

This function will manage all the necessary parts in creating the LaTeX outfile and
return the name of the oputfile.

=cut

sub write_LaTeX_File {
	my ( $self, $outfile ) = @_;
	my ( @temp, $path, $filename );
	@temp     = split( "/", $outfile );
	$filename = pop(@temp);
	$path     = join( "/", @temp );
	unless ( -d $path ) {
		mkdir($path)
		  or Carp::confess("I could not create the outpath '$path'\n$!\n");
	}
	$self->{'document'}->Outpath($path);
	return $self->{'document'}->write_tex_file($filename);
}

#sub GetAsLaTEX_book_String {
#	my ($self) = @_;
#	my $data   = $self->GetAsTextStructure();
#	my $str    = '';
#	my $level;
#	my $temp;
#	foreach my $entry (@$data) {
#		if ( $entry->{'level'} == 1 ) {
#			$level = 'chapter';
#		}
#		elsif ( $entry->{'level'} == 2 ) {
#			$level = 'section';
#		}
#		else {
#			$level = 'subsection';
#		}
#		$entry->{'name'} =~ s/_/\\_/g;
#		$str .=
#		    "\\$level"
#		  . "{$entry->{'name'}}\n\\label{"
#		  . root->Latex_Label( $entry->{'chapter_nr'} ) . "}\n\n";
#		if ( ref( $entry->{'creation_date'} ) eq "ARRAY" ) {
#			for ( my $i = 0 ; $i < @{ $entry->{'creation_date'} } ; $i++ ) {
#				next unless ( @{ $entry->{'text'} }[$i] =~ m/\w/ );
#				next if ( @{ $entry->{'text'} }[$i] =~ m/ARRAY\(/ );
#
#				@{ $entry->{'text'} }[$i] =~ s/\$/\\\$/g;
#				@{ $entry->{'text'} }[$i] =~ s/>/\$>\$ /g;
#				@{ $entry->{'text'} }[$i] =~ s/{//g;
#				@{ $entry->{'text'} }[$i] =~ s/}//g;
#				$str .=
#				    '\begin{flushright}' . "\n"
#				  . @{ $entry->{'creation_date'} }[$i] . "\n"
#				  . '\end{flushright}' . "\n";
#				$temp = @{ $entry->{'text'} }[$i];
#				$temp =~ s/_/\\_/g;
#				$temp =~ s/ä/\\"a/g;
#				$temp =~ s/Ä/\\"A/g;
#				$temp =~ s/ö/\\"o/g;
#				$temp =~ s/Ö/\\"O/g;
#				$temp =~ s/ü/\\"u/g;
#				$temp =~ s/Ü/\\"U/g;
#				$temp =~ s/#/\\#/g;
#				$temp =~ s/%/\\%/g;
#				$str .= $temp . "\n";
#			}
#		}
#	}
#	my $result = $self->get_Latex_header();
#	$result =~ s/##TEXT##/$str/;
#	$str = $self->Titel();
#	$result =~ s/##TITLE##/$str/;
#	$str    =~ s/ /_/g;
#	return $result, $str;
#}

sub GetAsTextStructure {
	my ($self) = @_;
	my ( @return, $already_used );
	$self->{'section'} = $self->{'subsection'} = $self->{'subsubsection'} = 0;
	$self->__rec_GetAsTextStructure( \@return, $self->{'chapter_order'},
		\$already_used, 1 );

#Carp::confess ( root::get_hashEntries_as_string (\@return, 3, "We created this chapter_array:"));
	return \@return;
}

sub __rec_GetAsTextStructure {
	my ( $self, $list, $chapter_order, $already_used, $level, @to_entry ) = @_;

	#Carp::confess ( root::get_hashEntries_as_string (, 3, " "));
	foreach my $level1 (@$chapter_order) {
		unless (
			defined $$already_used->{ join( " ", @to_entry )
				  . $level1->{'name'} } )
		{
			$self->{ 'section_' . $level }++;
			unless ( defined $level1->{'id'} ) {
				push(
					@$list,
					{
						'name'       => "$level1->{'name'}",
						'level'      => $level,
						'chapter_nr' => $self->{'section_1'} . '.'
						  . $self->{'section_2'} . '.'
						  . $self->{'section_3'}
					}
				);
				$$already_used->{ join( " ", @to_entry ) . $level1->{'name'} } =
				  @$list - 1;
			}
			else {
				push(
					@$list,
					{
						'id'            => $level1->{'id'},
						'name'          => "$level1->{'name'}",
						'level'         => $level,
						'creation_date' => $level1->{'creation_date'},
						'text'          => $level1->{'text'},
						'chapter_nr' => $self->{'section_1'} . '.' . 1 . '.' . 1
					}
				);
				$$already_used->{ join( " ", @to_entry ) . $level1->{'name'} } =
				  @$list - 1;
			}
		}
		elsif ( defined $level1->{'id'} ) {
			push(
				@{
					@$list[
					  $$already_used->{ join( " ", @to_entry )
							. $level1->{'name'} }
					  ]->{'creation_date'}
				  },
				$level1->{'creation_date'}
			);
			push(
				@{
					@$list[
					  $$already_used->{ join( " ", @to_entry )
							. $level1->{'name'} }
					  ]->{'text'}
				  },
				$level1->{'text'}
			);
		}
		if ( defined @{ $level1->{'subchapter'} }[0] ) {
			$to_entry[ $level - 1 ] = $level1->{'name'};
			for ( my $i = $level ; $i < 3 ; $i++ ) {
				$to_entry[$i] = undef;
			}
			$self->__rec_GetAsTextStructure( $list, $level1->{'subchapter'},
				$already_used, $level + 1, @to_entry );
		}
	}
	return 1;
}

#sub get_Latex_header {
#	return '\documentclass[twocolumn]{book}
#%\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry}
#\usepackage{hyperref}
#\usepackage{graphicx}
#\usepackage{nameref}
#\usepackage{longtable}
#
#\begin{document}
#\tableofcontents
#
#\title{ ##TITLE## }
#\author{Stefan Lang}\\
#\date{' . root->Today() . '}
#\maketitle
#
###TEXT##
#
#\end{document}
#';
#}

sub GetAsLinkList {
	my ( $self, $basic_link ) = @_;
	my ( @return, $already_used );
	return $self->{'document'}->get_document_structure_as_HTML_obj($basic_link);
}

sub AsString {
	my ($self) = @_;
	return $self->{'document'}->AsString();
}

sub print {
	my ($self) = @_;
	print $self->AsString();
	return 1;
}
1;
