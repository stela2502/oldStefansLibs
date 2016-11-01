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
use stefans_libs::sequence_modification::blastResult;

my ( $blastResult, $infile, $minLength, $minPercIdent, $maxGapOpen, $DoIMGTsearch);

$infile = $ARGV[0];
$minLength = 1000;
$minPercIdent = 90;
$maxGapOpen = 5;
$DoIMGTsearch = "AllBlastHits";

$blastResult = blastResult->new();

$blastResult->readBlastResults( $infile, $minLength, $minPercIdent, $maxGapOpen, $DoIMGTsearch );

$blastResult -> printNew_ResultFile ( "$infile.selected" );

print "selected blast Hits writen to $infile.selected \n";
