package PHASE_outfile;
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
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::MyProject::PHASE_outfile::LIST_SUMMARY;
use stefans_libs::MyProject::PHASE_outfile::BESTPAIRS_SUMMARY;



=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::MyProject::PHASE_outfile.pm

=head1 DESCRIPTION

A class to read from a PHASE output file

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class PHASE_outfile.

=cut

sub new{

	my ( $class, $debug ) = @_;

	my ( $self );

	$self = {
		'debug' => $debug,
		'supports' => { 'LIST_SUMMARY' => 1, 'BESTPAIRS_SUMMARY' => 1} 
  	};

  	bless $self, $class  if ( $class eq "PHASE_outfile" );

  	return $self;

}

sub read_file { 
	my ( $self, $infile ) = @_;
	Carp::confess ( "Sorry, but I have no file name to read from\n" ) unless ( defined $infile );
	Carp::confess ( "Sorry, but there is no file named '$infile'\n" ) unless ( -f $infile );
	open ( IN , "<$infile" ) or die "I could not open the file '$infile'\n$!\n";
	my $line = 0;
	my (@data, $do);
	while ( <IN> ){
		$line++;
		chomp($_);
		if ( $line < 6){
			push (@data, $_);
			next;
		}
		if ( $line == 6){
			push (@data, $_);
			unless ($self->__check_header( \@data )){
				Carp::confess ( "the format of the infile $infile is not supported!\n");
			}
		}
		if ( $_ =~ m/^BEGIN (\w+)$/){
			$do = $1;
			print "we read the part $do\n" if ( $self->{'debug'});
			$do = '' unless ( $self->{'supports'}->{$do});
			next;
		}
		next unless ( defined $do);
		if ( $_ =~ m/^END $do/ ){
			print "we close the part $do\n" if ( $self->{'debug'});
			$do = '';
			next;
		}
		if ( $do =~m/\w/ ){
			$self->{$do} = $do->new($self, $self->{'debug'}) unless ( defined $self->{$do} );
			$self->{$do}->AddLine( $_ );
		}
	}
	if ( $self->{'debug'}){
		print "I have read $line lines from the file $infile\n";
		print $self->{'BESTPAIRS_SUMMARY'}->Summary();
	}
	
}

sub getChromosome_description{
	my ( $self ) =@_;
	return $self->{'LIST_SUMMARY'};
}

sub __check_header{
	my ( $self, $header_lines ) = @_;
	Carp::confeass ( "I need an array to check the header content!") unless ( ref($header_lines) eq "ARRAY");
	my @data =  ("*************************************************************",
"****                                                     ****",
"****            Output from PHASE v2.1.1                 ****",
"****  Code by M Stephens, with contributions from N Li   ****",
"****                                                     ****",
"*************************************************************");
	return 1 if ( join(" ", @$header_lines) eq join( " ", @data));
	return 0;
	
}

sub get_chromosome_ids {
	my ( $self ) = @_;
	return $self->{'LIST_SUMMARY'}->get_data_keys();
}

sub get_sample_ids{
	my ( $self ) = @_;
	return $self->{'BESTPAIRS_SUMMARY'}->get_data_keys();
}

=head get_sample_id_groups

This function will groups the sample_ids on a chromosome basis.
You can get a group that sums up the samples according to the chromosomes on a 'dominant' setting,
including each sample twice; on a 'recessive' setting, including only samples that are homozygote for a chromosme
or on a 'combination' setting, that will create most groups, becuase each combination of chromosomes is resporten 
- including each sample oinly once.

=cut

sub get_sample_id_groups{
	my  $self = shift @_;
	return $self->{'BESTPAIRS_SUMMARY'}->get_sample_id_groups(@_);
}

1;
