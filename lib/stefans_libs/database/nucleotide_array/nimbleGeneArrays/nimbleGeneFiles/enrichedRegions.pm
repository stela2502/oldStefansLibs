package enrichedRegions;
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

use stefans_libs::root;
use stefans_libs::NimbleGene_config;
use strict;

sub new{
	
	my ( $class, $dataHash, $filename ) = @_;
	
	my ( $self );
	
	if ( defined $dataHash){
		$self = $dataHash;
	}
	else { 
		die "enrichedRegions: This class absolutely needs a data hash!\n";
	}
	
	$self->{info} = root->ParseHMM_filename($filename) unless ( defined $self->{info} );
	
#	print "DEBUG: a new object of the type enrichedRegions was created.\n",
#		"The important data structure of this class is contained in the hash \$dataHash, that contains the following data entries:\n";
#	root::print_hashEntries($dataHash,3);
#	
#	die "Mal sehen wie es weiter geht!\n";
	die "enrichedRegions: No hybridization information avaible\n" unless ( defined $self->{info} );
	
	bless $self, $class  if ( $class eq "enrichedRegions" );
	
	return $self;
	
}

sub isEnriched{
	my ( $self, $gbFileString, $gbFeature) = @_;
	
	my $enrichmentState = 1 == 0;
	my $gbFeatureArray;
	
	unless ( defined $self->{$gbFileString} ){
		warn "$self->isEnriched could not find $gbFileString\n";
		return undef, undef;
	}
	$self->{timesEnriched} = 0;
	$gbFeatureArray = $self->{$gbFileString};
	foreach my $hmm_gbFeature ( @$gbFeatureArray){
		if ( $hmm_gbFeature->Start < $gbFeature->End && $hmm_gbFeature->End > $gbFeature->Start ){
			$enrichmentState = 1 == 1;
			$self->{timesEnriched} ++;
		}
	}
	return $self->{info}, $enrichmentState, $self->{timesEnriched};
}

sub TimesEnriched{
	my ( $self ) =@_;
	return $self->{timesEnriched};
}

sub Plot{
	my ($self, $im, $x_axis, $y1, $y2, $gbFileString, $dataColor, $spcingLineColor, $iteration ) = @_;
	
	my ($dataArray, $gbF_start, $gbF_end, $y_center, $y_upper, $y_lower, $radius, $gbMin, $gbMax);
	
	#print "DEBUG $self->Plot got the values ($im, $x_axis, $y1, $y2, $gbFileString, $dataColor, $spcingLineColor, $iteration )\n";
	
	$y_center = int( ($y1 + $y2) / 2);
	$radius = int(((($y2 - $y1) **2) **0.5) / 2);
	$y_upper = int ($y_center + $radius * 0.8);
	$y_lower = int ($y_center - $radius * 0.8);
	
	$dataArray = $self->getEnrichedRegions4gbFileString($gbFileString);
#	print "DEBUG $self->PLot the dataArray (list of enrichd regions):\n";
#	root::print_hashEntries($dataArray,3);
	return undef unless ( defined @$dataArray);
	
	$self->drawDashedLine( $im, $x_axis, $y_center, $dataColor );
	$self->drawBaseline ( $im, $x_axis, $y2, $spcingLineColor );
	$gbMin = $x_axis->min_value();
	$gbMax = $x_axis->max_value();
	
	foreach my $gbFeature (@$dataArray){
		## is the gbFeature located in the region that should be plotted?
		($gbF_start, $gbF_end) = ( $gbFeature->Start, $gbFeature->End);
		next if ( $gbF_start > $x_axis->max_value() || $gbF_end < $x_axis->min_value() );
		$gbF_start = $gbMin if ( $gbF_start < $gbMin);
		$gbF_end = $gbMax if ( $gbF_end > $gbMax);
#		print "DEBUG $self PLOT print the feature:\n";
#		root::print_hashEntries($gbFeature, 5);
#		print 	"DEBUG $self PLOT using the values:\n\$x_axis->resolveValue($gbF_start), \$y_upper ,",
#							 "\$x_axis->resolveValue($gbF_end), \$y_lower,",
#							 "\$dataColor);\n",
#				$x_axis->resolveValue($gbF_start), "\t$y_lower\t",$x_axis->resolveValue($gbF_end),"\t$y_upper\t$dataColor\n";
#				
		## plot the thing
		$im->filledRectangle($x_axis->resolveValue($gbF_start), $y_lower ,
							 $x_axis->resolveValue($gbF_end), $y_upper,
							 $dataColor);
	}
	
	return 1;
}


sub drawBaseline{
	my ($self, $im, $x_axis, $y, $color) = @_;
	$im->setThickness(1);
	$im->line($x_axis->resolveValue($x_axis->min_value()), $y, $x_axis->resolveValue($x_axis->max_value()), $y, $color);
	return 1;
}

sub drawDashedLine{
	my ($self, $im, $x_axis, $y, $color) =@_;
	my ( $spacing, $dashLength);
	$spacing = 10;
	$dashLength = 4;
	
	for (my $startPixel = $x_axis->resolveValue($x_axis->min_value()); 
			$startPixel < $x_axis->resolveValue($x_axis->max_value());
			$startPixel += $spacing )
		{
			$im->setThickness(1);
			$im->line($startPixel, $y, $startPixel + $dashLength, $y, $color);
		}
	return 1;
}

sub Iteration{
	my ($self ) = @_;
	return $self->{info}->{Iteration};
}

sub IterationWeight{
	my ($self ) = @_;
	return "0$self->{info}->{Iteration}" if ( $self->{info}->{Iteration} < 10);
	return $self->{info}->{Iteration};
}

sub getEnrichedRegions4gbFileString{
	my ( $self, $gbFileString) = @_;
	my ($data, @return);
	warn "WE GOT NO filename in enrichedRegions::getEnrichedRegions4gbFileString\n" unless ( defined $gbFileString);
	foreach my $hash_gbFileString ( keys %$self){
		#print "enrichedRegions compare (var) $keys with (fix) $gbFileString\n";
		if ( $hash_gbFileString =~ m/$gbFileString/){
			print "return data for filename $hash_gbFileString ($gbFileString)\n";
			my $temp = $self->{$hash_gbFileString};
#			foreach my $gbFeature ( @$temp){
#				push ( @return, gbFeature->new( $gbFeature->{tag}, $gbFeature->{region}));
#			}
#			return \@return;
			return $self->{$hash_gbFileString};
		}
	}
	return undef;
}

sub Celltype{
	my ( $self, $cellType) = @_;
	if ( defined $cellType)	{
		warn "enrichedRegions: Celltype can not be changed!\n";
	}
	#warn "$self Celltype original = $self->{info}->{CellType}\n";
	if ( $self->{info}->{CellType} =~ m/:/){
		my @array = split ( ":", $self->{info}->{CellType});
		#@array = split ( " ", $array[1]);
		$self->{info}->{CellType} = $array[1]; #join (" ", @array);
	}
	#warn "$self Celltype modified (?) = $self->{info}->{CellType}\n";
	return $self->{info}->{CellType};
}

sub Antibody{
	my ( $self, $antibody) = @_;
	if ( defined $antibody)	{
		warn "enrichedRegions: antibody name can not be changed!\n";
	}
	return $self->{info}->{AB};
}
sub WeightByCellytpe_iteration_antibody{
	my ( $self ) = @_;
	
	return $self->{info}->{weight_CIA} if ( defined $self->{info}->{weight_CIA});
	
	my ( $cellWeight, $antibodyWeight, $cells, $antibodies, $iterationWeight );
	$cellWeight = $antibodyWeight = 0;
	$cellWeight = $self->WeightCelltype($self->Celltype());
	$antibodyWeight = $self->WeightAntibody($self->Antibody());
	$iterationWeight = $self->IterationWeight();
	$self->{info}->{weight_CIA} = "$cellWeight$iterationWeight$antibodyWeight";
	#print "enricgedRegions::WeightByCellytpe_iteration_antibody weight = $self->{info}->{weight_CIA}\n";
	return $self->{info}->{weight_ICA};
}

sub WeightByIteration_cellytpe_antbody{
	my ( $self ) = @_;
	
	return $self->{info}->{weight_ICA} if ( defined $self->{info}->{weight_ICA});
	
	my ( $cellWeight, $antibodyWeight, $cells, $antibodies, $iterationWeight );
	$cellWeight = $antibodyWeight = 0;
	$cellWeight = $self->WeightCelltype($self->Celltype());
	$antibodyWeight = $self->WeightAntibody($self->Antibody());
	$iterationWeight = $self->IterationWeight();
	$self->{info}->{weight_ICA} = "$iterationWeight$cellWeight$antibodyWeight";
	
	return $self->{info}->{weight_ICA};
}

sub WeightAntibody{
	my ( $self, $antibody_string) = @_;
	my @antibodyWeight = NimbleGene_config::GetAntibodyOrder();
	for (my $i = 0; $i< @antibodyWeight; $i ++){
		if ( lc($antibody_string) =~ m/$antibodyWeight[$i]->{matchingString}/ ){
			return "0$i" if ($i < 10);
			return $i;
		}
	}
	die "Antibody '$antibody_string' is unknown!\n";
}

sub WeightCelltype{
	my ( $self, $celltype_string) = @_;
	my @celltypeWeight = NimbleGene_config::GetCelltypeOrder();
	for (my $i = 0; $i< @celltypeWeight; $i ++){
		if ( lc($celltype_string) =~  m/$celltypeWeight[$i]->{matchingString}/ ){
			return "0$i" if ($i < 10);
			return $i;
		}
	}
	die "Celltype '$celltype_string' is unknown!\n";
}

1;
