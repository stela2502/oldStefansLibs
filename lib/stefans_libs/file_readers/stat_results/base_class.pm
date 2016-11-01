package stefans_libs_file_readers_stat_results_base_class;

#  Copyright (C) 2010-11-22 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::plot::simpleWhiskerPlot;
use stefans_libs::plot::simpleBarGraph;
use stefans_libs::database::pathways::kegg::kegg_genes;
use stefans_libs::database::genomeDB::gene_description;

use base 'data_table';
=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::file_readers::stat_results::base_class

=head1 DESCRIPTION

The base class for all stat results.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::file_readers::stat_results::base_class.

=cut

sub new {

	my ($class, $debug) = @_;

	my ($self);

	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {},
		'default_value'   => [],
		'header'          => [],
		'data'            => [],
		'index'           => {},
		'last_warning'    => '',
		'subsets'         => {}
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_file_readers_stat_results_base_class" );
	return $self;

}


sub GeneNames{
	my ( $self) = @_;
	my @return;
	my $gene_position = $self->Header_Position( 'Gene Symbol' );
	my $probeset_position = $self->Header_Position( 'Probe Set ID' );
	for ( my $i = 0; $i < @{$self->{'data'}}; $i++){
		$return[$i] = @{@{$self->{'data'}}[$i]}[$gene_position];
		$return[$i] = @{@{$self->{'data'}}[$i]}[$probeset_position] unless ($return[$i] =~ m/\w/ );
	}
	#print $self->AsString();
	#Carp::confess ( "we return the gene names:".join("; ",@return)."\n");
	return \@return;
}

=head2 Add_KEGG_Pathway_for_settings ( {
	'LaTeX_obj' => $results_sec, 
	'exclusion_lists' => { <interesting state> => { <gene_symbol> => 1 } },
	'outpath' =>  <path>
})

This function will hopefully do a lot of things:
1. it calls stefans_libs::database::pathways::kegg::kegg_genes->add_LaTeX_section_for_Gene_List
for each gene in the correlation result.
2. it selects only these genes, that are not mentioned in the 'exclusion_lists' hashes and adds a LaTeX section for each of these lists.
and 3. it will return the summary tables from the add_LaTeX_section_for_Gene_List calls in an hash { 'all' => SummaryTable(All Genes), <interesting state> => SummaryTable(All genes that do NOT match the gene lists) }

=cut

sub Add_KEGG_Pathway_for_settings {
	my ( $self, $hash ) = @_;
	my $error = '';
	$error .=
	    ref($self)
	  . "::Add_KEGG_Pathway_for_settings - 'LaTeX_obj has to be a 'stefans_libs::Latex_Document::Section', not a '"
	  . ref( $hash->{'LaTeX_obj'} )
	  . !"'\n"
	  unless (
		ref( $hash->{'LaTeX_obj'} ) eq
		"stefans_libs::Latex_Document::Section" );
	$error .=
	  ref($self)
	  . "::Add_KEGG_Pathway_for_settings - 'outpath' is not defined!\n"
	  unless ( defined $hash->{'outpath'} );
	$error .=
	  ref($self)
	  . "::Add_KEGG_Pathway_for_settings - 'kegg_reference_geneset' is not defined!\n"
	  unless ( defined $hash->{'kegg_reference_geneset'} );
	$hash->{'exclusion_lists'} = {}
	  unless ( ref( $hash->{'exclusion_lists'} ) eq "HASH" );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my ( $kegg_genes, $results, $temp_table );
	mkdir( $hash->{'outpath'} ) unless ( -d $hash->{'outpath'} );
	unless ( defined $self->{'kegg_genes'} ){
		$self->{'kegg_genes'} = $kegg_genes = kegg_genes->new( root->getDBH() );
	}
	else {
		$kegg_genes = $self->{'kegg_genes'};
	}
	## Now I am going to create a KEGG result for all genes,
	#Carp::confess (  root::get_hashEntries_as_string ( $self->getAsHash ( 'Probe Set ID', 'Gene Symbol') , 3 , "Is that a hash 'Probe Set ID' -> 'Gene Symbol'?"  ));
	$results->{'all'} = $kegg_genes->add_LaTeX_section_for_Gene_List(
		{
			'LaTeX_document' => $hash->{'LaTeX_document'},
			'genes'                  => $self->getAsArray('Gene Symbol'),
			'Probe Set ID' => $self->getAsHash ( 'Probe Set ID', 'Gene Symbol'),
			'kegg_reference_geneset' => $hash->{'kegg_reference_geneset'},
			'only_significant'       => 1,
			'LaTeX_object' => $hash->{'LaTeX_obj'}->Section('All correlations'),
			'temp_path'    => $hash->{'outpath'} . "/all_results",
			'phenotype' => 'all'
		}
	);
	$results->{'summary_table'} = $kegg_genes->{'summary_table'};
	#print "we have added a KEGG ALL section for the genes:\n" .join(", ", sort ( @{$self->getAsArray('Gene Symbol')}) )."\n";
	foreach my $setting ( keys %{ $hash->{'exclusion_lists'} } ) {
		$temp_table = $self->select_where(
			'Gene Symbol',
			sub {
				return 0
				  if ( $hash->{'exclusion_lists'}->{$setting}->{ $_[0] } );
				return 1;
			}
		);
		#print "$setting - we have the genes ".join(",",@{$temp_table->getAsArray('Gene Symbol')})."\n";
		
		$results->{$setting} = $kegg_genes->add_LaTeX_section_for_Gene_List(
			{	
				'LaTeX_document' => $hash->{'LaTeX_document'},
				'genes'                  => $temp_table->getAsArray('Gene Symbol'),
				'kegg_reference_geneset' => $hash->{'kegg_reference_geneset'},
				'only_significant'       => 1,
				'LaTeX_object' =>
				  $hash->{'LaTeX_obj'}->Section( "Selected genes " . $setting ),
				'temp_path' => $hash->{'outpath'} . "/".join("_",split(/\s/,$setting)),
				'phenotype' => $hash->{'LaTeX_obj'}->Title()
			}
		);
		#print "we have added a KEGG $setting section for the genes:\n" .join(", ", sort ( @{$temp_table->getAsArray('Gene Symbol')}) )."\n";
		
	}
	$results -> { 'genes_to_be_described' } = $kegg_genes -> {'genes_to_be_described'};
	return $results;
}

sub get_down_and_upregulated_genes {
	my ( $self ) = @_;
	my ( $genes_not_expressed_in_celltype, $genes_expressed_in_celltype, $temp);
	if ( ref($self) =~ m/Spearman/ ) {
			$temp = $self->getAsHash( 'Gene Symbol', 'rho' );
			foreach ( keys %$temp ) {
				$genes_not_expressed_in_celltype->{$_} = 1
				  if ( $temp->{$_} < 0 );
				$genes_expressed_in_celltype->{$_} = 1 if ( $temp->{$_} > 0 );
				Carp::confess "Sorry, but \$temp->{$_} is 0!\n" if ($temp->{$_} == 0 );
			}
		}
		elsif ( ref($self) =~ m/Wilcoxon/ ) {
			$temp = $self->getAsHash( 'Gene Symbol', 'fold change' );
			foreach ( keys %$temp ) {
				$genes_not_expressed_in_celltype->{$_} = 1
				  if ( $temp->{$_} < 1 );
				$genes_expressed_in_celltype->{$_} = 1 if ( $temp->{$_} > 1 );
				warn "Sorry, but \$temp->{$_} is 0!\n" if ($temp->{$_} == 1 );
			}
		}
		else { 
			warn "Sorry, but I can not get the get_down_and_upregulated_genes from a ".ref($self)." \n";
			return undef;
		}
		return ( $genes_not_expressed_in_celltype, $genes_expressed_in_celltype );
}

1;
