package multiLinePlot;

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
use stefans_libs::root;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use stefans_libs::multiLinePlot::ruler_x_axis;
use stefans_libs::multiLinePlot::multiline_gb_Axis;
use stefans_libs::multiLinePlot::multiline_HMM_Axis;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;

use GD;
use stefans_libs::gbFile;
use stefans_libs::NimbleGene_config;
use stefans_libs::multiLinePlot::multiLineLable;

=head1 Description

This class is used to create a multi line plot of HMM data with a gbFeature Table ( as recieved by gbFile->Features() ).

=cut

sub new {

	my ( $class, $pathModifier ) = @_;

	my ( $self, @gbLines, @DataLines, %HMM_data, @org, @cell, @ab, @iter );

	$self = {

		#use_V_segment_colors => 1==0,
		#useMultiColor	 => 1 == 1,
		use_V_segment_colors => 1 == 1,
		useMultiColor        => 1 == 0,
		drawTransfacList     => undef,
		dataLines            => \@DataLines,
		gbLines              => \@gbLines,
		x_border_factor      => 1 / 10,
		y_border_factor      => 1 / 20,
		spaceFactor          => 1 / 30,
		rulerFactor          => 1 / 10,
		gbFactor             => 1 / 4,
		gffFile              => gffFile->new(),
		hmm_data             => \%HMM_data,
		organism_list        => \@org,
		celltype_list        => \@cell,
		antibody_list        => \@ab,
		iteration_list       => \@iter,
		tics                 => 5,
		minorTics            => 5,
		lines                => 9,
		smallLines           => 11,
		printPrimer          => 0,
		width                => 1500,
		height               => 1000,
		Exon_Allow_Lines     => 8,
		Zeilen               => 5,
	};

	$self->{dataFactor} = 1 -
	  ( $self->{spaceFactor} * 2 + $self->{rulerFactor} + $self->{gbFactor} );
	my $today = Date::Simple->new();
	my $path  = NimbleGene_config::DataPath();
	$path = "$path/MultiLinePlots/$today";
	mkdir($path);
	$path = "$path/$pathModifier" if ( defined $pathModifier );
	$self->{OUTpath} = "$path/$pathModifier";
	system("mkdir -p $self->{OUTpath}");

	print "multiLinePlot outPath = $self->{OUTpath}\n";

	bless $self, $class if ( $class eq "multiLinePlot" );

	return $self;

}

sub create_ROI_Hash {
	my ( $self, $listRegionsOfInterest ) = @_;

	my ( @array, $i, @gbFileStrings, $entry );
	$i             = $self->{gbFiles};
	@gbFileStrings = ( keys %$i );

	foreach my $line (@$listRegionsOfInterest) {
		next if ( $line =~ m/^#/ );
		chomp $line;
		if ( $line =~ m/new=([\w\d]+)/ ) {

			#			print "$line contains a new file definition!\n";
## the new tag defines the outflie for that region!
			my ( @entry, @HMM_DataList, @colorList, @lineDefinitions );
			$entry[0] = $1;
			$entry    = \@entry;
			$i        = 1;
			push( @array, $entry );
			next;
		}

#new regions definition
#DMP,6000,16000,genomic sequence in sense orientation [bp],DSPP transcription start site,DSPP
		my $temp;
		(
			$temp->{gbFileString}, $temp->{start}, $temp->{end},
			$temp->{y_title}, $temp->{x_title}, $self->{regionsTitle}
		) = split( ",", $line );
		$temp->{regionsTitle} = $self->{regionsTitle};

		#	print "$self->{regionsTitle} \n";
		#	print "Changign gbfileStrings from  $temp->{gbFileString} to";
		foreach my $gbFileString (@gbFileStrings) {
			$temp->{gbFileString} = $gbFileString
			  if ( $temp->{gbFileString} =~ m/$gbFileString/ );
		}

#print " $temp->{gbFileString} (possible values were ",join (" ",@gbFileStrings),")\n";
#		print "Hash entry for filename $temp->{gbFileString} is stored in ",$entry," [$i] \n";
		@$entry[ $i++ ] = $temp;
	}

	#	die;
	return \@array unless ( $self->{test} );
	## TEST
	foreach my $Arrayhash (@array) {
		foreach my $Entry (@$Arrayhash) {
			unless ( lc($Entry) =~ m/hash/ ) {
				print "FilenameOfArrayHAsh = $Entry\n";
			}
			else {
				print "\tgbFileString = $Entry->{gbFileString}\n",
				  "\tstart = $Entry->{start} end = $Entry->{end}\n",
				  "\ty_title = $Entry->{y_title} x_title = $Entry->{x_title}\n",
				  "\tregionsTitle = $Entry->{regionsTitle}\n";
			}
		}
	}

	return \@array;
}

sub UseStdDev {
	my ($self) = @_;
	$self->{useStdDev} = 1 == 1;
	return $self->{useStdDev};
}

sub plotOnlyGBfiles {
	my ($self) = @_;

	my (
		$gbFileString, $pictureFileName, @HMM_DataList,
		@colorList,    @gbFile_Strings
	);

	$gbFileString    = $self->{gbFiles};
	$self->{noLable} = 1 == 1;
	@gbFile_Strings  = ( keys %$gbFileString );
	$self->{OUTpath} = "$self->{OUTpath}/gbFiles_only";
	root->CreatePath( $self->{OUTpath} );
	foreach $gbFileString (@gbFile_Strings) {
		$pictureFileName = "$self->{OUTpath}/$gbFileString.svg";
		$self->PlotGbFile( $pictureFileName, $gbFileString, \@HMM_DataList,
			\@colorList );
	}
	print "Bild als $pictureFileName gespeichert!\n";
}

sub plot {
	my ( $self, $listOfInterestingRegions ) = @_;
## das line Modell wird nicht hier festgelegt, es steht schon nach AddGBfile fest!
## nett waere es alles auf ein mmal darstellen zu koennen, also
## 1. zellltyp spezifisch alle antikoerper -> haben wir mehr als einen Zelltyp?
## 2. antikoerper spezifisch alle zelltypen -> mehr als einen Antikoerper
## 3. alles zusammen -> haben wir schon alles dargestellt?
## 4. von jeder HMM Iteration ein bild -> gibt es mehrere Iterationen?
## PlotGbFile ( $pictureFileName, $gbFileString, $HMM_DataList, $colorList )

	print
" $self->{hmm_count} unterschiedliche Datensaetze sollen dargestellt werden\n";

	my (
		$CellArray,         $AntibodyArray,   $IterationArray,
		$OrganismArray,     $pictureFileName, @HMM_DataList,
		@colorList,         $x,               @gbFile_Strings,
		$pictureFileName_1, @HMM_DataList_1,  @colorList_1,
		$x_1,               $ROI,             $ROI_path,
		$gbFileString,      $iteration,       $ROI_Data_by_Celltype
	);
	$ROI            = $self->create_ROI_Hash($listOfInterestingRegions);
	$x              = $self->{gbFiles};
	@gbFile_Strings = ( keys %$x );

	$CellArray      = $self->{celltype_list};
	$AntibodyArray  = $self->{antibody_list};
	$IterationArray = $self->{iteration_list};
	$OrganismArray  = $self->{organism_list};
	$self->new_im();
	warn "I can not handle multiple organisms!\n",
	  "only the first Organism will be used!\n",
	  "Output may not contain the picture you want to see\n"
	  if ( @$OrganismArray > 1 );

	foreach $iteration (@$IterationArray) {
		print "Using gbFile $gbFileString\n";
		$pictureFileName_1 = "$self->{OUTpath}/$iteration";
		root->CreatePath($pictureFileName_1);

		foreach $gbFileString (@gbFile_Strings) {
			print "Using Iteration $iteration\n";
			@HMM_DataList_1 = undef;
			@colorList_1    = undef;
			$x_1            = 0;
			$pictureFileName_1 =
			  "$self->{OUTpath}/$iteration/$gbFileString-$iteration.svg";
			$ROI_path = "$self->{OUTpath}/ROI_Iteration$iteration";
			foreach my $celltype (@$CellArray) {    # one Plot for each cell
## select the HMM_Data
				#				print "Using celltype $celltype\n";
				my @HMM_DataList;
				my @colorList;
				$x               = 0;
				$pictureFileName = "$self->{OUTpath}/$celltype/$iteration";
				root->CreatePath($pictureFileName);
				$pictureFileName =
				  "$pictureFileName/$gbFileString-$celltype-$iteration.svg";

				foreach my $antibody (@$AntibodyArray) {

					#					print "Using antibody $antibody\n";
					next
					  unless (
						defined $self->{hmm_data}->{ @$OrganismArray[0] }
						->{$celltype}->{$antibody}->{$iteration} );
					$HMM_DataList[$x] =
					  $self->{hmm_data}->{ @$OrganismArray[0] }->{$celltype}
					  ->{$antibody}->{$iteration};
					$colorList[$x] =
					  $self->{color}->selectColor( $celltype, $antibody );

					$HMM_DataList_1[$x_1] = $HMM_DataList[$x];
					$colorList_1[$x_1]    = $colorList[$x];
					$x++;
					$x_1++;
				}
				$ROI_Data_by_Celltype->{$celltype} =
				  { HMM_DataList => \@HMM_DataList, colorList => \@colorList };

				#				print "Do we die here?\n";
				$self->PlotGbFile(
					$pictureFileName, $gbFileString,
					\@HMM_DataList,   \@colorList
				);
			}
			$x = $HMM_DataList_1[0];

			#			print "First entry in HMM_DataList_1 = $x\n";
			$self->PlotGbFile(
				$pictureFileName_1, $gbFileString,
				\@HMM_DataList_1,   \@colorList_1
			);
		}
		foreach my $celltype ( keys %$ROI_Data_by_Celltype ) {
			root->CreatePath("$ROI_path/$celltype");

			#			print "Type1 ROI\n";
			$self->PlotRegionsOfInterest( "$ROI_path/$celltype", $ROI,
				\@HMM_DataList_1, \@colorList_1 );
		}

		#		print "Type2 ROI\n";
		$self->PlotRegionsOfInterest( $ROI_path, $ROI, \@HMM_DataList_1,
			\@colorList_1 );
	}    # ende foreach Iteration
}

sub Width {
	my ( $self, $width ) = @_;
	$self->{width} = $width if ( defined $width );

	#   print "Width = $self->{width}\n";
	return $self->{width};
}

sub Height {
	my ( $self, $width ) = @_;
	$self->{height} = $width if ( defined $width );

	#   print "Height = $self->{height}\n";
	return $self->{height};
}

sub new_im {

	my ( $self, $width, $height ) = @_;

	my (%temp);
	$self->{im} = undef;
	$self->{im} =
	  new GD::SVG::Image( $self->Width($width), $self->Height($height) );
	print "New Image ", $self->Width(), " x ", $self->Height(), "\n";
	$self->{color} = color->new( $self->{im} );
	$self->{color}->UseUniqueColors( 1 == 0 ) if ( $self->{useMultiColor} );
	$self->{lineCoordinates} = \%temp;
	return $self->{im};

## create the line model!
}

=heade2 SetlineModel

=head3 atributes

[0]: a reference to a hash with tthe structure:
{ width => <int>, height => <int>, lines => <int>,	x_border_factor  => <float>,
	   y_border_factor  => <float>, spaceFactor => <float>,
	   rulerFactor => <float>, gbFactor => <float>}

=head3 method

All values are set, if they exist. otherwise the defaoult values are used.
The last critical value is calculated as $self->{dataFactor} = 1 - ( $self->{spaceFactor} *2 + $self->{rulerFactor} + $self->{gbFactor});

=cut

sub SetLineModel {
	my ( $self, $lineModel, $HMM_DataList, $noRectangle ) = @_;

	$self->{font}        = Font->new("med") unless ( defined $self->{font} );
	$self->{lable}       = multiLineLable->new( $self->{font} );
	$self->{titleFactor} = $lineModel->{titleFactor}
	  if ( defined $lineModel->{titleFactor} );
	$self->Width( $lineModel->{width} );
	$self->Height( $lineModel->{height} );
	$self->{spaceFactor} = $lineModel->{spaceFactor}
	  if ( defined $lineModel->{spaceFactor} );
	$self->{rulerFactor} = $lineModel->{rulerFactor}
	  if ( defined $lineModel->{rulerFactor} );
	$self->{gbFactor} = $lineModel->{gbFactor}
	  if ( defined $lineModel->{gbFactor} );
	$self->{lines} = $lineModel->{lines} if ( defined $lineModel->{lines} );
	$self->{XY_plotFactor} = $lineModel->{XY_plotFactor}
	  if ( defined $lineModel->{XY_plotFactor} );
	$self->{x_border_factor} = $lineModel->{x_border_factor}
	  if ( defined $lineModel->{x_border_factor} );
	$self->{y_border_factor} = $lineModel->{y_border_factor}
	  if ( defined $lineModel->{y_border_factor} );
	$self->{XlableStart} = ( $self->Width() * $self->{x_border_factor} ) / 10;
	$self->{XlableEnd} =
	  ( $self->{x_border_factor} * $self->Width * 1.5 ) - $self->{XlableStart};

	$self->{dataFactor} =
	  1 -
	  ( $self->{spaceFactor} +
		  $self->{rulerFactor} +
		  $self->{gbFactor} +
		  $self->{titleFactor} +
		  $self->{XY_plotFactor} );

	die
"Hier gab es Probleme! Die Faktoren duerfen zusammmen nicht groesser als 1 sein!! (",
	  1 - $self->{dataFactor}, ") \n"
	  if ( $self->{dataFactor} < 0 || $self->{dataFactor} > 1 );

	my (
		$temp,          $gbData,            $start,
		$end,           $lineCoordinates,   $lineHeight,
		$lineLength_px, $Hmm_gbFeatureList, @array
	);

### Das eigentliche Bild initialisieren
	$self->new_im();

## Die X achsen definieren!
## Bezeichnungen der Werte fuer jede Zeile
	#
	#            x1                                           x2
	#         y1 |--------------------------------------------|
	#            |              title                         |
	#      ruler |--------------------------------------------|
	#            |              ruler                         |
	#   hmm_data |--------------------------------------------|
	#            |              hmm_data                      |
	#   XY_data  |--------------------------------------------|
	#            |              GFF_Data_Y_Axis               |
	#    gb_data |--------------------------------------------|
	#            |              gb_data                       |
	#      space |--------------------------------------------|
	#            |              space                         |
	#         y2 |--------------------------------------------|
	#
###
	$lineHeight =
	  ( $self->{height} - 2 * $self->{height} * $self->{y_border_factor} ) /
	  ( $self->{lines} );

	for ( my $i = 0 ; $i < $self->{lines} ; $i++ ) {
		my %temp;
		$self->{lineCoordinates}->{$i} = \%temp;

		$self->{lineCoordinates}->{$i}->{y1} =
		  $self->{height} * $self->{y_border_factor} + $i * $lineHeight;
		$self->{lineCoordinates}->{$i}->{x1} =
		  $self->{width} * $self->{x_border_factor} * 1.5;

		$self->{lineCoordinates}->{$i}->{y2} =
		  $self->{height} * $self->{y_border_factor} + ( $i + 1 ) * $lineHeight;
		$self->{lineCoordinates}->{$i}->{x2} =
		  $self->{width} - $self->{width} * $self->{x_border_factor} * 0.5;

		$self->{lineCoordinates}->{$i}->{ruler} =
		  $self->{lineCoordinates}->{$i}->{y1} +
		  $lineHeight * $self->{titleFactor};
		$self->{lineCoordinates}->{$i}->{hmm_data} =
		  $self->{lineCoordinates}->{$i}->{ruler} +
		  $lineHeight * $self->{rulerFactor};
		$self->{lineCoordinates}->{$i}->{XY_data} =
		  $self->{lineCoordinates}->{$i}->{hmm_data} +
		  $lineHeight * $self->{XY_plotFactor};
		$self->{lineCoordinates}->{$i}->{gb_data} =
		  $self->{lineCoordinates}->{$i}->{XY_data} +
		  $lineHeight * $self->{dataFactor};
		$self->{lineCoordinates}->{$i}->{space} =
		  $self->{lineCoordinates}->{$i}->{gb_data} +
		  $lineHeight * $self->{gbFactor};

#die "hier laeuft was mit der Region-Berechnung nicht rund!\n",
#	"y2 wurde nach der Berechnung nicht erreicht! ", int($self->{lineCoordinates}->{$i}->{space} + $lineHeight * $self->{spaceFactor}),
#	" != ", int($self->{lineCoordinates}->{$i}->{y2}),"\n" if ( int($self->{lineCoordinates}->{$i}->{space} + $lineHeight * $self->{spaceFactor}) !=
#	 int($self->{lineCoordinates}->{$i}->{y2}));
		## print a box around the line!
		$self->{im}->rectangle(
			$self->{lineCoordinates}->{$i}->{x1},
			$self->{lineCoordinates}->{$i}->{ruler},
			$self->{lineCoordinates}->{$i}->{x2},
			$self->{lineCoordinates}->{$i}->{space},
			$self->{color}->{black}
		) unless ( defined $noRectangle );

#		print "inserting a new x axis that should cover the range of ",
#		$self->{lineLength_bp} * $i," to ",$self->{lineLength_bp} * ($i + 1) ,"bp\n";
	}

## Bezeichnungen der Werte fuer jede Zeile
	#
	#                     x1                                           x2
	#                  y1 |--------------------------------------------|
	#                     |              title                         |
	#               ruler |--------------------------------------------|
	#                     |              ruler                         |
	# hmm_data, start_y_0 |--------------------------------------------|
	#                     |                 hmm_data  line 0           |
	#  start_y_1, end_y_0 |--------------------------------------------|
	#                     |                 hmm_data  line 1           |
	# start_y_$i, end_y_1 |--------------------------------------------|
	#                     |                 hmm_data  line $i          |
	#   XY_data, end_y_$i |--------------------------------------------|
	#                     |              GFF_Data_Y_Axis               |
	#             gb_data |--------------------------------------------|
	#                     |              gb_data                       |
	#               space |--------------------------------------------|
	#                     |              space                         |
	#                  y2 |--------------------------------------------|
	#
###

	my ( $data_space_y, $add_1, $add_2, $i1 );
	$data_space_y =
	  $self->{lineCoordinates}->{0}->{gb_data} -
	  $self->{lineCoordinates}->{0}->{hmm_data};

	# Die Bereiche im Bild fuer die HMM Daten muessen definiert werden!
	return 1 unless ( defined @$HMM_DataList );
	for ( my $i = 0 ; $i < @$HMM_DataList ; $i++ ) {
		$add_1 = $data_space_y * $i / @$HMM_DataList;
		$add_2 = $data_space_y * ( $i + 1 ) / @$HMM_DataList;
		$i1    = $i + 1;
		for ( my $a = 0 ; $a < $self->{lines} ; $a++ ) {
			$self->{lineCoordinates}->{$a}->{"start_y_$i"} =
			  $self->{lineCoordinates}->{$a}->{hmm_data} + $add_1;
			$self->{lineCoordinates}->{$a}->{"start_y_$i1"} =
			  $self->{lineCoordinates}->{$a}->{hmm_data} + $add_2;
		}
	}

	return 1;
}

sub AddGbFile {
	my ( $self, $gbFile_location ) = @_;

	unless ( defined $self->{gbFiles} ) {
		my %hash;
		$self->{gbFiles} = \%hash;
	}
	my $gbFile = gbFile->new($gbFile_location);
	$self->{gbFiles}->{ $gbFile->Name() } = $gbFile;
}

sub PlotRegionsOfInterest {
	my ( $self, $pictureFileName, $ROI, $HMM_DataList, $colorList, $lineModel )
	  = @_;

	my ( $roi, @gbFileStrings, $max, $a, $temp );

	#	return;
	$a = 1;
	## define the X_Axis
	print "sub PlotRegionsOfInterest\n@_\n";
	foreach $roi (@$ROI) {

		#	print "ROI! Nr.", $a++," , region filename = @$roi[0]\n";
		$lineModel->{lines}  = @$roi - 1;
		$lineModel->{height} = int(
			(
				( 1000 - 2000 * $self->{y_border_factor} ) *
				  $lineModel->{lines} / 4
			) + 2000 * $self->{y_border_factor}
		);
		$lineModel->{titleFactor} = 1 / 5;
		$self->SetLineModel( $lineModel, $HMM_DataList );

   #	print "New picture dimesions: ",$self->Width()," to ",$self->Height(),"\n";
		$max = 0;
		for ( my $i = 1 ; $i < @$roi ; $i++ ) {
			unless ( defined $self->{gbFiles}->{ @$roi[$i]->{gbFileString} } ) {
				$temp = $self->{gbFiles};
				foreach my $realGbfileString ( keys %$temp ) {
					if ( $realGbfileString =~ m/@$roi[$i]->{gbFileString}/ ) {
						$self->{gbFiles}->{ @$roi[$i]->{gbFileString} } =
						  $self->{gbFiles}->{$realGbfileString};
						print
"reset gbFile strings from $realGbfileString to @$roi[$i]->{gbFileString}\n";

						#	  @$roi[$i]->{gbFileString} = $realGbfileString;
					}
				}
			}
			$gbFileStrings[ $i - 1 ] = @$roi[$i]->{gbFileString};

			#			print "New ROI line gb axis using:\n",
			#				"gbfile @$roi[$i]->{gbFileString}\n",
			#				"start @$roi[$i]->{start} end @$roi[$i]->{end}\n";
			$self->{lable}
			  ->LineLable( "gbFiles", "Known Genes", "gb_data", "space" );
			$self->{lable}
			  ->LineLable( "title", "@$roi[$i]->{regionsTitle}", "y1", "ruler",
				$i - 1 );
			print
"new regions Title =  @$roi[$i]->{regionsTitle} gbfileString = @$roi[$i]->{gbFileString}\n";
			$self->{lineCoordinates}->{ $i - 1 }->{x_axis} =
			  multiline_gb_Axis->new(
				$self->{gbFiles}->{ @$roi[$i]->{gbFileString} },
				@$roi[$i]->{start},
				@$roi[$i]->{end},
				$self->{lineCoordinates}->{ $i - 1 }->{x1},
				$self->{lineCoordinates}->{ $i - 1 }->{gb_data},
				$self->{lineCoordinates}->{ $i - 1 }->{x2},
				$self->{lineCoordinates}->{ $i - 1 }->{space},
				"min",
				$self->{color}
			  );
			$max = @$roi[$i]->{end} if ( $max < @$roi[$i]->{end} );
			$self->{lineCoordinates}->{ $i - 1 }->{x_axis}->plot( $self->{im} );
		}
		$self->Hmm2im( $HMM_DataList, $colorList, \@gbFileStrings );
		$self->Ruler2im($max);
		$self->{lable}->plot( $self->{im}, $self->{lineCoordinates},
			$self->{XlableStart}, $self->{XlableEnd}, $self->{color}->{black} )
		  unless ( $self->{noLable} );
		$self->writePicture("$pictureFileName/@$roi[0].svg");
	}
}

sub PlotGbFile {
	my ( $self, $pictureFileName, $gbFileString, $HMM_DataList, $colorList,
		$lineModel )
	  = @_;

	my ( $temp, $gbData, $start, $end, $lineCoordinates, $lineHeight,
		$lineLength_px, $Hmm_gbFeatureList, $i1, $D5prime, $D3prime );

## das lineModel ewtl anpassen ja nach dem wie viele HMM Daten geschrieben werden sollen.
	return unless ( defined $gbFileString );
	$D5prime = $D3prime = 0;
	if ( $gbFileString =~ m/TCRA/ ) {
		$D5prime = 500000;
		$D3prime = 1800000;
	}

	#print "multiLinePlot height is $lineModel->{height}\n";
	$lineModel->{height} = 200 * $self->{lines};

	#die "Height was set to $lineModel->{height}";
	$lineModel->{lines} = $self->{lines};

	# $self->SetLineModel($line_model) if ( defined $line_model);
	$self->SetLineModel( $lineModel, $HMM_DataList );
	$self->{lineLength_bp} =
	  ( $self->{gbFiles}->{$gbFileString}->Length() - $D5prime - $D3prime ) /
	  $self->{lines};
	my @array;
	$gbData = $self->{gbData} = \@array;

	# Add the gbX_axis
	print "gbFile will be drawn on $self->{lines} lines\n";
	for ( my $i = 0 ; $i < $self->{lines} ; $i++ ) {
		$self->{lable}
		  ->LineLable( "gbFiles", "Known Genes", "gb_data", "space" );
		$self->{lineCoordinates}->{$i}->{x_axis} = multiline_gb_Axis->new(
			$self->{gbFiles}->{$gbFileString},
			( $self->{lineLength_bp} * $i ) + $D5prime,
			( $self->{lineLength_bp} * ( $i + 1 ) ),
			$self->{lineCoordinates}->{$i}->{x1},
			$self->{lineCoordinates}->{$i}->{gb_data},
			$self->{lineCoordinates}->{$i}->{x2},
			$self->{lineCoordinates}->{$i}->{space},
			"min",
			$self->{color}
		);
		$self->{lineCoordinates}->{$i}->{x_axis}->plot( $self->{im} );
	}
	$self->Hmm2im( $HMM_DataList, $colorList, $gbFileString );
	$self->Ruler2im( $self->{gbFiles}->{$gbFileString}->Length() );

	#	print "multLinePlot : Plot The lables\n";
	$self->{lable}->plot( $self->{im}, $self->{lineCoordinates},
		$self->{XlableStart}, $self->{XlableEnd}, $self->{color}->{black} )
	  unless ( $self->{noLable} );
	$self->writePicture($pictureFileName);
}

sub Hmm2im {
	my ( $self, $HMM_DataList, $colorList, $gbFileString ) = @_;
	my ( $i1, $Hmm_gbFeatureList, $temp, @HMM_gbFiles );

	$i1          = @$Hmm_gbFeatureList[0];
	@HMM_gbFiles = ( keys %$i1 );
	for ( my $i = 0 ; $i < @$HMM_DataList ; $i++ ) {
		$i1 = $i + 1;
		next unless ( defined @$HMM_DataList[$i] );

		#		print "$Hmm_gbFeatureList = $Hmm_gbFeatureList\n";
		$Hmm_gbFeatureList = @$HMM_DataList[$i]->{$gbFileString}
		  unless ( lc($gbFileString) =~ m/array/ );
		for ( my $a = 0 ; $a < $self->{lines} ; $a++ ) {
			$self->{lable}->LineLable(
				"$i",
"@$HMM_DataList[$i]->{info}->{CellType}, @$HMM_DataList[$i]->{info}->{AB}",
				"start_y_$i",
				"start_y_$i1"
			);
			$Hmm_gbFeatureList = @$HMM_DataList[$i]->{ @$gbFileString[$a] }
			  if ( lc($gbFileString) =~ m/array/ );

#			unless (defined $Hmm_gbFeatureList){
#				print "ROI filename @$gbFileString[$a] got no resulting HMM features!\n";
#				foreach my $gbFileRealName (@HMM_gbFiles){
#				     $Hmm_gbFeatureList = @$HMM_DataList[$i]->{$gbFileRealName} if ( $gbFileRealName =~ m/@$gbFileString[$a]/);
##				}
			#			}
			$temp = multiline_HMM_Axis->new(
				$Hmm_gbFeatureList,
				$self->{lineCoordinates}->{$a}->{"start_y_$i"},
				$self->{lineCoordinates}->{$a}->{"start_y_$i1"},
				$self->{lineCoordinates}->{$a}->{x_axis},
				@$colorList[$i],
				$self->{color}
			);
			$temp->plot( $self->{im} );
		}
	}
	return 1;
}

sub Ruler2im {
	my ( $self, $maxLenth ) = @_;

	# Das Sequenz Lineal plotten

	my ( $temp, @gbFileStrings );

	#	@gbFileStrings = @$gbFileString if ( lc($gbFileString) =~ m/array/);

	for ( my $a = 0 ; $a < $self->{lines} ; $a++ ) {

		#	    $gbFileString = $gbFileStrings[$a] if ( defined @gbFileStrings);
		#		print "Ruler2im \$gbFileString = $gbFileString\n";
		$temp = ruler_x_axis->new(
			$self->{lineCoordinates}->{$a}->{x_axis},
			$self->{color}->{black},
			"med",
			$self->{lineCoordinates}->{$a}->{x1},
			$self->{lineCoordinates}->{$a}->{ruler},
			$self->{lineCoordinates}->{$a}->{x2},
			$self->{lineCoordinates}->{$a}->{hmm_data},
			$maxLenth
		);

		$temp->noTitle(1);
		$temp->plot( $self->{im}, );
	}
	return 1;
}

sub writePicture {
	my ( $self, $pictureFileName ) = @_;

	# Das Bild speichern
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );
	print "We print to path $path\n";
	mkdir($path) unless ( -d $path );
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n$!\n";

	binmode PICTURE;

	print PICTURE $self->{im}->svg;
	close PICTURE;
	print "Bild als $pictureFileName gespeichert\n";
	return 1;
}

sub D0 {
	my ( $self, $d0 ) = @_;
	$self->{d0} = NimbleGene_config::D0 unless ( defined $self->{d0} );
	$self->{d0} = $d0 if ( defined $d0 );
	return $self->{d0};
}

sub CutoffValue {
	my ( $self, $cutoffValue ) = @_;

	if ( defined $cutoffValue ) {
		$self->{cutoffValue} = $cutoffValue;
	}
	$self->{cutoffValue} = NimbleGene_config::CutoffValue()
	  if ( $cutoffValue < -4 || !( defined $self->{cutoffValue} ) );

	return $self->{cutoffValue};
}

sub AddHMM_Data {
	my ( $self, $gffFilename ) = @_;

	my ( $list, $information, $i );

	$information = root->ParseHMM_filename($gffFilename);

	unless ( defined $self->{hmm_data} ) {
		$self->{hmm_data} = my $temp;
	}
	unless ( defined $self->{hmm_data}->{ $information->{Organism} } ) {
		my %org;

		$list = $self->{organism_list};
		push( @$list, $information->{Organism} )
		  unless ( join( " ", @$list ) =~ m/$information->{Organism}/ );

#		print "multiLinePlot AddHMM files new Organism ($information->{Organism}) found (pos. $i)!\n";
		$self->{hmm_data}->{ $information->{Organism} } = \%org;
	}
	unless (
		defined $self->{hmm_data}->{ $information->{Organism} }
		->{ $information->{CellType} } )
	{
		my %cell;

		$list = $self->{celltype_list};
		push( @$list, $information->{CellType} )
		  unless ( join( " ", @$list ) =~ m/$information->{CellType}/ );

#		print "multiLinePlot AddHMM files new CellType ($information->{CellType}) found (pos. $i)!\n";

		$self->{hmm_data}->{ $information->{Organism} }
		  ->{ $information->{CellType} } = \%cell;
	}
	unless (
		defined $self->{hmm_data}->{ $information->{Organism} }
		->{ $information->{CellType} }->{ $information->{AB} } )
	{
		my %AB;

		$list = $self->{antibody_list};
		push( @$list, $information->{AB} )
		  unless ( join( " ", @$list ) =~ m/$information->{AB}/ );

#		print "multiLinePlot AddHMM files new antibody ($information->{AB}) found (pos. $i)!\n";

		$self->{hmm_data}->{ $information->{Organism} }
		  ->{ $information->{CellType} }->{ $information->{AB} } = \%AB;
	}

	unless (
		defined $self->{hmm_data}->{ $information->{Organism} }
		->{ $information->{CellType} }->{ $information->{AB} }
		->{ $information->{Iteration} } )
	{

		$list = $self->{iteration_list};
		push( @$list, $information->{Iteration} )
		  unless ( join( " ", @$list ) =~ m/$information->{Iteration}/ );
		$i = @$list;

#		print "multiLinePlot AddHMM files new iteration ($information->{Iteration}) found (pos. $i)!\n";

		$self->{hmm_data}->{ $information->{Organism} }
		  ->{ $information->{CellType} }->{ $information->{AB} }
		  ->{ $information->{Iteration} } =
		  $self->getEnrichedRegions($gffFilename);

#		print "Daten fuer $information->{Organism} $information->{CellType} $information->{AB} $information->{Iteration} eingetragen!\n";
#		$i = $self->{hmm_data}->{$information->{Organism}}->{$information->{CellType}}->{$information->{AB}}->{$information->{Iteration}};
#		print "Filenames: ",join( " ", (keys %$i)),"\n";
		$self->{hmm_count} = 0 unless ( defined $self->{hmm_count} );
		$self->{hmm_count}++;
	}
	else {
		print
"Daten fuer $information->{Organism} $information->{CellType} $information->{AB} $information->{Iteration} wurden schon eingetragen!\n";
	}
	print
"We tried to insert a new set of HMM data! data count = $self->{hmm_count}\n";
	return $self->{hmm_data}->{ $information->{Organism} }
	  ->{ $information->{CellType} }->{ $information->{AB} }
	  ->{ $information->{Iteration} };
}

sub getEnrichedRegions {
	my ( $self, $gffFilename ) = @_;
	return $self->{gffFile}->getEnrichedRegions($gffFilename);
}

1;
