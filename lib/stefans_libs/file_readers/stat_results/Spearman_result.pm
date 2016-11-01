package stefans_libs::file_readers::stat_results::Spearman_result;

#  Copyright (C) 2010-11-09 Stefan Lang

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
use stefans_libs::file_readers::stat_results::base_class;
use stefans_libs::plot::simpleXYgraph;
use stefans_libs::array_analysis::regression_models::linear_regression;
use base 'stefans_libs_file_readers_stat_results_base_class';

=head1 General description

You can open and plot KruskalWallisTest results using this module.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'                 => $debug,
		'arraySorter'           => arraySorter->new(),
		'last_group'            => 0,
		'number_of_read_groups' => 0,
		'sample_ids'            => [],
		'header_position'       => {
			'Probe Set ID' => 0,
			'Gene Symbol'  => 1,
			'p value'      => 2,
			'S'            => 3,
			'rho'          => 4
		},
		'default_value' => [],
		'header' => [ 'Probe Set ID', 'Gene Symbol', 'p value', 'S', 'rho' ],
		'data'   => [],
		'index'  => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class
	  if (
		$class eq "stefans_libs::file_readers::stat_results::Spearman_result" );

	return $self;
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	## OK here we have some variability in the header information!
	## the first 5 columns are fixed, and after that we get some variability
	## there are $column[4]+1 many groups, that do even contain data
	## So we need to collect that data in order to be able to plot it afterwards!
	# warn "we try to add the value $value to the header list!\n";
	if ( defined $self->{'header_position'}->{$value} ) {
		return $self->{'header_position'}->{$value};
	}
	else {
		if ( $self->{'number_of_read_groups'} == 0 ) {
			@{ $self->{'sample_ids'} }[ $self->{'number_of_read_groups'} ] =
			  { 'tag' => 'Samples', 'samples' => [] };
			$self->{'number_of_read_groups'}++;
			$self->{'header_position'}->{$value} = $self->{'last_group'} =
			  scalar( @{ $self->{'header'} } );
		}
		## As it is no group definition it has to be a sample id
#print "we stuff the sample $value into the sample group ".($self->{'number_of_read_groups'}-1)."\n";
		Carp::confess( "ERROR - the data structure for the group "
			  . ( $self->{'number_of_read_groups'} - 1 )
			  . " was not initialized at column '$value'\n" )
		  unless (
			ref(
				@{ $self->{'sample_ids'} }
				  [ $self->{'number_of_read_groups'} - 1 ]
			) eq "HASH"
		  );
		push(
			@{
				@{ $self->{'sample_ids'} }
				  [ $self->{'number_of_read_groups'} - 1 ]->{'samples'}
			  },
			$value
		);
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		push( @{ $self->{'header'} }, $value );
		return $self->{'header_position'}->{$value};
	}
}

sub Shift_Axes {
	my ( $self, $bin ) = @_;
	if ( defined $bin ) {
		$self->{'__shift_axes__'} = $bin;
	}
	return $self->{'__shift_axes__'};
}

=head2 plot ( $outpath, $x value name, exclude_00 )

I will create a list of piczures, that depict the change in expression ofver the analyzed groups.

=cut

sub plot {
	my ( $self, $outpath, $type, $exclude_00 ) = @_;
	return [] if ( scalar( $self->{'data'} ) == 0 );
	$self->define_subset( '__data_description__', ['Probe Set ID', 'Gene Symbol'] );
#Carp::confess ( "Sorry, but plot is not implemented for the object ".ref($self)."\n" );
	my (
		$line, $error,  $figure, @groups, $dataset,
		$plot, @return, @temp,   $file_modifier
	);
	
	$type = '' unless ( defined $type );
	$error = ref($self) . ':plot($outpath) - the path does not exist!' . "\n"
	  unless ( -f $outpath );
	$figure = simpleXYgraph->new();
	$figure->_createPicture();

	foreach ( @{ $self->{'sample_ids'} } ) {
		push( @groups, $_->{'tag'} );
		$self->define_subset( $_->{'tag'}, $_->{'samples'} );
	}
	@groups = sort (@groups);
	my ( @colors, @labels, $geneName );

	foreach (
		'green', 'red',    'blue',  'pink', 'tuerkies1',
		'rosa',  'orange', 'brown', 'grey'
	  )
	{
		push( @colors, $figure->{'color'}->{$_} );
	}
	## I need to have a outfile_modifier as we might have the same results from a different correlation outfile.
	@temp          = split( "/", $self->{'read_filename'} );
	$file_modifier = $temp[ @temp - 1 ];
	@temp          = split( /\./, $file_modifier );
	$file_modifier = $temp[0];
	die
"We have no initial filename or we are unable to parse that into a file modifier!\n'$self->{'read_filename'}'\n'$file_modifier'"
	  unless ( $file_modifier =~ m/\w/ );
	
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$line = @{ $self->{'data'} }[$i];
		if (  -f $outpath
			. "/$file_modifier" . "_"
			. join( "_", @$line[ $self->Header_Position ( '__data_description__') ] )
			. ".svg" )
		{
			push( @return,
				    $outpath
				  . "/$file_modifier" . "_"
				  . join( "_", @$line[ $self->Header_Position ( '__data_description__')] )
				  . ".svg" );
			next;
		}
		$plot = simpleXYgraph->new();
		$plot->No_Line_Between( 'p = ' . sprintf( '%.1e', @$line[$self->Header_Position('p-value')] ), 1 );
		$geneName = @$line[$self->Header_Position('Gene Symbol')];
		$geneName = @$line[$self->Header_Position('Probe Set ID')] unless ( $geneName =~ m/\w/ );
		$geneName =~ s/ *\/\/.*$//;
		$plot->Title($geneName);
		$plot->Ytitle( $geneName . " values" );
		$plot->Xtitle( $type . " values" ) if ( defined $type );
		
		$dataset->{'x'} =
		  [ @{ $self->{'x_values'} }[ $self->Header_Position('Samples') ] ];
		$dataset->{'y'} = [ @$line[ $self->Header_Position('Samples') ] ];
		my $dataset_ok = 1;
		for ( my $i = 0; $i <scalar ( $self->Header_Position('Samples')) ; $i ++ ){
			unless ( @{$dataset->{'x'}}[$i] =~m/\d/){
				$dataset_ok = 0;
				last;
			}
			unless ( @{$dataset->{'y'}}[$i] =~m/\d/){
				$dataset_ok = 0;
				last;
			}
		}
		unless ( $dataset_ok ) {
			Carp::confess ( root::get_hashEntries_as_string ({'dataset' => $dataset, 'sample positions' => [ $self->Header_Position('Samples') ], 'line' => $line }  , 3 ,  "I am on line $i in the dataset and I do not have the same amount of x an y values!" ) );
		}
		if ($exclude_00) {
			my ( @x, @y );
			for ( my $i = 0 ; $i < @{ $dataset->{'x'} } ; $i++ ) {
				if (   @{ $dataset->{'x'} }[$i] =~ m/\d/
					&& @{ $dataset->{'y'} }[$i] =~ m/\d/ )
				{
					push( @x, @{ $dataset->{'x'} }[$i] );
					push( @y, @{ $dataset->{'y'} }[$i] );
				}
			}
			$dataset->{'x'} = [@x];
			$dataset->{'y'} = [@y];
		}
		print "now I will start to create the regressin line\n";
		## And now I would like to add a linear regression line to that!
		if ( $self->Shift_Axes() ) {
			my $temp;
			$temp           = $dataset->{'x'};
			$dataset->{'x'} = $dataset->{'y'};
			$dataset->{'y'} = $temp;
			$temp           = $plot->Ytitle();
			$plot->Ytitle( $plot->Xtitle() );
			$plot->Xtitle($temp);
		}
		my $regression = {
			'title' => "R = " . sprintf( '%.1e', @$line[$self->Header_Position('rho')] ),
			'color' => $colors[1],
			'x'     => $dataset->{'x'},
			'y'     => linear_regression->new()->_get_fitted_values(
				{
					'normalizing_values' => { 'a' => $dataset->{'x'} },
					'data_values'        => $dataset->{'y'}
				}
			)
		};
		print "we try to plot the x  values "
		  . join( ', ', @{ $dataset->{'x'} } )
		  . "\nand the y values "
		  . join( ', ', @{ $dataset->{'y'} } ) . "\n";
		@labels = ();
		$dataset->{'title'} = 'p = ' . sprintf( '%.1e', @$line[$self->Header_Position('p-value')] );
		$dataset->{'color'} = $colors[0] || 'black';
		$plot->AddDataset($dataset);
		$plot->AddDataset($regression);
		$plot->No_Data_points( $regression->{'title'}, 1 );
		push(
			@return,
			$plot->plot(
				{
					'x_res'   => 400,
					'y_res'   => 400,
					'outfile' => $outpath
					  . "/$file_modifier" . "_"
					  . join( "_", @$line[ $self->Header_Position ( '__data_description__')] ),
					'x_min' => 100,
					'x_max' => 400 - 40,
					'y_min' => 40,            # oben
					'y_max' => 400 - 70,      # unten
					'mode'  => 'landscape',
				}
			)
		);
	}
	return \@return;
}

sub _copy_without_data {
	my ($self) = @_;
	my $return = ref($self)->new();
	$return->{'read_filename'}   = $self->{'read_filename'};
	$return->{'debug'}           = $self->{'debug'};
	$return->{'arraySorter'}     = $self->{'arraySorter'};
	$return->{'header_position'} = $self->{'header_position'};
	$return->{'default_value'}   = $self->{'default_value'};
	$return->{'header'}          = $self->{'header'};
	$return->{'sample_ids'}      = $self->{'sample_ids'};
	$return->{'x_values'}        = $self->{'x_values'};
	foreach my $index_name ( keys %{ $self->{'index'} } ) {
		$return->{'index'}->{$index_name} = {};
	}
	foreach my $index_name ( keys %{ $self->{'uniques'} } ) {
		$return->{'uniques'}->{$index_name} = {};
	}
	$return->{'subsets'} = $self->{'subsets'};
	return $return;
}

sub Describe_Samples {
	my ( $self, $latex_section ) = @_;
	return 0 unless ( ref($latex_section) =~ m/Section$/ );
	my $data_table = data_table->new();
	foreach ( 'Sample ID', 'value' ) {
		$data_table->Add_2_Header($_);
	}
	foreach ( $self->Header_Position('Samples') ) {
		$data_table->AddDataset(
			{
				'Sample ID' => @{ $self->{'header'} }[$_],
				'value'     => @{ $self->{'x_values'} }[$_]
			}
		);
	}
	$data_table = $data_table->Sort_by( [ [ 'value', 'numeric' ] ] );
	$latex_section->AddText(
'For this phenotype we did apply a Spearman signed rank statistics implemented in R. We have used the samples '
		  . join( ", ", @{ $self->{'sample_ids'} } ) . ".\n"
		  . "The table shows the values for each sample" )
	  ->Add_Table($data_table);

	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	$self->Rename_Column( 'p value', 'p-value' );
	## the first row contains the reference data - no real data!
	$self->{'x_values'} = shift( @{ $self->{'data'} } );

	#print "we got the x values". join(', ', @{$self->{'x_values'}})."\n";
	foreach ( keys %{ $self->{'index'} } ) {
		$self->__update_index($_);
	}
	return 1;
}

sub AsString {
	my ( $self, $subset ) = @_;
	my $str = '';
	my @default_values;
	my @line;
	if ( defined $subset ) {
		## 1 get the default values
		@default_values = $self->getDefault_values($subset);
		foreach my $description_line ( @{ $self->{'description'} } ) {
			$description_line =~ s/\n/\n#/g;
			$str .= "#$description_line\n";
		}
		$str .= '#' unless ( $self->{'no_doubble_cross'} );
		$str .= join(
			$self->line_separator(),
			@{ $self->{'header'} }[ $self->define_subset($subset) ]
		) . "\n";
		foreach my $data ( @{ $self->{'data'} } ) {
			@line = @$data[ $self->define_subset($subset) ];
			for ( my $i = 0 ; $i < @line ; $i++ ) {
				$line[$i] = $default_values[$i] unless ( defined $line[$i] );
			}
			$str .= join( $self->line_separator(), @line ) . "\n";
		}
	}
	else {
		foreach my $description_line ( @{ $self->{'description'} } ) {
			$description_line =~ s/\n/\n#/g;
			$str .= "#$description_line\n";
		}
		$str .= '#' unless ( $self->{'no_doubble_cross'} );
		$str .= join( $self->line_separator(), @{ $self->{'header'} } ) . "\n";
		@default_values = $self->getAllDefault_values();
		$str .= join( $self->line_separator(), @{$self->{'x_values'}}[0..$self->Columns()-1])."\n";
		foreach my $data ( @{ $self->{'data'} } ) {
			@line = @$data;
			for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
				$line[$i] = $default_values[$i] unless ( defined $line[$i] );
			}
			$str .= join( $self->line_separator(), @line ) . "\n";
		}
	}
	return $str;
}

1;
