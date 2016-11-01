package Nimblegene_GeneInfo;

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
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::flexible_data_structures::data_table;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

This lib can be used to read from the nimblegene SignalMap formated gene info file

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Nimblegene_GeneInfo.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'header' => {
			'chromosome'               => 0,
			'nimbelegene_internal_tag' => 1,
			'tag'                      => 2,
			'start'                    => 3,
			'end'                      => 4,
			'value'                    => 5,
			'empty_1'                  => 6,
			'empty_2'                  => 7,
			'description'              => 8
		}
	};

	bless $self, $class if ( $class eq "Nimblegene_GeneInfo" );

	return $self;

}

sub get_closeby_gene_PROMOTER_MODE {
	my ( $self, $dataset ) = @_;
	return $self->get_closeby_gene( $dataset, 10000, 2000 );
}

sub get_closeby_gene_ENHANCER_MODE {
	my ( $self, $dataset ) = @_;
	return $self->get_closeby_gene( $dataset, 500000, 500000 );
}

=head2 get_closeby_gene ( $gffDataset, $upstream, $downstream )

The $gffDataset is a dataset that is returned by gffFile->GetData( $filename, 'preserve_structure_new').

This function identifies all genes, where a oligo is in a distance between -$upstream and 
+ $downstream of the transcription start. The orientation of the gene on the chromosome is taken into account.

The return value is a hash with the structure { 'oligoID<TAB>statistic_value' => [ <gene names> ] };

=cut

sub __define_promoter_structure{
	my ( $self, $downstream, $upstream ) = @_;
	return $self->{'__promoter_struct__'} if ( defined $self->{'__promoter_struct__'} );
	$self->{'__promoter_struct__'} = {};
	my ( $dataArray, $geneName);
	foreach $dataArray ( @{ $self->{'data'} } ) {
		$geneName = undef;
		next unless ( @$dataArray[2] eq 'transcription_start_site' );
		$geneName = $1 if ( @$dataArray[8] =~ m/Name=([\w\-]+);/ );
		unless ( defined $geneName ) {
			$geneName = $1 if ( @$dataArray[8] =~ m/accession=([\w\d]+);/ );
		}
		$self->{'__promoter_struct__'}->{ @$dataArray[0] } = []
		  unless ( ref( $self->{'__promoter_struct__'}->{ @$dataArray[0] } ) eq "ARRAY" );
		if ( @$dataArray[5] < 0 ) {
			push(
				@{ $self->{'__promoter_struct__'}->{ @$dataArray[0] } },
				[
					@$dataArray[3] - $downstream, @$dataArray[3] + $upstream,
					$geneName,                    'anti',
					@$dataArray[3]
				]
			);
		}
		else {
			push(
				@{ $self->{'__promoter_struct__'}->{ @$dataArray[0] } },
				[
					@$dataArray[3] - $upstream, @$dataArray[3] + $downstream,
					$geneName,                  'sense',
					@$dataArray[3]
				]
			);
		}
	}
	return $self->{'__promoter_struct__'};
}


sub get_closeby_gene {
	my ( $self, $gffDataset, $upstream, $downstream ) = @_;
	## I only need to look at the transcription start entries
	## value > 0 => sense; value < 0 => antisense
	## the tag (2) has to be transcription_start_site
	my ( $geneName, $return, $promoters, $dataArray, $oligoRep, $temp );
	$upstream = 0 unless ( defined $upstream);
	$downstream = 0 unless ( defined $downstream );
	$promoters = $self->__define_promoter_structure ( $upstream, $downstream );
	
	## now we have defined the promoters - we need to match the oligos to the promoters
	my ( $oligo_start, $oligo_end, $oligoID, $location );
	foreach $oligoRep (@$gffDataset) {
		$oligoID = $oligo_start = $oligo_end = undef;
		$oligo_start = $oligoRep->{'start'};
		$oligo_end   = $oligoRep->{'end'};
		$oligoID = $1 if ( $oligoRep->{'description'} =~ m/(CHR[\d\w]+\d+)/ );
		print "we search for the oligo $oligoID, $oligo_start, $oligo_end\n";
		Carp::confess(
			    ref($self)
			  . "::get_closeby_gene -> we could not recover the oligoID from the info "
			  . join( " ", @$oligoRep ) )
		  unless ( defined $oligoID );

		#$oligoID = "$oligoID\t$oligoRep->{'value'}";
		foreach $dataArray ( @{ $promoters->{ $oligoRep->{'chromosome'} } } ) {
			if (   $oligo_end >= @$dataArray[0]
				&& $oligo_start <= @$dataArray[1] )
			{
				$return->{$oligoID} = { 'genes' => [], 'location' => [] }
				  unless ( ref( $return->{$oligoID} ) eq "HASH" );
				unless (
					join( " ", @{ $return->{$oligoID}->{'genes'} } ) =~
					m/@$dataArray[2]/ )
				{
					## now there is the question about the distance to the transcription start site...
					$location = '';
					if ( @$dataArray[3] eq "sense" ) {
						$location = join( "",
							@$dataArray[4] - $oligo_start,
							"..", @$dataArray[4] - $oligo_end );
					}
					else {
						$location = join(
							"",
							(
								$oligo_end - @$dataArray[4],
								"..",
								$oligo_start - @$dataArray[4]
							)
						);
					}
					push( @{ $return->{$oligoID}->{'location'} }, $location );
					print
					  "we have a match to gene @$dataArray[2] and a location "
					  . @{ $return->{$oligoID}->{'location'} }
					  [ @{ $return->{$oligoID}->{'location'} } - 1 ] . "\n";
					push(
						@{ $return->{$oligoID}->{'genes'} },
						"@$dataArray[2]"
					);
				}

			}
		}
	}
	return $return;
}

=head2 define_promoter_locations ( $upstream, $downstream )

This function will define promoter regions relative to the gene start point.
It will also take the orientation of the gene in account in order to define the upstream and dowstream distances in a propper way.

You will get a data_table object with the following column headers:
'chromosome', 'Gene Symbol', 'promoter start', 'promoter end', 'orientation', 'transcription start'

=cut

sub define_promoter_locations {
	my ( $self, $upstream, $downstream ) = @_;
	my ( $geneName, $dataArray, $promoters );
	$promoters = data_table->new();
	foreach (
		'chromosome',
		'Gene Symbol',
		'promoter start',
		'promoter end',
		'orientation',
		'transcription start'
	  )
	{
		$promoters->Add_2_Header($_);
	}
	foreach $dataArray ( @{ $self->{'data'} } ) {
		$geneName = undef;
		next unless ( @$dataArray[2] eq 'transcription_start_site' );
		$geneName = $1 if ( @$dataArray[8] =~ m/Name=([\w\-]+);/ );
		unless ( defined $geneName ) {
			$geneName = $1 if ( @$dataArray[8] =~ m/accession=([\w\d]+);/ );
		}
		if ( @$dataArray[5] < 0 ) {
			$promoters->AddDataset(
				{
					'chromosome'          => @$dataArray[0],
					'Gene Symbol'         => $geneName,
					'promoter start'      => @$dataArray[3] - $downstream,
					'promoter end'        => @$dataArray[3] + $upstream,
					'orientation'         => 'anti',
					'transcription start' => @$dataArray[3]
				}
			);
		}
		else {
			$promoters->AddDataset(
				{
					'chromosome'          => @$dataArray[0],
					'Gene Symbol'         => $geneName,
					'promoter start'      => @$dataArray[3] - $upstream,
					'promoter end'        => @$dataArray[3] + $downstream,
					'orientation'         => 'sense',
					'transcription start' => @$dataArray[3]
				}
			);
		}
	}
	return $promoters;
}

=head2 get_closeby_gene_as_table (  $gffDataset, $upstream, $downstream )

The $gffDataset is a dataset that is returned by gffFile->GetData( $filename, 'preserve_structure').

This function identifies all genes, where a oligo is in a distance between -$upstream and 
+ $downstream of the transcription start. The orientation of the gene on the chromosome is taken into account.
But onle the oligo with the best p_value for ewach gene is reported!

The return value is a data_table object with the headers 'oligoID', 'statistic_value' and 'Gene Symbol'.
For each Oligo_ID there might be more genes as well as foreach gene more than one oligoID. 
The 'statistic_value' will be taken from the gff dataset. 

=cut

sub get_closeby_gene_as_table {
	my ( $self, $gffDataset, $upstream, $downstream ) = @_;
	my $promoters = $self->define_promoter_locations( $upstream, $downstream );
	return $self->combine_promoter_information_with_oligo_statistics(
		$promoters, $gffDataset );
}

=head2 combine_promoter_information_with_oligo_statistics ( $promoters, $gffDataset )

The $promoters dataset you get from $self->get_closeby_gene_as_table().
The $gffDataset is a dataset that is returned by gffFile->GetData( $filename, 'preserve_structure').

Here we will add the oligo with the best p_value for each promoter. The p_values are expected to be in -log10 format.
Otherwise we will select the worst p_value for each promoter - and that is most probably not what you want - or?

You get a data_table object with the columns 'chromosome', 'promoter start', 'promoter end', 'Gene Symbol', 'oligoID' and 'statistic_value'.
=cut

sub combine_promoter_information_with_oligo_statistics {
	my ( $self, $promoters, $gffDataset ) = @_;
	my ( $oligoRep, $error, $data_table, $gene_rep, $promoter_hash, $return );

	$promoters->define_subset( 'promoter credentials',
		[ 'chromosome', 'promoter start', 'promoter end' ] );
	$promoters->createIndex('chromosome');
	$promoters->createIndex('promoter start');
	$promoters->createIndex('promoter end');
	$return = data_table->new();
	foreach ( 'oligoID', 'statistic_value' ) {
		$promoters->Add_2_Header($_);
	}
	foreach ( @{ $promoters->{'header'} } ) {
		$return->Add_2_Header($_);
	}
	my $hash               = {};
	my $local_promoter_set = $promoters->select_where(
		'Gene Symbol',
		sub {
			if ( !defined $hash->{ $_[0] } ) { $hash->{ $_[0] } = 1; return 1; }
			return 0;
		}
	);
	$promoters =
	  $local_promoter_set->Sort_by( [ [ 'Gene Symbol', 'lexical' ] ] );
	my $oligo_data_split_by_chromosome = {};
	foreach $oligoRep (@$gffDataset) {
		$error = '';
		$error .= "we do not have a start for this oligo\n"
		  unless ( defined $oligoRep->{'start'} );
		$error .= "we do not have an end for this oligo\n"
		  unless ( defined $oligoRep->{'end'} );
		$oligoRep->{'oligoID'} = $1
		  if ( $oligoRep->{'description'} =~ m/(CHR[\d\w]+\d+)/ );
		$error .= "we do not have an oligoID for this oligo!\n"
		  unless ( defined $oligoRep->{'oligoID'} );
		Carp::confess(
			ref($self)
			  . "::combine_promoter_information_with_oligo_statistics - we have an error:\n$error\n"
		) if ( $error =~ m/\w/ );
		unless (
			defined
			$oligo_data_split_by_chromosome->{ $oligoRep->{'chromosome'} } )
		{
			$oligo_data_split_by_chromosome->{ $oligoRep->{'chromosome'} } =
			  data_table->new();
			foreach ( 'oligoID', 'chromosome', 'start', 'end', 'value' ) {
				$oligo_data_split_by_chromosome->{ $oligoRep->{'chromosome'} }
				  ->Add_2_Header($_);
			}
		}
		$oligo_data_split_by_chromosome->{ $oligoRep->{'chromosome'} }
		  ->AddDataset(
			{
				'oligoID'    => $oligoRep->{'oligoID'},
				'chromosome' => $oligoRep->{'chromosome'},
				'start'      => $oligoRep->{'start'},
				'end'        => $oligoRep->{'end'},
				'value'      => $oligoRep->{'value'}
			}
		  );
	}
	foreach my $oligo_data ( values %$oligo_data_split_by_chromosome ) {
		$oligo_data->define_subset( 'promoter credentials',
			[ 'chromosome', 'start', 'end' ] );
	}
	@$gffDataset = ();
	for ( my $i = 0 ; $i < @{ $local_promoter_set->{'data'} } ; $i++ ) {
		$promoter_hash = $local_promoter_set->get_line_asHash($i);
		$data_table =
		  $oligo_data_split_by_chromosome->{ $promoter_hash->{'chromosome'} }
		  ->select_where(
			'promoter credentials',
			sub {
				return 1
				  if ( $_[0] eq $promoter_hash->{'chromosome'}
					&& $promoter_hash->{'promoter start'} <= $_[2]
					&& $promoter_hash->{'promoter end'} >= $_[1] );
				return 0;
			}
		  );
		$data_table = $data_table->Sort_by( [ [ 'value', 'antiNumeric' ] ] );

		for ( my $a = 0 ; $a < @{ $data_table->{'data'} } ; $a++ ) {
			$gene_rep = $data_table->get_line_asHash($a);
			$promoter_hash->{'oligoID'} = $gene_rep->{'oligoID'};
			$promoter_hash->{'statistic_value'} = $gene_rep->{'value'};
			$return->AddDataset($promoter_hash);
			print
			  "We have added the oligo $promoter_hash->{'oligoID'} with a stat value of "
			  ."$promoter_hash->{'statistic_value'} "
			  . "for the gene $promoter_hash->{'Gene Symbol'} (n=$i)\n";
			last;
		}
	}
	return $return;
}

sub overlapps_gene {
	my ( $self, $gffDataset ) = @_;

	my ( $geneName, $return, $promoters, $dataArray, $oligoRep, $temp );

	foreach $dataArray ( @{ $self->{'data'} } ) {
		$geneName = undef;
		next unless ( @$dataArray[2] eq 'primary_transcript' );
		$geneName = $1 if ( @$dataArray[8] =~ m/Name=([\w\-]+);/ );
		unless ( defined $geneName ) {
			$geneName = $1 if ( @$dataArray[8] =~ m/accession=([\w\d]+);/ );
		}
		$promoters->{ @$dataArray[0] } = []
		  unless ( ref( $promoters->{ @$dataArray[0] } ) eq "ARRAY" );
		if ( @$dataArray[5] < 0 ) {
			push(
				@{ $promoters->{ @$dataArray[0] } },
				[
					@$dataArray[3], @$dataArray[4], $geneName,
					'anti',         @$dataArray[4]
				]
			);
		}
		else {
			push(
				@{ $promoters->{ @$dataArray[0] } },
				[
					@$dataArray[3], @$dataArray[4], $geneName,
					'sense',        @$dataArray[3]
				]
			);
		}
	}
	## now we have defined the promoters - we need to match the oligos to the promoters
	my ( $oligo_start, $oligo_end, $oligoID, $location );
	foreach $oligoRep (@$gffDataset) {
		$oligoID = $oligo_start = $oligo_end = undef;
		$oligo_start = $oligoRep->{'start'};
		$oligo_end   = $oligoRep->{'end'};
		$oligoID     = $1
		  if ( $oligoRep->{'description'} =~ m/(CHR[\d\w]+\d+)/ );
		print "we search for the oligo $oligoID, $oligo_start, $oligo_end\n";
		Carp::confess(
			    ref($self)
			  . "::get_closeby_gene -> we could not recover the oligoID from the info "
			  . join( " ", @$oligoRep ) )
		  unless ( defined $oligoID );

		#$oligoID = "$oligoID\t$oligoRep->{'value'}";
		foreach $dataArray ( @{ $promoters->{ $oligoRep->{'chromosome'} } } ) {
			if (   $oligo_end >= @$dataArray[0]
				&& $oligo_start <= @$dataArray[1] )
			{
				$return->{$oligoID} = { 'genes' => [], 'location' => [] }
				  unless ( ref( $return->{$oligoID} ) eq "HASH" );
				unless (
					join( " ", @{ $return->{$oligoID}->{'genes'} } ) =~
					m/@$dataArray[2]/ )
				{
					## now there is the question about the distance to the transcription start site...
					$location = '';
					if ( @$dataArray[3] eq "sense" ) {
						$location = join( "",
							@$dataArray[4] - $oligo_start,
							"..", @$dataArray[4] - $oligo_end );
					}
					else {
						$location = join(
							"",
							(
								$oligo_end - @$dataArray[4],
								"..",
								$oligo_start - @$dataArray[4]
							)
						);
					}
					push( @{ $return->{$oligoID}->{'location'} }, $location );
					print
					  "we have a match to gene @$dataArray[2] and a location "
					  . @{ $return->{$oligoID}->{'location'} }
					  [ @{ $return->{$oligoID}->{'location'} } - 1 ] . "\n";
					push(
						@{ $return->{$oligoID}->{'genes'} },
						"@$dataArray[2]"
					);
				}

			}
		}
	}
	return $return;
}

sub read_file {
	my ( $self, $filename )= @_;
	return $self-> GetData ( $filename );
}
sub GetData {
	my ( $self, $filename ) = @_;
	my $gffFile = gffFile->new();
	$self->{'data'} = $gffFile->GetData( $filename, "preserve_structure_new" );
	return 1;
}

1;
