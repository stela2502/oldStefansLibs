package GFF_data_Y_axis;
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
use stefans_libs::V_segment_summaryBlot::selected_regions_dataRow;
use stefans_libs::V_segment_summaryBlot::oligoBinReport;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

GFF_data_Y_axis

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

=head3 retrun values

A object of the class GFF_data_Y_axis

=cut

sub new {

   my ( $class, $line, $what ) = @_;

   my ( $self, %data, @cellTypes, @antibodyOrder);

    @cellTypes = NimbleGene_config::GetCelltypeOrder();

    @antibodyOrder = NimbleGene_config::GetAntibodyOrder(); 

   $self = {
	 oligoReport => oligoBinReport->new(),
	 plotLable => 1== 0,
     data => \%data,
	 UseMean => 1 == 1,
	 summary  => 1 ==0,
     binLength => 200,
     max       => undef,
	 useStdDev => 1 == 0,
#     flushMedian => 1 == 1,
     flushMedian => 1 == 0,
     min       => undef,
	 max_std  => undef,
	 min_std  => undef,
	 max_oligo_count     => 20 
   };
	print "$self->{oligoReport}\test test test test\n";
   bless ($self , $class ) if ( $class eq "GFF_data_Y_axis");
   return $self;
}

sub WindowSize{
	my ( $self, $windosize ) = @_;
	$self->{binLength} = $windosize if (defined $windosize);
	return $self->{binLength};
}

sub UseStdDev {
  my ( $self, $stdDev) = @_;
  $self->{useStdDev} = $stdDev if ( defined $stdDev );
  return $self->{useStdDev};
  return 1 == 0;
}

sub UseBars {
	my ( $self, $bars ) = @_;
	$self->{bars} = $bars if ( defined $bars);
	return $self->{bars};
}

sub UseMedian {
	my ( $self, $bool) = @_;
	$self->{useMedian} = $bool if ( defined $bool);
	return $self->{useMedian};
}

sub OrderPlotsByAntibody {
  my ( $self, $stdDev) = @_;
  $self->{orderByAK} = $stdDev if ( defined $stdDev );
  return $self->{orderByAK};
  return 1 == 0;
}

sub UseStdErrMean{
  my ( $self, $stdErr) = @_;
  $self->{useStdErr} = $stdErr if ( defined $stdErr );
  return $self->{useStdErr};
  return 1 == 0;
}

sub LargeDots {
	my ($self, $summary) = @_;
	if (defined $summary){
		$self->{summary} = $summary;
	}
	return $self->{summary};
}

sub SeparateArrays{
	my ($self, $summary) = @_;
	if (defined $summary){
		$self->{separate_arrays} = $summary;
	}
	return 1 == 0 unless ( defined $self->{separate_arrays});
	return $self->{separate_arrays};
}

sub Min{
  my ( $self, $min) = @_;
#  print "$self: Min($min) stored min = $self->{min}\n";
  $self->{min} = $min unless ( defined $self->{min});
  $self->{min} = $min if ( defined $min && $min < $self->{min});
  return $self->{min};
}

sub Max{
  	my ( $self, $max) = @_;
 	# root::identifyCaller($self,"Max");
 	# print "$self: Max($max) stored max = $self->{max}\n";
 	$self->{max} = $max unless ( defined $self->{max});
  	$self->{max} = $max if ( defined $max && $max > $self->{max});
  	return $self->{max};
}

sub setMax2value{
	my ( $self, $max) = @_;
	$self->{max} = $max if ( defined $max);
	return $max;
}

sub setMin2value{
	my ( $self, $min) = @_;
	$self->{min} = $min if ( defined $min);
	return $min;	
}

sub AddDataforChipType_old {
  my ( $self, $designString, $antibodySpecificity, $cellType, $dataArray, $length, $end ) = @_;
  my ( $dataHash );
  
  warn "depricated use NEW_Summary_GFF_Y_axis::AddDataforChipType_new()\n";
  return undef unless ( defined $antibodySpecificity);
  $dataHash =  $self-> ChipType ($designString, $antibodySpecificity, $cellType);
  $dataHash -> DataCount (1);
  #warn "$self:  conceptional error: all data lists mus be kept per gbFile!\n" unless (@$dataArray == 1);
 
  #print "DEBUG $self AddDataforChipType_old \$dataHash is of type $dataHash\n";
  #root::print_hashEntries($dataHash,3);
  ## Konzeptioneller FEHLER!! die Data rows muessen pro oligoLocationCenter gefuehrt werden!!!!
  root::print_hashEntries($dataArray,3,"ist da die NimbleGeneID mit drinn versteckt??\n#### $self AddDataforChipType_old \$dataArray\n");
  #print "We now insert the oligos from $dataArray into $dataHash\n";
  foreach my $oligoLocationCenter ( @$dataArray) {
  	  #print "DEBUG oligoLocationCenter?? $oligoLocationCenter\n";
  	  unless ( defined $dataHash -> {data}){
   		 #print "$self: new dataRow: $length, $self->{binLength}, $end \n";
 	  	 $dataHash -> {data} = dataRow->new($length, $self->{binLength}, $end);
 	 }
  	 next unless ( $dataHash->{data}->isRelevantOligo($oligoLocationCenter->{mean}));
     $self->Max( $oligoLocationCenter->{value}); 
     $self->Min( $oligoLocationCenter->{value});
     $dataHash -> {data}->AddOligo($oligoLocationCenter->{mean}, $oligoLocationCenter->{value}, $self->{flushMedian}, $oligoLocationCenter->{oligoID});
  }
  $dataHash -> {data}-> flush_median ($self->{flushMedian});
  return 1;
}

sub AddDataforChipType {
  my ( $self, $designString, $antibodySpecificity, $cellType, $dataArray, $length, $end, 
  	   $matching_gbTags, $nimbelGeneID ) = @_;
  
  warn "depricated use NEW_Summary_GFF_Y_axis::AddDataforChipType_new()\n";
  
  return $self->AddDataforChipType_old ($designString, $antibodySpecificity, $cellType, $dataArray, $length, $end)
  		unless ( defined $matching_gbTags);
  my ( $dataHash );
  return undef unless ( defined $antibodySpecificity);
  $dataHash =  $self-> ChipType ($designString, $antibodySpecificity, $cellType, $nimbelGeneID);
  #print "was ist denn das: $dataArray ??\n";
  warn "conceptional error: all data lists must be kept per gbFile!\n" unless ($dataArray == 1);
  
  #print "DEBUG $self AddDataforChipType \$dataHash is of type $dataHash\n";
  root::print_hashEntries($dataArray,3,"ist da die NimbleGeneID mit drinn versteckt??\n#### $self AddDataforChipType \$dataArray\n");
  
  #print "We now insert the oligos from $dataArray into $dataHash\n";
  foreach my $oligoLocationCenter ( @$dataArray) {
    
   	  #print "DEBUG with Features!! oligoLocationCenter?? $oligoLocationCenter\n";
  	  unless ( defined $dataHash -> {data}){
	  	  #print "DEBUG: $self AddDataforChipType : do we have a gbFile ($oligoLocationCenter->{gbFile})\n";
	  	  $dataHash -> {data} = selected_regions_dataRow->
	  	  		new($length, $self->{binLength}, $end, $oligoLocationCenter->{gbFile}, $matching_gbTags);
	  }
  	 #print "oligo start $oligoLocationCenter->{mean} sol genutzt werden?\n";
  	 next unless ( $dataHash->{data}->isRelevantOligo($oligoLocationCenter->{mean}));
  	 #print "JA!!\n";
     #$self->Max( $oligoLocationCenter->{value}); 
     #$self->Min( $oligoLocationCenter->{value});
#	 print "Lies this oligo in the range $length-$end? $oligoLocationCenter->{mean}\n";
     $dataHash -> {data}->AddOligo($oligoLocationCenter->{mean}, $oligoLocationCenter->{value}, $self->{flushMedian}, $oligoLocationCenter->{oligoID});
  }
  $dataHash -> {data}-> flush_median ($self->{flushMedian});
  return 1;
}

sub plot{
  my ( $self, $im, $y1, $y2, $x_axis, $color, $title, $resolution, 
       $legend, $font,$min_override, $max_override ) = @_;
  print "GFF_data_Y_axis atributes:\n",
      " \$self = $self\n\$im = $im\n\$y1 = $y1\n\$y2 = $y2\n\$x_axis = $x_axis\n\$color = $color\n\$title = $title\n\$resolution = $resolution\n", 
       "\$legend = $legend\n\$font = $font\n\$min_override = $min_override\n\$max_override = $max_override\n";

  my ( $data, $Y );
  $self->{legend} = $legend;
  $self->{im} = $im;
  $self->{font} = $font;
  $self->{colorObject} = $color;
  $self->{color} = $color;
  $data = $self->getAsPlottable();

#  print "GFF_data_Y_axis plot Y axis min = ",$self->Min(), " max = ", $self->Max(),"\n";
  $Y = axis->new(
        "Y",
        $y1,
        $y2,
        $title, $resolution
  );
  if ( $self->Max == $self->Min){
  	$self->Max($self->Max + 0.5);
  	$self->Min($self->Min - 0.5);
  }
  if ( $self->UseStdDev()){
		$Y->max_value($self->Max);
		$Y->min_value($self->Min);
  }
  else {
  		$Y->max_value($self->Max);
		$Y->min_value($self->Min);
  }	
#	$self->Max( $max_override ) if ( defined $max_override );
#	$self->Min( $min_override ) if ( defined $min_override );
	
#  print "GFF Yaxis min, max ", $Y->min_value(), $Y->max_value,"\n";
  $self->{axis} = $Y;
#  $max_override = 4;
#  $min_override = -3;
  $Y->max_value($self->Max($max_override)) if ( defined $max_override);
  $Y->min_value($self->Min($min_override)) if ( defined $min_override);
#  print "GFF_data_Y_axis min = ", $self->{axis}->min_value()," max = ", $self->{axis}->max_value(),"\n";
  $Y->plot($im,$x_axis->resolveValue($x_axis->min_value()), $self->{colorObject}->{black}); ## plot ruler
  $self->{im}->line(
	$x_axis->resolveValue( $x_axis->min_value() ) , $Y->resolveValue( 0 ),
    $x_axis->resolveValue( $x_axis->max_value() ) , $Y->resolveValue( 0 ),
	$self->{colorObject}->{grey});
  $self->{im}->line( 
	$x_axis->resolveValue( $x_axis->min_value() ) , $Y->resolveValue($Y->max_value()),
	$x_axis->resolveValue( $x_axis->max_value() ) , $Y->resolveValue( $Y->max_value() ),
	$self->{colorObject}->{black});
  $self->{im}->line(
	$x_axis->resolveValue( $x_axis->max_value() ), $Y->resolveValue($Y->min_value()),
	$x_axis->resolveValue( $x_axis->max_value() ) , $Y->resolveValue( $Y->max_value() ),
	$self->{colorObject}->{black});
	
  $self->Plot_DataPoints($data, $x_axis, $Y );
  $self->Plot_StdErrMean($data, $x_axis, $Y ) if ( $self->UseStdErrMean);
  $self->Plot_Std($data, $x_axis,$Y) if ( $self->UseStdDev); 
} 

sub getMinimumPoint{
    my ( $self ) = @_;
	return $self->{axis}->getMinimumPoint();
}

sub resolveValue{
    my ( $self, $value) = @_;
	return $self->{axis}->resolveValue($value);
}

sub Dimension{
	my ( $self) = @_;
	return $self->{axis}->{dimension} unless ( $self->{axis}->{dimension} == 0);
	return $self->{axis}->getDimension( $self->{axis}->max_value() - $self->{axis}->min_value() );
}	

sub Plot_StdErrMean {
    my ( $self, $Y_data, $X, $Y ) = @_;
	my ( $color, $colors, $i, $data, $last, $act ) ;
    $i      = 0;
    $colors = $self->{color};
    $self->{im}->setThickness(1);
    foreach my $hybType (@$Y_data) {
        $data = $hybType->{data};
        $last = undef;
		$color = $self->{colorObject}->selectColor($hybType->{cellType}, $hybType->{antibodySpecificity});
        foreach my $oligoBinRep (@$data) {
            next
              if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
            $act = {
                x => $X->resolveValue( $oligoBinRep->{bp} ),
                y => $Y->resolveValue( $oligoBinRep->{median} ),
                min => $Y->resolveValue(
                    $oligoBinRep->{mean} - $oligoBinRep->{stdErrMean}
                ),
                max => $Y->resolveValue(
                    $oligoBinRep->{mean} + $oligoBinRep->{stdErrMean}
                )
            };

            $self->{im}->line( $act->{x}, $act->{max}, $act->{x}, $act->{min},
                $color );

            $self->{im}->line(
                $act->{x} - 3,
                $act->{min},
                $act->{x} + 3,
                $act->{min},
                $color
			);
            $self->{im}->line(
                $act->{x} - 3,
                $act->{max},
                $act->{x} + 3,
                $act->{max},
                $color
			);
        }

    }
}

sub Plot_Std {
    my ( $self, $Y_data, $X, $Y ) = @_;
	my ( $color, $colors, $i, $data, $last, $act ) ;
    $i      = 0;
    $colors = $self->{color};
    $self->{im}->setThickness(1);
    foreach my $hybType (@$Y_data) {
        $data = $hybType->{data};
        $last = undef;
		$color = $self->{colorObject}->selectColor($hybType->{cellType}, $hybType->{antibodySpecificity});
        foreach my $oligoBinRep (@$data) {
            next
              if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
            $act = {
                x => $X->resolveValue( $oligoBinRep->{bp} ),
                y => $Y->resolveValue( $oligoBinRep->{median} ),
                min => $Y->resolveValue(
                    $oligoBinRep->{mean} - $oligoBinRep->{stdDev}
                ),
                max => $Y->resolveValue(
                    $oligoBinRep->{mean} + $oligoBinRep->{stdDev}
                )
            };

            $self->{im}->line( $act->{x}, $act->{max}, $act->{x}, $act->{min},
                $color );

            $self->{im}->line(
                $act->{x} - 3,
                $act->{min},
                $act->{x} + 3,
                $act->{min},
                $color
			);
            $self->{im}->line(
                $act->{x} - 3,
                $act->{max},
                $act->{x} + 3,
                $act->{max},
                $color
			);
        }

    }
}

sub Plot_DataPoints {
    my ( $self, $Y_data, $X, $Y ) = @_;
    my ( $i, $tokens, $colors, $data, $last, $act ,$color, $lastBP, $maxDifference);
	$maxDifference = $self->{binLength} * 1.5;
	$maxDifference = 500 if ( $maxDifference < 500);
    $i      = 0;
    $tokens = $self->{tokens};
    $colors = $self->{color};
    $self->{im}->setThickness(3);
    foreach my $hybType (@$Y_data) {
        $data = $hybType->{data};
        $last = undef;
		$color = $self->{colorObject}->selectColor($hybType->{cellType}, $hybType->{antibodySpecificity});
#		print "color for $hybType->{cellType}, $hybType->{antibodySpecificity} = $color\n";
        foreach my $oligoBinRep (@$data) {
            next
              if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
			$lastBP = $oligoBinRep->{bp} unless ( defined $lastBP);
            $act = {
                x => $X->resolveValue( $oligoBinRep->{bp} ),
                y => $Y->resolveValue( $oligoBinRep->{median} ),
                min => $Y->resolveValue(
                    $oligoBinRep->{mean} - $oligoBinRep->{stdDev}
                ),
                max => $Y->resolveValue(
                    $oligoBinRep->{mean} + $oligoBinRep->{stdDev}
                )
            };
			$act->{y} = $Y->resolveValue( $oligoBinRep->{mean} ) if ( $self->{UseMean} );
            $self->{legend}->AddEntry(
                $hybType->{antibodySpecificity},
                $hybType->{cellType},
                $self->{colorObject}->Token( $hybType->{cellType} ),
                $color
			) if ( defined $self->{legend});
            $self->{font}->plotStringCenteredAtXY(    #plotSmallString(
                $self->{im},
                $self->{colorObject}->Token( $hybType->{cellType} ),
                $act->{x},    # - $self->{tokenX_correction},
                $act->{y},    # - $self->{tokenY_correction},
                $color,
                "large",
                0
            ) if ( $self->{plotLable});
            unless ( $self->{summary} ){
				$self->{im}->setPixel($act->{x},$act->{y},$color) unless ( $self->{plotLable});
				$self->{im}->line(
			    $act->{x},
       	        $act->{y},
       	        $last->{x},
       	        $last->{y},
       	        $color
				) if ( defined $last && $oligoBinRep->{bp} - $lastBP < $maxDifference );
				$lastBP = $oligoBinRep->{bp};
            }
            else{
            	$self->plot_a_Raute($act->{x}, $act->{y}, 6, $color);
            	$lastBP = $oligoBinRep->{bp};
            }
            $last = $act;
        }
    }
    $self->{im}->setThickness(1);

}

sub redefineCelltype{
	my ($self, $celltype) = @_;
	my @array;
	
	if ( $celltype =~ m/:/){
		@array = split(":",$celltype);
		@array = split( " ",$array[1]);
		$celltype = join(" ",@array);
	}
	return $celltype;
}

=head2 getAsPlottable

=head3 return value

returns a plottable data structure of the type
[ { designString => string , antibodySpecificity => string, cellType => string,
    data => [ { bp => bin location float, mean => value mean float, StdDev => value StdDev } ] } ]

=cut

sub getAsPlottable {
  my ( $self, $min_override, $max_override ) = @_;

  my (@return, $data, $i, $min, $min_std, $min_err, $max, $max_std, $max_err);
  $data = $self->{data};
  $i = 0;
  $self->{max} = undef;
  $self->{min} = undef;
  #warn "jetzt gehts los!!($self)\n";
  #root::print_hashEntries($self->{data}, 7 ,"DEBUG: $self->{data} (data hash)\n");
  #die "Do not use this method any more - BUGGY!!\n";
  foreach my $value ( values %$data){
     my $hash;
     #print "DEBUG $self->getAsPlottable has multiple hashes called \$value:\n";
     #root::print_hashEntries($value, 3);
     
     $hash->{designString} = $value->{designString};
     $hash->{antibodySpecificity} = $value->{antibodySpecificity};
     $hash->{cellType} = $value->{cellType};
     $hash->{arrayCount} = $value->{data}->DataCount();
     $hash->{data} = $value->{data}->getAsPlottable();
     ($min, $min_std, $min_err) = $value->{data}->min();
     ($max, $max_std, $max_err) = $value->{data}->max();
     
     $self->Max($max);
     $self->Min($min);
     
     if ($self->UseStdDev){
     	$self->Max($max_std);
     	$self->Min($min_std);
     }
     
     if ($self->UseStdErrMean){
     	$self->Max($max_err);
  	   	$self->Min($min_err);
     }
     $self->setMax2value($max_override);
     $self->setMin2value($min_override);
     
     ## die HMM daten muessen aufbereitet werden!!
     ##$hash->??
	 #$hash->{n} = $value->{data}->{n};
	 $hash->{ID} = "$value->{designString} $value->{antibodySpecificity} $value->{cellType}";
     $return[$i++] = $hash;
	 
  }  
  return \@return;
}

sub printOligoData4Bin {
  my ( $self, $binNr, $pathToFiles ) = @_;
  my ( $data );
  $data = $self->{data};
  foreach my $hybType (values %$data){
    $self->{oligoReport}->AddToOligoReport(
		$hybType->{data}->printOligoData4Bin($binNr, "$pathToFiles/$hybType->{cellType}-$hybType->{antibodySpecificity}.dat" ),
		$data->{$hybType}->{cellType},$data->{$hybType}->{antibodySpecificity});
  }
  #$self->{oligoReport}->writeOligoReport("$pathToFiles/$binNr.dat");
  return 1;
}  

sub printOligoData4Bin_inBP {
  my ( $self, $binBP, $pathToFiles ) = @_;
  my ( $data );
  $data = $self->{data};
  foreach my $hybType (keys %$data){
	print "GFF_data_Y_axis printOligoData4Bin_inBP: $data->{$hybType}->{cellType},$data->{$hybType}->{antibodySpecificity}\n";
	$self->{oligoReport}->AddToOligoReport(
		$data->{$hybType}->{data}->printOligoData4Bin_inBP($binBP, "$pathToFiles/$binBP-$hybType.dat" ),
		$data->{$hybType}->{cellType},$data->{$hybType}->{antibodySpecificity});
  }
  #$self->{oligoReport}->writeOligoReport("$pathToFiles/$binBP.dat");
  return 1;
}	

sub writeOligoReport{
	my ( $self, $pathToFiles) = @_;
	return $self->{oligoReport}->writeOligoReport("$pathToFiles/evaluation.dat");
}

sub ChipType {

  my ( $self, $designString, $antibodySpecificity, $cellType, $nimbelGeneID ) = @_;
  
  print "DEBUG $self ChipType got nimbleGeneID $nimbelGeneID\n";

  my $string;
  $string = "$designString$antibodySpecificity$cellType$nimbelGeneID";
  
  unless ( defined $self->{data}->{$string}){
     my %hash;
     $self->{data}->{$string} = \%hash;
     $self->{data}->{$string}->{designString} = $designString;
     $self->{data}->{$string}->{antibodySpecificity} = $antibodySpecificity ;
     $self->{data}->{$string}->{cellType} = $cellType;
     $self->{data}->{$string}->{NimbleGeneID} = $nimbelGeneID;
  } 
  return $self->{data}->{$string};
}


sub GetTableHeader{
	my ( $self, $what ) = @_;
	
	if ($what eq "organism"){
		die "The data type organism is not jet included in the evaluation!\n";
	}
	else{
		my ( $data, @returnLine, $line1, $line2 );
		$data = $self->{data};
		foreach my $chipType ( sort keys %$data ){
			push (@returnLine, ("$data->{$chipType}->{cellType} - $data->{$chipType}->{antibodySpecificity}", " ") );
		}
		$line1 = join("\t", @returnLine);
		@returnLine = undef;
		foreach my $chipType ( sort keys %$data ){
			push (@returnLine, ("mean","std.dev."));
		}
		$line2 = join("\t",@returnLine);
		return $line1, $line2;
	}
}

sub GetAsTableLine{
	my ( $self ) = @_;
	my ( $data, @returnLine );
	$data = $self->{data};
	foreach my $chipType ( sort keys %$data ){
		push( @returnLine, ($data->{$chipType}->{data}->GetAsTableLine()));
	}
	return join ("\t",@returnLine);
}

=head2 AsTable

=head3 atributes

none

=head3 return values

returns the reference to a has with the structure
{ '$start position on sequence' => { '$hyb type' => { mean => <float>, std => <float> } } }.

=cut

sub AsTable{
  my ( $self, $position ) = @_;
  my ( $data, $hash, $mean, $std );
  
  $data = $self->{data};
  foreach my $hybType ( keys %$data){
     ( $position, $mean, $std) =  $data->{$hybType}->{data}->GetAsLineArray();
	 for (my $i = 0; $i < @$position; $i++){
	    if ( defined @$std[$i]){
	    unless ( defined $hash->{@$position[$i]} ) {
		   my %temp;
		   $hash->{@$position[$i]} = \%temp;
		}
	#	print "!!!!-AsTable-!!!! position @$position[$i] -> mean @$mean[$i] std @$std[$i]\n";
		
		$hash->{@$position[$i]} ->{$hybType} = { mean => @$mean[$i], std => @$std[$i]};
		}
	 }
  }
  return $hash;
}

sub AsTable_inBP{
  my ( $self, $position ) = @_;
  my ( $data, $hash);
  
  $data = $self->{data};
  foreach my $hybType ( keys %$data){
	my $temp;
     ( $temp->{position}, $temp->{mean}, $temp->{std}, $temp->{stdError}) =  $data->{$hybType}->{data}->GetAsLineArray_inBP($position);
	 $hash->{$hybType} = $temp;
  }
  return $hash;
}

sub AsTable_old {
  my ( $self ) = @_;
  my ( $data, @array, $location, $values, $StdAbw, $i, $print, @print);
#  open (OUT, ">$filename") or die "Konnte File $fielname nicht anlegen!\n";

  $data = $self->{data};
  foreach my $type (keys %$data){
      ($location, $values, $StdAbw) = $data->{$type}->{data}->GetAsLineArray();
      @print = ("Location $type\t",join("\t",@$location),"\n");
      $array[$i++] = join("",@print);
      @print = ("value $type\t",join("\t",@$values),"\n");
      $array[$i++] = join("",@print);
      @print = ("StdDev $type\t",join("\t",@$StdAbw),"\n");
      $array[$i++] = join("",@print);
  }
#  print "Table written ( $fielname) \n";
#  close ( OUT);
  return join ("\n",@array); 
}    

sub plot_a_Raute {
	my ($self, $x, $y, $RautenGroesse, $color) = @_;

	## wir malen eine Raute!!
	## das ist desastr�s in svg!!
	## statt dessen lieber einen arc!
	$RautenGroesse = 6 unless ( defined $RautenGroesse);
	
	my ( $y_start, $y_end );
	$self->{im}->arc($x,$y,$RautenGroesse,$RautenGroesse,0,360,$color);
	return 1;
	for ( my $xr = -$RautenGroesse ; $xr <= $RautenGroesse ; $xr++ ) {
		$y_end = $RautenGroesse - ( $xr**2 )**0.5;
		$y_start = -$y_end;
		for ( my $yr = $y_start ; $yr <= $y_end ; $yr++ ) {
			$self->{im}->setPixel( $x + $xr, $y + $yr, $color );
		}
	}

	#print "\n";
	return 1;
}

1;
