#!/usr/bin/perl
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
use stefans_libs::binaryEvaluation::VbinaryEvauation;

my ($binaryEvaluation, @line);

$binaryEvaluation = VbinaryEvauation->new();

my ( $listOfHMM_files, $listOfGBfiles, $OUtfile ) = @ARGV;


open (IN_HMM, "<$listOfHMM_files") or die root->FileOpenError($listOfHMM_files);

while ( <IN_HMM>){
	next if ($_ =~ m/^#/);
	chomp $_;
	@line = split(" ",$_);
	$binaryEvaluation->Add_HMM_File($line[0]);
}

close ( IN_HMM );

open ( IN_GB ,"<$listOfGBfiles" ) or die root->FileOpenError($listOfGBfiles);

while ( <IN_GB>){
    next if ($_ =~ m/^#/);
    chomp $_;
    @line = split(" ",$_);
	$binaryEvaluation->Add_gbFile($line[0]);
}

close ( IN_GB );

$binaryEvaluation->Evaluate();
$binaryEvaluation->printTable($OUtfile );

