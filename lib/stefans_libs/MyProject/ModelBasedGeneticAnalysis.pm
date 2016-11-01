package stefans_libs_MyProject_ModelBasedGeneticAnalysis;

#  Copyright (C) 2011-02-10 Stefan Lang

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
use stefans_libs::MyProject::GeneticAnalysis::Model;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::array_analysis::correlatingData;
use base 'data_table';

=head1 General description

This lib uses the outfiles from 'convert_PHASE_infile_To_Sample_Keys.pl' to models and uses whichever phenotype in the dataset to find the best predictive model.

=cut

sub new {

	my ( $class, $model, $debug ) = @_;
	my ($self);
	my $R = Statistics::R->new();
	if ( defined $model ){
		Carp::confess ( "Sorry the model may only be 'recessive' or 'dominant', not '$model'\n")
			unless ( "recessive dominant" =~ m/$model/ );
	}
	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'sample_lable'    => 0,
			'genotype_number' => 1,
		},
		'gap' => 0,
		'model' => $model,
		'default_value' => [],
		'header'        => [ 'sample_lable', 'genotype_number', ],
		'data'          => [],
		'index'         => {},
		'last_warning'  => '',
		'subsets'       => {},
		'models'        => [],
		'other_models'  => [],
		'chi_square'    => chi_square->new($R),
	};
	bless $self, $class
	  if ( $class eq "stefans_libs_MyProject_ModelBasedGeneticAnalysis" );

	return $self;
}

sub drop {
	my ( $self, $dropp ) = @_;
	my @temp;
	if ( ref($dropp) eq "ARRAY"){
		foreach my $array ( @$self->{'data'} ){
			@temp = spit("",@$array[1]);
			for( my $i= @$dropp - 1; $i >= 0; $i -- ){
				splice ( @temp, $i,1);
			}
			@$array[1] = join("",@temp);
		}
		## And I need to add a warning!
		$self->{'warn'} = '' unless ( defined $self->{'warn'});
		$self->{'warn'} .= "I have dropped the SNPs ".join(",",@$dropp );
	}
}

sub print {
	my ($self) = @_;
	my $str = '';
	$str .= "## ModelBasedGeneticAnalysis ##\n";
	$str .= $self->{'warn'} if ( defined $self->{'warn'});
	$str .= "number of models\t" . scalar( @{ $self->{'models'} } ) . "\n";
	$str .=
	  "Best overall RISK model\n"
	  . @{ $self->{'models'} }[0]
	  ->_print_model( $self->get_best_predictive_model() ) . "\n";
	$str .=
	  "Best overall PROTECTIVE model\n"
	  . @{ $self->{'models'} }[0]
	  ->_print_model( $self->get_best_protective_model() ) . "\n";
	$str .= "## Model Descriptions ##\n\n";
	foreach ( @{ $self->{'models'} } ) {
		$str .= $_->print();
	}
	return $str;
}

sub get_best_predictive_model {
	my ($self) = @_;
	my ( $best, $temp );
	$best = @{ $self->{'models'} }[0]->Max();
	$self->{'best_predictive_model'}  = @{ $self->{'models'} }[0];
	for ( my $i = 1 ; $i < @{ $self->{'models'} } ; $i++ ) {
		$temp = @{ $self->{'models'} }[$i]->Max();
		#print
#"disease: we compare $best->{'mean'} < $temp->{'mean'} && $best->{'n'} < $temp->{'n'}\n";
		if ( $temp->{'mean'} > 1.6 && $best->{'p_value'} > $temp->{'p_value'} )
		{
			$best = $temp;
			$self->{'best_predictive_model'} = @{ $self->{'models'} }[$i];
		}
	}
	return $best;
}

sub get_best_protective_model {
	my ($self) = @_;
	my ( $best, $temp );
	$best = @{ $self->{'models'} }[0]->Min();
	$self->{'best_protective_model'} = @{ $self->{'models'} }[0];
	for ( my $i = 1 ; $i < @{ $self->{'models'} } ; $i++ ) {
		$temp = @{ $self->{'models'} }[$i]->Min();
		#print
#"protective: we compare $best->{'mean'} > $temp->{'mean'} && $best->{'n'} < $temp->{'n'}\n";
		if (   $temp->{'mean'} < 1.4
			&& $best->{'p_value'} > $temp->{'p_value'} )
		{
			$best = $temp;
			$self->{'best_protective_model'} = @{ $self->{'models'} }[$i];
		}
	}

	return $best;
}

=head2 calculate_all_models ( {'SNP_count', 'max_subjects', 'phenotype' } )

This function will calculate the models for all possible SNP combination with exactly 
'SNP_count' SNPs in this dataset. Hence you should not 
use too many SNPs to built up these models.
You will not get anything back. To analyze the models use 
the get_best_predictive_model() 
and get_best_protective_model() functions.

=cut

sub calculate_all_models {
	my ( $self, $hash ) = @_;
	Carp::confess(
		root::get_hashEntries_as_string(
			$self, 3, "Why do we have no data!!! "
		)
	) unless ( ref( @{ $self->{'data'} }[0] ) eq "ARRAY" );
	my $max_SNP_count = scalar( split( "", @{ @{ $self->{'data'} }[0] }[1] ) );
	## now I need to permute the SNPs and create a model for each and every combination
	
	my $a = 0;
	
	for ( my $i = $hash->{'SNP_count'} ; $i > 0 ; $i --  ) {
		$a ++;
		for ( my $start = $i + 1 ; $start + $a < $max_SNP_count - 1 ; $start++ ) {
			$self->__calculate_fixed( $max_SNP_count, [0..$i], $a, $hash );
		}
	}

	return 1;
}

sub __calculate_fixed {
	my ( $self, $max_SNP_count, $fixed, $variable_length, $hash ) = @_;
	my $first_variable = @$fixed[ @$fixed - 1 ] + 1;
	for ( my $i = $first_variable + $self->{'gap'} ; $i + $variable_length < $max_SNP_count ; $i++ ) {
		$hash->{'SNPs'} = [ @$fixed, ($i..($i+$variable_length)) ];
		print ref($self)."::__calculate_fixed (".join(",",@{$hash->{'SNPs'}}).")\n";
		$self->create_model($hash);
	}
	return 1;
}

=head2 create_model ( { 'SNPs', 'max_subjects', 'phenotype' })

This function will creatae a model based on the SNP positions given in SNPs.
It will use the max number of samples 'max_subjects' and the 
readout phenotype 'phenotype'.

You get an object of the type 'stefans_libs_My_Project_GenetcAnalysis_Model' back.

=cut

sub create_model {
	my ( $self, $hash ) = @_;
	my $error = '';
	foreach ( 'SNPs', 'max_subjects', 'phenotype' ) {
		unless ( defined $hash->{$_} ) {
			$error .= "We miss the has key $_\n";
		}
	}
	$error .=
"The 'SNPs' key has to contain a list of positions in the 'genotype_number' string\n"
	  unless ( ref( $hash->{'SNPs'} ) eq "ARRAY" );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my $model =
	  stefans_libs_MyProject_GeneticAnalysis_Model->new( $hash,
		$self->{'chi_square'} );
	my ( @array, $phenotype_column );
	$phenotype_column = $self->Header_Position( $hash->{'phenotype'} );
	unless ( defined $phenotype_column ) {
		Carp::confess(
			"Sorry - the phenotype '$hash->{'phenotype'}' is unknown!\n");
	}
	for ( my $i = 0 ; $i < $hash->{'max_subjects'} ; $i++ ) {
		last unless ( ref( @{ $self->{'data'} }[$i] ) eq "ARRAY" );
		@array = ( split( "", @{ @{ $self->{'data'} }[$i] }[1] ) );
		$model->addKey_value(
			join( "", @array[ @{ $hash->{'SNPs'} } ] ),
			@{ @{ $self->{'data'} }[$i] }[$phenotype_column]
		);
	}
	$model->Finalize();
	push( @{ $self->{'models'} },$model );
	return $model; 
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		print "we add the column '$value'\n" if ( $self->{'debug'} );
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] = $value;
		${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ] =
		  '';
		$self->{'phenotypes'} = []
		  unless ( ref( $self->{'phenotypes'} ) eq "ARRAY" );
		push( @{ $self->{'phenotypes'} }, $value );
	}
	return $self->{'header_position'}->{$value};
}

sub After_Data_read {
	my ($self) = @_;
	Carp::confess("OHOH - we do not have any phenotype in our analysis!")
	  unless ( ref( $self->{'phenotypes'} ) eq "ARRAY" );
	$self->define_subset( 'PHENOTYPES', $self->{'phenotypes'} );
	if ( defined $self->{'model'} ){
		if ( $self->{'model'} eq "recessive"){
			foreach my $array (@{$self->{'data'}}){
				@$array[1] =~ s/[23]/5/g;
			}
		}
		elsif (  $self->{'model'} eq "dominant"){
			foreach my $array (@{$self->{'data'}}){
				@$array[1] =~ s/[12]/4/g;
			}
		}
	}
	return 1;
}

1;
