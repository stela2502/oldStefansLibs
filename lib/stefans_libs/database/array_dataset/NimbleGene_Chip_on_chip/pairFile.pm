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
use warnings;
use Archive::Zip;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::pairFile

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

sub expected_dbh_type {
	#return 'dbh';
	return "not a databse interface";
	#return "database_name";
}


=head2 GetData

=head3 arguments

[0]: the absolute position of the NimbleGene pair file

=head3 return value

Returns hash of the structure { $oligoID => $HybValue };

=cut

sub GetData {
	my ( $self, $file ) = @_;

	my ( @line, $data, $oligoColumn, $chromosomalRegion, $oligoID, $unknown );
	if ( $file =~ m/^(.+)\.zip/ ){
		$unknown = $1;
		@line = split( "/",$unknown);
		$unknown = $line[@line-1];
		warn "we hope, that we find an Dataset using the member '$unknown'\n";
		my $zipFile = Archive::Zip->new();
		unless ($zipFile ->read( $file ) == 0){
			Carp::confess( ref($self)."::AddData -> we can not read from the ZIP file $file\n");
		}
		open ( OUT, ">temp.data") or die "we could not craete a temp file to hold the unzipped data!\n";
		print OUT $zipFile->contents( $unknown );
		close (OUT);
		$zipFile = undef;
		$unknown = undef;
		$file = "temp.data";
	}
	open( IN, "<$file" ) or die "$self->GetData: Konnte File '$file' nicht oeffnen!\n";
	$self->{'error'} = '';
	my $i = 0;
	while (<IN>) {
		chomp $_;
		next if ( $_ =~ m/^#/);
		$i ++;
		#next if ( $i == 1); ## get rid of the first line - it is a header line!
		@line = split( "\t", $_ );
		unless ( defined $oligoColumn ){
			for (my $line = 0; $line < @line; $line++){
				if ( $line[$line] =~ m/(CHR[\d\w]+\d+)/ || $line[$line] =~ m/(RANDOM\d+)/){
					$oligoColumn = $line;
				}
			}
			next unless ( defined $oligoColumn);
		}
		$self->{'error'} .= ref($self).":GetData we found no oligoID containing column in line $i\n" unless ( $oligoColumn > -1);
		$oligoID = '';
		$oligoID = $1 if ($line[$oligoColumn] =~ m/(CHR[\d\w]+\d+)/ );# || $line[$oligoColumn] =~ m/(RANDOM\d+)/ );
		next unless ( $oligoID =~ m/CHR/);
		$data->{ $oligoID } = $line[@line-2];
		#print "we add $data->{ $oligoID } for oligo $oligoID\n";
	}
	unlink("temp.data") if ( -f "temp.data");
	#print ref($self).":we return an hash of oligo values $data\n";
	return $data;
}

1;
