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

use stefans_libs::statistics::MAplot;

my $MAplot;

#quantilNormalize("INPUT","Rag KO proB","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("H3K4Me2","Rag KO proB","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("H3K9Me3","Rag KO proB","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("H3Ac","Rag KO proB","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("H3Ac","Rag KO proB IL7","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("RNApol_II","Rag KO proB IL7","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("H4Ac","Rag KO proB IL7","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");
#quantilNormalize("INPUT","Rag KO proB IL7","Mus musculus","2005-07-19_RZPD1538_MM5_ChIP");

#quantilNormalize("H3K4Me2","Rag KO proB","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");
#quantilNormalize("H3K9Me3","Rag KO proB","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");
#quantilNormalize("H3Ac","Rag KO proB","Mus musculus", "2005-09-08_RZPD1538_MM6_ChIP");
#quantilNormalize("INPUT","Rag KO proT","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");
#quantilNormalize("H3K4Me2","Rag KO proT","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");
quantilNormalize("H3Ac","Rag KO proT","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");
#quantilNormalize("INPUT","DC","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");
#quantilNormalize("H3K4Me2","DC","Mus musculus","2005-09-08_RZPD1538_MM6_ChIP");




sub quantilNormalize{
    my ( $ab, $ce, $or, $de ) = @_;
    $MAplot = MAplot::new("MAplot");
    print "$ab, $ce, $or, $de\n";
    $MAplot->AddData($ab, $ce, $or, $de);
    $MAplot->QuantileNormalisation();
    $MAplot->NormalisationToDB();

    $MAplot = undef;
}
