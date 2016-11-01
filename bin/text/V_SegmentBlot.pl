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
use stefans_libs::XY_Summay_Evaluation;
use stefans_libs::database::fileDB;
use stefans_libs::gbFile;

die "argument[0] = gbFile_MysqlString\n",
  "argument[1] = GFF_File location file (one file per line)\n",
  "argument[2] = semicolonSeparatedMatchingStrings\n",
  "argument[3] = regionRadius\nargument[4] = Picture filename\n",
  "argument[5] = oligo bin dimension [bp]\n",
  "argument[6] = optional min override\n",
  "argument[7] = optional max override\n"
  if ( @ARGV < 6 );

my ( $gbFileTab, $GFF_File, $semicolonSeparatedMatchingStrings,
    $regionRadius, $pictureFilename )
  = @ARGV;

my $fileDB = fileDB->new();

print
"gbFile_MysqlString = $gbFileTab\nGFF_Files separated by semicolon = $GFF_File\nsemicolonSeparatedMatchingStrings $semicolonSeparatedMatchingStrings\nregionRadius $regionRadius\npicture Filename = $pictureFilename\n";
print " min override = $ARGV[6], max override = $ARGV[7]\n";

my @matchingStrings = split( ";", $semicolonSeparatedMatchingStrings );

foreach my $temp (@matchingStrings) {
	print $temp if ($temp =~ s/\//\\\//);
    print
"./V_SegmentBlot.pl $gbFileTab  $GFF_File $temp $regionRadius EnrichedV_Segment_$temp \n";
}

open( GFF, "<$GFF_File" ) or die "Konnte $GFF_File nicht öffnen!\n";

my ( @GFF_Files, $pathModifier, $V_segment_summaryBlot, $pictureData, @temp );

my ( $pictureData_50, $pictureData_100, $pictureData_250, $pictureData_500);

while (<GFF>) {
    next if ( $_ =~ m/^#/ );
    print $_;
	@temp = split ( " ", $_);
    push( @GFF_Files, $temp[0] ); # if ( $_ =~ m/^([\/\w\d].*) *#?.*$/ );
}

if ( $GFF_Files[0] =~ m/PATH_MODIFIER=([\w\d]*)/ ) {
    $pathModifier = $1;
    shift @GFF_Files;
    print "Path Modifier = $pathModifier\n";
}

$V_segment_summaryBlot = XY_Summay_Evaluation->new($pathModifier);

my $designID = "2005-09-08_RZPD1538_MM6_ChIP";
my $fileHash = $fileDB->SelectFiles_ByDesignId($designID);
my $i        = 0;
my @fake     = (
#	"J_segment", 
	"V_segment",
#	"mRNA",
#	"enhancer"
);
my $temp     = 0;
my ( $region, @regions, $gbFile, $gbFeatures );

foreach my $gbFilename ( keys %$fileHash ) {
    unless ( $gbFilename =~ m/$gbFileTab/ ){
		print "$gbFilename will not be evaluated!\n";
		next;
	}
    print "evaluating $gbFilename\n";
    $gbFile     = gbFile->new($gbFilename);
    $gbFeatures = undef;
    $gbFeatures = $gbFile->SelectMatchingFeatures_by_Tag( \@fake );
    foreach my $gbFeature (@$gbFeatures) {
        $temp = 0;
        foreach my $string (@matchingStrings) {
            $temp = 1 if ( $gbFeature->Name =~ m/$string/i );
			$temp = 1 if ( $temp == 0 && $gbFeature->Tag eq $string );
			#$temp = 1 if ( $temp == 0 && $gbFeature->getAsGB() =~ m/$string/ );
        }
        next if ( $temp == 0 );
        my $hash = {
            gbFile     => $gbFilename,
            name       => $gbFeature->Name(),
            complement => $gbFeature->IsComplement()
        };
        if ( defined $hash->{complement} ) {
            $region = $gbFeature->getRegionForDrawing();
            if ( @$region == 1 ) {
                $hash->{start} = @$region[0]->{end} - $regionRadius;
                $hash->{end}   = @$region[0]->{end} + $regionRadius;
                $gbFeature->ChangeRegion_Complement(
                    @$region[0]->{start} + $ARGV[3] );
                $hash->{gbFeature} = $gbFeature;
            }
            if ( @$region == 2 ) {
                $hash->{start} = @$region[1]->{end} - $regionRadius;
                $hash->{end}   = @$region[1]->{end} + $regionRadius;
                $gbFeature->ChangeRegion_Complement(
                    @$region[1]->{start} + $regionRadius )
                  if ( @$region == 2 );
                $hash->{gbFeatue} = $gbFeature;
            }
            die "Unexprected Problem: the V segment ", $gbFeature->Name(),
              " had more that 2 exons!"
              if ( @$region > 2 );
        }
        else {
            $region = $gbFeature->getRegionForDrawing();
            if ( @$region == 1 ) {
                $hash->{start} = @$region[0]->{start} - $regionRadius;
                $hash->{end}   = @$region[0]->{start} + $regionRadius;
                $gbFeature->ChangeRegion_Diff( @$region[0]->{start} - $regionRadius )
                  if ( @$region == 1 );
                $hash->{gbFeatue} = $gbFeature;
            }
            if ( @$region == 2 ) {
                $hash->{start} = @$region[1]->{start} - $regionRadius;
                $hash->{end}   = @$region[1]->{start} + $regionRadius;
                $gbFeature->ChangeRegion_Diff( @$region[1]->{start} - $regionRadius )
                  if ( @$region == 2 );
                $hash->{gbFeatue} = $gbFeature;
            }
            die "Unexprected Problem: the V segment ", $gbFeature->Name(),
              " had more that 2 exons!"
              if ( @$region > 2 );
        }
        $regions[ $i++ ] = $hash;
    }
    $pictureData_50 =
      $V_segment_summaryBlot->defineRegions( \@regions,
        "2005-09-08_RZPD1538_MM6_ChIP", $gbFilename );
}
print "Summary over $i different transcription start sites!\n";
$i = 0;

$pictureData_50 =
$V_segment_summaryBlot->AddX_axis( $pictureData_50, 0, $regionRadius * 2 );
$pictureData_100 = $V_segment_summaryBlot->Clone($pictureData_50);
$pictureData_250 = $V_segment_summaryBlot->Clone($pictureData_50);
$pictureData_500 = $V_segment_summaryBlot->Clone($pictureData_50);

print "AddX_axis wurde abgeschlossen!\n";

foreach my $gff (@GFF_Files) {

    print "Using GFF File: $gff\n";
    next if ( $gff =~ m/^#/ );
    $gff = $1 if ( $gff =~ m/^(.+) *#?.*/ );
    $pictureData_50 = $V_segment_summaryBlot->Add2Y_axis(
        $V_segment_summaryBlot->GetY_axisData( $pictureData_50, "$gff" ),
        0, $regionRadius * 2 , 50
    );
    $pictureData_100 = $V_segment_summaryBlot->Add2Y_axis(
        $V_segment_summaryBlot->GetY_axisData( $pictureData_100, "$gff" ),
        0, $regionRadius * 2 , 100
    );
    $pictureData_250 = $V_segment_summaryBlot->Add2Y_axis(
        $V_segment_summaryBlot->GetY_axisData( $pictureData_250, "$gff" ),
        0, $regionRadius * 2 , 250
    );
    $pictureData_500 = $V_segment_summaryBlot->Add2Y_axis(
        $V_segment_summaryBlot->GetY_axisData( $pictureData_500, "$gff" ),
        0, $regionRadius * 2 , 500
	);
}

#my $useStdDev = 1 == 0;
my $useStdDev = 1 == 1;

$V_segment_summaryBlot->{maxOverride} = $ARGV[7];
$V_segment_summaryBlot->{minOverride} = $ARGV[6];
$V_segment_summaryBlot->UseStdDev($pictureData_50, $useStdDev );
$V_segment_summaryBlot->UseStdDev($pictureData_100, $useStdDev );
$V_segment_summaryBlot->UseStdDev($pictureData_250, $useStdDev );
$V_segment_summaryBlot->UseStdDev($pictureData_500, $useStdDev );
$V_segment_summaryBlot->Plot($pictureData_500,"$pictureFilename-500", "", "location of a typical V segment", "mean region enrichment","GB_FILE?", 0, $regionRadius * 2, "relative position [bp]");
$V_segment_summaryBlot->Plot($pictureData_100,"$pictureFilename-100", "", "location of a typical V segment", "mean region enrichment","GB_FILE?", 0, $regionRadius * 2, "relative position [bp]");
$V_segment_summaryBlot->Plot($pictureData_250,"$pictureFilename-250", "", "location of a typical V segment", "mean region enrichment","GB_FILE?", 0, $regionRadius * 2, "relative position [bp]");
$V_segment_summaryBlot->Plot($pictureData_50,"$pictureFilename-50", "", "location of a typical V segment", "mean region enrichment","GB_FILE?", 0, $regionRadius * 2, "relative position [bp]");
