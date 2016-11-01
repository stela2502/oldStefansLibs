package singleLinePlot;
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

use stefans_libs::multiLinePlot;
use stefans_libs::V_segment_summaryBlot::gbFile_X_axis_with_NuclPos;
@ISA = qw(multiLinePlot);

sub new{

	my ( $class, $pathModifier ) = @_;
	
	my ( $self, @gbLines, @DataLines, %HMM_data, @org, @cell, @ab, @iter );
	
	$self = {
		use_V_segment_colors => 1==0,
		drawTransfacList => undef,
		dataLines        => \@DataLines,
		gbLines          => \@gbLines,
		x_border_factor  => 1/10,
		y_border_factor  => 1/20,
		gffFile          => gffFile->new(),
		hmm_data         => \%HMM_data,
		organism_list    => \@org,
		celltype_list    => \@cell,
		antibody_list    => \@ab,
		iteration_list   => \@iter,
		tics             => 5,
		minorTics        => 5,
		lines            => 6,
		smallLines       => 11,
		printPrimer      => 0,
		Exon_Allow_Lines => 8,
		Zeilen           => 5,
		
	};
	
	$self->{dataFactor} = 1 - ( $self->{spaceFactor} *2 + $self->{rulerFactor} + $self->{gbFactor});
	my $today = Date::Simple->new();
	my $path  = NimbleGene_config::DataPath();
	$path = "$path/SingleLinePlots/$today";
	mkdir($path);
	$path = "$path/$pathModifier" if ( defined $pathModifier);
	$self->{OUTpath} = "$path";
	system("mkdir -p $self->{OUTpath}");
	
	print "singleLinePlot outPath = $self->{OUTpath}\n";

  bless $self, $class  if ( $class eq "singleLinePlot" );

  return $self;

}

sub Summary{
	my ($self, $summary) = @_;
	if (defined $summary){
		$self->{summary} = $summary;
	}
	return $self->{summary};
}

sub plot_on_line{
	my ( $self, $filename, $lineModel, $gbFile, $start, $end, $GFF_Axis,
		$minOverride, $maxOverride, $line) = @_;
	$self->SetLineModel($lineModel); ## creates a new image!
	$self->{lineCoordinates}->{$line}->{x_axis} = 
	multiline_gb_Axis->new(
		$gbFile,
		$start, $end ,
		$self->{lineCoordinates}->{$line}->{x1},
		$self->{lineCoordinates}->{$line}->{gb_data},
		$self->{lineCoordinates}->{$line}->{x2},
		$self->{lineCoordinates}->{$line}->{space},
		"med", $self->{color}
	);
	#$self->{lineCoordinates}->{$line}->{x_axis}->Summary($self->Summary);
	
	$self->{lineCoordinates}->{$line}->{x_axis}->plot($self->{im}, $self->{font});
#	print "\n!!! MultiLine GB Axis ist fertig!\n";
	$GFF_Axis->plot(
		$self->{im}, 
		$self->{lineCoordinates}->{$line}->{hmm_data},
		$self->{lineCoordinates}->{$line}->{XY_data},
		$self->{lineCoordinates}->{$line}->{x_axis},
		$self->{color}, "mean region enrichment factor [log2 ( IP / INPUT )]",
		"med", undef, $self->{font}, $minOverride, $maxOverride
	);
	my $temp = ruler_x_axis->new(
		$self->{lineCoordinates}->{$line}->{x_axis}, $self->{color}->{black}, "med", 
		$self->{lineCoordinates}->{$line}->{x1}, $self->{lineCoordinates}->{$line}->{space},
		$self->{lineCoordinates}->{$line}->{x2}, $self->{lineCoordinates}->{$line}->{y2}, 
		$end);
	$temp->plot($self->{im});
	$filename = $1 if ( $filename =~ m/(.+)\.svg/ );
	my $windowsize = $GFF_Axis->WindowSize();
	$filename = "$filename-WS$windowsize.svg";
	$self->writePicture("$self->{OUTpath}/$filename");
	return;
}


sub plot{
	my ( $self, $hash ) = @_;
	my ( $useNuclPos );
	if ( $hash->{gbFile}->Name =~ m/Ig_H/){
		print "we got nucleosomal positions!\n";
		$useNuclPos = $hash->{NuclPosArray};
	}
	
	$self->SetLineModel($hash->{lineModel}, undef, "no");
	#warn "\nPossible problems during the identification of the x_axis $hash->{x_axis}\n";
	if ( ( defined $hash->{x_axis} )) { # && $hash->{x_axis} =~ m/gbFile_X_axis_with_NuclPos/ ) || $hash->{x_axis} =~ m/simple_multiline_gb_Axis/  ){
#	if ( defined $hash->{x_axis}) {
		#print "\nNo new x_axis was created!\n";
		$self->{lineCoordinates}->{0}->{x_axis} = $hash->{x_axis};
		$self->{lineCoordinates}->{0}->{x_axis}->defineLocation (
			$hash->{gbFile}, $hash->{start}, $hash->{end}, 		
			$self->{lineCoordinates}->{0}->{x1},
			$self->{lineCoordinates}->{0}->{gb_data},
			$self->{lineCoordinates}->{0}->{x2},
			$self->{lineCoordinates}->{0}->{space},
			"med", $self->{color}, $useNuclPos
		);
	}
	else{
		#print "\nnew xaxis was created!!\n";
		$self->{lineCoordinates}->{0}->{x_axis} = 
		#multiline_gb_Axis->new(
		gbFile_X_axis_with_NuclPos->new(
			$hash->{gbFile},
			$hash->{start}, $hash->{end} ,
			$self->{lineCoordinates}->{0}->{x1},
			$self->{lineCoordinates}->{0}->{gb_data},
			$self->{lineCoordinates}->{0}->{x2},
			$self->{lineCoordinates}->{0}->{space},
			"med", $self->{color}, $useNuclPos
		);
	}
#	$self->{lineCoordinates}->{0}->{x_axis}->NuclArray($useNuclPos);
	$self->{lineCoordinates}->{0}->{x_axis}->{title} = $hash->{X_title};
	$self->{lineCoordinates}->{0}->{x_axis}->plot($self->{im}, $self->{font});
#	print "\n!!! MultiLine GB Axis ist fertig!\n";
	
	$hash->{GFF_Axis}->Max( $hash->{maxOverride} );
	$hash->{GFF_Axis}->Min( $hash->{minOverride} );
	#root::print_hashEntries($hash, 1, "whatever is in the hash \$hash ($hash) in signleLinePlot->plot()");
	$hash->{GFF_Axis}->plot(
		$self->{im}, 
		$self->{lineCoordinates}->{0}->{hmm_data},
		$self->{lineCoordinates}->{0}->{XY_data},
		$self->{lineCoordinates}->{0}->{x_axis},
		$self->{color}, "mean enrichment factor [ log2 ]",
		"med", undef, $self->{font}, $hash->{minOverride}, $hash->{maxOverride}, 
		$hash->{HMM_data}, $hash->{gbFile}->Name()
	);
	my $i = 0;
	print "Due to a lib confusion: $self plotted a graph using:\n";
		root::print_hashEntries($self->{lineCoordinates}->{0}->{x_axis}, $i, "the x_axis: $self->{lineCoordinates}->{0}->{x_axis}\n");
		root::print_hashEntries($self->{lineCoordinates}->{0}->{x_axis}, $i, "the x_axis: $self->{lineCoordinates}->{0}->{x_axis}\n");
		root::print_hashEntries($self->{lineCoordinates}->{0}->{x_axis}->{x_axis}, $i, "with the real x_axis of the type $self->{lineCoordinates}->{0}->{x_axis}->{x_axis}\n");
		root::print_hashEntries($hash->{GFF_Axis},$i,"the y_axis: $hash->{GFF_Axis}\n");
		root::print_hashEntries($hash->{GFF_Axis}->{axis}, $i,"the real y_axis: $hash->{GFF_Axis}->{axis}\n");
		root::print_hashEntries($hash->{GFF_Axis}->{data}, $i,"the data bin structure of the y_axis: $hash->{GFF_Axis}->{data}\n");
		print "possibly this information is usefull\n";
	print "x_axis min value = ",$self->{lineCoordinates}->{0}->{x_axis}->min_value(),"\n",
		"x_axis max value = ",$self->{lineCoordinates}->{0}->{x_axis}->max_value(),"\n";

	$hash->{filename} = $1 if ( $hash->{filename} =~ m/(.+)\.svg/ );
	my $windowsize = $hash->{GFF_Axis}->WindowSize();
	$hash->{filename} = "$hash->{filename}_WS$windowsize.svg";
	$self->writePicture("$self->{OUTpath}/$hash->{filename}");
	return;
}

1;
