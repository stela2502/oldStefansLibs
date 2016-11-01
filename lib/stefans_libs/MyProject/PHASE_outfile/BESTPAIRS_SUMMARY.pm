package BESTPAIRS_SUMMARY;
#  Copyright (C) 2010-09-01 Stefan Lang

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


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::MyProject::PHASE_outfile::BESTPAIRS_SUMMARY.pm

=head1 DESCRIPTION

A class to store the BESTPAIRS_SUMMARY part of a PHASE outfile

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class BESTPAIRS_SUMMARY.

=cut

sub new{

	my ( $class, $upper, $debug ) = @_;

	my ( $self );

	unless ( ref($upper) eq "PHASE_outfile" ){
		Carp::confess ( "I need a PHASE_outfile_object at startup!");
	}
	unless ( ref($upper->getChromosome_description()) eq "LIST_SUMMARY"){
		Carp::confess ( "That PHASE_outfile object does not contain the necessary LIST_SUMMARY object!\n");
	}
	$self = {
		'debug' => $debug,
		'chromosome_desc' => $upper->getChromosome_description(),
		'data' => {},
		
  	};

  	bless $self, $class  if ( $class eq "BESTPAIRS_SUMMARY" );

  	return $self;

}

sub Summary{
	my ( $self ) = @_;
	return "we have ".scalar ( keys %{$self->{data}} ) . "Different datasets in this object\n";
}

sub AddLine{
	my ( $self, $line ) = @_;
	## lines look like "#100: (4,13)"
	Carp::confess ( "I can not pars an empty line!\n") unless ( defined $line);
	if ( $line =~ m/^#?(\w+): \((\d+),(\d+)\)/){
		if ( defined $self->{'data'}->{$1}){
			warn "we have a duplicate entry for sample_id $1!\n";
			next;
		}
		$self->{'data'}->{$1} = { 'chr1' => $2, 'chr2' => $3};
	}
	return 1;
}

sub describe_entry{
	my ( $self, $id ) = @_;
	return "Sample_id $id is unknown\n" unless ( ref($self->{'data'}->{$id}) eq "HASH");
	return "Sample $self->{'data'}->{$id}->{'sequence'}; chr1=$self->{'data'}->{$id}->{'chr1'}; chr2=$self->{'data'}->{$id}->{'chr2'}\n";
}

sub get_data_keys {
	my ( $self ) = @_;
	return (sort keys %{$self->{'data'}});
}

sub get_sample_id_groups{
	my ( $self, $group_type ) = @_;
	Carp::confess ("you need to give me a group_type and you gave me nothing!\n" )unless (defined  $group_type ) ;
	Carp::confess ("you can get groups for 'dominant', 'recessive' or 'combination', not for '$group_type'\n" ) unless ( "dominant recessive combination" =~ m/$group_type/);
	return $self->__group_dominant() if ( $group_type eq 'dominant');
	return $self->__group_recessive() if ( $group_type eq 'recessive');
	return $self->__group_combination() if ( $group_type eq 'combination');
}

sub __group_combination{
	my ( $self ) = @_;
	my ($sample,$data, $tag);
	foreach $sample ( keys %{$self->{'data'}}){
		$tag = $self->{'data'}->{$sample}->{'chr1'}.".".$self->{'data'}->{$sample}->{'chr2'};
		$data->{$tag} = [] unless ( defined $data->{$tag} );
	 	push ( @{$data->{$tag}}, $sample);
	}
	Carp::confess ( root::get_hashEntries_as_string ( $self, 3, "OOPS - there was no data" ) ) unless ( ref($data) eq "HASH" );
	return $data;
}

sub __group_recessive{
	my ( $self ) = @_;
	my ($sample,$data);
	foreach $sample ( keys %{$self->{'data'}}){
		next unless ($self->{'data'}->{$sample}->{'chr1'} eq  $self->{'data'}->{$sample}->{'chr2'});
		$data->{$self->{'data'}->{$sample}->{'chr1'}} = [] unless ( defined $data->{$self->{'data'}->{$sample}->{'chr1'}});
	 	push ( @{$data->{$self->{'data'}->{$sample}->{'chr1'}}}, $sample);
	}
	Carp::confess ( root::get_hashEntries_as_string ( $self, 3, "OOPS - there was no data" ) ) unless ( ref($data) eq "HASH" );
	return $data;
}

sub __group_dominant{
	my ( $self ) = @_;
	my ($sample,$data);
	foreach $sample ( keys %{$self->{'data'}}){
		$data->{$self->{'data'}->{$sample}->{'chr1'}} = [] unless ( defined $data->{$self->{'data'}->{$sample}->{'chr1'}});
	 	$data->{$self->{'data'}->{$sample}->{'chr2'}} = [] unless ( defined $data->{$self->{'data'}->{$sample}->{'chr2'}});
	 	push ( @{$data->{$self->{'data'}->{$sample}->{'chr1'}}}, $sample);
	 	push ( @{$data->{$self->{'data'}->{$sample}->{'chr2'}}}, $sample);
	}
	Carp::confess ( root::get_hashEntries_as_string ( $self, 3, "OOPS - there was no data" ) ) unless ( ref($data) eq "HASH" );
	return $data;
}

1;
