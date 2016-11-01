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
my ($filename, $delta);
$filename = "BN000872";
$delta = 10000;
my @infos = qw(
1892146	1895465
661605	664399
1729540	1732243
236124	238802
365661	367938
263175	265381
1066374	1068173
806638	808377
298938	300555
1802076	1803663
297018	298508
1975351	1976808
2137985	2139419
19	1426
1607601	1608994
1048688	1050073
2007523	2008899
280491	281706
825424	826612
268651	269830
312365	313526
776248	777389
116176	117303
1088793	1089913
1929599	1930628
1472335	1473350
223744	224752
1312150	1313150
1419375	1420351
503357	504306
157306	158247
1057454	1058385
809154	810041
2263477	2264352
594176	595040
1816930	1817777
227605	228423
1508048	1508839
1524423	1525199
1575785	1576548
1960983	1961721
1797663	1798384
1959961	1960668
258384	259080
1751672	1752350
17779	18445
69362	70025
737924	738576
742323	742932
985133	985686
1304192	1304717
1411285	1411810
213584	214109
181655	182176
1547041	1547552
);
for (my $i = 0; $i < @infos; $i +=2){
	print "$filename,",$infos[$i]-$delta,",",$infos[$i+1]+$delta,",none,none,enrichedIn_proB_notProT_",$infos[$i]-$delta,"-",$infos[$i+1]+$delta,",250\n";
}
