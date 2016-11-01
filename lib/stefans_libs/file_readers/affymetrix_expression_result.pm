package stefans_libs_file_readers_affymetrix_expression_result;

#  Copyright (C) 2010-12-07 Stefan Lang

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
use stefans_libs::array_analysis::correlatingData;
use base 'data_table';

=head1 General description

Read and use a modified Affymetrix expression results file. The benefit in using this class in stead of a simle data_table is, that we check for the ProbeSet ID and Gene Symbol columns and define them as a key and separate the other descriptive columns from the really data containing columns so that you can easily access these values. You can get an array of all accessable sample ids by calling Samples() on the object.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'            => $debug,
		'arraySorter'      => arraySorter->new(),
		'header_position'  => {},
		'default_value'    => [],
		'header'           => [],
		'data'             => [],
		'sample_groups'    => {},
		'index'            => {},
		'last_warning'     => '',
		'sample_ids'       => [],
		'description_cols' => [],
		'subsets'          => {},
	#	'no_doubble_cross' => 1,
	};
	bless $self, $class
	  if ( $class eq "stefans_libs_file_readers_affymetrix_expression_result" );

	return $self;
}

sub pre_process_array {
	my ( $self, $data ) = @_;
	my $line;
	for ( my $i = 0 ; $i < @$data ; $i++ ) {
		$line = shift(@$data);
		unless ( $line =~ m/^#[#%]/ ) {
			unshift( @$data, $line );
			last;
		}
	}
	return 1;
}

sub p4cS {
	my ( $self, @pattern ) = @_;
	return undef unless ( defined $pattern[0] );
	unless ( defined $self->{'p4cS'} ) {
		## OK I should not check anything!
		if ( defined $pattern[1] ) {
			print "we use the pattern as list\n";
			$self->{'p4cS'} = {};
			foreach (@pattern) {
				$self->{'p4cS'}->{$_} = 1;
			}
		}
		else {
			print "we use the pattern as regular expression ($pattern[0])\n";
			$self->{'p4cS'} = $pattern[0];
		}
		return 1;
	}
	Carp::confess(
		"You need to give me the pattern to identify the Samples first!\n")
	  unless ( defined $self->{'p4cS'} );
	if ( ref( $self->{'p4cS'} ) eq "HASH" ) {
		return $self->{'p4cS'}->{ $pattern[0] };
	}
	else {
		return $pattern[0] =~ m/$self->{'p4cS'}/;
	}
	Carp::confess("OOPS - you should not be able to reach that point!\n");
}

sub calculate_statistics {
	my ( $self, $dataname, $paired ) = @_;
	## I will simply add the results to my selve!
	if ( scalar( $self->Sample_Groups() ) == 2 ) {
		return $self->__calculate_wilcox( $dataname, $paired );
	}
	Carp::confess(
		"Sorry, I do not know how to calculate this statistics analysis!");
}

=head2 __calculate_wilcox

This function will be called internally if we have two return a Sample_Groups and you want to get a 
calculate_statistics result.

What you will get is a table containing the columns

Gene Symbol, meanA, stdA, meanB, stdB, fold change A/B, p value

All these dataset will also be stored in the initial expression file.
Hence you can easily store all results.
If you want to calculate a different analysis on this object please call
clear_sample_groups() to be able to add new groups.


=cut 

sub clear_sample_groups {
	my ($self) = @_;
	$self->{'sample_groups'} = {};
}

sub revert_RMA_log_values {
	my ($self) = @_;
	## OK I hope you know what you are doing!
	## I am going to convert the data - and you knew that!
	foreach ( @{ $self->Description() } ) {
		return 1 if ( $_ =~ m/I removed log2 sclare from the dataset!/ );
	}
	$self->Add_2_Description("I removed log2 sclare from the dataset!");

	my $array;
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$array = @{ $self->{'data'} }[$i];
		foreach ( $self->Header_Position('samples') ) {
			@$array[$_] = 2**@$array[$_];
		}
	}
	return 1;
}

sub __calculate_wilcox {
	my ( $self, $dataname, $paired ) = @_;
	my (
		@sample_groups, $group_string, $stat_object, $i,
		$pos_meanA,     $pos_meanB,    $pos_stdA,    $pos_stdB,
		$pos_diff,      $pos_p,        $array,       $temp,
		@temp,          @groupA,       @groupB
	);
	@sample_groups = values %{ $self->Sample_Groups() };
	$group_string =
	    "GroupA\t"
	  . join( "\t", @{ $sample_groups[0] } )
	  . "\tGroupB\t"
	  . join( "\t", @{ $sample_groups[1] } );
	$group_string .= "\tPAIRED" if ( defined $paired && $paired != 0 );
	## OK we will create a WILCOX test!
	$i = 0;
	foreach ( @{ $self->Description() } ) {
		return $self->__preprocess_stat_table( "wilcox analysis $i results",
			"wilcox analysis $i " )
		  if ( $_ =~ m/$group_string/ ); ## this analysis has already been done!
		$i++ if ( $_ =~ m/^wilcox analysis/ );
	}
	$stat_object = Wilcox_Test->new();
	$stat_object->SET_pairedTest($paired);
	## Setup data storage
	$self->Add_2_Description("wilcox analysis $i:\t$group_string");
	$pos_meanA = $self->Add_2_Header("wilcox analysis $i mean expression A");
	$pos_stdA  = $self->Add_2_Header("wilcox analysis $i std expression A");
	$pos_meanB = $self->Add_2_Header("wilcox analysis $i mean expression B");
	$pos_stdB  = $self->Add_2_Header("wilcox analysis $i std expression B");
	$pos_diff  = $self->Add_2_Header("wilcox analysis $i difference A-B");
	$pos_p     = $self->Add_2_Header("wilcox analysis $i expression p value");
	@groupA =
	  $self->define_subset( "wilcox analysis $i GroupA", $sample_groups[0] );
	@groupB =
	  $self->define_subset( "wilcox analysis $i GroupB", $sample_groups[1] );

	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {

		#print "we calaculate\n";
		$array = @{ $self->{'data'} }[$i];
		@temp = root->getStandardDeviation( [ @$array[@groupA] ] );
		@$array[$pos_meanA] = $temp[0];
		@$array[$pos_stdA]  = $temp[2];
		@temp = root->getStandardDeviation( [ @$array[@groupB] ] );
		@$array[$pos_meanB] = $temp[0];
		@$array[$pos_stdB]  = $temp[2];
		@$array[$pos_stdB]  = 1E-6 if ( @$array[$pos_stdB] == 0 );
		$temp[0]            = @$array[$pos_meanA];
		$temp[1]            = @$array[$pos_meanB];
		@$array[$pos_diff]  = $temp[0] - $temp[1];

		#print "Is that OK:  $temp[0] / $temp[1] = @$array[$pos_diff]#?\n";
		@temp = split(
			"\t",
			$stat_object->_calculate_wilcox_statistics(
				[ @$array[@groupA] ],
				[ @$array[@groupB] ]
			)
		);
		@$array[$pos_p] = $temp[0];
	}

	#delete ( $self->{'subsets'}->{ "wilcox analysis $i GroupA" } );
	#delete ( $self->{'subsets'}->{ "wilcox analysis $i GroupB" } );

	$self->define_subset(
		"wilcox analysis $i results",
		[
			"wilcox analysis $i expression p value",
			"wilcox analysis $i difference A-B",
			'Gene Symbol',
			"wilcox analysis $i mean expression A",
			"wilcox analysis $i std expression A",
			"wilcox analysis $i mean expression B",
			"wilcox analysis $i std expression B"

		]
	);
	return $self->__preprocess_stat_table( "wilcox analysis $i results",
		"wilcox analysis $i " );
}

sub __preprocess_stat_table {
	my ( $self, $anaysis_tag, $subset_tag ) = @_;

	my $return = $self->get_as_table_object($anaysis_tag);
	foreach ( @{ $return->{'header'} } ) {
		if ( $_ =~ m/$subset_tag(.*)/ ) {
			$return->Rename_Column( $_, $1 );
		}
	}
	$return->Description( $self->Description() );
	return $return;
}

sub Samples {
	my $self = shift;
	return $self->{'sample_ids'};
}

=head2 Generl description of the plotting system

First the system is quite complex for this dataset as 
most probably there are more data groups in this file and I need to know how to plot them!

In addition there could be an linearity in the patterns that I should keep track of.
The Y axis always depicts the expression values, but I might have min and max defined based on min and max of all genes.
Otherwise I only need to know at which x positions to plot the data.

This information should not be entered each time a dataset is used. Instead I can store that information in the
subsets and in the Description.

The Sample_Groups ( <group name>, [<column names>], $plotting_information  ) will not only create the simple grouping but also will create a
subset if that is not already existing. And upon reading of the file this information is recovered using the After_Data_read
function. (just for internal documentation!)

How to plot the data has to be predefined!
I want to have that in the Descriptions like that:

<subset name>\tx=<integer>;color=<string>;<some other thing>=<value>

And the string "x=<name>;color=<string>;label=<the label string>;<some other thing>=<value>" is exactly what the $plotting_information in the Sample_Groups should contain.

at some other occasion you need to add a 'x_values\t<tag1>\t<tag2>\t<tag3>\t...' Description! 

=head2 plot({})
 
=cut

sub get_hash_for_description {
	my ( $self, $description ) = @_;
	my @temp;
	if ( ref($description) eq "ARRAY" ) {
		$description = @$description[0];
	}
	@temp = split( "\t", $description );
	my $result;
	foreach ( split( ";", pop(@temp) ) ) {
		$result->{$1} = $2 if ( $_ =~ m/(\w+)=(.+)/ );
	}
	return $result;
}

#sub parse_groups_from_object{
#	my ( $self, $object ) = @_;
#	Carp::confess ( "Hej I need a 'stefans_libs_array_analysis_table_based_statistics_group_information' object in oder to do my job!\n"."Not ".ref($object)."\n")
#		unless ( ref($object) eq 'stefans_libs_array_analysis_table_based_statistics_group_information');
#	
#}

sub process_plotting_variables {
	my ( $self, $search_column, $column_entry, $titel_column ) = @_;
	my ( @datasets, @x_values );
	## dataset name - does not always have to be the same as the group names!
	## In addition I need a  x areas name!
	my ( $filename, $path, @temp, $result, $dataset, $order_array, $title_column_id );
	$title_column_id = $self->Header_Position($titel_column);
	$title_column_id = $self->Header_Position($search_column) unless ( defined $title_column_id);

	@temp = (split( "\t", @{ $self->Description('x_values') }[0] ));
	shift(@temp);
	$order_array = [@temp];

	unless ( defined @{ $self->Description('x_values') }[0] ) {
		my $str = $self->AsString();
		$str = substr($str, 0,400);
		Carp::confess(
			"Sorry I need an x_values description here in the affymetrix_expression_result object based on file '$self->{'read_filename'}'!\n$str\n");
	}
	foreach my $line_id (
		$self->get_rowNumbers_4_columnName_and_Entry(
			$search_column, $column_entry
		)
	  )
	{
		foreach my $samples_group ( keys %{ $self->{'sample_groups'} } ) {
			Carp::confess(
				"I do not know what to do with the sample '$samples_group'")
			  unless ( defined @{ $self->Description($samples_group) }[0] );
			$result =
			  $self->get_hash_for_description(
				$self->Description($samples_group) );
			$dataset->{ $result->{'label'} } = {
				'name'         => $result->{'label'},
				'data'         => {},
				'order_array'  => $order_array,
				'color'        => $result->{'color'},
				'border_color' => $result->{'color'},
			  }
			  unless ( ref( $dataset->{ $result->{'label'} } ) eq "HASH" );
			$dataset->{ $result->{'label'} }->{'data'}->{ $result->{'x'} } =
			  [ $self->get_value_4_line_and_column( $line_id, $samples_group )
			  ];
			  $self->{'actual_figure_title'} = @{@{$self->{'data'}}[$line_id]}[$title_column_id];
		}
		foreach ( values %{$dataset} ) {
			push( @datasets, $_ );
		}
		last;    # I will not produce multiple figures here!!!!! be specific!
	}
	return @datasets;
}

=head2 plot({
	'outfile' => the filename will be parsed into path and filename extension, 
	'select_column' => an existing column in the dataset - shoulöd really be unique as only the first entry in the pable matching will be plotted, 
	'values' => [ <column values> ],
	'titles' => [ <title strings> ], ## the same order like the <column values>!
})

The function will return a list of plotted figure files.

=cut

sub plot {
	my ( $self, $hash ) = @_;
	my ($error);
	$error = '';

	# 'y_title' 'x_title' 'title' 'x_res', 'y_res',   'x_border', 'y_border'
	foreach ( 'outfile', 'select_column', 'values' ) {
		$error .= "missing data for key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );

	## now I need to create the dataset to plot on the damn whisker plot!
	# and that should look like that:
	# $dataset = {
	# 'name' => 'T2D',
	# 'data' =>,
	# {
	# 	'A/B' => [<values>],
	#	'A/A' => [<values>],
	#	'B/B' => [<values>]
	# },
	# 'order_array'  => [ 'A/A', 'A/B', 'B/B' ],
	# 'color'        => $color->{'blue'},
	# 'border_color' => $color->{'grey'}
	# };
	my ( @datasets, $figure, $dataset, $path, $filename, @temp, $Graph, @figure_files, $field_entry, $title );
	@temp     = split( "/", $hash->{'outfile'} );
	$filename = pop(@temp);
	$path     = join( "/", @temp );
	$path     = "." unless ( $path =~ m/\w/ );
	@temp     = split( /\./, $filename );
	pop(@temp) if ( scalar(@temp) > 1 );
	$filename = join( ".", @temp );
	for ( my $i = 0 ; $i < scalar(  @{ $hash->{'values'}} ) ; $i ++ ){
		$field_entry = @{$hash->{'values'}}[$i];
		$title = $field_entry;
		$title = @{ $hash->{'titles'}}[$i] if ( ref($hash->{'titles'}) eq "ARRAY");

		@datasets =
		  $self->process_plotting_variables( $hash->{'select_column'},
			$field_entry, $hash->{'title_column'} );

		$figure = simpleWhiskerPlot->new();
		$figure->_createPicture({'x_res' => 800, 'y_res' => 600});
		$Graph = simpleWhiskerPlot->new();
		my $hash = {'x_res' => 800, 'y_res' => 600};
		$Graph -> _createPicture($hash);
		warn $Graph->{'im'}." is the image!\n";
		foreach $dataset (@datasets) {
			$dataset -> {'border_color'} =  $dataset -> {'color'} = $hash->{'color'}->{$dataset -> {'color'}};
			$Graph->AddDataset($dataset);
		}

		$Graph->Ytitle( $hash->{'expression values'} );
		$Graph->Title($self->{'actual_figure_title'});
		push (@figure_files, $Graph->plot(
			{
				'x_res'   => 800,
				'y_res'   => 600,
				'outfile' => "$path/$field_entry" . "_" . $filename,
				'x_min'   => 80,
				'x_max'   => 720,
				'y_min'   => 80,
				'y_max'   => 520,
				'mode'    => 'landscape',
			}
		) );
	}
	return @figure_files;
}

sub After_Data_read {
	my ($self) = @_;
	## first the real things
	my $error = '';
	$error .= "We did not get a 'Gene Symbol' column!\n"
	  unless ( defined $self->Header_Position('Gene Symbol') );
	$error .= "We did not get a 'Probe Set ID' column!\n"
	  unless ( defined $self->Header_Position('Probe Set ID') );
	Carp::confess(
"During the reading of the file $self->{'read_filename'} we got the erro:\n"
		  . $error )
	  if ( $error =~ m/\w/ );
	$self->define_subset( 'key', [ 'Probe Set ID', 'Gene Symbol' ] );
	if ( defined $self->{'sample_groups'}->{'samples'}){
		$self->{'sample_ids'} = $self->{'sample_groups'}->{'samples'};
	}
	else {
		$self->define_subset( 'samples',          $self->{'sample_ids'} );
		$self->define_subset( 'description_cols', $self->{'description_cols'} );
	}
	

	foreach my $array ( @{ $self->{'data'} } ) {
		@$array[0] = $1 if ( @$array[0] =~ m/^ (.*)/ );
		@$array[0] = $1 if ( @$array[0] =~ m/(.*) +$/ );
	}
	$self->{'no_doubble_cross'} = 1;
	
	## and then the plot specifics
	foreach my $subset_name ( keys %{ $self->{'subsets'} } ) {
		if ( defined @{ $self->Description($subset_name) }[0] ) {
			my @column_names;
			foreach my $column_id ( @{ $self->{'subsets'}->{$subset_name} } ) {
				push( @column_names, "@{$self->{'header'}}[$column_id]" );
			}
			$self->{'sample_groups'}->{$subset_name} = \@column_names;
		}
	}
	return 1;
}

sub Sample_Groups {
	my ( $self, $group_name, $sample_ids, $plotting_information ) = @_;

	if ( ref($sample_ids) eq "ARRAY" ) {
		$self->{'error'} = '';
		#print "we got the samples '$sample_ids'\n";
		my ( $known_samples, @usable_samples );
		foreach ( @{ $self->Samples() } ) {
			#print "we will recognize the sample $_\n";
			$known_samples->{$_} = 1;
		}
		foreach (@$sample_ids) {
			if ( $known_samples->{$_} ) {
				push( @usable_samples, $_ );
			}
			else { 
				warn "We do not have data on sample $_!\n";
				$self->{'error'} .= "We do not have data on sample $_!";
			}
		}
		shift(@usable_samples) unless ( defined $usable_samples[0] );
		$self->{'sample_groups'}->{$group_name} = \@usable_samples;
		$self->define_subset( $group_name, \@usable_samples );
		if ( defined $plotting_information ) {
			$self->Add_2_Description("$group_name\t$plotting_information");
		}
	}
	return ( $self->{'sample_groups'}->{$group_name} )
	  if ( defined $group_name );
	return $self->{'sample_groups'};
}

=head2 Calculate_MeanCentroid

I will calculate the mean expression for each sample over the whole dataset,
and return a new stefans_libs_file_readers_affymetrix_expression_result opbject with
only the mean centroid values in.

=cut

sub Calculate_MeanCentroid {
	my ($self) = @_;

	#my $return  = $self->_copy_without_data();
	my $centroid = { 'Gene Symbol' => 'mean_centroid' };
	foreach ( @{ $self->Samples } ) {
		$centroid->{$_} = root->mean( $self->getAsArray($_) );
	}

	#$return-> AddDataset ( $centroid );
	#return $return;
	$self->AddDataset($centroid);
	return $self;
}

=head2 normalizeExpression

This function will remove the mean expression from all expression estimates 
and give return the new data without touching the old object.

=cut

sub normalizeExpression {
	my ($self) = @_;
	my $return = $self->_copy_without_data();
	my ( $hash, $mean );
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$hash = $self->get_line_asHash($i);
		$mean = root->mean(
			[
				@{ @{ $self->{'data'} }[$i] }
				  [ $self->Header_Position('samples') ]
			]
		);

#print "we normalize the expresison of $hash->{'Gene Symbol'} to 0 removing the mean $mean\n";
		foreach ( @{ $self->Samples } ) {
			$hash->{$_} = ( $hash->{$_} - $mean );
		}
		$return->AddDataset($hash);
	}
	return $return;
}

sub normalize_std0_Expression {
	my ($self) = @_;
	my $return = $self->_copy_without_data();
	my ( $hash, $mean, $anzahl, $StandartAbweichung );
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$hash = $self->get_line_asHash($i);
		( $mean, $anzahl, $StandartAbweichung ) = root->getStandardDeviation(
			[
				@{ @{ $self->{'data'} }[$i] }
				  [ $self->Header_Position('samples') ]
			]
		);

#print "we normalize the expresison of $hash->{'Gene Symbol'} to 0 removing the mean $mean\n";
		foreach ( @{ $self->Samples } ) {
			$hash->{$_} = ( $hash->{$_} - $mean ) / $StandartAbweichung;
		}
		$return->AddDataset($hash);
	}
	return $return;
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		$value = "Probe Set ID" if ( $value eq "probeset_id" );
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] = $value;
		${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ] =
		  '';
		if ( $self->p4cS($value) ) {
			push( @{ $self->{'sample_ids'} }, $value );
		}
		else {
			push( @{ $self->{'description_cols'} }, $value );
		}
	}
	return $self->{'header_position'}->{$value};
}


sub _copy_without_data {
	my ($self) = @_;
	my $return = ref($self)->new();
	foreach (
		'no_doubble_cross', 'key',             'sample_ids',
		'description_cols', 'read_filename',   'debug',
		'arraySorter',      'header_position', 'default_value',
		'header',           'subsets'
	  )
	{
		$return->{$_} = $self->{$_};
	}
	foreach my $index_name ( keys %{ $self->{'index'} } ) {
		$return->{'index'}->{$index_name} = {};
	}
	foreach my $index_name ( keys %{ $self->{'uniques'} } ) {
		$return->{'uniques'}->{$index_name} = {};
	}
	return $return;
}

1;
