package Affy_description;

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

use stefans_libs::database::expression_estimate::probesets_table;
use stefans_libs::database::external_files;
use stefans_libs::database::variable_table;
use base('variable_table');
use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "Affy_description" );
	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "Affy_descriptions";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'identifier',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'The name of the Affy Array',
			'needed'      => ''
		}
	);
	push ( @{ $hash->{'variables'} },
		{
			'name'        => 'version',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'The version of the Affy Array',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'array_type',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'manufacturer',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'cdf_file_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
			  'the ID of the cdf file needed for the apt-probeset_summary call',
			'data_handler' => 'external_files'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'pgf_file_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
			  'the ID of the cdf file needed for the apt-probeset_summary call',
			'data_handler' => 'external_files'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'clf_file_id',
			'type' => 'INTEGER UNSIGNED',
			'NULL' => '1',
			'description' =>
			  'the ID of the cdf file needed for the apt-probeset_summary call',
			'data_handler' => 'external_files'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'lib_mode',
			'type' => 'VARCHAR(20)',
			'NULL' => '0',
			'description' =>
'a small help whether we should use the -d or the -p -c prog call',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'lib_description',
			'type' => 'TEXT',
			'NULL' => '0',
			'description' =>
'where did you get the lib information from - describe the source and the modifications you did',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the probeset_id to gene symbol information will be stored in this table',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['identifier', 'version']);
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['identifier', 'version']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	$self->{'data_handler'}->{'external_files'} =
	  external_files->new( $self->{'dbh'}, $self->{'debug'} );
	return $dataset;
}

sub create_expression_estimate {
	my ( $self, $hash ) = @_;
	my $error = '';
	$error .=
	  ref($self)
	  . " create_expression_estimate I need to know what type of expression estimate you want to produce (RMA or PLIER)\n"
	  unless ( defined $hash->{'mode'}
		|| !( $hash->{'mode'} eq "RMA" || $hash->{'mode'} eq "PLIER" ) );
	$error .=
	  ref($self)
	  . " create_expression_estimate we need an array of cell file ids in order to start the process!\n"
	  unless ( ref( $hash->{'cell_files'} ) eq "ARRAY" );
	$error .=
	  ref($self)
	  . "create_expression_estimate  we need to know which array library information we should use!\n"
	  unless ( defined $hash->{'identifier'} );
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				ref($self) . ".lib_mode",
				ref($self) . ".cdf_file_id",
				ref($self) . ".pgf_file_id",
				ref($self) . ".clf_file_id"
			],
			'where' => [ [ ref($self) . '.identifier', '=', 'my_value' ] ]
		},
		$hash->{'identifier'}
	);
	unless ( ref( @$data[0] ) eq "ARRAY" ) {
		$error .= ref($self)
		  . "::create_expression_estimate -> I did not get a library information for the array identifier $hash->{'identififer'}\n";
	}
	my $configuration = configuration->new( $self->{'dbh'}, $self->{'debug'} );
	my $cmd =
	  $configuration->GetConfigurationValue_for_tag('apt-probeset-summarize');
	$cmd = 'nix_und_alles' unless ( defined $cmd );
	$error .=
	  ref($self)
	  . "::create_expression_estimate -> I do not know how to call the apt-probeset-summarize program (configuration->GetConfigurationValue_for_tag( 'apt-probeset-summarize' ) )\n"
	  unless ( -f $cmd );

	my $result_path =
	  $configuration->GetConfigurationValue_for_tag('result_path');
	$error .=
	  ref($self)
	  . "::create_expression_estimate -> I do not know where the results should go to (configuration->GetConfigurationValue_for_tag( 'result_path' ) )\n"
	  unless ( -d $result_path );

	my $data_path =
	  $configuration->GetConfigurationValue_for_tag('temp_data_path');
	$error .=
	  ref($self)
	  . "::create_expression_estimate -> I do not know where the results should go to (configuration->GetConfigurationValue_for_tag( 'temp_data_path' ) )\n"
	  unless ( -d $data_path );

	$cmd .= " -a rma-sketch "      if ( $hash->{'mode'} eq "RMA" );
	$cmd .= " -a plier-mm-sketch " if ( $hash->{'mode'} eq "PLIER" );

	Carp::confess($error."\the resulting command = $cmd\n") if ( $error =~ m/\w/ );

	if ( @{ @$data[0] }[0] eq "cdf" ) {
		my $filehandle =
		  $self->{'data_handler'}->{'external_file'}
		  ->get_fileHandle( @{ @$data[0] }[1] );
		open( CDF, ">$data_path/$hash->{'identifier'}.cdf" )
		  or Carp::confess(
"I could not create the lib file '$data_path/$hash->{'identifier'}.cdf'\n"
		  );
		while (<$filehandle>) {
			print CDF $_;
		}
		close(CDF);
		$cmd .= " -d $data_path/$hash->{'identifier'}.cdf ";
	}
	elsif ( @{ @$data[0] }[0] eq 'plg' ) {
		my $filehandle =
		  $self->{'data_handler'}->{'external_file'}
		  ->get_fileHandle( @{ @$data[0] }[2] );
		open( CDF, ">$data_path/$hash->{'identifier'}.plg" )
		  or Carp::confess(
"I could not create the lib file '$data_path/$hash->{'identifier'}.plg'\n"
		  );
		while (<$filehandle>) {
			print CDF $_;
		}
		close(CDF);
		$cmd .= " -p $data_path/$hash->{'identifier'}.plg ";
		$filehandle =
		  $self->{'data_handler'}->{'external_file'}
		  ->get_fileHandle( @{ @$data[0] }[2] );
		open( CDF, ">$data_path/$hash->{'identifier'}.clf" )
		  or Carp::confess(
"I could not create the lib file '$data_path/$hash->{'identifier'}.clf'\n"
		  );
		while (<$filehandle>) {
			print CDF $_;
		}
		close(CDF);
		$cmd .= " -c $data_path/$hash->{'identifier'}.clf ";
	}

	foreach my $cell_file ( @{ $hash->{'cell_files'} } ) {
		unless ( -f $cell_file ) {
			$error .= ref($self)
			  . "::create_expression_estimate -> I can not find the file $cell_file\n";
		}
		$cmd .= " $cell_file ";
	}

	print "we will execute the command:\n$cmd\n";
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	## we need either a cdf file or both, the clf- and pgf-files
	unless ( -f $dataset->{'cdf_file'} ) {
		$self->{'error'} .=
		  ref($self)
		  . "::DO_ADDITIONAL_DATASET_CHECKS we need either the cdf or the plg and clf files!\n"
		  unless ( -f $dataset->{'clf_file'} && -f $dataset->{'pgf_file'} );
		$dataset->{'lib_mode'} = 'plg';
	}
	else {
		$dataset->{'lib_mode'} = 'cdf';
	}
	unless ( $self->{'error'} =~ m/\w/ ) {
		foreach my $tag ( 'cdf_file', 'clf_file', 'pgf_file' ) {
			if ( -f $dataset->{$tag} ) {
				$dataset->{ $tag . "_id" } =
				  $self->{'data_handler'}->{'external_files'}->AddDataset(
					{ 'file' => $dataset->{$tag}, 'filetype' => 'data_file' } ) if ( defined $dataset->{$tag});
				delete ($dataset->{$tag});
			}
		}
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;
	$self->{'error'} .= '';
	unless ( defined $dataset->{'affy_description'} ) {
		$self->{'error'} .= ref($self)
		  . "::INSERT_INTO_DOWNSTREAM_TABLES -> we have not got the 'affy_description'\n";
	}
	my $interface = probesets_table->new( $self->{'dbh'}, $self->{'debug'} );
	$dataset->{'baseName'} = ref($self) . "_" . $dataset->{'identifier'};
	$dataset->{'table_baseString'} = $interface->AddDataset($dataset);
	return 1;
}

sub GetLibInterface {
	my ( $self, $my_id ) = @_;
	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".table_baseString" ],
			'where'          => [ [ ref($self) . ".id", "=", "my_value" ] ],
		},
		$my_id
	);
	if ( scalar(@$rv) != 1 ) {
		Carp::confess(
			    ref($self)
			  . "::GetLibInterface -> we did not get the right amount of data ("
			  . scalar(@$rv)
			  . "  for the search $self->{'complex_search'}\n" );
	}
	my $interface = probesets_table->new( $self->{'dbh'}, $self->{'debug'} );
	$interface->{_tableName} = @{ @$rv[0] }[0];
	$interface->TableName();
	return $interface;
}
1;
