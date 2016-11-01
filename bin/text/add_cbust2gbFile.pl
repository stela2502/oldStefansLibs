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
use stefans_libs::gbFile;
use Getopt::Long;
use stefans_libs::root;
use stefans_libs::NimbleGene_config;
use stefans_libs::sequence_modification::ClusterBuster;


my ( $gb_File, $cbustExec, $matrixFile, $cbust_attr );
Getopt::Long::GetOptions(
	'-gbFile=s'		=> \$gb_File,
	'-cbust_executable=s' => \$cbustExec,
	'-matrixFile=s' => \$matrixFile,
	'-cbust_atributes=s' => \$cbust_attr 
) or die helpText();

die helpText() unless (defined $gb_File || defined $matrixFile);

sub helpText{
	"help for add_cbust2gbFile.pl
	-gbFile				:path to the used gbFile
	-cbust_executable	:location of the cbust executable
	-matrixFile			:location of the cbust matrix file
	-cbust_atributes	:all cbust atributes (must not contain batch commands! no filtering)
	"	;
}

my ( @cbustOutput, $temp, $gbFile, $today, $tempPath, $clusterBuster);


$gbFile = gbFile->new($gb_File);
$tempPath = NimbleGene_config::TempPath();
$today = root::Today();
$temp = $gbFile->Name();
$clusterBuster = ClusterBuster->new();

$gbFile->WriteAsFasta("$tempPath/temp.fasta", "target for cluster buster ($temp at $today)");

$cbustExec = "cbust" unless (defined $cbustExec);

die "cbust_atributes darf keine bash Steuerzeichen enthalten!!\n" if ( $cbust_attr =~ m/\|/ );

print "DEBUG add_cbust2gbFile.pl: system call:\n\t$cbustExec $cbust_attr $matrixFile $tempPath/temp.fasta > $tempPath/cbust.out\n";

system ( "$cbustExec $cbust_attr $matrixFile $tempPath/temp.fasta > $tempPath/cbust.out");

$clusterBuster->readCbustData("$tempPath/cbust.out");
$clusterBuster->readMatrixFile($matrixFile);
$gbFile->Features($clusterBuster->getAs_gbFeatureArray($cbust_attr, $today));

$temp = join("", split ( " ", $cbust_attr));
my $LOCUS = $gbFile->{header}->HeaderEntry("LOCUS");
$gbFile->{header}->HeaderEntry("LOCUS", "$LOCUS-cbust-$temp-$today");
$gbFile->WriteAsGB($gb_File,undef, undef, "cbust$temp");




