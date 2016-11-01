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
use stefans_libs::V_segment_summaryBlot;


die "argument[0] = gbFile_MysqlString\n","argument[1] = GFF_File location file (one file per line)\n","argument[2] = semicolonSeparatedMatchingStrings\n",
    "argument[3] = regionRadius\nargument[4] = Picture filename\n" if ( @ARGV != 5);

my ( $gbFileTab, $GFF_File, $semicolonSeparatedMatchingStrings, $regionRadius, $pictureFilename) = @ARGV;


print "gbFile_MysqlString = $gbFileTab\nGFF_Files separated by semicolon = $GFF_File\nsemicolonSeparatedMatchingStrings $semicolonSeparatedMatchingStrings\nregionRadius $regionRadius\npicture Filename = $pictureFilename\n";

my @matchingStrings = split (";",$semicolonSeparatedMatchingStrings);

foreach my $temp (@matchingStrings){
   print "./V_SegmentBlot.pl $gbFileTab  $GFF_File $temp $regionRadius EnrichedV_Segment_$temp \n";
}

open (GFF, "<$GFF_File") or die "Konnte $GFF_File nicht öffnen!\n";

my (@GFF_Files, $pathModifier, $V_segment_summaryBlot);

while (<GFF>){
  next if ( $_ =~ m/^#/);
  print $_;
  push (@GFF_Files, $1 ) if ( $_ =~ m/^([\/\w].*)$/);
}

if ( $GFF_Files[0] =~ m/PATH_MODIFIER=([\w\d]*)/){
   $pathModifier = $1;
   shift @GFF_Files;
   print "Path Modifier = $pathModifier\n";
}

$V_segment_summaryBlot = V_segment_summaryBlot->new($pathModifier);


foreach $GFF_File (@GFF_Files){
#   print "Using GFF File: $GFF_File\n";
   $V_segment_summaryBlot->AddData($gbFileTab, $GFF_File, \@matchingStrings,  $regionRadius);
}

$V_segment_summaryBlot->Plot($pictureFilename);
