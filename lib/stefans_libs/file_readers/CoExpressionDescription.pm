package stefans_libs::file_readers::CoExpressionDescription;

#  Copyright (C) 2010-11-04 Stefan Lang

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

use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::file_readers::CoExpressionDescription::KEGG_results;
use base 'data_table';

=head1 General description

This package is able to read and write a short summary over some coexpression results. This package is meant to be used to compare different co-expression datasets.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'r_cutoff'           => 0,
			'gene list type'     => 1,
			'phenotype list'     => 2,
			'phenotype count'    => 3,
			'KEGG results table' => 4,
		},
		'default_value' => [],
		'header'        => [
			'r_cutoff',
			'gene list type',
			'phenotype list',
			'phenotype count',
			'KEGG results table',
		],
		'data'         => [],
		'index'        => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class
	  if ( $class eq "stefans_libs::file_readers::CoExpressionDescription" );

	return $self;
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		Carp::confess(
			    "You try to change the table structure - That is not allowed!\n"
			  . "If you really want to change the data please use "
			  . "the original data_table class to modify the table structure!\n"
		);
	}
	return $self->{'header_position'}->{$value};
}

=head2 Link_in_KEGG_results

This function will read in all KEGG result tables and die if any of the KEGG tables could not be read

=cut

sub Link_in_KEGG_results {
	my ($self) = @_;
	$self->{'Kegg_Files'} = [];
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		my $KEGG_file =
		  stefans_libs::file_readers::CoExpressionDescription::KEGG_results
		  ->new();
		$KEGG_file->read_file( @{ @{ $self->{'data'} }[$i] }[4] );
		@{ $self->{'Kegg_Files'} }[$i] = $KEGG_file;
	}
	return 1;
}

=head get_interesting_Pathways

You can get the pathways that are overrepresented in at least one of the conditions we have information for.
You will get the pathways names as array of values.

=cut

sub get_interesting_Pathways {
	my ( $self, $tag ) = @_;
	$self->createIndex('gene list type');
	$self->Link_in_KEGG_results()
	  unless ( ref( $self->{'Kegg_Files'} ) eq "ARRAY" );
	Carp::confess(
		"tag '$tag' was not found in the dataset - we only support the tags "
		  . join( "; ", keys %{ $self->{'index'}->{'gene list type'} } ) )
	  unless ( ref( $self->{'index'}->{'gene list type'}->{$tag} ) eq "ARRAY" );
	my $return = {};
	foreach my $i ( @{ $self->{'index'}->{'gene list type'}->{$tag} } ) {
		Carp::confess("We could not read the file for data line $i\n")
		  unless ( defined @{ $self->{'Kegg_Files'} }[$i] );
		warn $self->get_line_asHash($i)->{'KEGG results table'} . "\n";
		foreach (
			@{ @{ $self->{'Kegg_Files'} }[$i]->get_significant_pathway_names() }
		  )
		{
			$return->{$_} = 1;
		}
	}
	return ( ( keys %$return ) );
}

sub plot_p_value_changes_for_these_pathways {
	my ( $self, $pathway_nams, $outpath ) = @_;
	$self->createIndex('gene list type');
	my ( $pathway_name, $pathway_hash, $temp_table, $phenotype_names,
		$data_hash, $dataset, $data_columns, @figures );
	foreach (@$pathway_nams) {
		$pathway_hash->{$_} = 1;
	}
	my $latex_figure_string = '';
	my $i                   = 0;
	$data_columns = [];
	my ($figures,@figure);
	foreach my $state ( sort keys %{ $self->{'index'}->{'gene list type'} } ) {
		$figures->{$state} = {};
		## I need to get the KEGG dataset from @{$self->{'Kegg_Files'}}
		## foreach line I find in the array $self->{'index'}->{'gene list type'}->{$state}
		## I want to built a table from this information, that contains the probeset_name,
		## the r_square cut off and then for each combination of the two first the 'hypergeometric p value'
		## from the KEGG file. The r_square I have stired, the 'pathway_name' and 'hypergeometric p value'
		## are part of the KEGG file. $state is either connection_group_genes.txt or genes.txt
		## and finally I need to implement to craete a plot from withing the data_table objects.
		## A kind of plot_as_XY { 'picture_name_columns', 'x_data_row', 'x_lable_column', 'y_data', 'y_lable_column' } function
		my $data_table_p = data_table->new();    ## p_values
		my $data_table_n = data_table->new();    ## number of genes
		my $data_table_g = data_table->new();    ## gene names
		foreach ( 'pathway_name', 'r_cutoff' ) {
			$data_table_p->Add_2_Header($_);
			$data_table_n->Add_2_Header($_);
			$data_table_g->Add_2_Header($_);
		}
		$data_table_p->createIndex('pathway_name');
		$data_table_n->createIndex('pathway_name');
		$data_table_g->createIndex('pathway_name');

		$i++;
		foreach
		  my $line_id ( @{ $self->{'index'}->{'gene list type'}->{$state} } )
		{

			$dataset->{'r_cutoff'} = @{ @{ $self->{'data'} }[$line_id] }[0];
			$phenotype_names = @{ @{ $self->{'data'} }[$line_id] }[2];
			push( @$data_columns, $phenotype_names ) if ( $i == 1 );
			## Now I want to get all the datasets for the columns 'matched genes', 'pathway_name' and 'Gene Symbols'
			## but only from those pathways, that I found to be interesting!
			$temp_table =
			  @{ $self->{'Kegg_Files'} }[$line_id]
			  ->select_where( 'pathway_name',
				sub { return 1 if ( $pathway_hash->{ $_[0] } ) } );
			## Now I need to process the data types!
			## 1. the p_values
			$data_hash = $temp_table->getAsHash( 'pathway_name',
				'hypergeometric p value' );
			foreach ( sort keys %$pathway_hash ) {
				$dataset->{'pathway_name'} = $_;
				$data_hash->{$_} = 1 unless ( defined $data_hash->{$_} );
				$data_hash->{$_} = 1 if ( $data_hash->{$_} <= 0 );
				$dataset->{$phenotype_names} = -&log10( $data_hash->{$_} );
				$data_table_p->Add_2_Header($phenotype_names);
				$data_table_p->AddDataset($dataset);
				delete( $dataset->{$phenotype_names} );
				$figures->{$state}->{$_} = {};
			}
			$data_hash =
			  $temp_table->getAsHash( 'pathway_name', 'matched genes' );
			foreach ( sort keys %$pathway_hash ) {
				$dataset->{'pathway_name'} = $_;
				$data_hash->{$_} = 0 unless ( defined $data_hash->{$_} );
				$dataset->{$phenotype_names} = $data_hash->{$_};
				$data_table_n->Add_2_Header($phenotype_names);
				$data_table_n->AddDataset($dataset);
				delete( $dataset->{$phenotype_names} );
			}
			$data_hash =
			  $temp_table->getAsHash( 'pathway_name', 'Gene Symbols' );
			foreach ( sort keys %$pathway_hash ) {
				$dataset->{'pathway_name'} = $_;
				$data_hash->{$_} = 'none' unless ( defined $data_hash->{$_} );
				$dataset->{$phenotype_names} = $data_hash->{$_};
				$data_table_g->Add_2_Header($phenotype_names);
				$data_table_g->AddDataset($dataset);
				delete( $dataset->{$phenotype_names} );
			}

		}
		## now I have added all the different data columns for one state - I should plot the info at least for the p_values!
		## but first and easiest - print the data_files!
		$data_table_g->write_file( $outpath
			  . "/Gene_Symbols_in_sign_pathways_"
			  . join( "_", split( " ", $state ) ) );
		$data_table_p->write_file( $outpath
			  . "/P_values_in_sign_pathways_"
			  . join( "_", split( " ", $state ) ) );
		$data_table_n->write_file( $outpath
			  . "/Number_of_Genes_in_sign_pathways_"
			  . join( "_", split( " ", $state ) ) );
		## and now we could try to plot the data...
		print "we try to craete a plot for these data columns:\n"
		  . join( "; ", @$data_columns ) . "\n";
		## I have a problem getting only one Type name in the array!
		my ( @array, $temp );
		foreach (@$data_columns) {
			push( @array, $_ ) unless ( $temp->{$_} );
			$temp->{$_} = 1;
		}
		$data_columns = \@array;

		foreach $pathway_name ( sort keys %$pathway_hash ) {
			$temp_table =
			  $data_table_p->select_where( 'pathway_name',
				sub { return 1 if ( $_[0] eq $pathway_name ); return 0 } );
			$temp = $outpath . "/$state" . "_" . "$pathway_name" . "_p_values";
			$temp =~ s/\s/_/g;
			$temp =~ s/\./_/g;
			$temp =~ s/[\(\)]/_/g;
			$figures ->{$state} -> {$pathway_name}->{'p_values'} = $temp_table->plot_as_bar_graph(
				{
					'outfile' => $temp,
					'title' =>
"P value for $pathway_name and gene list $state",
					'y_title'             => " p value [-log10]",
					'data_name_column'    => 'r_cutoff',
					'data_values_columns' => $data_columns,
					'x_res'               => 800,
					'y_res'               => 500,
					'x_border'            => 70,
					'y_border'            => 50,
					'y_min_value'         => 0
				}
			);
		}
		@figures = ();
		foreach $pathway_name ( sort keys %$pathway_hash ) {
			$temp_table =
			  $data_table_n->select_where( 'pathway_name',
				sub { return 1 if ( $_[0] eq $pathway_name ); return 0 } );
			$temp =
			  $outpath . "/$state" . "_" . "$pathway_name" . "_gene_count";
			$temp =~ s/\s/_/g;
			$temp =~ s/\./_/g;
			$temp =~ s/[\(\)]/_/g;
			$figures ->{$state} -> {$pathway_name}->{'gene_count'} = $temp_table->plot_as_bar_graph(
				{
					'outfile' => $temp,
					'title' =>
"number of genes for $pathway_name and gene list $state",
					'y_title'             => "gene count [n]",
					'data_name_column'    => 'r_cutoff',
					'data_values_columns' => $data_columns,
					'x_res'               => 800,
					'y_res'               => 500,
					'x_border'            => 70,
					'y_border'            => 50,
					'y_min_value'         => 0
				}
			);
		}
		## And now I want to get a simple PDF that allows me to look at the data in a hurry!
	}
	my @states =  ( sort keys %{ $self->{'index'}->{'gene list type'} } );
	print "we will analyze the states @states\n";
	foreach $pathway_name ( sort keys %$pathway_hash ) {
		print "we are at the pathway $pathway_name\n";
		for ( my $i = 0; $i < @states; $i++ ){
			
			$figure[$i*2] = $figures ->{$states[$i]} -> {$pathway_name}->{'gene_count'};
			$figure[($i*2)+1] = $figures ->{$states[$i]} -> {$pathway_name}->{'p_values'};
			print "Adinge the files\n $figure[$i]\n $figure[$i+1]\n";
		}
		$latex_figure_string .= $self->create_figureStr_using_these_vars( \@figure, $pathway_name);
	}
	
	return $latex_figure_string;
}

sub create_figureStr_using_these_vars {
	my ( $self, $figures,$pathway_name ) = @_;
	
	my ( $str, $file, $number_of_connection_net_vars, $width, @tic, $cut );
	@tic                           = qw( a b c d e f g h i j k );
	$cut                           = 1;
	$number_of_connection_net_vars = scalar(@$figures);
	if ( $number_of_connection_net_vars % 2 == 0 ) {
		$width = 0.98 * ( 2 / $number_of_connection_net_vars );
	}
	else {
		$width = 0.98 * ( 2 / ( 1 + $number_of_connection_net_vars ) );
	}
	$str = "\\section{$pathway_name}
	
	Here we have analyzed the KEGG pathway $pathway_name. AT the moment I need to figure out 
	what I can draw from this analysis as at the moment there are too manny KEGG pathways involved!
	
	\n\n\\begin{figure}[htb]";
	for ( my $i = 0 ; $i < @$figures ; $i++ ) {
		$file = @$figures[$i];
		
		$str .= "\\begin{minipage}[htbp]{$width\\linewidth}
	\\centering
	\\subfigure[]{
	\\includegraphics[width=\\linewidth]{$file}
	}
	\\end{minipage}";
		if ( ( ( $i + 1 ) * $width ) / 0.97 > $cut ) {
			$str .= "\\\\\n";
			$cut++;
		}

	}
	$str .= "
\\caption{Pathway $pathway_name.} 
\\end{figure} 

\\newpage
";
	return $str;
}

sub log10 {
	my ($value) = @_;
	Carp::confess("You must not give me a value <= 0 to take the log from\n")
	  unless ( $value > 0 );
	return log($value) / log(10);
}

1;
