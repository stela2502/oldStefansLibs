package WGAS;

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
use stefans_libs::database::sampleTable;
use stefans_libs::database::WGAS::rsID_2_SNP;
use stefans_libs::file_readers::plink;

use stefans_libs::database::variable_table::queryInterface;

use base variable_table;

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

	bless $self, $class if ( $class eq "WGAS" );
	$self->init_tableStructure();

	return $self;

}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "WGAS";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'study_name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => 'The name of the WGAS analysis',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'sample_id',
			'type'         => 'VARCHAR (200)',
			'NULL'         => '0',
			'data_handler' => 'sampleTable',
			'description'  => 'The internal link to the sample id',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'rsID_2_SNP_table',
			'type' => 'VARCHAR (200)',
			'NULL' => '0',
			'description' =>
'The table containing the rsID_2_SNP information for this array design',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'description',
			'type'        => 'TEXT',
			'NULL'        => '1',
			'description' => 'The description of the WGAS analysis',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'creation_time',
			'type'        => 'TIMESTAMP',
			'NULL'        => '0',
			'hidden'      => 1,
			'description' => 'the time the data was uploaded the first time',
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '1',
			'description' => 'the table name for the SNP_calls table'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, [ 'study_name', 'sample_id' ] );

	$self->{'table_definition'} = $hash;
	$self->{'UNIQUE_KEY'} = [ 'study_name', 'sample_id' ];

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
	$self->{'data_handler'}->{'sampleTable'} =
	  sampleTable->new( $self->{'dbh'}, $self->{'debug'} );
	return $dataset;
}

=head2 Create_rsID_2_SNP_table

This function should be used if you want to create a new study!
You need to give me an has that contains a 'rsID_2_SNP_table' name that 
you need to add the SNP_calls and a 'rsID_2_SNP_data' array, that contains the RS information hashes.
They look like {'rsID' => <rs\d+>, 'minorAllele' => [AGTC], 'majorAllele' => [AGTC] }.
We will create an error and die if the stucture is not like that.

This function will return ture if we did not find a problem or it will siply die!

=cut

sub ___check_rsID_2_SNP_table_data {
	my ( $self, $dataset ) = @_;
	my $error = '';
	unless ( ref($dataset) eq "ARRAY" ) {
		return
"Create_rsID_2_SNP_table -> we need an array containg the rsID informations!\n";
	}
	for ( my $i = 0 ; $i < @{$dataset} ; $i++ ) {
		foreach (qw/rsID minorAllele majorAllele/) {
			$error .= "position $i - we do not have a $_\n"
			  unless ( defined @{$dataset}[$i]->{$_} );
		}
	}
	return $error;
}

sub Create_rsID_2_SNP_table {
	my ( $self, $dataset ) = @_;
	my $error;
	unless ( defined $dataset->{'rsID_2_SNP_table'} ) {
		$error .= "we need a 'rsID_2_SNP_table' table name\n";
	}
	elsif ( $self->tableExists( $dataset->{'rsID_2_SNP_table'} ) ) {
		return 1;    ## the data has aready been inserted!
	}
	$error .=
	  $self->___check_rsID_2_SNP_table_data( $dataset->{'rsID_2_SNP_data'} );
	Carp::confess($error) if ( $error =~ m/w/ );
	my $rsID_SNP = rsID_2_SNP->new( $self->{'dbh'}, $self->{'debug'} );
	$rsID_SNP->setTableBaseName( $dataset->{'rsID_2_SNP_table'} );
	foreach my $data ( @{ $dataset->{'rsID_2_SNP_data'} } ) {
		$rsID_SNP->AddDataset($data);
	}
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	## I need to check if the study_name already has a rsID_2_SNP_table
	## As I can not create that on the fly!
	unless ( defined $dataset->{'rsID_2_SNP_table'} ) {
		## let's hpe that we have at least one other dataset for that study
		unless ( defined $dataset->{'study_name'} ) {
			$self->{'error'} .= ref($self)
			  . "::DO_ADDITIONAL_DATASET_CHECKS - we do nether have a rsID_2_SNP_table name nor a study_name - final!";
		}
		else {
			my $data = $self->get_data_table_4_search(
				{
					'search_columns' => [ ref($self) . '.rsID_2_SNP_table' ],
					'where' =>
					  [ [ ref($self) . '.study_name', '=', 'my_value' ] ],
					'limit' => "limit 1"
				},
				$dataset->{'study_name'}
			)->get_line_asHash(0);
			unless ( defined $data ) {
				$self->{'error'} .= ref($self)
				  . "::DO_ADDITIONAL_DATASET_CHECKS - we do not have a rsID_2_SNP_table name and no dataset for study '$dataset->{'study_name'}'\n";
			}
			elsif (
				$self->tableExists(
					$data->{ ref($self) . '.rsID_2_SNP_table' }
				)
			  )
			{
				$dataset->{'rsID_2_SNP_table'} =
				  $data->{ ref($self) . '.rsID_2_SNP_table' };
			}
			else {
				$self->{'error'} .= ref($self)
				  . "::DO_ADDITIONAL_DATASET_CHECKS - we do not have data for the rsID_2_SNP_table\n";
			}
		}
	}
	unless ( defined $dataset->{'table_baseString'} ) {
		$dataset->{'table_baseString'} = 'undefined';
	}
	unless ( ref( $dataset->{'SNP_call_data'} ) eq "ARRAY" ) {
		$self->{'error'} .=
		  "we definitely need an array of <SNP_call_data> values\n";
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub ___drop_table {
	my ( $self, $table_base_name ) = @_;

	my $sql = "DROP table $table_base_name";

	if ( $self->tableExists($table_base_name) ) {
		$self->{dbh}->do($sql)
		  or Carp::confess(
			    ref($self)
			  . ":create -> we could not execute '$sql;'\n"
			  . $self->{dbh}->errstr() );
		$self->{__tableNames} = undef;

		#print "we have executed the SQL '$sql';\n";
	}

	if ( $self->{debug} ) {
		print ref($self), ":create -> we run $sql\n";
	}

	return 1;
}

sub _dropTable {
	my ( $self, $table_base_name ) = @_;

	## I need to drop some downstream tables if I drop myselve!
	$table_base_name = $self->TableName($table_base_name);
	return 0 unless ( $self->tableExists($table_base_name) );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [
				ref($self) . ".table_baseString",
				ref($self) . ".rsID_2_SNP_table"
			],
			'where' => []
		}
	);
	my $table_names = {};
	foreach my $table_name_array ( @{ $data->{'data'} } ) {
		foreach (@$table_name_array) {

			#print "we got the downstream table $_\n";
			$table_names->{$_} = 1;
		}
	}
	foreach ( keys %$table_names ) {

		#print "we try to drop the table '$_'\n";
		$self->___drop_table($_);
	}
	$self->___drop_table($table_base_name);
	return 1;
}

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;

#Carp::confess ( root::get_hashEntries_as_string ($dataset, 3, "we have created a WGAS table entry with the id $id using this hash:"));

	my ( $interface, $sample_ids ) =
	  $self->GetDatabaseInterface_for_dataset($dataset);
	if ( $dataset->{'table_baseString'} eq "undefined" ) {
		$dataset->{'sample_id'} = $dataset->{'sample'}->{'id'}
		  unless ( defined $dataset->{'sample_id'} );
		$dataset->{'table_baseString'} =
		  join( "_", $dataset->{'study_name'}, $dataset->{'sample_id'} );
		$self->UpdateDataset(
			{
				'id'               => $id,
				'table_baseString' => $dataset->{'table_baseString'}
			}
		);
	}
	$interface->Add_SNP_call_data( $dataset->{'SNP_call_data'},
		$dataset->{'table_baseString'} );

	$self->{'error'} .= '';
	return 1;
}

=head2 export_4_PHASE

This function need an hash containing the variables 
'study_name', 'rsID' and 'outfile'.
An optional value is the 'sample_id' to restrict the result to a certain list of samples.

The function will get all variables from the database and print them as PHASE input file.

=cut

sub export_4_PHASE {
	my ( $self, $hash ) = @_;
	Carp::confess("Implement me!");
}

=head store_bim_file

This function will store some of the data stored in a bim file in a rsID_2_SNP table object.

We need the name of the bim file and a name for the table as arguments 1 and 2.

=cut

sub store_bim_file {
	my ( $self, $bim_file_name, $table_name ) = @_;
	my $rsID_SNP = rsID_2_SNP->new( $self->{'dbh'}, $self->{'debug'} );
	$rsID_SNP->TableName($table_name);
	my $bim_file = plink::bim_file->new();
	$bim_file->read_file($bim_file_name);
	$bim_file->store_in_rsID_2_SNP_table($rsID_SNP);
	return $rsID_SNP;
}

=head2 store_affymetrix_snp_description_file (file_readers::affymetrix_snp_description object, Database_Table_NAME )

This function will read a standars Affymetrix SNP description file and put the most important informations into the datbase.

=cut

sub store_affymetrix_snp_description_file {
	my ( $self, $table, $table_name ) = @_;
	my $rsID_SNP = rsID_2_SNP->new( $self->{'dbh'}, $self->{'debug'} );
	if ( $self->tableExists($table_name."_rsID_2_SNP")){
		$rsID_SNP->TableName($table_name);
		return $rsID_SNP;
	}
	$rsID_SNP->TableName($table_name);
	Carp::confess("I need a file_readers::affymetrix_snp_description object!")
	  unless ( ref($table) eq 'file_readers::affymerix_snp_description' );
	$table->store_in_rsID_2_SNP_table($rsID_SNP);
	return $rsID_SNP;
}

=head2 store_affymetrix_data ( $desc_file_name, $data_file_name, $table_name )

This function will create all necessars tables to store the affymetrix informations in the two files $desc_file_name and $data_file_name.
The files are read using the classes file_readers::affymetrix_snp_description and file_readers::affymetrix_snp_data.

=cut

sub store_affymetrix_data {
	my ( $self, $hash ) = @_;
	my ($desc_file_name, $data_file_name, $table_name);
	$desc_file_name = $hash->{'affy_descr_file'};
	$data_file_name = $hash->{'affy_data_file'};
	$table_name = $hash->{'WGAS_name'};
	my $table = file_readers::affymerix_snp_description->new();
	print "we check the memory usage before the read of the file '$desc_file_name'\n";
	system ( "free -m" );
	$table->read_file($desc_file_name);
	print "After the read we do check that once more:\n";
	system ( "free -m" );
	my $rsID_2_SNP = $self->store_affymetrix_snp_description_file( $table, $table_name );
	my $affy_snp_data = file_readers::affymerix_snp_data ->new();
	$affy_snp_data -> WGAS_name ( $table_name );
	print "now we will read in the data file '$data_file_name'\n";
	$affy_snp_data -> read_file ( $data_file_name );
	print "that has been done - lets see hoe thw memory is used...\n";
	system ( "free -m" );
	#die "The pure reading should already have exceeded our memory!\n";
	print "and now we try to import this data into the database!\n";
	$affy_snp_data -> store_in_WGAS_table( $self, $rsID_2_SNP, $table );
	print "done!\n";
	return $rsID_2_SNP;
}

sub store_ped_file {
	my ( $self, $hash ) = @_;
	Carp::confess("I need a has to start that function!\n")
	  unless ( ref($hash) eq "HASH" );
	my $error = '';
	$error .= "store_ped_file - I need the 'ped_file'\n"
	  unless ( defined $hash->{'ped_file'} );
	$error .= "store_ped_file - I need the 'rsID_2_SNP' object\n"
	  unless ( ref( $hash->{'rsID_2_SNP'} ) eq 'rsID_2_SNP' );
	$error .= "store_ped_file - I need the 'WGAS_name'\n"
	  unless ( defined $hash->{'WGAS_name'} );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my $ped_file = plink::ped_file->new();
	$ped_file->use_file( $hash->{'ped_file'} );
	$ped_file->WGAS_name( $hash->{'WGAS_name'} );
	$ped_file->store_in_WGAS_table( $self, $hash->{'rsID_2_SNP'} );
	return 1;
}

sub GetDatabaseInterface_for_dataset {
	my ( $self, $dataset ) = @_;
	Carp::confess("Sorry, but i need a hash at strtup!\n")
	  unless ( ref($dataset) eq "HASH" );
	Carp::confess(
"Sorry, but at least the 'study_name' is necessary to get the interface!\n"
	) unless ( defined $dataset->{'study_name'} );
	## if you want you can also get a interface stuffed with a lot of sample datasets!
	my ( $data, $first_line, $hash, $interface, @sample_Labels );
	if ( defined $dataset->{'sample_id'} ) {
		$data = $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . '.rsID_2_SNP_table',
					ref($self) . '.table_baseString',
					'sampleTable.sample_lable'
				],
				'where' => [
					[ ref($self) . '.study_name', '=', 'my_value' ],
					[ ref($self) . '.sample_id',  '=', 'ma_value' ]
				]
			},
			$dataset->{'study_name'},
			$dataset->{'sample_id'}
		);
	}
	else {
		$data = $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . '.rsID_2_SNP_table',
					ref($self) . '.table_baseString',
					'sampleTable.sample_lable'
				],
				'where' => [ [ ref($self) . '.study_name', '=', 'my_value' ] ]
			},
			$dataset->{'study_name'}
		);
	}
	unless ( defined $data ) {
		Carp::confess(
"Sorry, I do not have an dataset to give to you - please use the AddDataset first!"
		);
	}
	if ( scalar( @{ $data->{'data'} } ) > 50 ) {
		$interface = variable_table::queryInterface->new();

		for ( my $a = 0 ; $a < @{ $data->{'data'} } ; $a += 50 ) {
			my $part_interface =
			  rsID_2_SNP->new( $self->{'dbh'}, $self->{'debug'} );
			$part_interface->{'_tableName'} =
			  $data->get_line_asHash(0)->{ ref($self) . '.rsID_2_SNP_table' };
			for ( my $i = $a ;
				$i < @{ $data->{'data'} } && $i < $a + 50 ; $i++ )
			{
				$hash = $data->get_line_asHash($i);
				$part_interface->Add_SNP_calls_Table(
					{
						'tableName' =>
						  $hash->{ ref($self) . '.table_baseString' },
						'sample_lable'  => $hash->{'sampleTable.sample_lable'},
						'tableBaseName' => $dataset->{'study_name'},
						'sample_id'     => $dataset->{'sample_id'}
					}
				);
			}
			$interface->AddTable($part_interface);
			push( @sample_Labels, $part_interface->Sample_Lables() );
		}
	}
	else {
		$interface = rsID_2_SNP->new( $self->{'dbh'}, $self->{'debug'} );
		$interface->{'_tableName'} =
		  $data->get_line_asHash(0)->{ ref($self) . '.rsID_2_SNP_table' };
		### NO - that will not work  - unfortunately!
		### I need to restrict the amount of table in one interface,
		### but create some more interfaces so.
		## That is the day I start to use the queryInterface class!
		for ( my $i = 0 ; $i < @{ $data->{'data'} } ; $i++ ) {
			$hash = $data->get_line_asHash($i);
			$interface->Add_SNP_calls_Table(
				{
					'tableName' => $hash->{ ref($self) . '.table_baseString' },
					'sample_lable'  => $hash->{'sampleTable.sample_lable'},
					'tableBaseName' => $dataset->{'study_name'},
					'sample_id'     => $dataset->{'sample_id'}
				}
			);
		}
		@sample_Labels = $interface->Sample_Lables();
	}
	return $interface, [@sample_Labels];
}

sub expected_dbh_type {
	return 'dbh';

	#return 'database_name';
}

1;
