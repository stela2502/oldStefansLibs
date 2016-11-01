package stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description;

#  Copyright (C) 2011-03-03 Stefan Lang

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

use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::genomeDB;

use base 'data_table';

=head1 General description

This interface is to add the cis gene information to a rsID based analysis of the SNP 2 gene correlations.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'rsID'                        => 0,
			'Correlating genes (p value)' => 1
		},
		'default_value' => [],
		'header'        => [ 'rsID', 'Correlating genes (p value)' ],
		'data'          => [],
		'index'         => {},
		'last_warning'  => '',
		'subsets'       => {},
		'accepted_new'  => {
			'rsID (closest gene)'  => 1,
			'chr,'                 => 1,
			'rs position'          => 1,
			'gene start'           => 1,
			'gene end'             => 1,
			'distance SNP to gene' => 1,
			'GWAS p value' => 1
		}
	};
	bless $self, $class
	  if ( $class eq
"stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description"
	  );

	return $self;
}

## two function you can use to modify the reading of the data.

sub pre_process_array {
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	return 1;
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		unless ( $self->{'accepted_new'}->{$value} ) {
			Carp::confess("You must not add that column '$value'!\n")
			  unless ( $self->__check_accepted_new_partial($value) );
		}
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] = $value;
		${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ] =
		  '';
	}
	return $self->{'header_position'}->{$value};
}

sub Add_Closest_genes {
	my ( $self, $organism_tag, $max_distance ) = @_;

	$max_distance = 1E6 unless ( defined $max_distance );
## Do whatever you want!
	my ( $sql, $genome, $genomeInterface );
	$genome = genomeDB->new();
	$genomeInterface =
	  $genome->GetDatabaseInterface_for_Organism($organism_tag);
	$genomeInterface = $genomeInterface->get_rooted_to('gbFilesTable');
	$genomeInterface = $genomeInterface->get_SNP_Table_interface();

	my $data_table = $genomeInterface->get_data_table_4_search(
		{
			'search_columns' => [
				'gbFeaturesTable.name',  'SNP_table.rsID',
				'gbFeaturesTable.start', 'gbFeaturesTable.end',
				'SNP_table.position'
			],
			'where' => [
				[ 'gbFeaturesTable.tag', '=', 'my_value' ],
				[
					[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
					'>',
					[
						'chromosomesTable.chr_start', '+',
						[ 'gbFeaturesTable.start', '-', 'my_value' ]
					]
				],

				[
					[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
					'<',
					[
						'chromosomesTable.chr_start', '+',
						[ 'gbFeaturesTable.end', '+', 'my_value' ]
					]
				],
				[ 'SNP_table.rsID', '=', 'my_value' ]
			]
		},
		'gene',
		$max_distance,
		$max_distance,
		$self->getAsArray('rsID')
	);
	$self->Add_2_Description( "We added the closest gene using this search: "
		  . $genomeInterface->{'complex_search'} );
	$data_table->set_HeaderName_4_position( 'cis gene',    0 );
	$data_table->set_HeaderName_4_position( 'rsID',        1 );
	$data_table->set_HeaderName_4_position( 'gene start',  2 );
	$data_table->set_HeaderName_4_position( 'gene end',    3 );
	$data_table->set_HeaderName_4_position( 'rs position', 4 );
	## and now I need to create the sorting entry
	$data_table->Add_2_Header('distance SNP to gene');
	$data_table->define_subset( 'dist_calc',
		[ 'gene start', 'gene end', 'rs position' ] );
	my ( $upper, $lower );
	## Calculate the smallest distance to either start or end
	$data_table->calculate_on_columns(
		{
			'function' => sub {
				$upper = $lower = 0;
				$upper = ( ( $_[0] - $_[2] )**2 )**0.5;
				$lower = ( ( $_[1] - $_[2] )**2 )**0.5;
				return $upper if ( $upper < $lower );
				return $lower;
			},
			'data_column'   => 'dist_calc',
			'target_column' => 'distance SNP to gene'
		}
	);
	## sort by that distance
	$data_table = $data_table-> Sort_by (  [['distance SNP to gene', 'numeric']] );
	## throw away all results but the closest
	my $hash;
	$data_table = $data_table ->select_where ( 'rsID' , sub { unless ( $hash->{$_[0]}){ $hash->{$_[0]}= 1; return 1;} return 0;});
	## and now add the data
	$data_table -> createIndex ( 'rsID');
	$self->createIndex( 'rsID' );
	foreach ( @{$data_table->{'header'}}){
		$self->{'accepted_new'}->{$_} = 1;
	}
	$self->merge_with_data_table ( $data_table );
	## now all should be fine - test!
}

sub __check_accepted_new_partial {
	my ( $self, $value ) = @_;
	## $self->{'fold_change_columns'}
	foreach ( @{ $self->{'accepted_new_partial'} } ) {
		if ( $value =~ m/difference A-B/ ) {
			push( @{ $self->{'fold_change_columns'} }, $value );
		}
		elsif ( $value =~ m/p value/ ) {
			push( @{ $self->{'expreesion_p_values'} }, $value );
		}
		return 1 if ( $value =~ m/$_/ );
	}
	return 0;
}

sub Add_GWAS_data {
	my ( $self, $filename, $rsidCol_name, $p_value_col_name ) = @_;
	my $data_table = data_table->new();
	$self->createIndex('rsID');
	$data_table -> read_file ( $filename );
	$self->Add_2_Description ( "I added GWAS data in file $filename" );
	my $error = '';
	$error .= "The GWAS data does not contain a column named $rsidCol_name\n" unless ( defined $data_table->Header_Position ($rsidCol_name)) ;
	$error .= "The GWAS data does not contain a column named $p_value_col_name\n" unless ( defined $data_table->Header_Position ($p_value_col_name) );
	Carp::confess ( $error ) if ( $error =~m/\w/);
	$data_table -> Rename_Column($p_value_col_name, 'GWAS p value');
	$data_table -> Rename_Column($rsidCol_name, 'rsID' );
	$data_table -> define_subset ( 'GWAS_DATA', [ 'rsID', 'GWAS p value' ]);
	$data_table = $data_table -> get_as_table_object ( 'GWAS_DATA' );
	$data_table ->createIndex ( 'rsID' );
	$self-> merge_with_data_table ( $data_table );
	return 1;
}
1;
