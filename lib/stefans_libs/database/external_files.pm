package external_files;

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
use stefans_libs::database::variable_table;
use stefans_libs::database::system_tables::configuration;
use File::Copy;

use base ('variable_table');

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store file references. This table can be used for pictures, text_documents and data_files (further types may be added in the future...

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class external_files.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless ( defined $dbh );

	my ($self);

	$self = {
		'dbh'                 => $dbh,
		'debug'               => $debug,
		'supported_dataTypes' => [ 'picture', 'text_document','text', 'data_file','cdf', 'pgl', 'clf', 'png', 'svg' ]
	};

	bless $self, $class if ( $class eq "external_files" );

	my $configuration = configuration->new();
	my $return        = $configuration->GetConfigurationValue_for_tag(
		'externalFiles_storage_path');
	unless ( defined $return ) {
		$configuration->AddDataset(
			{
				'tag'   => 'externalFiles_storage_path',
				'value' => "/storage/workarea/shared/stefan_l/database/"
			}
		);
		$return = $configuration->GetConfigurationValue_for_tag(
			'externalFiles_storage_path');
	}
	$self->{'data_path'} = $return;
	#warn "\n\n$class -> new() we init our table!\n";
	$self->init_tableStructure();
	#warn "and we got the result from table exists:".$self->tableExists()."\n\n\n";
	#die;
	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "external_files";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'filename',
			'type'        => 'VARCHAR (200)',
			'file_upload' => 1,
			'NULL'        => '1',
			'description' => 'the name of the file',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'filetype',
			'type' => 'VARCHAR (200)',
			'NULL' => '0',
			'description' =>
			  'the filetype (one of picture, text_document or data_file)',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'upload_time',
			'type'        => 'TIMESTAMP',
			'internal'    => 1,
			'NULL'        => '0',
			'description' => 'the time when the file was uploaded',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'mode',
			'type'        => 'VARCHAR (10)',
			'NULL'        => '0',
			'description' => 'I need to know if the file is a binary file or a normal text file',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'INDICES'} }, ['filetype'] );
	push( @{ $hash->{'UNIQUE'} },  ['filename'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['filename']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		#print "and we try to create this table!".$self->TableName()."\n";
		$self->create();
	}

	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	my $ok = 0;
	foreach my $supported ( @{ $self->{'supported_dataTypes'} } ) {
		$ok = 1 if ( $dataset->{'filetype'} eq $supported );
	}
	my @temp = split ( "/", $dataset->{'filename'});
	my $filename = $temp[@temp-1];
	my $id = $self->_return_unique_ID_for_dataset( { 'filename' => $filename});
	#Carp::confess( "$self->{'warning'}\n") if ( $self->{'warning'} =~ m/\w/);
	$dataset->{'id'} = $id if ( defined $id  );
	
	$self->{'error'} .=
	  ref($self)
	  . "check_dataset -> Sorry, but we do not support the 'filetype' $dataset->{'filetype'}\n"
	  unless ($ok);
	unless ( -f $dataset->{'filename'} ) {
		$self->{'error'} .= ref($self)
		  . "check_dataset -> Sorry, but I can not open the 'file' '$dataset->{'filename'}'\n";
	}
	return !( $self->{'error'} =~ m/\w/ );
}

=head2 post_INSERT_INTO_DOWNSTREAM_TABLES

Here we move save the external file to the storage directory for external files.

=cut

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';

	#print "\n\ncp $dataset->{'file'} $self->{'data_path'}$id.dta\n\n";
	unless ( -f "$self->{'data_path'}$id.dta" ) {
		copy( $dataset->{'filename'}, "$self->{'data_path'}$id.dta" )
		  or Carp::confess(
"File $dataset->{'filename'} cannot be copied to $self->{'data_path'}$id.dta.\n$!"
		  );
		my @temp = split ( "/", $dataset->{'filename'});
		my $filename = $temp[@temp-1];
		$self->UpdateDataset( { 'id' => $id, 'filename' => $filename});
	}
	else {
		Carp::confess ( ref($self)." - I encountered a critical error - the file already existed on this server (id = $id)\n");
	}
	return 1;
}

=head addInitialDataset

Here we do not want to init any table entries, instead, we need to clean up the storage path!

=cut 

sub addInitialDataset{
	my ( $self ) = @_;
	opendir ( DIR, "$self->{'data_path'}") or Carp::confess( "we could not open the dir $self->{'data_path'}\n");
	my @file = readdir(DIR);
	closedir ( DIR );
	foreach my $file ( @file ){
		next if ($file =~ m/^\./);
		unlink($self->{'data_path'}.$file) or Carp::confess ( "we could not unlink the files $self->{'data_path'}$file and we got the error $!\n");
		print "\nwe deleted the file $self->{'data_path'}$file\n\n";
	}
	print "we tried to delete the files $self->{'data_path'}*\n";
	return 1;
}

sub get_fileHandle{
	my ( $self, $dataset ) = @_;
	my $id;
	if ( defined $dataset->{'id'}){
		$id = $dataset->{'id'};
	}
	else {
		$id = $self->_return_unique_ID_for_dataset($dataset);
	}
	## I need to check whether the file is a binary file or not - if it is I am in trouble!
	my $info = $self->getArray_of_Array_for_search({
 	'search_columns' => [ref($self).'.mode'],
 	'where' => [[ref($self).".id", '=', 'my_value']]
 	}, $id);
 	if ( @{@$info[0]}[0] eq "binary"){
 		#warn  "sorry, but you can NOT get the data using this method - you will not be able to write the data!\n" ;
		$self->{'filemode'} = "binary";
 	}
 	else {
 		$self->{'filemode'} = "text";
 	}
	open ( DATA, "<$self->{'data_path'}$id.dta" ) or Carp::confess(ref($self)."::get_fileHandle -> we could not open the file '$self->{'data_path'}$id.dta' that got from the database for this search hash:\n".root::get_hashEntries_as_string($dataset,3,'') );
	return \*DATA;
}

sub expected_dbh_type {
	return 'dbh';
}

1;
