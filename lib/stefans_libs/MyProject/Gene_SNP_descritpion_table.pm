package stefans_libs_MyProject_Gene_SNP_descritpion_table;

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

use
  stefans_libs::MyProject::Gene_SNP_descritpion_table::rsID_based_SNP_2_gene_description;
use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=head1 General description

This lib can read and convert the Gene - SNP description tables that we wanted to add the the Supplement of our islet papaer.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'rsID'         => 0,
			'Probe Set ID' => 1,
			'Gene Symbol'  => 2,
			'p_value'      => 3,
			'rho'          => 4
		},
		'default_value' => [],
		'header' => [ 'rsID', 'Probe Set ID', 'Gene Symbol', 'p_value', 'rho' ],
		'accepted_new' => { 'Gene Symbol (p_value)' => 1 },
		'data'         => [],
		'index'        => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class
	  if ( $class eq "stefans_libs_MyProject_Gene_SNP_descritpion_table" );

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

sub populate_on_correlation_files {
	my ( $self, $p_value, @files ) = @_;
	my @line;
	$self->Add_2_Header('Gene Symbol (p_value)');
	foreach my $infile (@files) {
		open( IN, "<$infile" )
		  or die "I could not open the infile $infile\n$!\n";
		print "we have opened the infile $infile\n" if $self->{'debug'};
		while (<IN>) {
			next unless ( $_ =~ m/rs\d+\t/ );
			chomp $_;
			@line = split( "\t", $_ );
			if ( $line[3] <= $p_value){
			#print "we process line $_\n";
			$self->AddDataset(
				{
					'rsID'                  => $line[0],
					'Probe Set ID'          => $line[1],
					'Gene Symbol'           => $line[2],
					'p_value'               => $line[3],
					'rho'                   => $line[4],
					'Gene Symbol (p_value)' => "$line[2] ($line[3])",
				}
			);
			}
		}
		close(IN);
	}
	return 1;
}

sub merge_on_rsID {
	my ($self) = @_;
	my $data_table =
	  stefans_libs_MyProject_Gene_SNP_descritpion_table_rsID_based_SNP_2_gene_description
	  ->new();

	#'rsID'                        => 0,
	#'Correlating genes (p value)' => 1
	Carp::confess("Sorry, but we do not have the right data\n")
	  unless ( defined $self->Header_Position('Gene Symbol (p_value)') );
	my $data_col = $self->Header_Position('Gene Symbol (p_value)');
	$self->createIndex ( 'rsID' );
	my ( $row_id, $data_str );
	foreach my $rsID ( $self->getIndex_Keys( 'rsID' ) ){
		$data_str = '';
		foreach my $row_id ( @{$self->{'index'}->{'rsID'}->{$rsID}}){
			$data_str .= @{@{$self->{'data'}}[$row_id]}[$data_col].", ";
		}
		$data_str =~ s/, $//;
		$data_table->AddDataset(
			{
				'rsID' => $rsID,
				'Correlating genes (p value)' => $data_str
			}
		);
	}
	return $data_table;
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
1;
