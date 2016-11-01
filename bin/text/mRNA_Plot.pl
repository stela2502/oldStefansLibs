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
use stefans_libs::V_segment_summaryBlot::gbFeature_X_axis;
use stefans_libs::gbFile;

die "argument[0] = gbFile_MysqlString !not used!\n",
  "argument[1] = GFF_File location file (one file per line)\n",
  "argument[2] = semicolonSeparatedMatchingStrings\n",
  "argument[3] = regionRadius\n",
  "argument[4] = Picture filename\n",
  "argument[5] = oligo bin dimension [bp]\n"
  if ( @ARGV != 6 );

my ( $gbFileTab, $GFF_File, $semicolonSeparatedMatchingStrings,
    $regionRadius, $pictureFilename )
  = @ARGV;

my $fileDB = fileDB->new();

print
"gbFile_MysqlString = $gbFileTab\nGFF_Files separated by semicolon = $GFF_File\nsemicolonSeparatedMatchingStrings $semicolonSeparatedMatchingStrings\nregionRadius $regionRadius\npicture Filename = $pictureFilename\n";

my @matchingStrings = split( ";", $semicolonSeparatedMatchingStrings );

foreach my $temp (@matchingStrings) {
    print
"./V_SegmentBlot.pl $gbFileTab  $GFF_File $temp $regionRadius EnrichedV_Segment_$temp \n";
}

open( GFF, "<$GFF_File" ) or die "Konnte $GFF_File nicht öffnen!\n";

my ( @GFF_Files, $pathModifier, $V_segment_summaryBlot, $pictureData, @temp );

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
my @fake     = ("mRNA");
my $temp     = 0;
my ( $region, @regions, $gbFile, $gbFeatures );

foreach my $gbFilename ( keys %$fileHash ) {
    next if ( $gbFilename =~ m/BN000872/ );
    print "evaluating $gbFilename\n";
    $gbFile     = gbFile->new($gbFilename);
    $gbFeatures = undef;
    $gbFeatures = $gbFile->SelectMatchingFeatures_by_Tag( \@fake );
    foreach my $gbFeature (@$gbFeatures) {
        $temp = 0;
        foreach my $string (@matchingStrings) {
            $temp = 1 if ( $gbFeature->Name =~ m/$string/i );
        }
        next if ( $temp == 0 );
        my $hash = {
            gbFile     => $gbFilename,
            name       => $gbFeature->Name(),
            complement => $gbFeature->IsComplement()
        };
        if ( defined $hash->{complement} ) {
            $region = $gbFeature->getRegionForDrawing();
            $hash->{start} = @$region[0]->{start} - $regionRadius;
            $hash->{end}   = @$region[0]->{start} + $regionRadius;
            $gbFeature->ChangeRegion_Complement(
                @$region[0]->{start} + $ARGV[3] );
            $hash->{gbFeature} = $gbFeature;
        }
        else {
            $region = $gbFeature->getRegionForDrawing();
            $hash->{start} = @$region[0]->{start} - $regionRadius;
            $hash->{end}   = @$region[0]->{start} + $regionRadius;
            $gbFeature->ChangeRegion_Diff( @$region[0]->{start} - $regionRadius );
            $hash->{gbFeatue} = $gbFeature;
        }
        $regions[ $i++ ] = $hash;
    }
    $pictureData =
      $V_segment_summaryBlot->defineRegions( \@regions,
        "2005-09-08_RZPD1538_MM6_ChIP", $gbFilename );
}
print "Summary over $i different transcription start sites!\n";
$i = 0;
$pictureData->{X_axis} = gbFeature_X_axis->new(0, $regionRadius * 2);
$i = $regionRadius * 2;
my @temp = ( gbFeature->new( "mRNA", "$regionRadius..$i") );
$pictureData->{X_axis}->Add_gbFeatures(\@temp);
$pictureData->{X_axis}->Finalize("mRNA");
#$pictureData =
#  $V_segment_summaryBlot->AddX_axis( $pictureData, 0, $regionRadius * 2 );

print "AddX_axis wurde abgeschlossen!\n";

foreach my $gff (@GFF_Files) {

    print "Using GFF File: $gff\n";
    next if ( $gff =~ m/^#/ );
    $gff = $1 if ( $gff =~ m/^(.+) *#?.*/ );
    $pictureData = $V_segment_summaryBlot->Add2Y_axis(
        $V_segment_summaryBlot->GetY_axisData( $pictureData, "$gff" ),
        0, $regionRadius * 2 , $ARGV[5]
        
    );
}


$V_segment_summaryBlot->Plot($pictureData,$pictureFilename, "", "location of a typical mRNA start", "mean region enrichment","GB_FILE?", 0, $regionRadius * 2);
