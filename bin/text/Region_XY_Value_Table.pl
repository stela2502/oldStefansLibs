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
use stefans_libs::XY_Evaluation;
use stefans_libs::database_old::fileDB;
use stefans_libs::gbFile;
use stefans_libs::multiLinePlot::simple_multiline_gb_Axis;
use stefans_libs::multiLinePlot::multilineXY_axis;

die "argument[0] = gbFile_MysqlString\n",
  "argument[1] = GFF_File location file (one file per line)\n",
  "argument[2] = semicolonSeparatedMatchingStrings\n",
  "argument[3] = region length\n", "argument[4] = Table filename\n",
  "argument[5] = optional regionList file for graphical output\n",
  "argument[6] = min override (optional)\n",
  "argument[7] = max override (optional)\n"
  if ( @ARGV < 5 );
my @arrayOfSubregions;
my ( $gbFileTab, $GFF_File, $semicolonSeparatedMatchingStrings,
    $regionRadius, $pictureFilename, $masterRegion )
  = @ARGV;

my $fileDB = fileDB->new();

print
"gbFile_MysqlString = $gbFileTab\nGFF_Files separated by semicolon = $GFF_File\nsemicolonSeparatedMatchingStrings $semicolonSeparatedMatchingStrings\nregionRadius $regionRadius\npicture Filename = $pictureFilename\n";

my @matchingStrings = split( ";", $semicolonSeparatedMatchingStrings );

foreach my $temp (@matchingStrings) {
    print
"./V_SegmentBlot.pl $gbFileTab  $GFF_File $temp $regionRadius EnrichedV_Segment_$temp \n";
}

open( GFF, "<$GFF_File" ) or die "Konnte $GFF_File nicht oeffnen!\n";

my ( @GFF_Files, $pathModifier, $V_segment_summaryBlot, $pictureData, @temp );

while (<GFF>) {
    next if ( $_ =~ m/^#/ );
    print $_;
    @temp = split( " ", $_ );
    push( @GFF_Files, $temp[0] );    # if ( $_ =~ m/^([\/\w\d].*) *#?.*$/ );
}

if ( $GFF_Files[0] =~ m/PATH_MODIFIER=([\w\d]*)/ ) {
    $pathModifier = $1;
    shift @GFF_Files;
    print "Path Modifier = $pathModifier\n";
}

$V_segment_summaryBlot = XY_Evaluation->new("$pathModifier-summary");

my $designID = "2005-09-08_RZPD1538_MM6_ChIP";
my $fileHash = $fileDB->SelectFiles_ByDesignId($designID);
my $i        = 0;
my @fake     = (
    "C_region",  "V_segment", "mRNA", "enhancer",
    "D_segment", "J_segment", "C_segment"
);
my $temp = 0;
my ( $region, @regions, $gbFile, $gbFeatures );

foreach my $gbFilename ( keys %$fileHash ) {
    next unless ( $gbFilename =~ m/$gbFileTab/ );
    print "evaluating $gbFilename\n";
    $gbFile     = gbFile->new($gbFilename);
    $gbFeatures = undef;
    $gbFeatures = $gbFile->SelectMatchingFeatures_by_Tag( \@fake );
    foreach my $gbFeature (@$gbFeatures) {
        $temp = 0;
        foreach my $string (@matchingStrings) {
            $temp = 1 if ( $gbFeature->Name =~ m/$string/i );
            $temp = 1 if ( $temp == 0 && $gbFeature->Tag eq $string );
        }
        next if ( $temp == 0 );
        my $hash = {
            gbFile     => $gbFilename,
            tag        => $gbFeature->Tag(),
            name       => $gbFeature->Name(),
            complement => $gbFeature->IsComplement()
        };
        $region = $gbFeature->getRegionForDrawing();
        if ( $hash->{tag} eq "V_segment" ) {
            if ( @$region == 1 ) {
                $hash->{start}    = @$region[0]->{start};
                $hash->{end}      = @$region[0]->{start} + $regionRadius;
                $hash->{gbFeatue} = $gbFeature;
            }
            if ( @$region == 2 ) {
                $hash->{start}    = @$region[1]->{start};
                $hash->{end}      = @$region[1]->{start} + $regionRadius;
                $hash->{gbFeatue} = $gbFeature;
            }
            die "Unexprected Problem: the V segment ", $gbFeature->Name(),
              " had more that 2 exons!"
              if ( @$region > 2 );
        }
        else {
            $hash->{start}    = @$region[0]->{start};
            $hash->{end}      = @$region[0]->{start} + $regionRadius;
            $hash->{gbFeatue} = $gbFeature;
        }
        $regions[ $i++ ] = $hash;
        @temp            = undef;
        $temp[0]         = $hash;
        $hash->{pictureData} =
          $V_segment_summaryBlot->defineRegions( \@temp,
            "2005-09-08_RZPD1538_MM6_ChIP", $gbFilename );

    }
    $masterRegion =
      $V_segment_summaryBlot->createSimpe_PictureData_ofFile( $gbFilename, 0,
        $gbFile->Length(), "2005-09-08_RZPD1538_MM6_ChIP" );
    print "Summary Data x axis is $masterRegion->{X_axis}\n";
}
print "$i different regions get evaluated\n";
$i = 0;

print "AddX_axis wurde abgeschlossen!\n";

foreach my $gff (@GFF_Files) {

    print "Using GFF File: $gff\n";
    next if ( $gff =~ m/^#/ );
    $gff = $1 if ( $gff =~ m/^(.+) *#?.*/ );
    foreach my $region (@regions) {
        $region->{pictureData} = $V_segment_summaryBlot->Add2Y_axis(
            $V_segment_summaryBlot->GetY_axisData(
                $region->{pictureData}, "$gff"
            ),
            $region->{start},
            $region->{end},
            $regionRadius
        );
    }
}

my ( @table, $header, $line1, $line2 );

for ( my $i = 0 ; $i < @regions ; $i++ ) {
    $region = $regions[$i];
    unless ( defined $header ) {
        ( $line1, $line2 ) =
          $V_segment_summaryBlot->GetTableHeader( $region->{pictureData} );
        $table[0] = " \t \t \t \t$line1";
        $table[1] = "filename\tfeature tag\tfeature name\tstart [bp]$line2";
        $header   = "done";
    }
    @temp = undef;
    @temp = (
        $region->{gbFile}, $region->{tag}, $region->{name}, $region->{start},
        $V_segment_summaryBlot->GetAsTableLine( $region->{pictureData} )
    );
    $line1 = join( "\t", @temp );
    $table[ $i + 2 ] = $line1;
}

open( OUT, ">/Mass/ArrayData/Tabelaric_Report/$pictureFilename.csv" )
  or die
"konnte file /Mass/ArrayData/Tabelaric_Report/$pictureFilename.csv nicht anlegen!\n";

print OUT join( "\n", @table );

close(OUT);

print
"Tabelle in /Mass/ArrayData/Tabelaric_Report/$pictureFilename.csv gespeichert\n";

open( RegionsFile, "<$ARGV[5]" )
  or die "Es wurde keine Datei mit Regionen angegeben\nFertig\n";

my ($hash, $multilineXY_axis);

$multilineXY_axis = multilineXY_axis->new();

for ( my $i = 0 ; $i < @regions ; $i++ ) {
    $region = $regions[$i];
    $temp =
      $V_segment_summaryBlot->AsTable_inBP(
        ( $region->{start} + $region->{end} ) / 2,
        $region->{pictureData} );
   # foreach my $key ( keys %$temp ) {
   #     print "HashKey: $key\n";
   #     my $temp2 = $temp->{$key};
   #     foreach my $key2 ( keys %$temp2 ) {
   #         print "\t$key2\t$temp2->{$key2}\n";
   #     }
   # }
    $multilineXY_axis->AddTabellaricData($temp);
}
$masterRegion->{Y_axis} = $multilineXY_axis;
$V_segment_summaryBlot->{minOverride} = $ARGV[6];
$V_segment_summaryBlot->{maxOverride} = $ARGV[7];

while (<RegionsFile>) {
    next if ( $_ =~ m/^#/ );
    next if ( $_ =~ m/^new=/ );
    chomp $_;
    (
        $hash->{gbFile}, $hash->{start},        $hash->{end},
        $hash->{X_axis}, $hash->{pictureTitle}, $hash->{filename},
        $hash->{binLength}, @arrayOfSubregions
    ) = split( ",", $_ );
    $hash->{pictureTitle} = "  ";
    print "\n\ngbFile = $hash->{gbFile}\n", "start = $hash->{start}\n",
      "end = $hash->{end}\n", "X_axis = $hash->{X_axis}\n",
      "pictureTitle = $hash->{pictureTitle}\n",
      "filename = $hash->{filename}\n",
      "oligo bin length = '$hash->{binLength}'\n\n\n";
	$temp = @arrayOfSubregions;
	print " regionXY....pl got $temp subregions info (3 per one subregion)\n";
	if ( $temp > 2){
		$V_segment_summaryBlot->resetAxis($masterRegion);
    	for (my $i = 0; $i < @arrayOfSubregions; $i += 3){
	  		$V_segment_summaryBlot->defineSubAxis($masterRegion, $arrayOfSubregions[$i], $arrayOfSubregions[$i +1], $arrayOfSubregions[$i+2]);
		}
	}
    $V_segment_summaryBlot->Plot(
        $masterRegion, $hash->{filename}, "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, $hash->{start}, $hash->{end}
    ) if ( $gbFile->Name =~ m/$hash->{gbFile}/ );
}
return;
if ( $gbFile->Name =~ m/Ig_H/ ) {
    $V_segment_summaryBlot->Plot(
        $masterRegion, "IVAR1", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 300000, 400000
    );
    $V_segment_summaryBlot->Plot(
        $masterRegion, "IVAR2", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 600000, 700000
    );
    $V_segment_summaryBlot->Plot(
        $masterRegion, "IVAR3", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 750000, 850000
    );
    $V_segment_summaryBlot->Plot(
        $masterRegion, "Full_IgH.summary", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 0, $gbFile->Length()
    );
    $V_segment_summaryBlot->Plot(
        $masterRegion, "DJh.summary", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 2585000, 2650000
    );
    $V_segment_summaryBlot->Plot(
        $masterRegion, "distal_Vh", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 0, 1200000
    );
    $V_segment_summaryBlot->Plot(
        $masterRegion, "proximal_Vh", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 1200000, 2530000
    );
}
if ( $gbFile->Name =~ m/TCRB/ ) {
    $V_segment_summaryBlot->Plot(
        $masterRegion, "Full_TCRB.summary", "",
        "rel. position [bp]",
        "mean enrichment factor [log2]",
        $gbFile, 0, $gbFile->Length()
    );

}

