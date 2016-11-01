package pairFile;
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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::nimbleGeneFiles::pairFile

=head1 DESCRIPTION

=head2 Depends on

none

=head2 Provides

L<GetData|"GetData">

=head1 METHODS

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {};

	bless( $self, $class ) if ( $class eq "pairFile" );
	return $self;
}

=head2 GetData

=head3 arguments

[0]: the absolute position of the NimbleGene pair file

=head3 return value

Returns hash of the structure { $oligoID => $HybValue };

=cut

sub GetData {
	my ( $self, $file ) = @_;

	my ( @line, $data, $oligoID, $value, $chromosomalRegion );
	open( IN, "<$file" ) or die "$self->GetData: Konnte File $file nicht šffnnen!\n";

	while (<IN>) {
		chomp $_;
		next if ( $_ =~ m/^#/);
		@line = split( "\t", $_ );
		next unless ( $line[3] =~ m/(CHR\d+)([PR])\d+/ );
		$value = $line[9];
		$data->{ $line[3] } = $value;
		
	}
	return $data;
}

1;
