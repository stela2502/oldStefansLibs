package compare_SNP_2_Gene_expression_results;

#  Copyright (C) 2010-08-23 Stefan Lang

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
use stefans_libs::file_readers::SNP_2_gene_expression_reader;
use stefans_libs::database::genomeDB;
use stefans_libs::database::PubMed_queries;
use stefans_libs::plot::Chromosomes_plot;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::MyProject::compare_SNP_2_Gene_expression_results.pm

=head1 DESCRIPTION

A lib to read several SNP 2 gene expression result files and compare them against each other. In addition it supports the output as LaTex long table.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class compare_SNP_2_Gene_expression_results.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'order'     => [],
		'data'      => {},
		'SNP_count' => {}
	};

	bless $self, $class
	  if ( $class eq "compare_SNP_2_Gene_expression_results" );

	return $self;

}

sub Add_file {
	my ( $self, $infile, $p_value_cutoff ) = @_;
	Carp::confess("I can not read from an non existing file '$infile'!\n")
	  unless ( -f $infile );
	$p_value_cutoff = 1 unless ( defined $p_value_cutoff );
	$p_value_cutoff = $self->{'p_value_cutoff'}
	  if ( defined $self->{'p_value_cutoff'} );
	$self->{'p_value_cutoff'} = $p_value_cutoff if ( defined $p_value_cutoff );

	my $SNP_2_gene_expression_file = SNP_2_gene_expression_reader->new();
	my $snp_count =
	  $SNP_2_gene_expression_file->read_file( $infile, $p_value_cutoff );
	print "we got $snp_count SNPs from file $infile\n";
	if (
		defined $self->{'data'}
		->{ $SNP_2_gene_expression_file->{'correlating_gene'} } )
	{
		$snp_count = $self->{'data'}
		->{ $SNP_2_gene_expression_file->{'correlating_gene'} } -> read_file( $infile, $p_value_cutoff );
	}
	else {
		$self->{'data'}->{ $SNP_2_gene_expression_file->{'correlating_gene'} } =
	  $SNP_2_gene_expression_file;
	}
	push(
		@{ $self->{'oder'} },
		$SNP_2_gene_expression_file->{'correlating_gene'}
	);
	foreach my $rsID ( $SNP_2_gene_expression_file->get_rsIDs() ) {
		$self->{'SNP_count'}->{$rsID} = []
		  unless ( ref( $self->{'SNP_count'}->{$rsID} ) eq "ARRAY" );
		push(
			@{ $self->{'SNP_count'}->{$rsID} },
			$SNP_2_gene_expression_file->{'correlating_gene'}
		);
	}
	return $snp_count;
}

sub __chromosomes_plot {
	my ( $self, $organism_tag ) = @_;

	if ( ref( $self->{'chr_plot'} ) eq 'Chromosomes_plot' ) {
		my ( $data_table_2, $data ) =
		  $self->__genomic_positions_for_rsIDs($organism_tag);
		return $self->{'chr_plot'}, $data_table_2;
	}

	$organism_tag |= 'H_sapiens';
	$self->{'chr_plot'} = Chromosomes_plot->new( root::getDBH() );
	$self->{'chr_plot'}->create_chromosomes_for_organism($organism_tag);
	my ( $data_table_2, $data ) =
	  $self->__genomic_positions_for_rsIDs($organism_tag);
	foreach my $chr_name ( keys %$data ) {
		$self->{'chr_plot'}
		  ->Add_Data_4_chromosome( $chr_name, $data->{$chr_name} );
	}
	return ( $self->{'chr_plot'}, $data_table_2 );
}

sub get_chromosmes_data {
	my ( $self, $organism_tag ) = @_;
	unless ( defined $self->{'chr_plot'} ) {
		$self->__chromosomes_plot($organism_tag);
	}
	return $self->{'chr_plot'}->{'chromosomes'};
}

sub __genomic_positions_for_rsIDs {
	my ( $self, $organism_tag ) = @_;
	return $self->{'chromosomal_positions'}, $self->{'chromosomal_dataset'}
	  if ( defined $self->{'chromosomal_positions'}
		&& defined $self->{'chromosomal_dataset'} );
	my ( $genome, $genomeInterface );
	$organism_tag = 'H_sapiens' unless ( defined $organism_tag);
	## get the loaction of all the rsIDs
	$genome = genomeDB->new();
	$genomeInterface =
	  $genome->GetDatabaseInterface_for_Organism($organism_tag);
	$genomeInterface = $genomeInterface->get_rooted_to('SNP_table');
	my $complex_select = "#1 + #2, #3, #4";
	my $data_table     = $genomeInterface->get_data_table_4_search(

		#	my $data_table = $genomeInterface->create_SQL_statement(
		{
			'complex_select' => \$complex_select,
			'search_columns' => [
				'chromosomesTable.chr_start', 'SNP_table.position',
				'SNP_table.rsID',             'chromosomesTable.chromosome'
			],
			'where' => [ [ 'SNP_table.rsID', '=', 'my_value' ] ],
			'order_by' =>
			  [ 'chromosomesTable.chromosome', 'chromosomesTable.chr_start' ]
		},
		[ keys %{ $self->{'SNP_count'} } ]
	);

	#print $data_table->AsString().$genomeInterface->{'complex_search'}."\n";
	## create the data
	my ($data);
	$data = {};
	my $data_table_2 = data_table->new();
	$data_table_2->Add_2_Header('rsID');
	$data_table_2->Add_2_Header('Chromosome');
	$data_table_2->Add_2_Header('chr. position');

	foreach my $line ( @{ $data_table->{'data'} } ) {
		$data_table_2->AddDataset(
			{
				'rsID'          => @$line[1],
				'Chromosome'    => @$line[2],
				'chr. position' => @$line[0]
			}
		);
		$data->{ @$line[2] } = []
		  unless ( ref( $data->{ @$line[2] } ) eq "ARRAY" );
		push( @{ $data->{ @$line[2] } }, @$line[0] );
	}
	$self->{'chromosomal_positions'} = $data_table_2;
	$self->{'chromosomal_dataset'}   = $data;
	return $self->{'chromosomal_positions'}, $self->{'chromosomal_dataset'};
}

=head identify_regions_with_more_entries_in_object

Tjis function should be used to identify chromosomal regions that have more 'entries' 
in the other object than in this object.

You will get two data_tables; the first containing the information why I selected some regions and
the second stating all the rsIDs and p_values for the relevant SNPs.

The columns of the first table are: 'chromosome', 'start', 'end', 'difference'
ordered by 'difference'.

The columns of the second file are 'rsID', 'close by genes', 'p values' and

=cut

sub identify_regions_with_more_entries_in_object {
	my ( $self, $object, $organism_tag ) = @_;
	Carp::confess(
		"Sorry, but to compare I need an object of type " . ref($self) . "!\n" )
	  unless ( ref($object) eq ref($self) );
	$organism_tag |= 'H_sapiens';
	my (
		$chromosome,   $my_data_table,        $other_data_table,
		$data_array,   $differences,          $Chromosomes_plot,
		$data_table_2, $obj_Chromosomes_plot, $obj_data_table_2, $rsIDs, $row_number, $rs_2_position
	);
	## initialize all necessary dataset
	( $Chromosomes_plot, $data_table_2 ) =
	  $self->__chromosomes_plot($organism_tag);
	( $obj_Chromosomes_plot, $obj_data_table_2 ) =
	  $object->__chromosomes_plot($organism_tag);
	$obj_data_table_2 -> createIndex ('Chromosome');
	my $return = data_table->new();
	$differences = data_table->new();
	foreach (
		'chromosome', 'start',
		'end',        'low stat cutoff [n]',
		'hight stat cut off [n]', 'rsIDs'
	  )
	{
		$differences->Add_2_Header($_);
	}

#print root::get_hashEntries_as_string ($self->get_chromosmes_data(), 3, "the chromosomes data: ");
	## get the real information
	foreach my $chromosome ( keys %{ $self->get_chromosmes_data() } ) {

#print root::get_hashEntries_as_string (  $self->get_chromosmes_data()->{$chromosome}, 2, "and that is one chromosome entry $chromosome,  a ".ref($self->get_chromosmes_data()->{$chromosome}));
		$my_data_table =
		  $self->get_chromosmes_data()->{$chromosome}->getAsDataTable();
		foreach $row_number ($obj_data_table_2 -> get_rowNumbers_4_columnName_and_Entry ( 'Chromosome',$chromosome ) ){
				$rs_2_position -> { $obj_data_table_2 -> get_value_4_line_and_column ( $row_number, "chr. position" )} =
					 $obj_data_table_2 -> get_value_4_line_and_column ( $row_number, 'rsID' );
		}
		next unless ( scalar( @{ $my_data_table->{'data'} } ) > 0 );
		$other_data_table =
		  $object->get_chromosmes_data()->{$chromosome}->getAsDataTable()
		  ->getAsHash( 'start', 'value' );

		foreach $data_array ( @{ $my_data_table->{'data'} } ) {
			#print root::get_hashEntries_as_string ( $data_array, 3,
			#	"we have some data at $chromosome: " );
			if ( $other_data_table->{ @$data_array[0] } - @$data_array[2] > 4 )
			{
				$rsIDs = '';
				foreach ( sort { $a <=> $b} keys %$rs_2_position){
					$rsIDs .= " $rs_2_position->{$_}"if ( $_ >= @$data_array[0] && $_ <= @$data_array[1]);
				}
				$differences->AddDataset(
					{
						'chromosome' => $chromosome,
						'start'      => @$data_array[0],
						'end'        => @$data_array[1],
						'low stat cutoff [n]' =>
						  $other_data_table->{ @$data_array[0] },
						'hight stat cut off [n]' => @$data_array[2],
						'rsIDs' => $rsIDs
					}
				);
			}

		}
	}

	# now I need to create the summary table object - that will be tough
	# and the object has to have its own class - it will become that complex!
	#print $differences->AsString();
	#print $obj_data_table_2->AsString();

  #now we have something like
  #chromosome     start   end     low stat cutoff [n]     hight stat cut off [n]
  #2       42000000        43000000        10      0
  #1       168000000       169000000       5       0
  #9       123000000       124000000       8       1
  #10      115000000       116000000       5       0
	## now just get the original SNPs from some place - need to find that place first - SHIT!
	return $differences;

	return $return;
}

=header2 genes_that_correlate_with_rsID

the function expects a rsID as input and will return two array refs, the first containing a list of genes and the second containing a list of p_values.

=cut

sub genes_that_correlate_with_rsID {
	my ( $self, $rsID ) = @_;
	return unless ( defined $rsID );
	my ( @genes, @p_values );
	foreach my $gene ( keys %{ $self->{'data'} } ) {
		if ( defined $self->{'data'}->{$gene}->p_value_for_rsID($rsID) ) {
			push( @genes, $gene );
			push( @p_values,
				$self->{'data'}->{$gene}->p_value_for_rsID($rsID) );
		}

	}
	return \@genes, \@p_values;
}

sub plot_chromosome_distribution {
	my ( $self, $outfile, $organism_tag ) = @_;
	Carp::confess("I can not plot a figure without a valid outfile!\n")
	  unless ( defined $outfile );
	$organism_tag |= 'H_sapiens';
	## initialize the chromosomes
	my ( $Chromosomes_plot, $data_table_2 ) =
	  $self->__chromosomes_plot($organism_tag);

	$Chromosomes_plot->Title( "SNP locations ("
		  . join( ", ", ( keys %{ $self->{'data'} } ) )
		  . "; p< $self->{'p_value_cutoff'})" );
	$Chromosomes_plot->plot(
		{
			'x_res'   => 1800,
			'y_res'   => 1200,
			'y_min'   => 20,
			'y_max'   => 1100,
			'x_min'   => 100,
			'x_max'   => 1780,
			'outfile' => $outfile
		}
	);
	return $data_table_2;
}

=head qualify_SNPs

If you have added a set of SNP_2_gene_expression outfiles to this object using
\$self->Add_file(), this function will return two data_table object; the first containing the 
close by gene name, the rsID and the chromosome name, whereas the second file contains the 
close by gene name and the maount of publication on that gene, that might be interesting 
in connection to T2D using the PubMed search <gene name> [All Fields]  AND ("fat"[All Fields] OR ("insulin"[MeSH Terms] OR
	  "insulin"[All Fields] NOT "Insulin like growth factor"[All Fields]) OR T2D[All Fields] OR ("mitochondria"[MeSH Terms] OR 
	 "mitochondria"[All Fields]) OR ("channel"[All Fields])) NOT ("review"[All Fields])
	 
	 Hope the results do help!
=cut

sub qualify_SNPs {
	my ( $self, $organism_tag, $max_distance ) = @_;
	## here I n, eed to get the pubmed information for all the genes, that lie close by the genes.
	## And that is hell lot of data to collect!
	my ( $sql, $genome, $genomeInterface, $temp );
	$organism_tag = 'H_sapiens' unless ( defined $organism_tag );
	$max_distance |= 0;
	$genome = genomeDB->new();
	$genomeInterface =
	  $genome->GetDatabaseInterface_for_Organism($organism_tag);
	$genomeInterface = $genomeInterface->get_rooted_to('gbFilesTable');
	$genomeInterface = $genomeInterface->get_SNP_Table_interface();

	my $data_table = $genomeInterface->get_data_table_4_search(

		#	my $data_table = $genomeInterface->create_SQL_statement(
		{
			'search_columns' => [
				'gbFeaturesTable.name', 'SNP_table.rsID',
				'chromosomesTable.chromosome'
			],
			'where' => [
				[ 'gbFeaturesTable.tag', '=', 'my_value' ],
				[
					[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
					'>',
					[
						'chromosomesTable.chr_start', '+',
						[ 'gbFeaturesTable.start', '-', 'my_value' ]
					]
				],

				[
					[ 'SNP_table.position', '+', 'chromosomesTable.chr_start' ],
					'<',
					[
						'chromosomesTable.chr_start', '+',
						[ 'gbFeaturesTable.end', '+', 'my_value' ]
					]
				],
				[ 'SNP_table.rsID', '=', 'my_value' ]
			]
		},
		'gene',
		$max_distance,
		$max_distance,
		[ keys %{ $self->{'SNP_count'} } ]
	);
	print "we did the search\n$genomeInterface->{'complex_search'}\n";
	## and now we need to get all the Gene informations from NCBI - hell of a lot of work - perfect for over night work!
	my ( $PubMed_queries, $data_table_2 );
	$data_table->rename_column( 'gbFeaturesTable.name',        'gene' );
	$data_table->rename_column( 'SNP_table.rsID',              'rsID' );
	$data_table->rename_column( 'chromosomesTable.chromosome', 'CHR' );

	$data_table->Add_2_Header('gene count');
	$data_table->Add_2_Header('genes correlating with this SNP');
	$data_table->createIndex('gene');
	$data_table->createIndex('rsID');

#Carp::confess ( root::get_hashEntries_as_string ($self->{'SNP_count'}, 3, "what is stored in the variable 'SNP_count'? "));
	foreach my $gene ( keys %{ $self->{'SNP_count'} } ) {

		#print "we look at the rsID '$gene' ($self->{'SNP_count'}->{$gene})\n";
		$data_table->Add_Dataset(
			{
				'rsID'       => $gene,
				'gene count' => scalar( @{ $self->{'SNP_count'}->{$gene} } ),
				'genes correlating with this SNP' =>
				  join( ", ", @{ $self->{'SNP_count'}->{$gene} } )
			}
		);
	}

	$PubMed_queries = PubMed_queries->new( root::getDBH(), $self->{debug} );
	$data_table_2 = data_table->new();
	$data_table_2->Add_2_Header('gene symbol');
	$data_table_2->Add_2_Header('PubMed T2D hits');
	$data_table->Add_2_Header('PubMed T2D hits');

	foreach my $gene ( $data_table->getIndex_Keys('gene') ) {
		$temp = $PubMed_queries->get_T2D_hit_count_4_GeneSymbol($gene);
		$data_table_2->Add_Dataset(
			{
				'gene symbol'     => $gene,
				'PubMed T2D hits' => $temp
			}
		);
		$data_table->Add_Dataset(
			{
				'gene'            => $gene,
				'PubMed T2D hits' => $temp
			}
		);
	}
	$data_table_2 =
	  $data_table_2->Sort_by( [ [ 'PubMed T2D hits', 'numeric' ] ] );
	return $data_table, $data_table_2;
}

1;
