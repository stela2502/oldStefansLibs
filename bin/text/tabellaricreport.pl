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
use stefans_libs::V_segment_summaryBlot::List4enrichedRegions;
use stefans_libs::database::nucleotide_array::nimbleGeneArrays::nimbleGeneFiles::gffFile;
use stefans_libs::gbFile;
use Getopt::Long;
use stefans_libs::database_old::fileDB;

my ($listFile, $gbFile, $matchingFeatures, $gbFileObj, $features, @matchingFeatures, 
	$tableFile, $gbFile_MySQL_entry, $hmmReportEntry, $headerWritten);

Getopt::Long::GetOptions(
    'hmmFileList=s' => \$listFile,
    'gbFileString=s' => \$gbFile,
    'matchingFeatures=s' => \$matchingFeatures,
    'output=s' => \$tableFile
   ) or die HelpString();

die "Sorry - you forgot -hmmFileList\n", HelpString() unless (defined $listFile );
die "Sorry - you forgaot -gbFileString", HelpString() unless (defined $gbFile);
die "Sorry - you forgaot -matchingFeatures", HelpString() unless (defined $matchingFeatures);

$tableFile = "output.csv" unless ( defined $tableFile);
$tableFile = "$tableFile.csv" unless ($tableFile =~ m/.csv$/ );

my $list = List4enrichedRegions->new();
my $gffFile = gffFile->new();

open( HMM_File, "<$listFile")
	or die "regionXY_plot could not open hmm location file\n";

# import the HMM infos

while ( <HMM_File>) {
	next if ( $_ =~ m/^#/ );
	chomp $_;
	print "Add HMM data for file $_\n";
	$list->AddData($gffFile->getEnrichedRegions($_) );
}
close (HMM_File);

## open the gbFile
($gbFileObj, $gbFile_MySQL_entry) = GetGBFileObject($gbFile);
## get the feature ref
$features = $gbFileObj->Features();
@matchingFeatures = split ( ";", $matchingFeatures);

open (OUT, ">$tableFile") or die "could not create $tableFile\n";

foreach my $gbFeature ( @$features){
	## Do some magic!
	## we can evaluate whatever we want here
	## CAUTION the whole length of the feature is used
	$hmmReportEntry = $list->isEnriched($gbFile_MySQL_entry, $gbFeature);
	print OUT $hmmReportEntry->getTableHeaderLine() unless ( $headerWritten);
	$headerWritten = 1 == 1;
	print OUT $hmmReportEntry->getAsTableLine();
}
close (OUT);

print "Results were written to '$tableFile'\n";

#print "\$list->{enrichedRegions} = ",$list->{enrichedRegions},"\n";
#root::print_hashEntries($list, 5 );



sub HelpString{
	return
	"tabellaricreport.pl command line paramenters\n",
	"\t-hmmFileList      :list file containing the used HMM data Files one per line\n",
	"\t-gbFileString     :the gbFile identification string\n",
	"\t-matchingFeatures :a list of gbFeatures separarated by ';'\n";
}

sub GetGBFileObject {
    my ( $fileString, $designString ) = @_;
    my ( $fileRef, $fileNameHash, $gbFile, $fileDB );
	
	$fileDB = fileDB->new;
	$designString = NimbleGene_config::DesignID() unless (defined  $designString);
	
    $fileRef      = root->getPureSequenceName($fileString);
    $fileNameHash = $fileDB->SelectFiles_ByDesignId($designString);

    foreach my $temp ( keys %$fileNameHash ) {
        if ( $temp =~ m/$fileRef->{MySQL_entry}/ ) {
			return gbFile->new($temp), $fileRef->{MySQL_entry};
        }
    }
    return undef;
}
