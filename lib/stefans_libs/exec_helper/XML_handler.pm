package XML_handler;

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
use XML::Simple;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A lib that helps to create XML job packages. I does NOT create library XML files!
Therefore it will generate a error if the 'VALUE' tag for a argument is not set, although the value is important.
The logics in this script.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class XML_handler.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'dbh' => root::getDBH( 'root', '' ),
		'XML_interface' => XML::Simple->new( ForceArray => ['CONFLICTS_WITH'],  AttrIndent => 1),
		'argument_tags' => [
			{
				'name'        => 'ARGUMENT_NAME',
				'description' => 'the command line switch for the script'
			},
			{
				'name'        => 'IS_NECESSARY',
				'description' => 'a boolean tag if the argument is needed'
			},
			{
				'name' => 'VALUE',
				'description' =>
'the value of that argument. The value will be added to the command line.'
			}
		],
		'argument_warnings' => [
			{
				'name' => 'CONFLICTS_WITH',
				'description' =>
'a list of other ARGUMENT_NAMEs, that must not be set, if this argument is set'
			}
		],
		'job_tags' => [
			{
				'name' => 'THREAD_PROVE',
				'description' =>
'a boolean argument, if the script is thread prove and should be executed using the "perl_demon.pl" wrapper'
			},
			{
				'name'        => 'SCRIPT_NAME',
				'description' => 'the name of the sript'
			},
			{
				'name' => 'DESCRIPTION',
				'description' =>
'A short description of the script. This description can be used by the GUI for help.'
			},
			{
				'name' => 'ENCAPSULATED',
				'description' =>
'wheather the executable can be prepared in a working directory before the execution.'
			},
			{
				'name'        => 'RUN_NICE',
				'description' => 'low priority for large jobs.'
			}
		],
		'dependant_tags' => {
			'THREAD_PROVE' => {
				'equals'            => 1,
				'additionalEntries' => [ ]
			  }

		},
		'dataset' => {}
	};

	bless $self, $class if ( $class eq "XML_handler" );

	return $self;

}

sub _add_argument_tags{
	my ( $self, $dataset) = @_;
	$self->{error} = $self->{warning} = '';
	die $self->{error} unless ($self->_check_arguments ( { "arguments" => [ $dataset ]}));
	unless ( defined $self->{'dataset'} -> {"arguments"}){
		$self->{'dataset'} -> {"arguments"} = [];
	}
	push ( @{$self->{'dataset'} -> {"arguments"}}, $dataset);
	return 1;
}

sub _add_job_tags{
	my ( $self, $dataset) = @_;
	$self->{error} = $self->{warning} = '';
	die $self->{error} unless ($self->_check_job_tags (  { 'executable' => $dataset } ) );
	$self->{'dataset'} ->  {'executable'} = $dataset;
	return 1;
}

sub _check_job_tags{
	my ( $self, $job_hash ) = @_;
	
	foreach my $tag ( @{ $self->{'job_tags'} } ) {
		$self->{error} .=
		  ref($self)
		  . ":print_XML_job_description -> each job needs '$tag->{name}' tag ($tag->{description})!\n"
		  unless ( defined $job_hash->{'executable'}->{ $tag->{'name'} } );
		if ( defined $self->{'dependant_tags'}->{ $tag->{name} }
			&& $self->{'dependant_tags'}->{ $tag->{name} }->{'equals'} eq
			$job_hash->{'executable'}->{ $tag->{'name'} } )
		{
			## there are some XML entries, that depend on that entry - we have to check for them!
			foreach my $add_tag (
				@{
					$self->{'dependant_tags'}->{ $tag->{name} }
					  ->{'additionalEntries'}
				}
			  )
			{
				$self->{error} .=
				  ref($self)
				  . ":print_XML_job_description -> we miss the depending tag $add_tag->{'name'} (downstream of $tag->{name})\n"
				  unless (
					defined $job_hash->{'executable'}->{ $add_tag->{'name'} } )
				  ;
			}
		}
	}
	return 1;
}

sub _check_arguments{
	my ( $self, $job_hash ) = @_;
	foreach my $argument ( @{ $job_hash->{'arguments'} } ) {
		unless ( ref($argument) eq "HASH" ) {
			$self->{error} .= ref($self)
			  . ":print_XML_job_description -> each argument has to be a hash!\n";
			next;
		}
		foreach my $tag ( @{ $self->{'argument_tags'} } ) {
			if ( $tag->{'name'} eq "VALUE" ){
				next if ( ! $argument->{'IS_NECESSARY'} && ! defined $argument->{'VALUE'} );
			} 
			$self->{error} .=
			  ref($self)
			  . ":print_XML_job_description -> each argument needs a '$tag->{name}' tag ($tag->{description})!\n"
			  unless ( defined $argument->{ $tag->{'name'} } );
		}
	}
	return 1;
}

sub _check_jobHash {
	my ( $self, $job_hash ) = @_;
	$self->{error} = $self->{warning} = '';

	$self->_check_job_tags($job_hash);

	$self->{error} .=
	  ref($self)
	  . ":print_XML_job_description -> we need a list (array ref) of arguments!"
	  unless ( defined defined $job_hash->{'arguments'} );
	## and now we need to verify the arguments??  - NO that has to be done in the GUI!
	## We do not need to do that here!
	## we will die anyways if it is not doable! ;-)
	$self->_check_arguments($job_hash);
	
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

=head2 print_XML_job_description

The function needs a job description hash as only argument.
THe job description hash is defined using the two global variables 'argument_tags' and 'job_tags'.
All entries in the that are connected to the arguments of the executable are described using the 'argument_tags',
whereas the actual script is described using the 'job_tags'. Please refere to the code to get details of which tags are needed.

=cut

sub print_XML_job_description_2_file {
	my ( $self, $job_hash, $filename ) = @_;
	die $self->{error} unless ( $self->_check_jobHash($job_hash) );
	my ( $writer, $file_str );
	$file_str = $self->{'XML_interface'}->XMLout($job_hash);

#print ref($self),"we have encoded the hash into a XML file structure!\nDoes it look good??\n",$file_str;
	if ( defined $filename ) {
		open( OUT, ">$filename" )
		  or die "we could not create the file '$filename'\n";
		print OUT $file_str;
		close(OUT);
		print "We have written the XML file to '$filename'\n";
	}
	return $file_str;
}

sub read_XML_job_description_from_file {
	my ( $self, $filename ) = @_;
	die ref($self),
	  ":read_XML_job_description_from_file -> that is no file: '$filename'"
	  unless ( -f $filename );
	return $self->{'XML_interface'}->XMLin($filename);
}

sub get_script_cmd_from_xml_file {
	my ( $self, $xml_file ) = @_;
	my ( $dataHash, $cmd );
	$cmd      = '';
	$dataHash = $self->read_XML_job_description_from_file($xml_file);
	$self->{'last_data_hash'} = $dataHash;
	if ( $dataHash->{'executable'}->{'SCRIPT_NAME'} =~ m/\w/ ) {
		$cmd .= $dataHash->{'executable'}->{'SCRIPT_NAME'} . " ";
	}
	else {
		$self->{error} .= ref($self)
		  . ":get_script_cmd_from_xml_file -> there is no SCRIPT_NAME!\n";
	}
	foreach my $arg ( @{ $dataHash->{arguments} } ) {
		$cmd .= "-" . $arg->{'ARGUMENT_NAME'} . " \"" . $arg->{'VALUE'} . "\" " if ( defined $arg->{'VALUE'});
		$self->{error} .=
		  ref($self)
		  . ":get_script_cmd_from_xml_file -> there is no ARGUMENT_NAME in one argument!\n"
		  unless ( $arg->{'ARGUMENT_NAME'} =~ m/[\w]/ );
		$self->{error} .=
		  ref($self)
		  . ":get_script_cmd_from_xml_file -> there is no VALUE in one argument!\n"
		  if ( ! $arg->{'VALUE'} =~ m/[\w\d]/ && $arg->{'IS_NECESSARY'} );
	}
	return $cmd;
}

sub is_threadable {
	my ($self) = @_;
	die ref($self), "is_threadable -> we have no data!\n"
	  unless ( ref( $self->{'last_data_hash'} ) eq "HASH" );
	return $self->{'last_data_hash'}->{'executable'}->{'THREAD_PROVE'};
}

sub Get_FormBuilder_Fields {
	my ( $self, $xml_file ) = @_;
	return [] unless ( -f $xml_file );
	$self->read_XML_job_description_from_file($xml_file);
	
}

1;
