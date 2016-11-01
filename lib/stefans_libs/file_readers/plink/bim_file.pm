package plink::bim_file;
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
use base ( 'data_table' );

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

plink::map_file

=head1 DESCRIPTION

A lib to read the plink map file.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class map_file.

=cut

sub new{

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {},
		'default_value'   => [],
		'header'          => [],
		'data'            => [],
		'index'           => {},
		'last_warning'    => '',
		'subsets'         => {}
	};

  	bless $self, $class  if ( $class eq "plink::bim_file" );

  	return $self;

}

sub read_file { 
	my ( $self, $file ) = @_;
	Carp::confess ( "I need a file!!" ) unless ( defined $file );
	open ( IN , "<$file" ) or die "I could not read from the file $file\n$!\n";
	foreach ('chromosome', 'rsID', 'Genetic distance [morgan]', 'position', 'majorAllele', 'minorAllele' ){
		$self->Add_2_Header ( $_ );
	}
	while ( <IN> ){
		chomp $_;
		push ( @{$self->{'data'}}, [split( " ", $_)]);
	}
	close ( IN );
}

sub store_in_rsID_2_SNP_table {
	my ( $self, $rsID_2_SNP_table ) = @_;
	Carp::confess( "Sorry, but the rsID_2_SNP is not OK '$rsID_2_SNP_table'") unless ( ref($rsID_2_SNP_table) eq "rsID_2_SNP" );
	$self->define_subset ( 'db', [ 'rsID','majorAllele', 'minorAllele']);
	my $last_id;
	if ( defined $rsID_2_SNP_table ->readLatestID() ){
		return 1 if ( $rsID_2_SNP_table ->readLatestID() >= scalar ( @{$self->{'data'}}) );
		Carp::confess ( "Sorry, but you must not add to a table that you created only partially - drop the table first!");
	}
	for ( my $i = 0; $i < scalar ( @{$self->{'data'}}); $i ++){
		$last_id = $rsID_2_SNP_table -> BatchAddDataset ( $self->get_line_asHash($i, 'db' ) );
	}
	
	return 1;
}

1;
