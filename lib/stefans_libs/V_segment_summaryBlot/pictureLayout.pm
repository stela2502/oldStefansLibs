package pictureLayout;
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

sub new {

	my ( $class, $single_array, $bars ) = @_;

	die
"pictureLayout absolutely needs to know if a each accay should be plotted in a different line\n",
	"and if a bar- or line-plot has to be defined!\n"
	  unless ( defined $bars );
	my ( $self, $data, @temp, @temp1, @temp2, @temp3, @temp4 );

	$self = {
		pictureOrder           => undef,
		dataSet               => $data,
		useSigle_array		  => $single_array,
		useBarPlot            => $bars,
		pictureCoordinates    => undef,
		hmmDataSets           => \@temp,
		Yaxies4enrichmentData => \@temp1,
		Yregion4hmmDataSet    => \@temp2,
		Ytitle                => \@temp3,
		titleStrings          => \@temp4
	};

	bless $self, $class if ( $class eq "pictureLayout" );

	return $self;

}

sub structurizeDataSet {
	my ( $self, $enrichmentDataSet, $HMM_dataSet ) = @_;
	my ( @cellTypeOrder, @antibodyOrder );

	@cellTypeOrder = NimbleGene_config::GetCelltypeOrder();
	@antibodyOrder = NimbleGene_config::GetAntibodyOrder();

	my ( $antiboyID, $cellTypeID, @plotOrder, $temp, $dataSetCount, $hmmData,
		$ct_string, $ab_string );
	$self->{pictureOrder} = \@plotOrder;
	#root::print_hashEntries($enrichmentDataSet,4,"ETSTTESTETSTSTETET $enrichmentDataSet\n");
	foreach my $data ( values %$enrichmentDataSet ) {
		( $antiboyID, $ab_string ) =
		  $self->_getPositionInArray( $data->{antibodySpecificity}, @antibodyOrder );
		( $cellTypeID, $ct_string ) =
		  $self->_getPositionInArray( $data->{cellType}, @cellTypeOrder );

		unless ( defined $plotOrder[$cellTypeID] ) {
			my $temp;
			$plotOrder[$cellTypeID] = { title => $ct_string, data => $temp };
		}
		$hmmData = undef;
		$hmmData =
		  $HMM_dataSet->getEnrichedRegions4CelltypeAndAntibody(
			$data->{cellType}, $data->{antibodySpecificity} )
		  if ( defined $HMM_dataSet );
		$self->{useHMM_data} = 1==1 if (defined $hmmData);
		$plotOrder[$cellTypeID]{data}->{"$antiboyID$data->{NimbleGeneID}"} = {
			enrichmentDataSet => $data,
			hmmData           => $hmmData,
			title             => $ab_string,
			celltype		  => $ct_string,
			nimbleGeneID      => $data->{NimbleGeneID}
		};
	}

	$dataSetCount = 0;
	my ($a);
	for ( my $i = 0 ; $i < @plotOrder ; $i++ ) {
		$temp = $plotOrder[$i]{data};
		next unless ( defined %$temp );
		foreach my $key (sort keys %$temp ) {
			$a = substr($key,0,1);
			#print "DEBUG $self structurizeDataSet got key $key and antibodyID $a\n";
			if ( defined $temp->{$key} ) {
				$self->{dataSet}[ $dataSetCount++ ] = {
					enrichmentDataSet => $temp->{$key}->{enrichmentDataSet},
					type              => "enrichment",
					celltypeID        => $i,
					antibodyID        => $a,
					hmmData           => $temp->{$key}->{hmmData},
					title			  => $temp->{$key}->{title},
					celltype          => $temp->{$key}->{celltype},
					nimbleGeneID	  => $temp->{$key}->{nimbleGeneID}
				};
			}
		}
	}
	return $self->{dataSet};

}

sub Ytitle4SubPlot {
	my ( $self, $subPlot, $y ) = @_;
	my ($Ytitle);
	$Ytitle = $self->{Ytitle};
	if ( defined $y ) {
		@$Ytitle[$subPlot] = $y;
	}
	return @$Ytitle[$subPlot];
}

sub createYregionsMap {
	my ( $self, $y1, $y2, $minValue, $maxValue ) = @_;
	## Much work to do!!
	

	if ( $self->{useSigle_array} ) {
		my $dataSets = $self->{dataSet};
		my ( $subPlotCount, $space4SubPlot_in_pixel, $antibodyCount, $hmmCount );
		## die plots der unterschiedlichen AK's müssen getrennt werden!
		$subPlotCount = @$dataSets;
		$space4SubPlot_in_pixel = int( ( $y2 - $y1 ) / $subPlotCount );
		for ( my $i = 0 ; $i < @$dataSets ; $i++ ) {
			$hmmCount = 0;
			$hmmCount = 1 if ( defined @$dataSets[$i]->{hmmData});
			$self->createAxies4Subplot ($y1, $space4SubPlot_in_pixel, $i, $minValue, $maxValue, @$dataSets[$i], $hmmCount );
			#root::print_hashEntries(@$dataSets[$i],2,"Are the axies defined??\n");
		}
	}
	elsif ($self->{useBarPlot}) {
		## Jeder Typ von Array muss in ein extra Feld!
		my $dataSets = $self->{dataSet};
		my ( $subPlotCount, $space4SubPlot_in_pixel, $antibodyCount, $hmmCount );
		## die plots der unterschiedlichen AK's müssen getrennt werden!
		$subPlotCount = @$dataSets;
		$space4SubPlot_in_pixel = int( ( $y2 - $y1 ) / $subPlotCount );
		for ( my $i = 0 ; $i < @$dataSets ; $i++ ) {
			$hmmCount = 0;
			$hmmCount = 1 if ( defined @$dataSets[$i]->{hmmData});
			$self->createAxies4Subplot ($y1, $space4SubPlot_in_pixel, $i, $minValue, $maxValue, @$dataSets[$i], $hmmCount );
			#root::print_hashEntries(@$dataSets[$i],2,"Are the axies defined??\n");
		}
	} 
	else {
		my ( $dataSets, $subPlotArray);
		$dataSets = $self->{dataSet};
		$subPlotArray = $self->{pictureOrder};
		# die Einträge in $subPlotArray sind vollständig,
		# trotzdem muss ich mit den dataSets arbeiten, weil die später geplottet werden!
		# dataSet->{celltypeID} verweist auf die SubPlots => erst mal sehen, elce wir überhaupt haben und 
		# dann die Achen definieren
		my ($celltype2axies, @temp,$dataSet, $subPlotCount,$space4SubPlot_in_pixel,$i, $temp, $hmmCount);
		foreach $dataSet ( @$dataSets){
			$celltype2axies->{$dataSet->{celltypeID}} = 1;
		}
		@temp = ( keys %$celltype2axies);
		## bis jetzt zeigt $usedSubplots->{celltypeID} auf keinen sinnvollen Wert.
		## => $usedSubplots->{celltypeID} soll auf einen Hash mit den möglichen axen zeigen,
		## die für dieses datenset genutzt werden.
		## Anzahl der Subplots errechnen
		@temp = (keys %$celltype2axies );
		$subPlotCount = @temp;
		## platz für die SubPlots errechnen
		$space4SubPlot_in_pixel = int( ( $y2 - $y1 ) / $subPlotCount );
		## jetzt erst mal die Nummer des Subplots der cellTypeID zuordnen und die Achen definieren
		for ( $i = 0; $i < @temp; $i++){
			$celltype2axies->{$temp[$i]} = { hmmData => $self->{useHMM_data} };
			$hmmCount = $self->getAmountOfHMMDataSets4subPlot($temp[$i]);
			$self->createAxies4Subplot ($y1, $space4SubPlot_in_pixel, $i, $minValue, $maxValue, $celltype2axies->{$temp[$i]}, $hmmCount );
		}
		
		foreach my $dataSet ( @$dataSets){
			$dataSet-> {axis} = $celltype2axies->{$dataSet->{celltypeID}}->{axis};
			$dataSet -> {enrichmentAxis} = $celltype2axies->{$dataSet->{celltypeID}}->{enrichmentAxis};
			$dataSet -> {hmmAxis} = $celltype2axies->{$dataSet->{celltypeID}}->{hmmAxis};
		}
		
	}
	return 1;
}

#sub Yaxis4enrichmentDataSubPlot {
#	my ( $self, $subPlot, $y1, $y2, $minValue, $maxValue ) = @_;
#	my ($data);
#	$data = $self->{Yaxies4enrichmentData};
#
#	if ( defined $y1 && defined $y2 ) {
#		@$data[$subPlot] = axis->new( "Y", $y1 + 40, $y2, " ", "med" );
#		@$data[$subPlot]->max_value($maxValue);
#		@$data[$subPlot]->min_value($minValue);
#		@$data[$subPlot]->{tics} = 5;
#		$self->Ytitle4SubPlot( $subPlot, $y1 + 18 );
#		@$data[$subPlot]->resolveValue(0);
#	}
#	return @$data[$subPlot];
#}

#sub Yregion4hmmDataSet_SubPlot {
#	my ( $self, $subPlot, $y1 ) = @_;
#	my ($data);
#	$data = $self->{Yregion4hmmDataSet};
#	if ( defined $y1 ) {
#		my $hmmData = $self->{hmmDataSets};
#		@$data[$subPlot] = { y1 => $y1, y2 => $y1 + @$hmmData[$subPlot] * 10 };
#		return @$data[$subPlot]->{y2};
#	}
#	return @$data[$subPlot]->{y1}, @$data[$subPlot]->{y2};
#}
#
#sub totalAmountOfHMMdata {
#	my ($self) = @_;
#	my ( $dataArray, $return );
#	$dataArray = $self->{pictureOrder};
#	$return    = 0;
#	for ( my $i = 0 ; $i < @$dataArray ; $i++ ) {
#		$return += $self->getAmountOfEnrichmentDataSets4subPlot($i);
#	}
#	return $return;
#}
#
#sub titleString4SubPlot {
#	my ( $self, $subPlot, $string ) = @_;
#	my ($dataArray);
#	$dataArray = $self->{titleStrings};
#	if ( defined $string && length($string) > 0 ) {
#
#		#my $temp = {};
#		#@$dataArray[$subPlot] = $temp;
#		@$dataArray[$subPlot] = { title => $string };
#		print
#"DeBUG $self->titleString4SubPlot string $string added for subPlot $subPlot\n";
#	}
#
##	print "DEBUG $self->titleString4SubPlot subPlot $subPlot array $dataArray hash @$dataArray[$subPlot]\n";
##	print "\tDEBUG $self->titleString4SubPlot title = @$dataArray[$subPlot]->{title}\n";
#	unless ( defined @$dataArray[$subPlot] ) {
#		warn
#		  "$self->titleString4SubPlot for subPlot $subPlot is not defined!\n";
#		return undef;
#	}
#	return @$dataArray[$subPlot]->{title};
#}
#
#sub subTitleString4SubPlot {
#	my ( $self, $subPlot, $subTitle, $string ) = @_;
#	my ( $pictureOrder, $data );
#	die
#"$self->subTitleString4SubPlot absolutely needs a subTitle in int format (not $subTitle)\n"
#	  unless ( int($subTitle) == $subTitle );
#	$pictureOrder = $self->{pictureOrder};
#	$data         = @$pictureOrder[$subPlot];
#	if ( defined $string ) {
#		@$data[$subTitle]->{subTitle} = $string;
#	}
#	@$data[$subTitle]->{subTitle};
#}
#
#sub orderByCelltype {
#	my ( $self, $celltypeOrder, $antibodyOrder ) = @_;
#	my ( $data, @pictureOrder, $subPlotNumber, $subPlotRef, $ab_number,
#		$title );
#	$data = $self->{data}->{'enrichmentData'};
#	$self->{pictureOrder} = \@pictureOrder;
#	warn "construction of the initial picture order\n";
#
#	foreach my $dataSet (@$data) {
#		( $subPlotNumber, $title ) =
#		  $self->_getPositionInArray( $dataSet->{cellType}, @$celltypeOrder );
#
##warn "we got the subPlot Nr. $subPlotNumber and the string $title for the celltype $dataSet->{cellType}\n";
#		$self->titleString4SubPlot( $subPlotNumber, $title );
#
#		unless ( defined @pictureOrder[$subPlotNumber] ) {
#			my @temp;
#			@pictureOrder[$subPlotNumber] = \@temp;
#		}
#
#		$subPlotRef = @pictureOrder[$subPlotNumber];
#		( $ab_number, $title ) =
#		  $self->_getPositionInArray( $dataSet->{antibodySpecificity},
#			@$antibodyOrder );
#		$self->AddAdditionalSpaceForHMMDataSets( $subPlotNumber,
#			$self->getAmountOfEnrichmentDataSets4subPlot($subPlotNumber) );
#
#		@$subPlotRef[$ab_number] = $dataSet;
#		$dataSet->{subTitle} = "$dataSet->{arrayCount}x $title";
#
#	}
#
#	$self->removeUnusedSubplots();
#
#	return 1;
#}

sub amountOfSubPlots {
	my ($self) = @_;
	my ($pictureOrder);
	$pictureOrder = $self->{pictureOrder};
	my $i = @$pictureOrder;
	return $i;
}

sub getInfo4subPlot {
	my ( $self, $subPlotNumber ) = @_;
	die
"$self->getInfo4subPlot : you have to insert data before using this method!\n"
	  unless ( defined $self->{pictureOrder} );
	my ( $subPlotData, @return, $data );
	
	$data         = $self->{pictureOrder}[$subPlotNumber]{data};
	print
"DEBUG $self->getInfo4subPlot dataset for cellTypeID $subPlotNumber = $data\n";

	foreach my $dataSet (values %$data) {

		next unless ( defined $dataSet );
		print
"DEBUG $self->getInfo4subPlot adds { antibody => $dataSet->{title} , celltype => $dataSet->{celltype} }\n";
		push(
			@return,
			{
				antibody => $dataSet->{title},
				celltype => $dataSet->{celltype}
			}
		);
	}
	return \@return;
}

#sub getEnrichmentData4subPlot {
#	my ( $self, $subPlot ) = @_;
#	my ( $pictureOrder, @return, $data );
#	die
#"$self->getInfo4subPlot : you have to sort the data values before using this method!\n"
#	  unless ( defined $self->{pictureOrder} );
#	$pictureOrder = $self->{pictureOrder};
#	print
#"DEBUG $self->getEnrichmentData4subPlot for subPlot $subPlot = @$pictureOrder[$subPlot]\n";
#	return @$pictureOrder[$subPlot];
#}
#
#sub removeUnusedSubplots {
#	my ($self) = @_;
#	my ( $old_pictureOrder, @newPictureOrder, $subPlotNumber, $ab_number, $temp,
#		$changed, $dataSet );
#	$old_pictureOrder = $self->{pictureOrder};
#
#	## remove all not defined subPlot parts
#	$subPlotNumber = 0;
#	$changed       = 1 == 0;
#	for ( my $i = 0 ; $i < @$old_pictureOrder ; $i++ )
#	{    # $dataSet (@$old_pictureOrder) {
#
#		if ( defined @$old_pictureOrder[$i] ) {
#			$newPictureOrder[$subPlotNumber] = @$old_pictureOrder[$i];
#
##warn "removeUnusedSubplots old subNr $i, old title = ",$self->titleString4SubPlot($i),"\n";
#			$self->titleString4SubPlot( $subPlotNumber,
#				$self->titleString4SubPlot($i) );
#
##warn "removeUnusedSubplots new subNr $subPlotNumber, old title = ",$self->titleString4SubPlot($subPlotNumber),"\n";
#			$subPlotNumber++;
#		}
#	}
#	$self->{pictureOrder} = \@newPictureOrder;
#
#	#return 1 unless ( $changed);
#
#	my @temp;
#	$self->{hmmDataSets} = \@temp;
#	for ( my $i = 0 ; $i < @newPictureOrder ; $i++ ) {
#		$temp      = $newPictureOrder[$i];
#		$ab_number = $self->getAmountOfEnrichmentDataSets4subPlot($i);
#		print
#"DEBUG: $self->removeUnusedSubplots: add $ab_number sets to subpicture $i\n";
#		$self->AddAdditionalSpaceForHMMDataSets( $i, $ab_number );
#	}
#
#	return 1;
#}
#
#sub getAmountOfEnrichmentDataSets4subPlot {
#	my ( $self, $subPlot ) = @_;
#	my ( $data, $count );
#	$data = $self->getEnrichmentData4subPlot($subPlot);
#	foreach my $temp (@$data) {
#		$count++ if ( defined $temp );
#	}
#	return $count;
#}

sub getAmountOfHMMDataSets4subPlot {
	my ( $self, $subPlot ) = @_;
	my ( $data, $count );
	$data = $self->{pictureOrder}[$subPlot]{data};
	foreach my $temp (values %$data) {
		$count++ if ( defined $temp->{hmmData} );
	}
	return $count;
}

sub _getPositionInArray {
	my ( $self, $value, @array ) = @_;
	
	#print "_getPositionInArray searches for $value!\n";
	for ( my $i = 0 ; $i < @array ; $i++ ) {
		if ( defined $array[$i]->{notMatch} ) {

#warn "_getPositionInArray compares '$value' to $array[$i]->{matchingString}\n",
#"the string '$array[$i]->{notMatch}' must not be part of '$value'\n";
			next if ( lc($value) =~ m/$array[$i]->{notMatch}/ );

#			warn "And it was not!\n";
		}
		return $i, $array[$i]->{plotString}
		  if ( lc($value) =~ m/$array[$i]->{matchingString}/ );
	}
}

=head2 createAxies4Subplot

=head3 atributes

[0]: min y position [Pixel]
[1]: space for one subplot [Pixel]
[2]: min value for the enrichment data set
[3]: max value for the enrichment data set
[4]: the data hash where the axies information should be inserted
[5]: the number of HMM data sets to be displayed in this subplot

=head3 return values

A reference to a array with the structure [ [ $featureLines ] ];

=cut

sub createAxies4Subplot {
	my ( $self, $y1, $space4SubPlot_in_pixel, $subPlotCount, $minValue, $maxValue, $hash, $amountOfHMM_data) = @_;

	#print "DEBUG $self createAxies4Subplot got:\n\t",
	# "$y1, $space4SubPlot_in_pixel, $subPlotCount, $minValue, $maxValue, $hash, $amountOfHMM_data\n";
	 
	my ( $freeSpace, $enrichmentDataSpace, $hmmDataSpace);
	$hmmDataSpace = 0;
	$freeSpace = 0.04;
	$hmmDataSpace = (15 * $amountOfHMM_data) / $space4SubPlot_in_pixel if ($space4SubPlot_in_pixel > 0);
	$enrichmentDataSpace = 1 - $freeSpace - $hmmDataSpace;
	
	$hash->{axis} = axis->new(
		"Y",
		int( $y1 + ( $subPlotCount * $space4SubPlot_in_pixel ) ),
		int( $y1 + ( ( $subPlotCount + 1 ) * $space4SubPlot_in_pixel ) ),
		" ", "med"
	);    ## um alles einzugrenzen...
	$hash->{axis}->max_value(1);
	$hash->{axis}->min_value(-1);

	if ( $hmmDataSpace > 0 ) {
		$hash->{hmmAxis} = axis->new(
			"Y",
			int(
				$y1 + ( $subPlotCount * $space4SubPlot_in_pixel ) +
				  $space4SubPlot_in_pixel * ($freeSpace + $enrichmentDataSpace)
			),
			int( $y1 + ( ( $subPlotCount + 1 ) * $space4SubPlot_in_pixel ) ),
			" ", "med"
		);    ## HMM daten direkt unter den anderen Daten (20% des Platzes)!
		$hash->{hmmAxis}->min_value(-1);
		$hash->{hmmAxis}->max_value(1);
		$hash->{hmmAxis}->resolveValue(0);
		$hash->{enrichmentAxis} = axis->new(
			"Y",
			int(
				$y1 + ( $subPlotCount * $space4SubPlot_in_pixel ) +
				  $space4SubPlot_in_pixel * $freeSpace
			),
			int(
				$y1 + ( $subPlotCount * $space4SubPlot_in_pixel ) +
				  $space4SubPlot_in_pixel * ($freeSpace + $enrichmentDataSpace)
			),
			" ", "med"
		);    ## enrichment Daten (mit HMM nur 78% des Platzes)
		$hash->{enrichmentAxis}->min_value($minValue);
		$hash->{enrichmentAxis}->max_value($maxValue);
		$hash->{enrichmentAxis}->{tics} = 3;
		$hash->{enrichmentAxis}->resolveValue(0);
	}
	else {
		$hash->{enrichmentAxis} = axis->new(
			"Y",
			int(
				$y1 + ( $subPlotCount * $space4SubPlot_in_pixel ) +
				  $space4SubPlot_in_pixel *$freeSpace
			),
			int(
				$y1 + ( $subPlotCount * $space4SubPlot_in_pixel ) + $space4SubPlot_in_pixel
			),
			" ", "med"
		);    ## enrichment Daten (ohne HMM 98% vom Platz)
		$hash->{enrichmentAxis}->min_value($minValue);
		$hash->{enrichmentAxis}->max_value($maxValue);
		$hash->{enrichmentAxis}->{tics} = 3;
		$hash->{enrichmentAxis}->resolveValue(0);
	}
	return 1;
}

1;