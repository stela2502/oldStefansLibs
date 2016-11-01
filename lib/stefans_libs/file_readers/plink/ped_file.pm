package plink::ped_file;

#  Copyright (C) 2010-09-07 Stefan Lang

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::file_readers::plink::ped_file.pm

=head1 DESCRIPTION

A lib to read the plink ped file.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class ped_file.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {};

	bless $self, $class if ( $class eq "plink::ped_file" );

	return $self;

}

sub use_file {
	my ( $self, $file ) = @_;
	Carp::confess("I need a file!!") unless ( defined $file );
	open( IN, "<$file" ) or die "I could not read from the file $file\n$!\n";
	$self->{'file'} = \*IN;
	return 1;
}

sub store_in_WGAS_table {
	my ( $self, $WGAS_table, $rsID_2_SNP_table ) = @_;
	my $error = '';
	$error .= "I need a WGAS table interface to store the data in the database!"
	  unless ( ref($WGAS_table) eq "WGAS" );
	$error .=
"I need a rsID_2_SNP_table table interface to store the data in the database!"
	  unless ( ref($rsID_2_SNP_table) eq "rsID_2_SNP" );
	$error .=
	  "Sorry, please link me to a file first (\$self->use_file(<filename>))\n"
	  unless ( ref( $self->{'file'} ) eq "GLOB" );
	Carp::confess($error) if ( $error =~ m/\w/ );
	## now I need to read a line and process the values!
	my $IN = $self->{'file'};
	while (<$IN>) {
		chomp($_);
		$self->__insert_line( $WGAS_table, $rsID_2_SNP_table, $_ );
	}
	return 1;
}

sub WGAS_name {
	my ( $self, $name ) = @_;
	$self->{'wgas_name'} = $name if ( defined $name );
	Carp::confess("Sorry, but I need an WGAS name!\n")
	  unless ( defined $self->{'wgas_name'} );
	return $self->{'wgas_name'};
}

sub __insert_line {
	my ( $self, $WGAS_table, $rsID_2_SNP_table, $line ) = @_;
	## OK - the lines look like that: 8 8 0 0 2 2 A A G G
	## and the headers would be 'Family ID' 'Individual ID' 'Paternal ID' 'Maternal ID' 'Sex (1=male; 2=female; other=unknown)'  'Phenotype'
	## and then there comes a touple of SNP calls that have to be processed!!
	my @line = split( " ", $_ );
	my $sample_id = $self->get_sample_id( $WGAS_table, $line[1] );
	my $temp;
	if (
		ref(
			$temp = $WGAS_table->get_data_table_4_search(
				{
					'search_columns' => [ ref($WGAS_table) . ".id" ],
					'where'          => [
						[ ref($WGAS_table) . ".study_name", '=', 'my_value' ],
						[ ref($WGAS_table) . ".sample_id" , '=', 'my_value' ]
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

	#print "we have created a sample_id '$sample_id'\n";
	my ( @data_array, $position );
	$position = 0;
	print "starting to encde the SNP calls for sample $sample_id\n";
	$rsID_2_SNP_table->__init_whole_internal_dataset();
	print "The translation data was read from the database\n";
	for ( my $i = 6 ; $i < @line ; $i += 2 ) {
		$data_array[$position] = $rsID_2_SNP_table->encode_SNP(
			{
				'id'       => $position + 1,
				'Allele_1' => $line[$i],
				'Allele_2' => $line[ $i + 1 ]
			}
		);
		$position++;
	}
	print "Encoding is finished\n";
	return $WGAS_table->AddDataset(
		{
			'sample_id'        => $sample_id,
			'rsID_2_SNP_table' => $rsID_2_SNP_table->TableName(),
			'SNP_call_data'    => \@data_array,
			'study_name'       => $self->WGAS_name()
		}
	);
	print "Data was added\n";
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
			'name'                => 'lymphozytes',
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
