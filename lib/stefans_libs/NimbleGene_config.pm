package NimbleGene_config;
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

sub new {
	my ($class) = @_;

	my ($self);
	$self = { database => "NimbleGene_Test" };

	bless( $self, $class ) if ( $class eq "NimbleGene_config" );
	return $self;
}

sub GetOpenFontPath {

	return
"~/IgH_Locus/Libs_new_structure/fonts/LinLibertineFont/LinLibertine_Bd-2.3.2.ttf";
}

sub D0 {
	## return the max length of a gap in the HMM line && the minimum region length to be marked as enriched
	return 500;
}

sub CutoffValue {
	## the cutoff value that each oligo in a enriched region has to overcome
	## commonly this feature is used after HMM calculation so the oligoValue is
	## the probabillity to be part of a enriched region

	return 0.99;
}

sub ProbabillityEstimatingArray {
	my $hash = {
		antibody => "H3K4Me2",
		celltype => "Rag KO proB",
		organism => "Mus musculus",
		designID => "2005-09-08_RZPD1538_MM6_ChIP",
		what     => "TStat"
	};
	return $hash;
}

sub DesignID {
	return "2005-09-08_RZPD1538_MM6_ChIP";
}

sub CategorySteps {
	## here you can define how many different categories should be used
	## for the probability functions in the HMM evaluation
	return 100;
}

sub TempPath {
	warn "NimbleGene_config TempPath $!\n" if ( mkdir("/Mass/temp/") == 0 );
	return "/Users/stefanlang/ArrayData/temp";

	#return "/Mass/temp";
}

sub DataPath {
	#my $dataPath = "/Mass/ArrayData/Evaluation";
	my $dataPath = "/Users/stefanlang/ArrayData";
	return $dataPath;
}

sub isTheSameCelltype {
	my ( $celltype1, $celltype2 ) = @_;
	my (@cellTypedefinition);
	## test, of both celltypes against the celltype order!
	return NimbleGene_config::_getCelltypePosition($celltype1) ==
	  NimbleGene_config::_getCelltypePosition($celltype2);
}

sub _getCelltypePosition {
	my ($celltype) = @_;
	my @array = NimbleGene_config::GetCelltypeOrder();

	for ( my $i = 0 ; $i < @array ; $i++ ) {
		if ( defined $array[$i]->{notMatch} ) {
			next if ( lc($celltype) =~ m/$array[$i]->{notMatch}/ );
		}
		return $i if ( lc($celltype) =~ m/$array[$i]->{matchingString}/ );
	}
}

sub GetCelltypeOrder {
	return (

		#{ matchingString => "", plotString => "" },
		{
			matchingString => "prob\$",
			plotString     => "proB cells",
			notMatch       => "il7"
		},
		{ matchingString => "prot",     plotString => "proT cells" },
		{ matchingString => "dc",       plotString => "dendritic cells" },
		{ matchingString => "prob il7", plotString => "proB cells (IL7)" },
		{ matchingString => "preb il7", plotString => "preB cells (IL7)" },
		{
			matchingString => "pro/preb",
			plotString     => "pro vs preB cells (IL7)"
		},
		{ matchingString => "preb" ,    plotString => "preB/proB (TET + IL7)" }
	);
}

sub GetAntibodyOrder {
	return (
		{ matchingString => "h3ac",    plotString => "H3Ac" },
		{ matchingString => "h3k4me2", plotString => "H3K4Me2" },
		{ matchingString => "h3k9me3", plotString => "H3K9Me3" }
	);

}

1;
