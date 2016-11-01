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

use stefans_libs::database::nucleotide_array::oligo2dnaDB;
my ( $oligo2dnaDB );

$oligo2dnaDB = oligo2dnaDB->new();
#$oligo2dnaDB->IdentifyMultiHitOligos("2005-09-08_RZPD1538_MM6_ChIP");
$oligo2dnaDB->IdentifyMultiHitOligos("2005-07-19_RZPD1538_MM5_ChIP");

