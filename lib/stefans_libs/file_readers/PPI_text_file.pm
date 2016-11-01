package stefans_libs_file_readers_PPI_text_file;

#  Copyright (C) 2011-01-13 Stefan Lang

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
use stefans_libs::root;

=head1 General description

This class is able to read a tab separated PPI data file and do an easy extendsion of a gene list due to the PPI data.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = { 'debug' => $debug, };
	bless $self, $class
	  if ( $class eq "stefans_libs_file_readers_PPI_text_file" );

	return $self;
}

sub read_file {
	my ( $self, $file ) = @_;
	if ( defined $file){
	$self->{'PPI_file'} = $file if ( -f $file );
	}
	Carp::confess("Sorry, but I can not open the file '$self->{'PPI_file'}'\n")
	  unless ( -f $self->{'PPI_file'} );
	return $self->{'PPI_file'};
}

sub Links_Outfile {
	my ( $self, $file ) = @_;
	if ( defined $file){
	$self->{'PPI_out_file'} = $file;
	}
	return $self->{'PPI_out_file'};
}

sub expand {
	my ( $self, $gene_list, $link_only_genes ) = @_;
	my $file = $self->read_file();
	open( IN, "<$file" );
	my ( @line, $PPI_linked, $genes, $restrict_to_list, $outfile );
	if ( ref($link_only_genes) eq "ARRAY"){
		if ( defined @$link_only_genes[0] ){
			foreach ( @$link_only_genes ){
				$restrict_to_list -> {$_} = 1;
			}
		}
	}
	foreach (@$gene_list) {
		$genes->{$_} = 1;
	}
	$outfile = $self->Links_Outfile ();
	open ( OUT , ">$outfile") or Carp::confess ( "Sorry, but I could not create the outfile '$outfile'\n$!\n") if ( defined $outfile);
	if ( ref($restrict_to_list) eq "HASH"){
		while (<IN>) {
		next if ( $_ =~ m/^#/ || $_ =~ m/^Gene1/ );
		chomp($_);
		@line = split( "\t", $_ );
		if ( $genes->{ $line[0] } &&  
		   $restrict_to_list->{$line[1]}){
			print OUT $_."\n" if ( defined $outfile );
			$PPI_linked->{ $line[1] } = 1 ;
		}
	}
	}
	else {
	while (<IN>) {
		next if ( $_ =~ m/^#/ || $_ =~ m/^Gene1/ );
		chomp($_);
		@line = split( "\t", $_ ); 
		if ( $genes->{ $line[0] } ){
			print OUT $_."\n" if ( defined $outfile );
			$PPI_linked->{ $line[1] } = 1;
		}
	}
	}
	foreach (@$gene_list) {
		$PPI_linked->{$_} = 1;
	}
	return [  sort keys %$PPI_linked ];
}

1;
