package file_readers::affymerix_snp_description;
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

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::file_readers::affymerix_snp_description.pm

=head1 DESCRIPTION

A class to read the affy SNP array descriptions and store them in an rsID_2_SNP_table.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class affymerix_snp_description.

=cut

sub new{

	my ( $class, $debug ) = @_;

	my ( $self );

	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'line_separator' => ',',
		'string_separator' => '"',
		'header_position' => {},
		'default_value'   => [],
		'header'          => [],
		'data'            => [],
		'index'           => {},
		'last_warning'    => '',
		'subsets'         => {}
	};
	if ( $class eq "file_readers::affymerix_snp_description" ){
		bless $self, $class ;
	}
	else {
		die "sorry - I am not myself!\n";
	}
  	

  	return $self;

}

=head2 store_in_rsID_2_SNP_table ( $rsID_2_SNP_table)

The only specific class function is to create the right subset in the data and
populate the database table.

=cut

sub store_in_rsID_2_SNP_table{
	my ( $self, $rsID_2_SNP_table ) = @_;
	Carp::confess( "Sorry, but the rsID_2_SNP is not OK '$rsID_2_SNP_table'") unless ( ref($rsID_2_SNP_table) eq "rsID_2_SNP" );
	$self->Rename_Column ( 'dbSNP RS ID', 'rsID');
	$self->Rename_Column ( 'Allele A','majorAllele');
	$self->Rename_Column ( 'Allele B','minorAllele');
	#$self->define_subset ( 'db', [ 'dbSNP RS ID','Allele A', 'Allele B']);
	$self->define_subset ( 'db', [ 'rsID','majorAllele', 'minorAllele']);
	
	my ($last_id, $already_added, $temp);
	if ( defined $rsID_2_SNP_table ->readLatestID() ){
		return 1 if ( $rsID_2_SNP_table ->readLatestID() >= scalar ( @{$self->{'data'}}) );
		warn "Could it be possible that you had duplicate entries - damn, but I will hope all is good!\n";
		return 1;
		Carp::confess ( "Sorry, but you must not add to a table that you created only partially - drop the table first!");
	}
	for ( my $i = 0; $i < scalar ( @{$self->{'data'}}); $i ++){
		$temp = $self->get_line_asHash($i, 'db' );
		if ( $already_added->{$temp->{'rsID'}}){
			warn "we have a duplicate entry for rsID $temp->{'rsID'} - we will not add the second one!\n";
			next;
		}
		$already_added->{$temp->{'rsID'}} = 1;
		$last_id = $rsID_2_SNP_table -> BatchAddDataset ( $temp );
	}
	
	return 1;
}

1;
