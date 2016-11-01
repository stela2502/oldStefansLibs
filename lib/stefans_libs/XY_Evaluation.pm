package XY_Evaluation;
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
use stefans_libs::gbFile;
use stefans_libs::database::nucleotide_array::oligo2dnaDB;
use stefans_libs::database_old::fileDB;
use stefans_libs::root;
use stefans_libs::database_old::hybInfoDB;
use stefans_libs::database::array_dataset::NimbleGene_Chip_on_chip::gffFile;
use stefans_libs::V_segment_summaryBlot::gbFile_X_axis;

#use stefans_libs::V_segment_summaryBlot::GFF_data_Y_axis;
use stefans_libs::V_segment_summaryBlot::List4enrichedRegions;
use stefans_libs::V_segment_summaryBlot::NEW_Summary_GFF_Y_axis;
use stefans_libs::plot;
use stefans_libs::singleLinePlot;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

V_segment_summaryBlot

=head1 DESCRIPTION

=head2 Provides

=head1 METHODS

=head2 new

=head3 atributes

none 

=head3 retrun values

A object of the class XY_Evaluation

=cut

sub new {

	my ( $class, $pathModifier ) = @_;

	my ( $self, @oligoBins, %gbData, %cellTypes );

	$self = {
		createSequenceSlides => undef,
		width                => 1200,
		defaultBinLength	=> 250,
		pathModifier        => $pathModifier,
		hmmData             => List4enrichedRegions->new,
		featureArray        => undef,
		array_TStat         => array_TStat->new(),
		oligoArrays         => \@oligoBins,
		nimbleGeneGFF_Files => undef,
		fileDB              => fileDB->new(),
		hybInfoDB           => hybInfoDB->new,
		gbData              => \%gbData,
		gffFile             => gffFile->new,
		oligo2dnaDB         => oligo2dnaDB->new,
		cellTypes           => \%cellTypes,
		minOverride         => -1.5,
		maxOverride         => 4,
		max_oligo_count     => 5
	};

	bless( $self, $class ) if ( $class eq "XY_Evaluation" );
	return $self;
}

sub GetAsHash {
	my ( $self, $pictureData, $position ) = @_;
	return $pictureData->{Y_axis}->AsTable($position);
}

sub GetAsHash_inBP {
	my ( $self, $pictureData, $position ) = @_;
	die "\$pictureData->{Y_axis} is not defined!\n" unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->AsTable_inBP($position);
}

sub printOligoData4Bin_inBP {
	my ( $self, $pictureData, $bp, $pathToFiles ) = @_;
	root->CreatePath($pathToFiles);
	return $pictureData->{Y_axis}->printOligoData4Bin_inBP( $bp, $pathToFiles );
}

sub writeOligoReport {
	my ( $self, $pictureData, $pathToFiles ) = @_;
	root->CreatePath($pathToFiles);
	return $pictureData->{Y_axis}->writeOligoReport($pathToFiles);
}

sub UseStdDev {
	my ( $self, $pictureData, $use ) = @_;
	$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new() 
		unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->UseStdDev($use);
}

sub LargeDots{
	my ( $self, $pictureData, $bars) = @_;
	$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new() 
		unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->LargeDots($bars);
}

sub UseBars{
	my ( $self, $pictureData, $bars) = @_;
	$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new() 
		unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->UseBars($bars);
}

sub UseMedian{
	my ($self, $pictureData, $median) = @_;
	$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new() 
		unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->UseMedian ($median);
}

sub SeparateArrays{
	my ( $self, $pictureData, $use ) = @_;
	$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new() 
		unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->SeparateArrays($use);
}

sub UseStdErrMean {
	my ( $self, $pictureData, $use ) = @_;
	$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new() 
		unless ( defined $pictureData->{Y_axis});
	return $pictureData->{Y_axis}->UseStdErrMean($use);
}

sub Colored_V_segments {
	my ( $self, $pictureData, $bool ) = @_;
	return $pictureData->{X_axis}->Colored_V_segments($bool);
}

sub highlight_Vsegment {
	my ( $self, $pictureData, $bool ) = @_;
	#print "and we ($self) add that to the x_axis $pictureData->{X_axis}\n";
	return $pictureData->{X_axis}->highlight_Vsegment($bool);
}

sub WidePicture {
	my ( $self, $set2value ) = @_;
	if ( defined $set2value ) {
		$self->{widePicture} = $set2value;
	}
	return $self->{widePicture};
}

sub NarrowPicture {
	my ( $self, $set2value ) = @_;
	if ( defined $set2value ) {
		$self->{narrowPicture} = $set2value;
	}
	return $self->{narrowPicture};
}

sub used_gbFeatures {
	my ( $self, $ref2matchingArray ) = @_;
	$self->{displayedGBregions} = $ref2matchingArray
	  if ( defined @$ref2matchingArray[0] );
	return $self->{displayedGBregions};
}

sub Plot_hash {
	my ( $self, $hash ) = @_;

	my ( $plot, $height, $count, $columnHight, $gbFactor, $spaceFactor,
		$XY_plotFactor, $origWidth );

	$plot = singleLinePlot->new( $self->{pathModifier} );

	$hash->{x_axis}->{start} = $hash->{start} if ( defined $hash->{start} );
	$hash->{x_axis}->{end}   = $hash->{end}   if ( defined $hash->{end} );

	#$plot = singleLinePlot->new($self->{pathModifier});

	$count = $self->{cellTypes};
	
	$columnHight = int( $self->{width} / 1000 * 330 );
	$origWidth   = $self->{width};
	$self->{width} = int( $self->{width} * 1.5 ) if ( $self->WidePicture );
	$self->{width} = int( $self->{width} * 0.7 )
	  if ( $self->NarrowPicture() );

	$height = $columnHight * ( keys %$count );
	$height = $columnHight * 2 if ( $height == $columnHight );
	$height = $columnHight * 2 if ( $height == 0 );
	$gbFactor         = 50 / $height;
	$spaceFactor      = $gbFactor / 2;
	$XY_plotFactor    = 1 - $gbFactor - $spaceFactor;
	$hash->{HMM_data} = $self->{hmmData};

	$hash->{lineModel} = {
		width         => $self->{width},
		height        => $height,
		gbFactor      => $gbFactor,
		XY_plotFactor => $XY_plotFactor,
		spaceFactor   => $spaceFactor,
		rulerFactor   => 0,
		lines         => 1
	};


	$hash->{x_axis}->Summary( $self->Summary );
	$hash->{x_axis}->showPrimer( $self->showPrimer );
	my @temp = $hash->{x_axis}->UsedRegions( $self->used_gbFeatures() );
	#root::print_hashEntries($self, 5 , "the dump of xy_evaluation during the Plot_hash process\n");
	$plot->plot($hash);
	$self->{width} = $origWidth;
	return 1;
}

sub Summary {
	my ( $self, $summary ) = @_;
	
	if ( defined $summary ) {
		$self->{summary} = $summary;
	}

	#print "DEBUG $self: SUMMARY we have a value of $self->{summary}\n";
	return $self->{summary};
}

sub showPrimer {
	my ( $self, $summary ) = @_;
	if ( defined $summary ) {
		$self->{primer} = $summary;
	}
	return $self->{primer};
}

sub resetAxis {
	my ( $self, $pictureData ) = @_;
	return $pictureData->{X_axis}->resetAxis();
}

sub Plot {
	my (
		$self,   $pictureData, $filename, $pictureTitle, $xTitle,
		$yTitle, $gbFile,      $start,    $end,          $nuclData
	) = @_;
	my (
		$plot,        @temp,     $height,
		$count,       $gbFactor, $XY_plotFactor,
		$spaceFactor, $hash,     $columnHight
	);

	print
"XY_Evaluation->Plot width = $self->{width}\nXY_Evaluation->Plot is DEPRICATED use XY_Evaluation->Plot_hash\n";


	$hash = {
		filename            => $filename,
		gbFile              => $pictureData->{X_axis}->{gbFile},
		start               => $pictureData->{X_axis}->{start},
		end                 => $pictureData->{X_axis}->{end},
		X_title             => $pictureData->{title},
		GFF_Axis            => $pictureData->{Y_axis},
		minOverride         => $self->{minOverride},
		maxOverride         => $self->{maxOverride},
		rulerTitle          => undef,
		HMM_data            => undef,
		GBfile_MySQL_string => undef,
		NuclPosArray        => $nuclData,
		HMM_data            => $self->{hmmData},
		x_axis              => $pictureData->{X_axis}
	};

	return $self->Plot_hash($hash);

}

sub Set_X_title {
	my ( $self, $pictureData, $title ) = @_;
	$pictureData->{X_axis}->{title} = $title;
	return 1;
}

sub AddX_axis {
	my ( $self, $pictureData, $start, $end ) = @_;

	my ( $features, @featurePlottables, $X_AxisData );
	$X_AxisData = $pictureData->{regionList};
	unless ( defined $pictureData ) {
		my %temp;
		$pictureData = \%temp;
	}
	unless ( defined $pictureData->{X_axis} ) {
		$pictureData->{X_axis} =
		  gbFile_X_axis_with_NuclPos->new( @$X_AxisData[0]->{gbFile},
			$start, $end );
		#print "Create a new X_Axis: gbFile_X_axis_with_NuclPos->new(  @$X_AxisData[0]->{gbFile},  $start, $end )\n";
	}

	return $pictureData;
}

sub Delete_HMM_Data {
	my ($self) = @_;
	$self->{hmmData} = undef;
	$self->{hmmData} = List4enrichedRegions->new();
}

sub AddHMM_Data {
	my ( $self, $gffFilename ) = @_;

	my ( $list, $information, $i, $data );

	#$information = root->ParseHMM_filename($gffFilename);
	$information = $self->{gffFile}->getEnrichedRegions($gffFilename);
	$self->{hmmData}->AddData($information);
	return $information;
}

sub defineSubAxis {
	my ( $self, $pictureData, $start, $end, $percentage ) = @_;
	print "$self defineSubAxis: ($pictureData, $start, $end, $percentage)\n";
	return $pictureData->{X_axis}->defineSubAxis( $start, $end, $percentage );
}

=head2 Add2Y_axis

=head3 atributes

[0]: the antibody specificity

[1]: the design string

[2]: the celltype

[3]: the reference to the Y_axis data array

[4]: the up to now created picture data hash or undef

[5]: the start of the evaluated region ein basepairs

[6]: the end of the evaluated region in basepairs

[7]: length of the data bin

=head3 return value

The reference to the picture array data hash reference

=cut

sub Add2Y_axis {
	my (
		$self,       $antibody,    $designString, $celltype,
		$Y_AxisData, $pictureData, $start,        $end,
		$binLength,  $matching_gbTags, $nimbelGeneID
	) = @_;

	$self->{start} = $start;
	$self->{end}   = $end;
	#print "DEBUG $self Add2Y_axis got nimbleGeneID $nimbelGeneID\n";
	$self->used_gbFeatures($matching_gbTags);

	$self->{cellTypes}->{$celltype} = 1;
	unless ( defined $pictureData ) {
		my %temp;
		$pictureData = \%temp;
	}
	unless ( defined $pictureData->{Y_axis} ) {

		#      print "Creating a new GFF_data_Y_axis object!\n";
		$pictureData->{Y_axis} = NEW_Summary_GFF_Y_Axis->new();

		print
		  "\nUsing $pictureData->{Y_axis}->{binLength} bp window length\n\n";
	}
	$pictureData->{Y_axis}->BinLength ( $binLength );
	my $gbFile = $pictureData->{regionList};
	$pictureData->{Y_axis}
	  ->AddDataforChipType_new( $designString, $antibody, $celltype,
		$Y_AxisData, $start, $end, @$gbFile[0]->{gbFile},
		$matching_gbTags, $nimbelGeneID );
	return $pictureData;
}

sub initialize_Yaxis{
	my ( $self, $pictureData) = @_;
	unless ( defined $pictureData->{Y_axis}){
		
	}
	
}

sub getY_Axis_PlottableObject {
	my ( $self, $pictureData ) = @_;
	return $pictureData->{Y_axis};
}

=head2 defineRegions

=head3 atributes

[0]: the reference to a array with the structure ( { start, end} )

[1]: the nimbleGene chip design string

[2]: the mysql entry of the wanted genbank formated sequence file

=head3 return value

the reference to a pictureHash with the structure 
{ regionList => { start => $, end => $, featureArray => \@(gbfeatures), oligos => \@({oligoID, meanBP, oligoCount}) } }

=cut

sub defineRegions {
	my ( $self, $regionData, $designString, $gbFileString ) = @_;
	my ( @regions, $region, $i, $gbFile, $pictureData, $Info );
	$i = 0;

#print "DEBUG: $self: defineRegions (regionData = $regionData,designString = $designString,gbFileString = $gbFileString )\n";

	foreach $region (@$regionData) {
		( $regions[ $i++ ], $Info ) =
		  $self->defineRegion( $gbFileString, $region->{start}, $region->{end},
			$designString );
	}
	$pictureData->{regionList} = \@regions;
	$pictureData->{gbFileInfo} = $Info;
	$i                         = @regions;

	#print "DEBUG: $self: $i regions defined\n";
	return $pictureData;
}

sub createSimpe_PictureData_ofFile {
	my ( $self, $gbFile_String, $start, $end, $designString ) = @_;

	my ( $pictureData, $gbFile, $Info );

	( $gbFile, $Info ) = $self->GetGBFileObject( $gbFile, $designString );
	$pictureData->{X_axis} =
	  simple_multiline_gb_Axis->new( $gbFile, $start, $end );
	$pictureData->{gbFileInfo} = $Info;
	return $pictureData;
}

=head2 defineRegion

=head3 atributes

[0]: the gbFile object where the oligos should bind to

[1]: the starting position on this gbFile

[2]: the end position on this gbFile

[3]: the NimbleGene chip design string

=head3 return value

Retruns a hash reference with the structure 
{ start => atribute[1], end => atribute[2], featureArray => \(gbFeatures), oligos => \({oligoID, meanBP, oligoCount}) }

=cut 

sub defineRegion {
	my ( $self, $gbFile, $start, $end, $designString ) = @_;
	my ( $data, $oligoLocationArray, @Oligos, $mean, $i, $Info, $hash );

#print "DEBUG: $self: defineRegion ($gbFile, $start, $end, $designString )\n";
#print "DEBUG: $self: XY_Evaluation defineRegion gbFile = $gbFile region between $start and $end bp\n";

	( $gbFile, $Info ) = $self->GetGBFileObject( $gbFile, $designString );

	$oligoLocationArray =
	  $self->{oligo2dnaDB}
	  ->GetOligoLocationArray( $designString, $Info->{MySQL_entry} );

	$i = 0;
	$self->{lastEntry} = 0 unless ( defined $self->{lastEntry} );
	$hash = @$oligoLocationArray[ $self->{lastEntry} ];
	$self->{lastEntry} = 0 if ( @$hash[1] > $start );
	$self->{lastEntry} = 0 unless ( defined @$hash[1] );

#print "last entry for the OligoArray ( @$hash[1] > $start) = $self->{lastEntry}\n";
	for ( ; $self->{lastEntry} < @$oligoLocationArray ; $self->{lastEntry}++ ) {

 #print "DEBUG: $self: target region = $start to $end; Oligo end = @$hash[2]\n";
		$hash = @$oligoLocationArray[ $self->{lastEntry} ];
		next if ( @$hash[2] < $start );
		$mean = ( @$hash[1] + @$hash[2] ) / 2;
		if ( $mean < $end && $mean > $start ) {
			@$hash[0] = $1 if ( @$hash[0] =~ m/(CHR\d+[RP]\d+)/ );
			$Oligos[ $i++ ] = {
				mean       => $mean,
				oligoID    => "@$hash[0]",
				oligoCount => @$hash[5]
			};
		}
		if ( @$hash[1] > $end ) {

	  #	print "stop of iteration at position $self->{lastEntry} @$hash[1]bp\n" ;
			last;
		}
	}
	$mean = @$oligoLocationArray;

#print "DEBUG: $self: we reached the end (used oligos: n = $i)? is $mean < $self->{lastEntry}?\n";
	@Oligos = sort numeric_BP @Oligos;

	#	my $NewgbFile = gbFile->new();
	#	$NewgbFile -> Length ($end);
	#	$NewgbFile -> Features($gbFile->GetFeatureInRegion( $start, $end ));
	#	print "XY_Evaluation NewgbFile = $NewgbFile\n";
	$data = {
		start        => $start,
		end          => $end,
		gbFile       => $gbFile,
		featureArray => $gbFile->GetFeatureInRegion( $start, $end ),
		oligos       => \@Oligos
	};
	return $data, $Info;
}

sub numeric_BP {
	return $a->{mean} <=> $b->{mean};
}

=head2 GetY_axisData

=head3 atributes

[0]: the picture array hash as defined by $self->defineRegions()

[1]: the absolute location of the signalMap formted enrichment data

=head3 return values

The used antibody-specificity, the NimbleGene chip design string, the celltype and a array with the structure ({mean,value,oligoID}),
that can be used to add the data to i.e. a GFF_data_Y_axis object.
 
=cut

sub GetY_axisData {
	my ( $self, $pictureHash, $GFFfileLocation ) = @_;

	my (
		$useTStatGFF, $specificity, $designString,
		$celltype,    $gffData,     $oligoList,
		@YAxisData,   $i,           $regionList
	);
	$self->{max_oligo_count} = 5 unless ( defined $self->{max_oligo_count} );
	( $useTStatGFF, $specificity, $designString, $celltype ) =
	  $self->getInfos4SignalMapFormatedFile($GFFfileLocation);

	$gffData = $self->{gffFile}->GetData($GFFfileLocation)
	  unless ($useTStatGFF);
	$gffData = $self->getTStatGFF_data( $specificity, $celltype, $designString )
	  if ($useTStatGFF);

	$i          = 0;
	$regionList = $pictureHash->{regionList};
	foreach my $region (@$regionList) {
		$oligoList = $region->{oligos};
		foreach my $oligoInfo (@$oligoList) {

#print "DEBUG: $self: $i GetY_axisData oligoID = $oligoInfo->{oligoID} oligoCount $oligoInfo->{oligoCount} <= $self->{max_oligo_count} ?\n";
			$YAxisData[ $i++ ] = {
				mean    => $oligoInfo->{mean},
				value   => $gffData->{ $oligoInfo->{oligoID} },
				oligoID => $oligoInfo->{oligoID}
			  }
			  if ( $oligoInfo->{oligoCount} <= $self->{max_oligo_count} );
		}
	}

	# print "XY_Evaluation GetY_axisData got $i data points\n";
	return $specificity, $designString, $celltype, \@YAxisData, $pictureHash;
}

sub GetGBFileObject {
	my ( $self, $fileString, $designString ) = @_;
	my ( $fileRef, $fileNameHash, $gbFile );

	#    print "GetGBFileObject $fileString, $designString \n";

	return $self->{gbFile}->{$fileString}->{gbFile},
	  $self->{gbFile}->{$fileString}->{fileRef}
	  if ( defined $self->{gbFile}->{$fileString}
		&& defined $self->{gbFile}->{$fileString}->{gbFile}
		&& defined $self->{gbFile}->{$fileString}->{fileRef} );

	#    return $self->{gbFile}->{$fileString}
	#      if ( defined $self->{gbFile}->{$fileString} );

	$fileRef      = root->getPureSequenceName($fileString);
	if ( defined stat($fileRef->{fileLocation})){
		$self->{gbFile}->{$fileString} =
			{ gbFile => gbFile->new($fileRef->{fileLocation}), fileRef => $fileRef };
		return $self->{gbFile}->{$fileString}->{gbFile}, $self->{gbFile}->{$fileString}->{fileRef};
	}

	$fileNameHash = $self->{fileDB}->SelectFiles_ByDesignId($designString);

	foreach my $temp ( keys %$fileNameHash ) {
		if ( $temp =~ m/$fileRef->{MySQL_entry}/ ) {
			$self->{gbFile}->{$fileString} =
			  { gbFile => gbFile->new($temp), fileRef => $fileRef };
			return $self->{gbFile}->{$fileString}->{gbFile},
			  $self->{gbFile}->{$fileString}->{fileRef};
		}
	}
	return undef;
}

=head2 getInfos4SignalMapFormatedFile

=head3 atributes

[0]: the name of a SignalMap formated file or a nimbleGeneID

=head3 return values

A boolean value of the TStat data should be used (got no SignalMap file),
the antibody specificity, the NimbleGene chip design string
and the used Celltype.

=cut

sub getInfos4SignalMapFormatedFile {
	my ( $self, $GFF_file ) = @_;

	my ( $nimbleInfos, $useTStatGFF, $tempGFF, $nimbleID, $i );

	$nimbleInfos = $self->{hybInfoDB}->getAllByNimbleID();
	$useTStatGFF = 1 == 1 unless ( $GFF_file =~ m/\// );
	$tempGFF     = $self->File_containgNimbleID($GFF_file);

	$i = 0;

	#    print "searching for NimbleID $tempGFF\n";
	foreach $nimbleID ( keys %$nimbleInfos ) {
		if ( $tempGFF == $nimbleID ) {

			#            print "$nimbleID ist ein Teil von $GFF_file!\n";
			$i = "cy5"
			  if ( $nimbleInfos->{$nimbleID}->{cy5}->{TemplateType} =~ m/^E/ );
			$i = "cy3"
			  if ( $nimbleInfos->{$nimbleID}->{cy3}->{TemplateType} =~ m/^E/ );
			return $useTStatGFF, $nimbleInfos->{$nimbleID}->{$i}->{Antibody},
			  $nimbleInfos->{$nimbleID}->{$i}->{ArrayDesign},
			  $nimbleInfos->{$nimbleID}->{$i}->{Celltype};
		}

	}
	return undef;
}

sub File_containgNimbleID {
	my ( $self, $file ) = @_;

	my ($fileNimbelID);
	$fileNimbelID = $1 if ( $file =~ m/^(\d+) ?.*/ );
	if ( $file =~ m/\// ) {
		$fileNimbelID = $1 if ( $file =~ m/(\d+)_/ );
		$fileNimbelID = $1 if ( $file =~ m/IP_(\d+)/ );
	}
	return $fileNimbelID;
}

sub GetAsTableLine {
	my ( $self, $pictureData ) = @_;
	return $pictureData->{Y_axis}->GetAsTableLine();
}

sub GetTableHeader {
	my ( $self, $pictureData ) = @_;
	return $pictureData->{Y_axis}->GetTableHeader();
}

sub AsTable_inBP {
	my ( $self, $bp, $pictureData ) = @_;
	return $pictureData->{Y_axis}->AsTable_inBP($bp);
}

sub getTStatGFF_data {
	my ( $self, $antibody, $celltype, $designID ) = @_;

	my ( $organism, $i );

	( $organism, $celltype ) = split( ":", $celltype );
	( $organism, $i ) = $self->{array_TStat}->GetValue_forInfoID(
		$self->{array_TStat}
		  ->getInfo( $antibody, $celltype, $organism, $designID ),
		"gff_summary"
	);

	foreach my $value ( values %$organism ) {
		$value = exp( $value / 1.442695 );
	}
	return $organism;

}

sub print_pictureData {
	my ( $self, $pictureData ) = @_;

	print "DEBUG $self: the pictureData ($pictureData):\n";
	warn "output hast to be redirected into a file to use this method!!\n";
	my $i        = 1;
	my $maxDepth = 2;
	while ( my ( $key, $value ) = each(%$pictureData) ) {
		$self->printEntry( $key, $value, $i, $maxDepth );
	}
	return 1;
}

sub print_hashEntries {
	my ( $self, $hash, $maxDepth, $topMessage ) = @_;
	if ( defined $topMessage ) {
		print "$topMessage\n";
	}
	else {
		print "DEBUG $self: entries of the hash $hash:\n";
	}
	while ( my ( $key, $value ) = each(%$hash) ) {
		$self->printEntry( $key, $value, 1, $maxDepth );
	}
	return 1;
}

sub printEntry {
	my ( $self, $key, $value, $i, $maxDepth ) = @_;

	my $max = 10;
	my ( $printableString, $maxStrLength );
	$maxStrLength = 30;

	if ( defined $value ) {
		for ( $a = $i ; $a > 0 ; $a-- ) {
			print "\t";
		}
		$printableString = $value;
		if ( length($value) > $maxStrLength ) {
			$printableString = substr( $value, 0, $maxStrLength );
			$printableString = "$printableString ...";
		}
		print "$key\t$printableString\n";
	}
	else {
		for ( $a = $i ; $a > 0 ; $a-- ) {
			print "\t";
		}
		$printableString = $key;
		if ( length($value) > $maxStrLength ) {
			$printableString = substr( $key, 0, $maxStrLength );
			$printableString = "$printableString ...";
		}
		print "$printableString\n";
	}
	return 1 if ( $maxDepth == 0 );
	if ( $value =~ m/ARRAY/ ) {
		$max = 20;
		foreach my $value1 (@$value) {
			$self->printEntry( $value1, undef, $i + 1, $maxDepth - 1 );
			last if ( $max-- == 0 );
		}
	}
	if ( $value =~ m/HASH/ ) {
		$max = 20;
		while ( my ( $key1, $value1 ) = each %$value ) {
			$self->printEntry( $key1, $value1, $i + 1, $maxDepth - 1 );
			last if ( $max-- == 0 );
		}
	}
	if ( $key =~ m/ARRAY/ ) {
		$max = 20;
		foreach my $value1 (@$key) {
			$self->printEntry( $value1, undef, $i + 1, $maxDepth - 1 );
			last if ( $max-- == 0 );
		}
	}
	if ( $key =~ m/HASH/ ) {
		$max = 20;
		while ( my ( $key1, $value1 ) = each %$key ) {
			$self->printEntry( $key1, $value1, $i + 1, $maxDepth - 1 );
			last if ( $max-- == 0 );
		}
	}
	return 1;
}

1;
