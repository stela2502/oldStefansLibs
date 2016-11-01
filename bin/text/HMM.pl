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
use stefans_libs::statistics::HMM;

my ($HMM, @antibody, $antibody, $celltype, $organism, @designIDs, $designID);

my ( $organism );
$organism = "Mus musculus";

#CalculateHMM("H3Ac","Rag KO proB",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
CalculateHMM("H3K4Me2","Rag KO proB",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
CalculateHMM("H3K9Me3","Rag KO proB",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
CalculateHMM("H3Ac","Rag KO proT",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
CalculateHMM("H3K4Me2","Rag KO proT",$organism, "2005-09-08_RZPD1538_MM6_ChIP");
CalculateHMM("H3K4Me2","DC",$organism, "2005-09-08_RZPD1538_MM6_ChIP");

@antibody = (
      "H3Ac",
      "H3K4Me2", 
      "H3K9Me3"
             );

($celltype,$organism) = (
#                        "H3Ac", 
#                        "H3K4Me2",
#                        "H3K9Me3",
                        "Rag-KO proB IL7",
#                        "Rag-KO proB",
                        "Mus musculus"
                        );

@designIDs = (
        "43",  # das neueste Design
        "44",  # das neue Design auf falschem Genome release
);



sub CalculateHMM{
   my ($antibody,$celltype,$organism, $designID) = @_;
#   $HMM = undef;
#   $HMM = HMM::new("HMM");

#$HMM->MarcowTest();
   	system( "./hmm_execute.pl -antibody \"$antibody\" -celltype \"$celltype\" -organism \"$organism\" -designID \"$designID\" -what \"tstat\" ");
	return 0;
#   $HMM->CalculateHMM({antibody => $antibody, celltype => $celltype, organism => $organism, designID => $designID, what => "tstat" });
}
