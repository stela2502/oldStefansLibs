package template4deepEvaluation;
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
use warnings;

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "template4deepEvaluation" );

  	return $self;

}


sub deepAnalysis{
	my ( $self, $rsID ) = @_;
	
	my ($snpStore, $key, $temp);
	my @affectedGenes = my $correlatingSNPs_dbInterface -> selectGenes_correlatingWithSNP( $rsID );
	
	my $geneClusters_obj = selectGeneClusters ( my $affyArrayType, \@affectedGenes );
	
	foreach my $sign_geneCluster ( $geneClusters_obj -> selectSignificantClusters() ){
		## now we should get a list of genes in the same cluster
		$snpStore = {};
		my $geneList = $sign_geneCluster->getGeneList();
		## possibly the expression of these genes is affected by other SNPs?
		## OK - that is almoast impossible to calculate (!) but it may be interesting!!
		## !!!!! here we need another object that handles a DB connection to the resulting gene lists !!!!!
		foreach my $gene ( $geneList->getGeneNames() ){
			my  @possibleCausativeSNPs_actual =  my $correlatingSNPs_dbInterface -> selectSNPs_correlatingWithGene ( $gene );
			## we have to check if the difference in expression is a combination of these SNPs
			## ATTENTION: we have to include a systems biology thing here: ( MINDMAP )
			## or do we look for a statistical aproach? A Logistic Regression??
			foreach $key ( @possibleCausativeSNPs_actual ){
				$snpStore->{$key} = [] unless ( defined $snpStore->{$key} );
				push (@{$snpStore->{$key}}, $gene);
				
				
			}
			
			## if any SNP is affecting the expression of the whole List (or at least 2 genes in the list) - something very interesting is happening!
			foreach $key ( keys %$snpStore ){
				$self->add2Report( "SNP affecting gene list",$key, $snpStore->{$key}, $geneList ) if ( @{$snpStore->{$key}} > 0 );
			}
		}
	}
}

1;
