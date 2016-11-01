package singleLinePlotHMM;
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

use strict;
use warnings;

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
	
	print "multiLinePlot outPath = $self->{OUTpath}\n";

  bless $self, $class  if ( $class eq "singleLinePlotHMM" );

  return $self;

}

sub plot_on_line{
	my ( $self, $filename, $lineModel, $gbFile, $start, $end, $GFF_Axis,
		$minOverride, $maxOverride, $line) = @_;
	$self->SetLineModel($lineModel);
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

	$filename = "$filename.png" unless ( $filename =~ m/\.png$/);
	$self->writePicture("$self->{OUTpath}/$filename");
	return;
}


sub plot{
	my ( $self, $hash ) = @_;
	
	#my ($filename, $lineModel, $gbFile, $start, $end, $X_title, $GFF_Axis,
	#	$minOverride, $maxOverride, $rulerTitle, $HMM_data, $GBfile_MySQL_string, $nuclData);
	
	die "FATAL ERROR: no GBfile_MySQL_string ('$hash->{GBfile_MySQL_string}') in singleLinePlotHMM splot()\n" 
		unless (defined $hash->{GBfile_MySQL_string});
	
	my ( $useNuclPos );
	print "singleLinePlotHMM plot gbFile = $hash->{gbFile}\nfilename = ",$hash->{gbFile}->Name(),"\n";
	$useNuclPos = $hash->{nuclData} if ( $hash->{gbFile}->Name =~ m/Ig_H/);
	
	$self->SetLineModel($hash->{lineModel}, undef, "no");
	$self->{lineCoordinates}->{0}->{x_axis} = 
	gbFile_X_axis_with_NuclPos->new(
		$hash->{gbFile},
		$hash->{start}, $hash->{end} ,
		$self->{lineCoordinates}->{0}->{x1},
		$self->{lineCoordinates}->{0}->{gb_data},
		$self->{lineCoordinates}->{0}->{x2},
		$self->{lineCoordinates}->{0}->{space},
		"med", $self->{color}, $hash->{useNuclPos}
	);
	$self->{lineCoordinates}->{0}->{x_axis}->Title( $hash->{X_title} );
	$self->{lineCoordinates}->{0}->{x_axis}->plot($self->{im}, $self->{font});
#	print "\n!!! MultiLine GB Axis ist fertig!\n";
	#print " Haben wir hier das richtige GFF_Axis objekt? $GFF_Axis\n";die;
	$hash->{GFF_Axis}->plot(
		$self->{im}, 
		$self->{lineCoordinates}->{0}->{hmm_data},
		$self->{lineCoordinates}->{0}->{XY_data},
		$self->{lineCoordinates}->{0}->{x_axis},
		$self->{color}, "mean enrichment factor [ log2 ]",
		"med", undef, $self->{font}, $hash->{minOverride}, $hash->{maxOverride},
		$hash->{HMM_data}, $hash->{GBfile_MySQL_string}
	);
	#my $temp = ruler_x_axis->new(
	#	$self->{lineCoordinates}->{0}->{x_axis}, $self->{color}->{black}, "med", 
	#	$self->{lineCoordinates}->{0}->{x1}, $self->{lineCoordinates}->{0}->{space},
	#	$self->{lineCoordinates}->{0}->{x2}, $self->{lineCoordinates}->{0}->{y2}, 
	#	$hash->{end});
	#$self->{lineCoordinates}->{0}->{x_axis}->defineAxis();
	#$temp->plot($self->{im}, $self->{color}->{black}, $hash->{rulerTitle});

	$hash->{filename} = "$hash->{filename}.png" unless ( $hash->{filename} =~ m/\.png$/);
	$self->writePicture("$self->{OUTpath}/$hash->{filename}");
	return;
}

1;
