package file_readers::affymerix_snp_data;

#  Copyright (C) 2010-10-15 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

use base ( 'data_table' );
=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::file_readers::affymerix_snp_data.pm

=head1 DESCRIPTION

A class to read the affy SNP array calls and store thwm in a WGAS database interface.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class affymerix_snp_data.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'            => $debug,
		'arraySorter'      => arraySorter->new(),
		'header_position'  => {},
		'default_value'    => [],
		'header'           => [],
		'data'             => [],
		'index'            => {},
		'last_warning'     => '',
		'subsets'          => {}
	};

	bless $self, $class if ( $class eq "file_readers::affymerix_snp_data" );

	return $self;

}

sub store_in_WGAS_table {
	my ( $self, $WGAS_table, $rsID_2_SNP_tabl, $affy_description_table ) = @_;
	my ( $SNP_order_array, $sample_name, $data, @data, $sample_id );
	print "we will now start to import the data into the database!\n";
	## get the SNP order from the $affy_description_table
	$SNP_order_array = $affy_description_table->getAsArray('Probe Set ID');
	## OK and I need the sample ID - but that should be the column headers starting at <1>
	for ( my $i = 1 ; $i < @{ $self->{'header'} } ; $i++ ) {

		$sample_name = @{ $self->{'header'} }[$i];
		$sample_id = $self->get_sample_id( $WGAS_table, $sample_name );

		next
		  if ( defined $self->__samples_does_exist( $WGAS_table, $sample_id ) );

		## The SNPs in our dataset have to become the same order as in the data table
		$data = $self->getAsHash( 'probeset_id', $sample_name );
		print "we get data for probeset_id and '$sample_name'\n";
		my $i = 0;
		for ( my $pos = 0 ; $pos < @$SNP_order_array ; $pos++ ) {
			unless ( defined $data->{ @$SNP_order_array[$pos] }){
				$data->{ @$SNP_order_array[$pos] } = -1 ;
			}
			$data[$i++] = "$data->{@$SNP_order_array[$pos]}";
		}
		## and now add the information to the table!
		$data = undef;
#		Carp::confess(root::get_hashEntries_as_string ({
#				'sample_id'        => $sample_id,
#				'rsID_2_SNP_table' => $rsID_2_SNP_tabl->TableName(),
#				'SNP_call_data' => \@data,
#				'study_name'    => $self->WGAS_name()
#			}, 3, "we would insert this dataset if we would have other values than 0 in the 'SNP_call_data'"));
		$WGAS_table->AddDataset(
			{
				'sample_id'        => $sample_id,
				'rsID_2_SNP_table' => $rsID_2_SNP_tabl->TableName(),
				'SNP_call_data' => \@data,
				'study_name'    => $self->WGAS_name()
			}
		);
		@data = undef;
		print "done with sample $sample_name ($sample_id)\n";
	}
	return 1;
}

sub WGAS_name {
	my ( $self, $name ) = @_;
	$self->{'wgas_name'} = $name if ( defined $name );
	Carp::confess(
		"Sorry, but you called WGAS_name and I do not know the name!\n")
	  unless ( defined $self->{'wgas_name'} );
	return $self->{'wgas_name'};
}

sub __samples_does_exist {
	my ( $self, $WGAS_table, $sample_id ) = @_;
	my $temp;
	if (
		ref(
			$temp = $WGAS_table->get_data_table_4_search(
				{
					'search_columns' => [ ref($WGAS_table) . ".id" ],
					'where'          => [
						[ ref($WGAS_table) . ".study_name", '=', 'my_value' ],
						[ ref($WGAS_table) . ".sample_id",  '=', 'my_value' ]
					]
				},
				$self->WGAS_name(),
				$sample_id
			  )->get_line_asHash(0)
		) eq "HASH"
	  )
	{
		## the dataset is already present in the database!
		return $temp->{ ref($WGAS_table) . ".id" };
	}
	return undef;
}

=head get_sample_id

This function will process the sample id based on the sample lable.
If the sample is not stored in the database, it will create the sample in the database.

As this might include a lot of table usage, you might need to update the information stored in this function!

=cut

sub get_sample_id {
	my ( $self, $WGAS_table, $sample_lable ) = @_;
	my $dataset =
	  $WGAS_table->{'data_handler'}->{'sampleTable'}->get_data_table_4_search(
		{
			'search_columns' => ['sampleTable.id'],
			'where' => [ [ 'sampleTable.sample_lable', '=', 'my_value' ] ]
		},
		$sample_lable
	  )->get_line_asHash(0);
	return $dataset->{'sampleTable.id'} if ( ref($dataset) eq "HASH" );
	return $WGAS_table->{'data_handler'}->{'sampleTable'}
	  ->AddDataset( $self->__sample_creation_hash($sample_lable) );
}


sub __sample_creation_hash {
	my ( $self, $sample_lable ) = @_;
	return {
		'extraction_protocol' => {
			'name'         => 'DNA extraction',
			'description'  => 'WGAS standard DNA extraction protocol',
			'version'      => '1.0',
			'working_copy' => "just follow the kit description",
			'original_protocol_description' => {
				'file'     => 'Just_a_test_file.txt',
				'filetype' => 'text_document'
			},
			'materialList' => { 'list_id' => 1 }
		},
		'sample_lable' => $sample_lable,
		'tissue'       => {
			'organism'            => { 'organism_tag' => 'H_sapiens' },
			'name'                => 'islets',
			'extraction_protocol' => {
				'name'        => 'my test extraction_protocol',
				'version'     => "1.0",
				'description' => "a test protocol entry",
				'working_copy' =>
"1. get up in the morning\n2. eat breakfast\n3. go to work\n4. go home\n5. eat diner\n6. go to bed\n",
				'original_protocol_description' => {
					'file'     => 'Just_a_test_file.txt',
					'filetype' => 'text_document'
				},
				'materialList' => { 'list_id' => 1 }
			}
		},
		'subject' => {
			'identifier' => $sample_lable,
			'organism'   => { 'organism_tag' => 'H_sapiens' },
			'project'    => {
				'name'     => $self->WGAS_name() . " WGAS",
				'aim'      => "to make the WGAS data accessible",
				'grant_id' => 1
			}
		},
		'storage' => {
			'temperature' => "-20",
			'building'    => "60",
			'floor'       => "3",
			'room'        => '62',
			'description' => 'this is a FAKE sample you will not find it ',
			'box_label'   => 'my FAKE samples'
		},
		'initial_amount' => 1,
		'name'           => 'WGAS'
	};
}

1;
