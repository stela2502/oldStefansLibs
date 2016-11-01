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
use stefans_libs::multiLinePlot;
use stefans_libs::database_old::fileDB;
use stefans_libs::NimbleGene_config;

my ($gbFileName) = @ARGV;

warn
"atribute[0]: a file with a list gbFile locations\nAll Files listed in the MySQL DB are used\n"
  unless ( defined $gbFileName );

my ( @temp, $multiLinePlot, $ChIP_Infos, $gbFiles, $fileDB );

#$fileDB = fileDB->new();
#$ChIP_Infos = NimbleGene_config::ProbabillityEstimatingArray();
#$gbFiles = $fileDB->SelectFiles_ByDesignId($ChIP_Infos->{designID});

$multiLinePlot = multiLinePlot->new();

if ( defined $gbFileName ) {
    open( GB_File, $gbFileName )
      or die "could not open gff file list $gbFileName\n";
    print "opened file $gbFileName\n";
    while (<GB_File>) {
        if ( $_ =~ m/LOCUS/ ) {
            print "Nur ein gbFile auswerten: $gbFileName\n";
            $gbFiles->{$gbFileName} = $gbFileName;
            last;
			next;
        }
        next if ( $_ =~ m/^#/ || $_ =~ m/^PATH_MODIFIER=/ );
        @temp = split( " ", $_ );
        $gbFiles->{ $temp[0] } = $temp[0];
    }
    close( GB_File );
}
else {
    $fileDB     = fileDB->new();
    $ChIP_Infos = NimbleGene_config::ProbabillityEstimatingArray();
    $gbFiles    = $fileDB->SelectFiles_ByDesignId( $ChIP_Infos->{designID} );
}

foreach my $gbFile ( keys %$gbFiles ) {
    print "Add $gbFile\n";
    $multiLinePlot->AddGbFile($gbFile);
}

my $lineModel = {
    lines           => 10,
    width           => 1500,
    height          => 800,
    spaceFactor     => 1 / 16,
    rulerFactor     => 1 / 5,
    gbFactor        => 2 / 3,
    x_border_factor => 1 / 10,
    y_border_factor => 1 / 20
};
$multiLinePlot->SetLineModel($lineModel);
$multiLinePlot->plotOnlyGBfiles();
