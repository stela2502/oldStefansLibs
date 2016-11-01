package expression_net;

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
use stefans_libs::database::variable_table;
use stefans_libs::database::scientistTable;
use stefans_libs::database::experiment;
use stefans_libs::database::expression_estimate::expr_est_list;
use stefans_libs::database::expression_net::expression_net_data;
use base "variable_table";

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!"
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

	bless $self, $class if ( $class eq "expression_net" );
	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {
	return 'dbh';
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "expression_net";
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'experiment_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the experiment table',
			'data_handler' => 'experimentTable',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'scientist_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the scientists table',
			'data_handler' => 'scientist_table',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'access_right',
			'type'        => 'VARCHAR (10)',
			'NULL'        => '0',
			'description' => 'the acces right all, group, scientist ',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'expr_est_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => 'the link to the expression lists',
			'data_handler' => 'expr_est_list',
			'needed'       => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'p_value_cutoff',
			'type' => 'FLOAT',
			'NULL' => '0',
			'description' =>
'only correlations with a p value equal or less than this value are stored',
			'needed' => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'table_baseString',
			'type'        => 'VARCHAR (100)',
			'NULL'        => '0',
			'description' => 'the table name, where the actual data is stored',
			'needed'      => ''
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['expr_est_list_id'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = []
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	$self->{'data_handler'}->{'experimentTable'} =
	  experiment->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'scientist_table'} =
	  scientistTable->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'expr_est_list'} =
	  expr_est_list->new( $self->{'dbh'}, $self->{'debug'} );

	return $dataset;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	unless ( defined $dataset->{'p_value_cutoff'} ) {
		$dataset->{'p_value_cutoff'} = 0.05;
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

=header 2

GetInterfaces ( $my_id )

The function returns two interfaces! The first interface is a interface to the expression_net data,
the second interface is a interface to the expression_estimates that were used to create the data.

=cut

sub GetInterfaces {
	my ( $self, $id ) = @_;
	my $data = $self->getArray_of_Array_for_search({
 	'search_columns' => [ref($self).".table_baseString", ref($self).".expr_est_list_id"],
 	'where' => [[ref($self).".id", '=', 'my_value']]
	},$id);
	unless ( ref( @$data[0]) eq "ARRAY"){
		warn "we do not have any data for your request - please use ".ref($self)."::AddDataset to create the internal entries!\n";
		return undef;
	}
	my $myDataInterface = expression_net_data->new($self->{'dbh'}, $self->{'debug'});
	$myDataInterface->TableName (@{@$data[0]}[0] );
	my $expreesion_Data =  $self->{'data_handler'}->{'expr_est_list'}->GetExpressionInterface_4_ListID(@{@$data[0]}[1]);
	return $myDataInterface, $expreesion_Data;
}

sub Get_Correlation_4_genes_and_listID {
	my ( $self, $my_id, $geneList, $listID, $cutoff ) = @_;
	unless ( defined $listID ) {
		Carp::confess(
			ref($self)
			  . "::Get_Correlation_4_genes_and_listID - sorry, but I can not get you the dataset if you do not provide a listID(ARG[1])\n"
		);
	}
	unless ( ref($geneList) eq "ARRAY" ) {
		warn ref($self)
		  . "::Get_Correlation_4_genes_and_listID - That is a joke! we definitely need an array of gene names to work on this list - otherwise we woiuld return way too much data - belive me!\n";
		return undef;
	}
	if ( ref($listID) eq "ARRAY" ) {
		## OK we got an array of expression_est_ids and not the list id - but we can handle that!
		$listID =
		  $self->{'data_handler'}->{'expr_est_list_id'}
		  ->AddDataset( { 'others_id' => $listID } );
	}
	$cutoff = 0.05 unless ( defined $cutoff );
	$cutoff = 0.05 if ( $cutoff > 0.05 || $cutoff <= 0 );
	
	my ( $exp_net_interface, $exp_estimates_interface ) =
	 $self->GetInterfaces ( $my_id );
	 
	my ( $return, $oneGene, $THE_gene, $ALL_genes, $ref, $p, $r );
	foreach my $gene (@$geneList) {
		## first we look for that data in the database
		$oneGene = $exp_net_interface->getArray_of_Array_for_search(
			{
				'search_columns' => [ ref($exp_net_interface).'.gene_name_2', ref($exp_net_interface).'.p_value', ref($exp_net_interface).'.r_square' ],
				'where'          => [ [ref($exp_net_interface).'.gene_name_1', '=', 'my_value'] ],
			}, $gene
		);
		unless ( scalar( @$oneGene ) > 0 ){
			$self->{'statistics'} = spearman_test->new() unless ( ref($self->{'statistics'}) eq "spearman_test");
			## the data is not in the database! We have to create it!
			## 1. get the expression values for the \$gene
			$THE_gene = $exp_estimates_interface->getExpression_values_4_gene( $gene );
			$ALL_genes = $exp_estimates_interface->getExpression_values_4_ALL_genes ( );
			$ref = $THE_gene->get_expression_4_gene( $gene );
			for ( my $id = 0; $id < $ALL_genes->max_id(); $id++){
				( $p, $r ) = $self->{'statistics'} -> calculate_spearmanWeightFit_statistics ($ref, $ALL_genes->get_expression_4_id( $id) );
				if ( $p <= $cutoff){
					$exp_net_interface->AddDataset( { 'gene_name_1' => $gene, 'gene_name_2' => $ALL_genes->Gene_Symbol_4_id( $id), 'p_value' => $p, 'r_square' =>  $r} );
					push ( @$oneGene, [$ALL_genes->Gene_Symbol_4_id( $id), $p ,$r ] );
				}
			}
		}
		$return -> {$gene} = $oneGene;
	}
}

package spearman_test;

use strict;
use warnings;
use stefans_libs::array_analysis::correlatingData::stat_test;
use base ( 'stat_test');

sub new {

	my ($class, $R) = @_;

	my ($self);
	
	unless ( defined $R){
		$R = Statistics::R->new();
	}

	$self = {
		R             => $R,
		statTest      => 0,
		sinceReinit   => 0
	};

	$self->{R}->startR() unless ( $self->{R}->is_started() );
	die "$self could not activate the R interface\n"
	  unless ( $self->{R}->is_started() );

	bless $self, $class if ( $class eq "spearman_test" );
	return $self;
}

sub calculate_spearmanWeightFit_statistics {
	my ( $self, $referenceData, $actualData ) = @_;

	unless ( defined $referenceData ){
		#warn "we have no refernece data!\n";
		return "p value\trho" ;
	}
	
	$self->forceRunningR();
	
	my $cmd = 
		"x<- c(".
		join( ',', @$referenceData ).
		")\ny<-c(".
		join( ',', @$actualData ).
		")\nres <- cor.test( x,y,method='spearman')\n".
		"print ( res )";
		
	##print "R command:\n$cmd\n";
	$self->{'last_cmd'} = $cmd;
	$self->{R}->send($cmd);
	
	unless ( $self->{R}->is_started() ){
		$self->forceRunningR();
		$self->{R}->send($cmd);
	}
	
	my $return = $self->{R}->read();
	$self->{lastR} = $return;
	my @return = split( "\n", $return );
	$return = join( " ", @return );
	my $p   = $1 if ( $return =~ m/p-value [=<] (\d?\.?\d+e?-?\d*)/ );
	my $rho = $1 if ( $return =~ m/rho *(-?[\d\.]+) *$/ );
	$self->{lastP} = $p;
	#print "Spreaman result(NEW): $return \n";# unless  ( defined $p );
	#print "p: $p\tspearman: $s\trho: $rho\n";
	#die;
	return $p, $rho;
}

1;
