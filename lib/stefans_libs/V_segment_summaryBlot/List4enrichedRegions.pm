package List4enrichedRegions;
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

use stefans_libs::plot::Font;
use stefans_libs::V_segment_summaryBlot::hmmReportEntry;

use strict;

sub new{

  my ( $class, $enrichedRegions ) = @_;

  my ( $self, @array );

  $enrichedRegions = \@array unless (defined $enrichedRegions); 

  $self = {
	enrichedRegions => $enrichedRegions,
	data_by_celltype => undef
  };

  bless $self, $class  if ( $class eq "List4enrichedRegions" );

  return $self;

}

sub by_ICA{
	return $a->WeightByIteration_cellytpe_antbody() <=> $b->WeightByIteration_cellytpe_antbody();
}
sub by_Iteration{
	return $a->Iteration() <=> $b->Iteration();
}
sub by_CIA{
	return $a->WeightByCellytpe_iteration_antibody() <=> $b->WeightByCellytpe_iteration_antibody();
}



sub amountOfDataSets4celltype{
	my ( $self, $celltype ) = @_;
	
	my ( $data_by_celltype, $temp );
	print "ERROR SEARCH $self amountOfDataSets4celltype \celltype = $celltype\n";
	$data_by_celltype = $self->{data_by_celltype};
	
	if ( $celltype =~ m/:/){
		my @temp = split (":",$celltype);
		$celltype = $temp[1];
	}
	
	unless ( defined $data_by_celltype){
		my $enrichedRegions = $self->{enrichedRegions};
		#print "\tDEBUG $self: List4enrichedRegions::Plot: Type of enriched regions: $enrichedRegions\n";
		foreach my $data ( sort by_CIA @$enrichedRegions){
			unless ( defined $data_by_celltype->{$data->Celltype()}){
				my @temp;
				$data_by_celltype->{$data->Celltype()} = \@temp;
			}
			$temp = $data_by_celltype->{$data->Celltype()};
			push (@$temp, $data);
		}
		$self->{data_by_celltype} = $data_by_celltype;
	}
	#print "ERROR SEARCH $self amountOfDataSets4celltype #2 \celltype = $celltype\n";
	#root::print_hashEntries	($data_by_celltype,2,"does the first level ID $celltype exist?\n");
	my $dataArray = $data_by_celltype->{$celltype};
	root::print_hashEntries	($dataArray,2,"What is returned for the celltype $celltype?\n");
	return 0 unless ( defined @$dataArray);
	my $i = @$dataArray;
	return $i;
}

sub _getPositionInArray{
	my ($self, $value, @array) = @_;
	for (my $i = 0; $i < @array; $i++){
		if ( defined $array[$i]->{notMatch} ) {
			 #warn "_getPositionInArray compares '$value' to $array[$i]->{matchingString}\n",
			 #"the string '$array[$i]->{notMatch}' must not be part of '$value'\n";
			 next if ( lc($value) =~m/$array[$i]->{notMatch}/ );
			 #warn "And it was not!\n";
		}
		return $i, $array[$i]->{plotString} if ( lc($value) =~m/$array[$i]->{matchingString}/);
	}
}

sub getEnrichedRegions4CelltypeAndAntibody{
	my ($self, $celltype, $antibody ) = @_;
	
	my ( @list, $i, @cellTypes);
	my $enrichedRegions = $self->{enrichedRegions};
	
	foreach my $List (@$enrichedRegions){
		print "DEBUG $self -> getEnrichedRegions4CelltypeAndAntibody comparision!\n",
		"is celltype $celltype the same as $List->{info}->{CellType}\n";
		push(@list, $List) if (
			$List->{info}->{AB} eq $antibody && 
			NimbleGene_config::isTheSameCelltype($celltype, $List->{info}->{CellType})
		);
		$i = $List->{Iteration} if ( $i < $List->{Iteration});
	}
	foreach my $list (@list){
		return $list if ( $list->{Iteration} == $i );
	}
	return undef;
}


sub Print {
	my ( $self ) = @_;
	my $data = $self->{enrichedRegions};
	my $i = 0;
	foreach my $value (@$data){
		print "L1 = ",$i++,"  = $value\n";
		if ( lc($value) =~ m/hash/ ){
			foreach my $key2 ( keys %$value ){
				print "\tL2 = $key2 -> $value->{$key2}\n";
				if ( $key2 =~ m/info/){
					my $temp = $value->{$key2};
					while (my ($keys3, $value2 ) = each ( %$temp)){
						print "\t\t L3 = $keys3 -> $value2\n";
					}
				}
			}
		}
		if ( lc($value) =~ m/array/ ){
			foreach my $key2 ( @$value ){
				print "\tL2 = $key2\n";
			}
		}
	}
	print "fertig\n";
}

sub Plot {
	my ( $self, $dataArray, $im, $x_axis, $y1, $y2, $gbFileString, $ColorObject ) = 
		@_;
	my ( $enrichedRegions, $amountOfPlottedDatasets, $delta_y, $font, $enrichmentDataSet, $actual_yStart);
	$font = Font->new("med");
	
	#print "DEBUG: $self->Plot hos the values ( $dataArray, $im, $x_axis, $y1, $y2, $gbFileString, $ColorObject )\n";
	#print "\twhat is in the $dataArray ??\n";
	#root::print_hashEntries($dataArray,2);
	
	$amountOfPlottedDatasets = 0;
	foreach my $enrichmentDataSet ( @$dataArray){
		$enrichedRegions = undef;
		$enrichedRegions = $self->getEnrichedRegions4CelltypeAndAntibody(
			$enrichmentDataSet->{celltype}, $enrichmentDataSet->{antibody}
		);
		$amountOfPlottedDatasets ++ if ( defined $enrichedRegions);
	}
	return undef if ( $amountOfPlottedDatasets == 0);
	
	$delta_y = ($y2 - $y1) / ($amountOfPlottedDatasets);
	
	#print "DEBUG: $self->plot: We get no plotted HMM Datasets!\n",
	#	"maybe because the \$dataArray $dataArray does not contain any Information?\n";
	$actual_yStart = $y1;
	
	for ( my $i = 0; $i < @$dataArray; $i ++){
		$enrichmentDataSet = @$dataArray[$i];
		print "\tDEBUG $self->plot: celltype = $enrichmentDataSet->{celltype} and antibody = $enrichmentDataSet->{antibody}\n";
		$enrichedRegions = undef;
		$enrichedRegions = $self->getEnrichedRegions4CelltypeAndAntibody(
			$enrichmentDataSet->{celltype}, $enrichmentDataSet->{antibody}
		);
		unless ( defined $enrichedRegions){
			warn "could not find a enrichmentDataSet for celltype $enrichmentDataSet->{cellType} and antibody $enrichmentDataSet->{antibodySpecificity}\n";
			next;
		}
		#print "\tDEBUG $self->plot: we print (!!) between x1/y1 ",
		#$x_axis->resolveValue($x_axis->max_value()),"/$y1 and x2/y2 ",
		#$x_axis->resolveValue($x_axis->min_value()),"/$y2 for the gbFileString $gbFileString\n",
		#	"\tcolor = ",$ColorObject->selectColor($enrichmentDataSet->{celltype}, $enrichmentDataSet->{antibody}),"\n";
		#print "DEBUG question in List4enrichedRegions:\n\tis the varaiable \$enrichedRegions a class object (?) : $enrichedRegions\n"; # (YES 25.08.2008)
		
		$enrichedRegions ->Plot( $im, $x_axis, $actual_yStart, $actual_yStart + $delta_y, $gbFileString, 
			$ColorObject->selectColor($enrichmentDataSet->{celltype}, $enrichmentDataSet->{antibody}), 
			$ColorObject->{grey}, undef);
		$actual_yStart += $delta_y;
		#print "DEBUG $self Question: What is in the object \$enrichedRegions?\n";
		#root::print_hashEntries($enrichedRegions,3);
	}
	
	$im->rectangle($x_axis->resolveValue($x_axis->min_value() ),
		$y1, $x_axis->resolveValue($x_axis->max_value() ),
		$y2, $ColorObject->{black});


#	$i = 0;
#	foreach my $data (sort by_Iteration @$dataArray){
#	#for (my $i = 0; $i < @$dataArray; $i++){
#		
#		unless (defined $lastIteration ){
#			$lastIteration = $data->Iteration();
#			push(@changePoints,{ count => $i , iteration => $lastIteration - 1 });
#		}
#		$multiline_HMM_Axis = multiline_HMM_Axis->new(
#			$data->getEnrichedRegions4gbFileString($gbFileString), 
#			$y1 + $y_delta * $i, 
#			$y1 + $y_delta * ( $i + 1 ),
#			$x_axis,
#			$ColorObject->selectColor(@$dataArray[$i]->Celltype, @$dataArray[$i]->Antibody), $ColorObject
#		);
#		$multiline_HMM_Axis->plot($im);
#		unless ( $lastIteration == $data->Iteration()) {
#			
#			$im->setThickness(3);
#			$im->line($x_axis->resolveValue($x_axis->min_value() ),
#				$y1 + $y_delta * ( $i ),
#				$x_axis->resolveValue($x_axis->max_value() ),
#				$y1 + $y_delta * ( $i ),
#				$ColorObject->{black}
#			);
#			$im->setThickness(1);
#			$im->line($x_axis->resolveValue($x_axis->min_value() ),
#				$y1 + $y_delta * ( $i ),
#				$x_axis->resolveValue($x_axis->max_value() ),
#				$y1 + $y_delta * ( $i ),
#				$ColorObject->{grey}
#			);
#			$lastIteration = $data->Iteration();
#			push(@changePoints,{ count => $i, iteration => $lastIteration - 1});
#		}
#		$i++;
#	}
#	push(@changePoints,{ count => $i, iteration => $lastIteration - 1 });
#	for ($i = 0; $i < @changePoints -1 ; $i++){
#		print "\tTry to plot in range", join (" - ", ($x_axis->resolveValue($x_axis->min_value() ) - 25,
#			$y1 + $y_delta * ( $changePoints[$i]->{count} ),
#			$x_axis->resolveValue($x_axis->min_value() ) - 5,
#			$y1 + $y_delta * ( $changePoints[$i+1]->{count}))),"\n";
#		$font->drawStringInRegion_Ycentered_rightLineEnd(
#			$im,
#			#"HMM #$changePoints[$i]->{iteration}", 
#			"#$changePoints[$i]->{iteration}",
#			$x_axis->resolveValue($x_axis->min_value() ) - 15,
#			$y1 + $y_delta * ( $changePoints[$i]->{count} ),
#			$x_axis->resolveValue($x_axis->min_value() ) - 3,
#			$y1 + $y_delta * ( $changePoints[$i+1]->{count}),
#			$ColorObject->{black}, "tiny"
#		) if (defined $changePoints[$i]->{iteration}) ;
#	}
#	## Fertig
#	#$data_by_celltype = undef;
#	return 1;
}



sub AddData{
	my ( $self, $data) = @_;
	#Hier werden die daten eingefŸgt, die ein gffFile->getEnrichedRegions("filename") zurŸckgibt!
	#print "List4enrichedRegions got one $data->{HMM_by_gbFile} object!\n";
	if ( $data =~ m/enrichedRegions/ ) {
		my $enrichedRegions = $self->{enrichedRegions};
		push (@$enrichedRegions, $data );
		#print "List4enrichedRegions: we had an insert!\n";
	}
	$self->{data_by_celltype} = undef;
	return 1;
}

sub isEnriched{
	my ( $self, $gbFileString, $gbFeature) = @_;
	my ($info, $enrichmentState );
	my $data = $self->{enrichedRegions};
	my $reportEntry = hmmReportEntry->new($gbFileString, $gbFeature);
	for ( my $i = 0; $i < @$data; $i++){
		$reportEntry->AddSearchResult(@$data[$i]->isEnriched($gbFileString, $gbFeature));
	}
	return $reportEntry;
}

sub getCountForCelltype{
	my ( $self, $celltype) = @_;
	my ( $return, $hmmArray, @array, $celltypeString );
	$celltypeString = $celltype;
	
	$return = $self->{celltypeCount};
	if ( $celltype =~ m/:/){
		@array = split(":",$celltype);
		@array = split( " ",$array[1]);
		$celltypeString = join(" ",@array);
	}
	if ( $celltype =~ m/_/){
		@array = split("_",$celltype);
		$celltypeString = join(" ",@array);
	}
	
	unless ( defined $return) {
		$hmmArray = $self->{enrichedRegions};
		print "\tDo we have some entries in $hmmArray?:\n";
		foreach my $HMM_data (@$hmmArray){
			print "\t\tentry = $HMM_data\n";
			unless ( defined $return->{$HMM_data->Celltype()}){
				$return->{$HMM_data->Celltype()} = 0;
			}
			$return->{$HMM_data->Celltype()} ++;
		}
		$self->{celltypeCount} = $return;
	}
	foreach my $key ( keys %$return){
		return $return->{$key} if ( $key eq $celltypeString );
	}
	print "\tUnter allen Zelltypen (", join( "; ",(keys %$return)), ") war der Zelltyp '$celltype' nicht vorhanden!\n";
	return 0;
}

1;
