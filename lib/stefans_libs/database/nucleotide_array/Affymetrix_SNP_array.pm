package Affymetrix_SNP_array;

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
use
  stefans_libs::database::nucleotide_array::Affymetrix_SNP_arrays::affy_SNP_info;
use stefans_libs::database::external_files;
use stefans_libs::array_analysis::dataRep::affy_SNP_annot;
use stefans_libs::database::variable_table;
use base ('variable_table');

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "Affymetrix_SNP_array" );

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
	$hash->{'table_name'} = "Affymetrix_array_lib";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'identifier',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the Affymetrix array name',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'cdf_file_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the affy cdf file (will be downloaded)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chrX_file_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the affy chrX file (will be downloaded)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'chrY_file_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the affy chrY file (will be downloaded)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'bird1_model_file_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the affy birdseed version 1 modles (will be downloaded)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'bird2_model_file_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the affy birdseed version 2 modles (will be downloaded)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'special_SNPs_file_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '1',
			'description' => 'the affy special_SNPs file (will be downloaded)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the info where to put the affy annotation informations to (will be downloaded)',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['identifier'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['identifier']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $dataset;
}

sub get_apt_call {
	my ( $self) = @_;
	return undef;
}

sub DO_ADDITIONAL_DATASET_CHECKS{
	my ( $self, $dataset ) = @_;
	## here we have to download the affymetrix source files!
	## but that has to wait! most importantly we need to store the SNP data!!
	$self->{error} .= ref($self)."::DO_ADDITIONAL_DATASET_CHECKS -> we need some data to store in the table (annot_file)" unless (  defined $dataset->{'annot_file'} || -f $dataset->{'annot_file'} );
	return 1 unless ( $self->{'error'} =~ m/\w/);
	return 0;
}

sub INSERT_INTO_DOWNSTREAM_TABLES{
	my ( $self, $dataset ) = @_;
	my $affy_SNP_annot = affy_SNP_annot->new($dataset->{'annot_file'});
	my $affy_SNP_info = affy_SNP_info->new( $self->{'dbh'}, $self->{'debug'});
	$affy_SNP_info->TableBaseName($dataset->{'table_baseString'});
	$affy_SNP_annot->AddToDatabase ( $affy_SNP_info );
	return 1;
}

sub get_Array_Lib_Interface{
	my ( $self, $dataset) = @_;
	my $affy_SNP_info = affy_SNP_info->new( $self->{'dbh'}, $self->{'debug'});
	$affy_SNP_info->TableBaseName($dataset->{'table_baseString'});
	return $affy_SNP_info;
}

1;
