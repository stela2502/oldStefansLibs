package NEW_GFF_data_Y_axis;
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

use stefans_libs::V_segment_summaryBlot::GFF_data_Y_axis;
use stefans_libs::V_segment_summaryBlot::pictureLayout;

@ISA = qw(GFF_data_Y_axis);

use strict;

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
		binLength     => 200,
		max           => undef,
		useStdDev     => 1 == 0,

		#     flushMedian => 1 == 1,
		flushMedian     => 1 == 0,
		min             => undef,
		max_std         => undef,
		min_std         => undef,
		max_oligo_count => 5
	};

	#print "NEW_GFF_x_axis\n";
	bless( $self, $class ) if ( $class eq "NEW_GFF_data_Y_axis" );
	$self->{debug} = 1 == 1;
	return $self;

}

sub BinLength {
	my ( $self, $binLength ) = @_;
	$self->{binLength} = $binLength if ( defined $binLength && $binLength > 0 );
	return $self->{binLength};
}

sub createTitles4antibodyHash {
	my ( $self, $antibodyHash, $withCount ) = @_;
	my ( @return, $i );
	$i = 0;
	foreach my $specifity ( keys %$antibodyHash ) {
		$return[$i] = $specifity;
		$return[$i] = "$specifity (n=$antibodyHash->{$specifity})"
		  if ( defined $withCount );
		$i++;
	}
	return @return;
}

sub createTitles4cellTypeHash {
	my ( $self, $cellTypeHash, $withCount ) = @_;
	my ( @return, $i );
	$i = 0;
	foreach my $cellType ( keys %$cellTypeHash ) {
		$return[$i] = $cellType;
		$return[$i] = "$cellType (n=$cellTypeHash->{$cellType}->{count})"
		  if ( defined $withCount );
		$i++;
	}
	return @return;
}

sub defineSubPlots {
	my ( $self, $x_axis ) = @_;

	my ( $x, $x1, $x2, $x3, $max, $min );

	$max = $x_axis->resolveValue( $x_axis->max_value() );
	$min = $x_axis->resolveValue( $x_axis->min_value() );

	$x  = int( $min + ( $max - $min ) / 40 );
	$x1 = int( $min + ( $max - $min ) / 4 );
	$x3 = int( $min + ( $max - $min ) / 5 * 3 );
	$x2 = int( ( $x1 + $x3 ) / 2 );

	return $x, $x1, $x2, $x3;
}

sub orderByType2 {
	my ( $self, $item ) = @_;
	my ($type2);
	$type2 = $self->{antibodyOrder};
	for ( my $i = 0 ; $i < @$type2 ; $i++ ) {

#print "orderByType2 $item -> $i, @$type2[$i]->{plotString}\n" if ( lc($item) =~m/@$type2[$i]->{matchingString}/);
		return $i, @$type2[$i]->{plotString}
		  if ( lc($item) =~ m/@$type2[$i]->{matchingString}/ );
	}
	die "Exception in $self",
	  "  orderByType2: String $item matches no sorting criteria!\n";
	return undef;
}

sub orderByType1 {
	my ( $self, $item ) = @_;
	my ($type1);
	$type1 = $self->{cellTypes};
	for ( my $i = 0 ; $i < @$type1 ; $i++ ) {

#print "orderByType1 $item -> $i, @$type1[$i]->{plotString}\n" if ( lc($item) =~m/@$type1[$i]->{matchingString}/);
		if ( defined @$type1[$i]->{notMatch} ) {
			next if ( lc($item) =~ m/@$type1[$i]->{notMatch}/ );
		}
		return $i, @$type1[$i]->{plotString}
		  if ( lc($item) =~ m/@$type1[$i]->{matchingString}/ );
	}
	die
"Exception in $self orderByType1: String $item matches no sorting criteria!\n";
	return undef;
}

sub plotY_title {
	my ( $self, $im, $title, $resolution, $min_override, $max_override,
		$x_axis ) = @_;

	my $y_axis =
	  axis->new( "Y", $self->{y1}, $self->{y2}, $title, $resolution );
	$y_axis->min_value($min_override);
	$y_axis->max_value($max_override);
	$y_axis->plotTitle(
		$im,
		$x_axis->resolveValue( $x_axis->min_value() ),
		$self->{colorObject}->{black}, $title
	);
	return 1;
}

sub getSubplotCount {
	my ($self) = @_;

}

sub plot {
	my ( $self, $im, $y1, $y2, $x_axis, $color, $title, $resolution, $legend,
		$font, $min_override, $max_override, $HMM_data, $GBfile_MySQL_string )
	  = @_;

#print "DEBUG $self: plot got the following atributes:\n\t",
#   " \$self = $self\n\t\$im = $im\n\t\$y1 = $y1\n\t\$y2 = $y2\n\t\$x_axis = $x_axis\n\t\$color = $color\n\t\$title = $title\n\t\$resolution = $resolution\n\t",
#   "\$legend = $legend\n\t\$font = $font\n\t\$min_override = $min_override\n\t\$max_override = $max_override\n\n";

	my (
		$i,                $data,          $Y,
		$hybType,          $string,        $cellTypes,
		$dataSets,         $antibodies,    $temp,
		$plottableArray,   $_color,        $dataSet,
		$plottableDataSet, $pictureLayout, $subPlotGroup,
		$dataGroup
	);
	$self->{y1}          = $y1;
	$self->{y2}          = $y2;
	$self->{legend}      = $legend;
	$self->{im}          = $im;
	$self->{font}        = $font;
	$self->{colorObject} = $color;
	$self->getAsPlottable();

	$pictureLayout = pictureLayout->new( $self->SeparateArrays(), $self->UseBars() );

	print
"DEBUG $self: Min and Max Values during the plot: \n\t\t$self plot Y axis min = ",
	  $self->Min($min_override), " max = ", $self->Max($max_override), "\n";

	$plottableDataSet =
	  $pictureLayout->structurizeDataSet( $self->{data}, $HMM_data );
	$pictureLayout->createYregionsMap( $y1, $y2, $self->Min(), $self->Max() );

#	root::print_hashEntries( $pictureLayout, 5,
#		"The picture Layout after createYregionsMap ($pictureLayout)" );

# Die Graphik wird komliziert!
# 1. Die Ausgabe erfolgt in bis zu n gesonderten Abschnitten, nach Zelltypen getrennt.
# 2. Die Abschnitte sind jeweils durch eine titlezeile voneinander getrennt, in der der Zelltyp steht.

	my ( $x, $x1, $x2, $x3 ) = $self->defineSubPlots($x_axis);

	#print "here we try to create a new SVG Group:\n";
	$temp = "GFF data";
	$temp = "$temp median values" if ( $self->UseMedian() );
	$temp = "$temp mean values" unless ( $self->UseMedian() );
	$temp = "$temp + bars" if ($self->UseBars());
	$temp = "$temp + widowzize = @$plottableDataSet[0]->{enrichmentDataSet}->{data}->{binLength}";
	my $GFFGroup = $self->{im}->newGroup($temp);

	#print "Did it!!\n";

	$self->plotY_title( $im, $title, $resolution, 0, 1, $x_axis );

	#print "DEBUG $self: do we get some subPlots?\n";
	$temp = @$plottableDataSet;

	#print "$self->Plot got $temp subPlots\n";

	for ( my $subPlot = 0 ; $subPlot < @$plottableDataSet ; $subPlot++ ) {
		$dataSet = @$plottableDataSet[$subPlot];
		
		$dataSet->{enrichmentAxis}->{tics} = 3 if ( $self->SeparateArrays() );

		#root::print_hashEntries( $dataSet, 2,
		#	"das Daten Set das zur Bilderstellung dienen soll!\n" );
		$subPlotGroup =
		  $GFFGroup->newGroup(
"subPlot_$subPlot-$dataSet->{celltype}-$dataSet->{title}-$dataSet->{nimbleGeneID}"
		  );

		## a black box around the subplot unless self->UseBars()
		$self->{im}->rectangle(
			$x_axis->resolveValue( $x_axis->min_value() ),
			$dataSet->{axis}->resolveValue( $dataSet->{axis}->min_value() ),
			$x_axis->resolveValue( $x_axis->max_value() ),
			$dataSet->{axis}->resolveValue( $dataSet->{axis}->max_value() ),
			$self->{colorObject}->{black}
		) unless ( $self->SeparateArrays() );

		$self->{font}->plotString(
			$self->{im},
			$dataSet->{celltype},
			$x,
			$dataSet->{enrichmentAxis}
			  ->resolveValue( $dataSet->{enrichmentAxis}->max_value() ),
			$self->{colorObject}->{black}
		) unless ( $self->SeparateArrays() );

		$self->{im}->line(
			$x_axis->resolveValue( $x_axis->min_value() ),
			$dataSet->{enrichmentAxis}->resolveValue(0),
			$x_axis->resolveValue( $x_axis->max_value() ),
			$dataSet->{enrichmentAxis}->resolveValue(0),
			$self->{colorObject}->{grey}
		);    ## die Nullinie

		if ( $subPlot == @$plottableDataSet - 1 ) {
			$self->{im}->line(
				$x_axis->resolveValue( $x_axis->min_value() ),
				$dataSet->{axis}->resolveValue( $dataSet->{axis}->min_value() ),
				$x_axis->resolveValue( $x_axis->max_value() ),
				$dataSet->{axis}->resolveValue( $dataSet->{axis}->min_value() ),
				$self->{colorObject}->{white}
			);
			$x_axis->plot_simple_base_line(
				$self->{im},
				$dataSet->{axis}->resolveValue( $dataSet->{axis}->min_value() ),
				$self->{colorObject}->{black},
				"no"
			);
		}    ## die durchbrochene Zeile...

		$_color =
		  $color->selectColor( $dataSet->{celltype}, $dataSet->{title} );
		$dataGroup =
		  $subPlotGroup->newGroup(
			"sp_$subPlot-2-$dataSet->{celltype}-$dataSet->{title}");

		unless ( $self->SeparateArrays() ) {
			$temp = $x1 if ( $dataSet->{antibodyID} == 0 );
			$temp = $x2 if ( $dataSet->{antibodyID} == 1 );
			$temp = $x3 if ( $dataSet->{antibodyID} == 2 );
			print "we try to plot the string '$dataSet->{enrichmentDataSet}->{data}->{dataSets}x $dataSet->{title}' at x pos $temp\n";
			$self->{font}->plotString(
				$self->{im},
				"$dataSet->{enrichmentDataSet}->{data}->{dataSets}x $dataSet->{title}",
				$temp,
				$dataSet->{enrichmentAxis}
				  ->resolveValue( $dataSet->{enrichmentAxis}->max_value() ),
				$_color
			);
		}

		$dataSet->{enrichmentAxis}
		  ->plot( $self->{im}, $x_axis->resolveValue( $x_axis->min_value() ),
			$color->{black} );

		$plottableArray =
		  $dataSet->{enrichmentDataSet}->{data}->getAsPlottable();

		$self->Plot_DataPoints_with_lines( $plottableArray, $x_axis,
			$dataSet->{enrichmentAxis}, $_color )
		  unless ( $self->UseBars() );
		$self->Plot_DataPoints_with_bars( $plottableArray, $x_axis,
			$dataSet->{enrichmentAxis}, $_color )
		  if ( $self->UseBars() );
		$self->Plot_StdErrMean( $plottableArray, $x_axis,
			$dataSet->{enrichmentAxis}, $_color )
		  if ( $self->UseStdErrMean );
		$self->Plot_Std( $plottableArray, $x_axis, $dataSet->{enrichmentAxis},
			$_color )
		  if ( $self->UseStdDev );
		$self->{im}->endGroup($dataGroup);

		if ( defined $dataSet->{hmmData} ) {

			#plot the hmm data

			$dataSet->{hmmData}->Plot(
				$self->{im},
				$dataSet->{hmmAxis}
				  ->resolveValue( $dataSet->{hmmAxis}->min_value() ),
				$dataSet->{hmmAxis}
				  ->resolveValue( $dataSet->{hmmAxis}->max_value() ),
				$GBfile_MySQL_string,
				$_color,
				undef
			) if ( $self->UseBars() );

			$HMM_data->Plot(
				$pictureLayout->getInfo4subPlot( $dataSet->{celltypeID} ),
				$self->{im},
				$x_axis,
				$pictureLayout->Yregion4hmmDataSet_SubPlot($subPlot),
				$GBfile_MySQL_string,
				$self->{colorObject}
			) unless ( $self->UseBars() );
		}
		$self->{font}->plotString(
			$self->{im},
			"$dataSet->{nimbleGeneID}: $dataSet->{celltype} $dataSet->{title}",
			$x_axis->resolveValue( $x_axis->min_value() ) + 10,
			$dataSet->{enrichmentAxis}
			  ->resolveValue( $dataSet->{enrichmentAxis}->max_value() ) + 5,
			$self->{colorObject}->{black}
		) if ( $self->SeparateArrays() );
		$self->{im}->endGroup($subPlotGroup);

	}
	$self->{im}->endGroup();
	return 1;
}

sub Plot_StdErrMean {
	my ( $self, $Y_data, $X, $Y, $color ) = @_;
	my ( $data, $last, $act );

	$self->{im}->setThickness(1);

	$data = $Y_data->{data};
	$last = undef;
	foreach my $oligoBinRep (@$data) {
		next
		  if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
		$act = {
			x   => $X->resolveValue( $oligoBinRep->{bp} ),
			y   => $Y->resolveValue( $oligoBinRep->{median} ),
			min => $Y->resolveValue(
				$oligoBinRep->{mean} - $oligoBinRep->{stdErrMean}
			),
			max => $Y->resolveValue(
				$oligoBinRep->{mean} + $oligoBinRep->{stdErrMean}
			)
		};

		$self->{im}
		  ->line( $act->{x}, $act->{max}, $act->{x}, $act->{min}, $color );

		$self->{im}->line(
			$act->{x} - 3,
			$act->{min}, $act->{x} + 3,
			$act->{min}, $color
		);
		$self->{im}->line(
			$act->{x} - 3,
			$act->{max}, $act->{x} + 3,
			$act->{max}, $color
		);
	}
	return 1;
}

sub Plot_Std {
	my ( $self, $Y_data, $X, $Y, $color ) = @_;
	my ( $colors, $i, $data, $last, $act );

	$self->{im}->setThickness(1);
	$data = $Y_data->{data};
	$last = undef;
	foreach my $oligoBinRep (@$data) {
		next
		  if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
		$act = {
			x => $X->resolveValue( $oligoBinRep->{bp} ),
			y => $Y->resolveValue( $oligoBinRep->{median} ),
			min =>
			  $Y->resolveValue( $oligoBinRep->{mean} - $oligoBinRep->{stdDev} ),
			max =>
			  $Y->resolveValue( $oligoBinRep->{mean} + $oligoBinRep->{stdDev} )
		};

		$self->{im}
		  ->line( $act->{x}, $act->{max}, $act->{x}, $act->{min}, $color );

		$self->{im}->line(
			$act->{x} - 3,
			$act->{min}, $act->{x} + 3,
			$act->{min}, $color
		);
		$self->{im}->line(
			$act->{x} - 3,
			$act->{max}, $act->{x} + 3,
			$act->{max}, $color
		);
	}
	return 1;
}

sub Plot_DataPoints_with_bars {
	my ( $self, $Y_data, $X, $Y, $color ) = @_;
	my (
		$i,             $tokens, $colors, $data,
		$last,          $act,    $lastBP, $x_positions,
		$antibodyOrder, $asRectangle
	);

	$i             = 0;
	$x_positions   = $self->{X_positions};
	$antibodyOrder = $self->{antibodyOrder};
	$tokens        = $self->{tokens};
	$self->{im}->setThickness(1);
	$data = $Y_data;    #->{data};

#	print "DEBUG $self: we reach?? color = $color\n";
#root::print_hashEntries($data, 5,"The \$data ($data) structure in New_GFF_data_Y_axis->Plot_DataPoints_with_bars()\n");
	foreach my $oligoBinRep (@$data) {
		next if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
		next if ( $X->isOutOfRange($oligoBinRep->{start}) );
		next if ( $X->isOutOfRange($oligoBinRep->{end}));
		
		$asRectangle = 1 == 1;
		$asRectangle = 1 == 0
		  if (
			int( $X->resolveValue( $oligoBinRep->{start} ) ) ==
			int( $X->resolveValue( $oligoBinRep->{end} ) ) );
		
		$act = $oligoBinRep->{mean} unless ( $self->{UseMedian} );
		$act = $oligoBinRep->{median} if ( $self->{UseMedian} );

		print "try to plot the value $act between $oligoBinRep->{start} and $oligoBinRep->{end} (start_pix = -100)\n"
			if ( $X->resolveValue( $oligoBinRep->{start} ) == -100);
		print "try to plot the value $act between $oligoBinRep->{start} and $oligoBinRep->{end} (end_pix = -100)\n"
			if ( $X->resolveValue( $oligoBinRep->{end} ) == -100 );
		
		if ( $act > 0 ) {
			$self->{im}->filledRectangle(
				int( $X->resolveValue( $oligoBinRep->{start} ) ),
				$Y->resolveValue(0),
				int( $X->resolveValue( $oligoBinRep->{end} ) ),
				$Y->resolveValue($act),
				$color
			) if ($asRectangle);
			$self->{im}->line(
				int( $X->resolveValue( $oligoBinRep->{start} ) ),
				$Y->resolveValue(0),
				int( $X->resolveValue( $oligoBinRep->{end} ) ),
				$Y->resolveValue($act),
				$color
			) if ( !$asRectangle );
		}
		elsif ( $act < 0 ) {
			$self->{im}->filledRectangle(
				int( $X->resolveValue( $oligoBinRep->{start} ) ),
				$Y->resolveValue($act),
				int( $X->resolveValue( $oligoBinRep->{end} ) ),
				$Y->resolveValue(0),
				$color
			) if ($asRectangle);
			$self->{im}->line(
				int( $X->resolveValue( $oligoBinRep->{start} ) ),
				$Y->resolveValue($act),
				int( $X->resolveValue( $oligoBinRep->{end} ) ),
				$Y->resolveValue(0),
				$color
			) if ($asRectangle);
		}
		else {
			$self->{im}->line(
				int( $X->resolveValue( $oligoBinRep->{start} ) ),
				$Y->resolveValue(0),
				int( $X->resolveValue( $oligoBinRep->{end} ) ),
				$Y->resolveValue(0),
				$color
			);
		}
	}
	$self->{im}->setThickness(1);
}

sub Plot_DataPoints_with_lines {
	my ( $self, $Y_data, $X, $Y, $color ) = @_;
	my (
		$i,           $tokens, $colors, $data,
		$last,        $act,    $lastBP, $maxDifference,
		$x_positions, $antibodyOrder
	);
	$maxDifference = $self->{binLength} * 1.5;
	$maxDifference = 500 if ( $maxDifference < 500 );
	$i             = 0;
	$x_positions   = $self->{X_positions};
	$antibodyOrder = $self->{antibodyOrder};
	$tokens        = $self->{tokens};
	$self->{im}->setThickness(4);
	$data = $Y_data;    #->{data};

	#	print "DEBUG $self: we reach?? color = $color\n";
	foreach my $oligoBinRep (@$data) {
		next if ( $oligoBinRep->{mean} == 0 && $oligoBinRep->{stdDev} == 0 );
		$lastBP = $oligoBinRep->{bp} unless ( defined $lastBP );
		$act = {
			x => $X->resolveValue( $oligoBinRep->{bp} ),
			y => $Y->resolveValue( $oligoBinRep->{median} ),
			min =>
			  $Y->resolveValue( $oligoBinRep->{mean} - $oligoBinRep->{stdDev} ),
			max =>
			  $Y->resolveValue( $oligoBinRep->{mean} + $oligoBinRep->{stdDev} )
		};
		$act->{y} = $Y->resolveValue( $oligoBinRep->{mean} )
		  unless ( $self->{UseMedian} );
		if ( $self->LargeDots() ) {

#			print "DEBUG $self: \$self->plot_a_Raute($act->{x}, $act->{y}, 6, $color);\n";
			$self->plot_a_Raute( $act->{x}, $act->{y}, 6, $color );
		}
		else {

#			print "DEBUG $self: \$self->{im}->setPixel( $act->{x}, $act->{y}, $color );\n";
			$self->{im}->setPixel( $act->{x}, $act->{y}, $color );
		}
		if ( $act->{x} < 0 ) {
			$last = $lastBP = undef;
			next;
		}
		$self->{im}
		  ->line( $act->{x}, $act->{y}, $last->{x}, $last->{y}, $color )
		  if ( defined $last
			&& $oligoBinRep->{bp} - $lastBP < $maxDifference
			&& !$self->LargeDots() );
		$lastBP = $oligoBinRep->{bp};
		$last   = $act;
	}
	$self->{im}->setThickness(1);
}

1;
