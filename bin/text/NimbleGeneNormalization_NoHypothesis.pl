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
use stefans_libs::normlize::normalizeGFFvalues;
use stefans_libs::NimbleGene_config;
use stefans_libs::root;


my $outpath = NimbleGene_config->DataPath();
my $today = root->Today();
$outpath = "$outpath/NewGFFnormalized/$today";
root->CreatePath($outpath);

my $normalizeGFFvalues;

my $organism = "Mus musculus";

#$normalizeGFFvalues = normalizeGFFvalues->new();
#$normalizeGFFvalues->AddDataForHybType("H3Ac","Rag KO proB",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
#$normalizeGFFvalues->Normalize($outpath);

$normalizeGFFvalues = undef;
$normalizeGFFvalues = normalizeGFFvalues->new();
$normalizeGFFvalues->AddDataForHybType("H3K4Me2","Rag KO proB",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
$normalizeGFFvalues->Normalize($outpath);

#$normalizeGFFvalues = undef;
#$normalizeGFFvalues = normalizeGFFvalues->new();
#$normalizeGFFvalues->AddDataForHybType("H3K9Me3","Rag KO proB",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
#$normalizeGFFvalues->Normalize($outpath);


