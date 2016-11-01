package database;
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
use stefans_libs::database::expression_estimate::CEL_file_storage;
use stefans_libs::database::expression_estimate::Affy_description;
use stefans_libs::database::expression_estimate;
#use stefans_libs::database::antibodyTable;
use stefans_libs::database::materials::materialList;
use stefans_libs::database::materials::materialsTable;
#use stefans_libs::database::antibodyTable;
use stefans_libs::database::array_dataset::oligo_array_values;
use stefans_libs::database::array_dataset;
use stefans_libs::database::creaturesTable::familyTree;
use stefans_libs::database::creaturesTable;
#use stefans_libs::database::dataset_registaration;
#use stefans_libs::database::experiment::hypothesis;
#use stefans_libs::database::experiment::partizipatingSubjects;
#use stefans_libs::database::experiment;
#use stefans_libs::database::fulfilledTask;
#use stefans_libs::database::genomeDB::genbank_flatfile_db;
#use stefans_libs::database::genomeDB::genomeImporter;
#use stefans_libs::database::genomeDB::genomeSearchResult;
#use stefans_libs::database::genomeDB::nucleosomePositioning;
#use stefans_libs::database::genomeDB;
#use stefans_libs::database::grant_table;
#use stefans_libs::database::hypothesis_table;
#use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::enrichedRegions;
#use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
#use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::pairFile;
#use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile;
#use stefans_libs::database::nucleotide_array::nimbleGeneArrays;
#use stefans_libs::database::nucleotide_array::oligo2dnaDB;
#use stefans_libs::database::nucleotide_array::oligoDB;
#use stefans_libs::database::nucleotide_array;
#use stefans_libs::database::nucleotide_array::regions_of_interest_table;
#use stefans_libs::database::organismDB;
#use stefans_libs::database::personTable;
#use stefans_libs::database::project_table;
#use stefans_libs::database::protocol_table;
use stefans_libs::database::scientistTable;
#use stefans_libs::database::scientistTable::scientificComunity;
#use stefans_libs::database::subjectTable;
#use stefans_libs::database::system_tables::configuration;
#use stefans_libs::database::system_tables::errorTable;
#use stefans_libs::database::system_tables::jobTable;
#use stefans_libs::database::system_tables::loggingTable;
#use stefans_libs::database::system_tables::thread_helper;
#use stefans_libs::database::system_tables::workingTable;
#use stefans_libs::database::tissueTable;
#use stefans_libs::database::variable_table;
#use stefans_libs::database::subjectTable::phenotype_registration;
#use stefans_libs::database::LabBook;
=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a simple container to import all database classes at once

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class database.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "database" );
  	
	die ref($self).":new -> this class is only a container to use all database classes without having to write docends of use statements\n";

  	return $self;

}


1;
