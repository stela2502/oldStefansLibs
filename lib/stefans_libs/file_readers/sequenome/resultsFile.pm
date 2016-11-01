package stefans_libs_file_readers_sequenome_resultsFile;

#  Copyright (C) 2011-02-15 Stefan Lang 

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

use stefans_libs::file_readers::sequenome::resultFile::report;

use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=head1 General description

The file reader for the sequenome results.

=cut
sub new {

    my ( $class, $debug ) = @_;
    my ($self);
    $self = {
        'debug'           => $debug,
        'arraySorter'     => arraySorter->new(),
        'header_position' => { 
            'Well' => 0,
            'Assay' => 1,
            'Genotype' => 2,
            'Description' => 3,
            'Sample' => 4,
            'Operator' => 5,
        },
        'default_value'   => [],
        'header'          => [
            'Well',
            'Assay',
            'Genotype',
            'Description',
            'Sample',
            'Operator',       ],
        'data'            => [],
        'index'           => {},
        'last_warning'    => '',
        'subsets'         => {},
     	'report' => stefans_libs_file_readers_sequenome_resultFile_report ->new()
    };
    bless $self, $class if ( $class eq "stefans_libs_file_readers_sequenome_resultsFile" );

    return $self;
}

sub pre_process_array{
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	$self->{'addiational_header_hash'} = {
		'Plate Result Report' => 0,
		'Customer' => 1,
		'Project' => 2,
		'Plate' => 3,
		'Experiment' => 4,
		'Chip' => 5
	};
	my (@temp, $line);
	for ( my $i = 0; $i < 7; $i++ ){
		$line = shift ( @$data );
		chomp ($line);
		@temp = split("\t", $line );
		next if ( $i == 6); ## an empty line
		Carp::confess ( "Format Missmatch on line ".($i+1). " '$line' could not be recognized " )
			unless ( $self->{'addiational_header_hash'} ->{$temp[0]} == $i);
		if ( $i > 0 ){
			$self->{'addiational_header_hash'} ->{$temp[0]} = $temp[1];
		}
	}
	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	## now I need to ckeck how manny assays were called
	for ( my $i = 0; $i < @{$self->{'data'}}; $i ++) {
		$self->{'report'}->check_line_hash ( $self->get_line_asHash($i));
	}
	return 1;
}


sub print_report{
	my ( $self, $file ) = @_;
	return $self->{'report'} -> print ( $file );
}

sub Add_2_Header {
    my ( $self, $value ) = @_;
    return undef unless ( defined $value );
    unless ( defined $self->{'header_position'}->{$value} ) {
        Carp::confess( "You try to change the table structure - That is not allowed!\n".
            "If you really want to change the data please use ".
            "the original data_table class to modify the table structure!\n"
        ) ;
    }
    return $self->{'header_position'}->{$value};
}

=head2 Add_2_DB

I expect you to have thought about that quite extensively - OK?
I will die if you have not set my $self->project_id() to some usefull project!

This function will create a new chip entry in teh database and push all other 
information in the right tables, in case we got a 'Genotype' that differs from 'NA'.

For the chip definition we will take the header of the Sequenome results file and the project_id.
=cut

sub project_id{
	my ( $self, $project_id) = @_;
	$self->{'__project_id__'} = $project_id if ( defined $project_id);
	return $self->{'__project_id__'};
}
sub Add_2_DB{
	my ( $self, $db_interface ) = @_;
	my $project_id =  $self->project_id();
	unless ( defined $self->project_id() ){
		Carp::confess ( "A internal error occured - I do not know the project_id!\n");
	}
	unless ( ref($db_interface) eq "stefans_libs_database_sequenome_data"){
		Carp::confess ( "Sorry, but I need a dbInterface of the class 'stefans_libs_database_sequenome_data'\n")
	}
	my ($hash, $dataset, $chip_id, $assay_ids, $quality_ids );
	$assay_ids = {};
	$quality_ids = {};
	for ( my $i = 0; $i < @{$self->{'data'}}; $i++){
		$hash = $self->get_line_asHash($i);
		next if ($hash->{'Genotype'} eq "NS" );
		$dataset = {
			'chip_id' => $chip_id,
			'chip' => {
				'customer' => $self->{'addiational_header_hash'}->{'Customer'},
				'project' => $self->{'addiational_header_hash'}->{'Project'},
				'project_id' => $self->project_id(),
				'plate'=> $self->{'addiational_header_hash'}->{'Plate'},
				'experiment'=> $self->{'addiational_header_hash'}->{'Experiment'},
				'chip'=> $self->{'addiational_header_hash'}->{'Chip'}
			},
			'sample_lable' => $hash->{'Sample'},
			'assay_id' => $assay_ids->{$hash->{'Assay'}},
			'assay' => {
				'assay_name' => $hash->{'Assay'},
				'assay_description' => '',
				'calls' => 0,
				'fails' => 0
			},
			'genotype' => $hash->{'Genotype'},
			'quality_id' => $quality_ids->{$hash->{'Description'}},
			'quality' => {
				'quality_tag' => $hash->{'Description'},
				'quality_class' => $self->{'report'}->{'Description'}->{$hash->{'Description'}}
			}
		};
		$db_interface -> AddDataset ( $dataset );
		$chip_id = $dataset->{'chip_id'} if ( defined $dataset->{'chip_id'} );
		$assay_ids->{$hash->{'Assay'}} = $dataset->{'assay_id'} if ( defined $dataset->{'assay_id'} );
		$quality_ids->{$hash->{'Description'}} = $dataset->{'quality_id'} if ( defined $dataset->{'quality_id'} );
	}
	## and now we update the assay informations!
	$self-> {'report'} -> UpdateAssayInfos ( $db_interface ) ;
	return 1;
}

1;

