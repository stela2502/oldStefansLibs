package affy_cell_flatfile;

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
use PerlIO::gzip;

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

new returns a new object reference of the class affy_cel_flatfile.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless ( defined $dbh );

	my ($self);

	$self = {
		'dbh'   => $dbh,
		'debug' => $debug
	};

	bless $self, $class if ( $class eq "affy_cell_flatfile" );

	my $configuration = configuration->new();
	my $return        = $configuration->GetConfigurationValue_for_tag(
		'affy_cellfiles_storage_path');
	unless ( defined $return ) {
		$configuration->AddDataset(
			{
				'tag'   => 'affy_cellfiles_storage_path',
				'value' => "/database/affy_cell_Files/"
			}
		);
		$return = $configuration->GetConfigurationValue_for_tag(
			'affy_cellfiles_storage_path');
	}
	$self->{'data_path'} = $return;
	unless ( -d $self->{'data_path'} ) {
		mkdir( $self->{'data_path'} )
		  or Carp::confess(
			ref($self)
			  . "::new -> I can not create the storage path $self->{'data_path'}\n$!\n"
		  );
	}
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "affy_cell_files";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'file',
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
			'name' => 'array_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '0',
			'description' =>
			  'the id in the array_datasets table, that describes this dataset',
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
	push( @{ $hash->{'UNIQUE'} }, ['array_id'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['array_id']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}

	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	unless ( -f $dataset->{'file'} ) {
		$self->{'error'} .= ref($self)
		  . "check_dataset -> Sorry, but I can not open the 'file' $dataset->{'file'}\n";
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
		use Compress::Zlib;

		open( FILE, $dataset->{'file'} );
		binmode FILE;

		my $buf;
		my $gz = gzopen( "$self->{'data_path'}$id.dta", "wb" );
		if ( !$gz ) {
			print "Unable to write $self->{'data_path'}$id.dta $!\n";
			exit;
		}
		else {
			while ( my $by = sysread( FILE, $buf, 4096 ) ) {
				if ( !$gz->gzwrite($buf) ) {
					print
"Zlib error writing to $self->{'data_path'}$id.dta: $gz->gzerror\n";
					exit;
				}
			}
			$gz->gzclose();
			print
"'$dataset->{'file'}' GZipped to '$self->{'data_path'}/$id.dta'\n";

		}
		my $sql =
		    "UPDATE "
		  . $self->TableName
		  . " SET file = '$self->{'data_path'}/$id.dta' where id = $id;";
		$self->{'dbh'}->do($sql)
		  or Carp::confess( "OOPS - we could not execute '$sql;'\n"
			  . $self->{'dbh'}->errstr() );
	}
	return 1;
}

sub get_fileHandle {
	my ( $self, $dataset ) = @_;
	my $rv = $self->GET_entries_for_UNIQUE( ['file'], $dataset );
	open( DATA, "<:gzip", $rv->{'file'} )
	  or Carp::confess(
		    ref($self)
		  . "::get_fileHandle -> we could not open the file '$rv->{'file'}' that got from the database for this search hash:\n"
		  . root::get_hashEntries_as_string( $dataset, 3, '' ) );
	return \*DATA;
}

sub expected_dbh_type {
	return 'dbh';

	#return "not a databse interface";
	#return "database_name";
}

1;
