package nimbleGeneArrays;

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
use stefans_libs::database::nucleotide_array::oligoDB;
use stefans_libs::database::oligo2dna_register;
use stefans_libs::database::experiment;
use stefans_libs::database::variable_table;
use
  stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::ndfFile;
use stefans_libs::database::array_dataset::oligo_array_values;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A data handler class that handles downstream tables!
The class nimbleGeneFiles can handle nimbleGene array library information.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class nimbleGeneArrays.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class: new -> we definitly need a DBI object at startup\n"
	  unless ( defined $dbh );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh,
		'oligo2dna_register' => oligo2dna_register->new( )
	};

	bless $self, $class if ( $class eq "nimbleGeneArrays" );

	return $self;

}

sub expected_dbh_type {
	return "not a primary table handler";
}

sub identifyCaller {
	my ( $class, $function ) = @_;
	my $i = 0;
	my $result;
	while (1) {
		my ( $package, $filename, $line, $subroutine ) = caller( $i++ );
		if ( defined($package) && ( $package ne "main" ) ) {
			$result = $subroutine;
		}
		else {
			last;
		}
	}
	print "$class $function was called by $result!\n";
}

=head2 check_dataset

A dataset has to contain the hash entries 'identifier', 'array_type' and either 'ndf_file' or 'oligo2dna'.
If you want to add an oligonucleotide Dataset, you neet to use the class stefans_libs::database::array_dataset.

=cut

sub check_dataset {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';

	unless ( defined $dataset ) {
		$self->{error} .=
		  ref($self) . ":check_dataset -> we got no dataset to check!!\n";
		return 0;
	}
	## here we only need to identify the downstream data handling objects!
	if ( defined $dataset->{'ndf_file'} ) {
		## obviously we want to add a nimblegene library file (an oligoDB)
		$dataset->{'task'} = 'add ndf file';
		unless ( -f $dataset->{'ndf_file'} ) {
			$self->{error} .=
			    ref($self)
			  . ":check_dataset -> no nimblegene nucleotide definition file"
			  . " (.ndf; 'ndf_file') or the file '$dataset->{'ndf_file' }' can't be read\n";
			return 0;
		}
		$self->{ndfFile} = ndfFile->new();
		$self->{data} =
		  $self->{ndfFile}->GetAsFastaDB( $dataset->{'ndf_file'} );
		$self->{error} .= $self->{data}->{error}
		  if ( defined $self->{data}->{error} );
	}
	elsif ( defined $dataset->{'data'} ) {
		$dataset->{'task'} = "add oligo2dna information";
		## 'oligo2dna' lib import!;
		$self->{data} = $dataset->{'data'};
	}
	else {
		$self->{error} .= ref($self)
		  . ":check_dataset we do not know what to do with this dataset!\n";
	}

	$self->{'array_type'} = $dataset->{'array_type'};
	$self->tableBaseName("nimblegene_$dataset->{identifier}");

	return 0 if ( $self->{error} =~ m/\w/ );

	return 1;
}

sub get_Array_Lib_Interface {
	my ( $self, $dataset, $SUPER_datarow ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . ":get_Array_Lib_Interface -> we have not got a data_row from the database containing the 'table_baseString'\n"
	  unless ( defined $SUPER_datarow->{'table_baseString'} );
	
#	unless ( defined $dataset->{'genome_id'}){
#		##oops - we need to check whether we have matched this array lib to a genome!
#		## but that has to be done inside the 'oligo2dna_register'
#	}
	my $genome_dataset = {
		'id'           => $dataset->{'genome_id'},
		'organism_id'  => $dataset->{'organism_id'},
		'organism_tag' => $dataset->{'organism_tag'}
	};
	my $interface = $self->{'oligo2dna_register'}->get_Array_Lib_Interface(
		{
			'id'            => $SUPER_datarow->{'id'},
			'describing_table_name' => 'nucleotide_array_libs'
		}, 
		$genome_dataset
	);
	$self->{'error'} .= $self->{'oligo2dna_register'}->{'error'};
	return $interface;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	#print ref($self) . ":we try to execute the task '$dataset->{'task'}'\n";

	die $self->{error} unless ( $self->check_dataset($dataset) );

	die ref($self),
":AddDataset -> you have to check the dataset first ( Check_Array_Dataset )\n",
	  unless ( defined $self->{'tableBaseName'} );

	if ( $dataset->{'task'} eq "add ndf file" ) {
		my $oligoDB = oligoDB->new( $self->{dbh}, $self->{debug} );
		
		$oligoDB->create( $self->tableBaseName() );
		$oligoDB->this_AddDataset( $self->{data} );
	}
	else {
		Carp::confess(
			ref($self)
			  . ":AddDataset -> sorry, we do not know what to do with this task '$dataset->{'task'}'\n"
		);
	}

	return 0;
}

sub get_oligoPositions_in_region {
	my ( $self, $tableName, $gbFile_ids, $start, $end ) = @_;
	my $oligo2dnaDB = oligo2dnaDB->new( $self->{dbh}, $self->{debug} );
	$oligo2dnaDB->setTableBaseName($tableName);
	return $oligo2dnaDB->get_oligoPositions_in_region( $tableName, $gbFile_ids,
		$start, $end );
}

sub getDataset_from_Table {
	my ( $self, $tableName, $type ) = @_;

	die ref($self),
":getDataset_from_Table -> we need to know the type of the dataset you want to get!"
	  unless ( defined $type || $self->{supportedArrayTypes} =~ m/$type/ );

	if ( $type eq "ndf" ) {
		my $oligoDB = oligoDB->new( $self->{dbh}, $self->{debug} );
		return $oligoDB->Get_as_fastaDB($tableName);
	}
	return 0;
}

sub Get_OligoDB_4_table_baseString {
	my ( $self, $table_baseString ) = @_;
	return undef unless ( defined $table_baseString );
	my $oligoDB = oligoDB->new( $self->{dbh}, $self->{debug} );
	$oligoDB->TableName($table_baseString);
	return $oligoDB;
}

sub Match_NucleotideArray_to_Genome {
	my ( $self, $nucleotideArray_hash, $genome_hash ) = @_;
	return $self->{'oligo2dna_register'}
	  ->Match_oligoDB_to_Genome( $nucleotideArray_hash, $genome_hash );
}

sub _getLinkageInfo {
	my ($self) = @_;
	return $self->{'oligo2dna_register'}->_getLinkageInfo;

}

sub getDescription {
	return
"This class is a task-based wrapper, that can be used to convert NimbleGene ndf files to oligoDB table objects
and match these oligo databases to one of the internal genomes.\\\\ 
In the future, it should also be possible to import the NimbleGene positions files. 
But I think it is saver to match the oligos to one of our genomes to use the array....";

}

sub getPosition_for_oligoIDs {
	my ( $self, $baseString, $oligoIDs, $genomeObject ) = @_;
}

sub getSequence_for_oligoIDs {
	my ( $self, $baseString, $oligoIDs, $genomeObject ) = @_;
}

sub getAll_Oligos_asFastaDB {
	my ( $self, $baseString ) = @_;

}

sub tableBaseName {
	my ( $self, $tableBaseName ) = @_;
	if ( defined $tableBaseName ) {
		$self->{'tableBaseName'} =
		  join( "_", ( split( " ", $tableBaseName ) ) );
	}
	return $self->{'tableBaseName'};
}

1;
