package NEW_Summary_GFF_Y_axis;
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

use stefans_libs::V_segment_summaryBlot::NEW_GFF_data_Y_axis;
use stefans_libs::V_segment_summaryBlot::selected_regions_dataRow;
@ISA = qw(NEW_GFF_data_Y_axis);

use strict;
use warnings;

sub new {

	my ( $class, $line, $what ) = @_;

	my ( @antibodyOrder, $self, %data, @cellTypes );

	@cellTypes = NimbleGene_config::GetCelltypeOrder();

	@antibodyOrder = NimbleGene_config::GetAntibodyOrder();

	$self = {
		oligoReport   => oligoBinReport->new(),
		cellTypes     => \@cellTypes,
		antibodyOrder => \@antibodyOrder,
		plotLable     => 1 == 0,
		data          => \%data,
		UseMean       => 1 == 1,
		binLength     => 250,
		max           => undef,
		useStdDev     => 1 == 0,

		#     flushMedian => 1 == 1,
		flushMedian     => 1 == 0,
		min             => undef,
		max_std         => undef,
		min_std         => undef,
		max_oligo_count => 5
	};

	bless $self, $class if ( $class eq "NEW_Summary_GFF_Y_axis" );

	return $self;

}

sub AddDataforChipType_new {
	my (
		$self,     $designString, $antibodySpecificity,
		$cellType, $dataArray,    $length,
		$end,      $gbFile,       $matching_gbTags, $nimbelGeneID
	) = @_;

	print "$self AddDataforChipType_new we add data for NimbleGeneID $nimbelGeneID\n";

	my ($dataHash);
	return undef unless ( defined $antibodySpecificity );
	$nimbelGeneID = undef unless ( $self->SeparateArrays() );
	#if ( ! $self->UseBars() && defined $nimbelGeneID ){
#		warn "option -separate_arrays is not supported without the -bars option!\n";
#		$nimbelGeneID = undef;
#	}
	$dataHash =
	  $self->ChipType( $designString, $antibodySpecificity, $cellType, $nimbelGeneID );
	unless ( defined $dataHash->{data} ) {

		#print "DEBUG $self: new dataRow: $length, $self->{binLength}, $end \n";
		$dataHash->{data} =
		  selected_regions_dataRow->new( $length, $self->{binLength}, $end,
			$gbFile, $matching_gbTags );
	}
	$dataHash->{data}->startOfNewDataSet();

	#print "we created a new pseudo x_axis (selected_regions_dataRow)\n";
	#print "We now insert the oligos from $dataArray into $dataHash\n";
	foreach my $oligoLocationCenter (@$dataArray) {
		next
		  unless (
			$dataHash->{data}->isRelevantOligo( $oligoLocationCenter->{mean} )
		  );
		$dataHash->{data}->AddOligo(
			$oligoLocationCenter->{mean}, $oligoLocationCenter->{value},
			$self->{flushMedian},         $oligoLocationCenter->{oligoID}
		);
	}
	$dataHash->{data}->flush_median( $self->{flushMedian} );
	return 1;
}

1;
