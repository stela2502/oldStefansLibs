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

use stefans_libs::root;
use stefans_libs::NimbleGene_config;
use stefans_libs::histogram;
use stefans_libs::nimbleGeneFiles::gffFile;
use stefans_libs::XYplot;
use strict;


my ( $fileInfo, $i, $hmmDataList, $gffFile, $histogram, $data, $XYplot, @X, @Y);

$hmmDataList = $ARGV[0];
open (IN ,"<$hmmDataList") or die "Ich konnte die HMM Listen-Datei '$hmmDataList' nicht öffnen!\n";
$gffFile = gffFile->new();
$histogram = histogram->new();

while ( <IN>){
	chomp $_;
	$fileInfo = root->ParseHMM_filename($_);
	$data = $gffFile->GetData($_);
    @X = (values %$data );
	$data = $histogram->AddDataArray( \@X , 100 );
	$histogram->writeHistogram("Iteration-$fileInfo->{Iteration}.csv");
	next;
	foreach my $key ( sort numeric keys %$data){
		$X[$i] = $key;
		$Y[$i] = $data->{$key};
		$i++;
	}
	$XYplot = XYplot->new();
	$XYplot->AddData(\@X, \@Y, "Iteration $fileInfo->{Iteration}", "black", "line" );
	$XYplot->{x_title} = "probability to be part of a enriched region";
	$XYplot->{y_title} = "count";
	$fileInfo->{Iteration} = $fileInfo->{Iteration} -1;
	$XYplot->plot("Iteration-$fileInfo->{Iteration}.png");
}

sub numeric {
	return $a <=> $b;
}
