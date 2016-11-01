#! /usr/bin/perl
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
use stefans_libs::plot::simpleXYgraph;
use Getopt::Long;

my ( $infile, $plotName, $pictureTitel, $yTitel, $xTitel, $useStdDef);

Getopt::Long::GetOptions(
	"-inFile=s"		=> \$infile,
	"-outFile=s"	=> \$plotName,
	"-plot_titel=s"	=> \$pictureTitel,
	"-x_titel=s"	=> \$xTitel,
	"-y_titel=s"	=> \$yTitel,
	"-use_stdDef"	=> \$useStdDef
) or die helpText();

die helpText() unless ( defined $infile && defined $plotName);

sub helpText{
	return
"	-inFile		:file containing the <tab> separated data set\n",
"				:first line (#) contains the y column lables in the same columns as the data is stored\n",
"	-outFile	:the name of the outfile\n",
"	-plot_titel	:the title of the graph\n",
"	-x_titel	:the axis titel for the x axis\n",
"	-y-titel	:the axis titel for the y axis\n",
"	-use_stdDef	:each second column in the dataset is used as standard deviation; the titel is ignored\n";

}


open (IN, "<$infile" ) or die "Kann elider das Datenfile '$infile' nicht šffnen!\n";

my (@line, $data, @xValues, @titles, $dataCount, $i);

$dataCount = 0;
while (<IN>){
	chomp($_);
	if ($_ =~ m/^#(.+)/){
		@line = split ("\t", $1);
		@titles = @line;
		shift (@line);
		unless ( $useStdDef){
		foreach my $yTitel ( @line){
			if ( defined $data->{$yTitel}){
				warn "duplicate y-titel '$yTitel' - only last Data-set will be plotted!\n";
			}
			my (@y, @stdAbw );
			$data->{$yTitel} = { x => \@xValues, y => \@y, stdAbw => \@stdAbw };
		}
		}
		else{
		my $line = 1 == 1;
		foreach my $yTitel ( @line){
			if ( defined $data->{$yTitel}){
				warn "duplicate y-titel '$yTitel' - only last Data-set will be plotted!\n";
			}
			my (@y, @stdAbw );
			if ( $line ){
				$data->{$yTitel} = { x => \@xValues, y => \@y, stdAbw => \@stdAbw };
				$line = 1 == 0;
			}
			else{
				$line = 1 == 1
			}
		}
		}
		next;
	}
	@line = split ("\t", $_ );
	push (@xValues, $line[0]);
	unless ($useStdDef){
	for ( $i = 1; $i < @line; $i++){
		$data->{$titles[$i]}->{y}[$dataCount] = $line[$i];
	}
	}
	else{
		for ( $i = 1; $i < @line; $i += 2){
			$data->{$titles[$i]}->{y}[$dataCount] = $line[$i];
			$data->{$titles[$i]}->{stdAbw}[$dataCount] = $line[$i+1];
		}
	}
	$dataCount ++
}

my $plot = simpleXYgraph->new();
#$data, $x_res, $y_res, $xTitle, $yTitle, $pictureTitle, $filename 
$plot->plotData($data, 500, 350, $xTitel, $yTitel, $pictureTitel, $plotName);
