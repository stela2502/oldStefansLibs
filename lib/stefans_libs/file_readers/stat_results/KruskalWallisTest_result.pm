package stefans_libs::file_readers::stat_results::KruskalWallisTest_result;

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
			'Probe Set ID'       => 0,
			'Gene Symbol'        => 1,
			'p-value'            => 2,
			'chi-squared'        => 3,
			'degrees of freedom' => 4
		},
		'default_value' => [],
		'header'        => [
			'Probe Set ID',
			'Gene Symbol',
			'p-value',
			'chi-squared',
			'degrees of freedom'
		],
		'data'         => [],
		'index'        => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class
	  if ( $class eq
		"stefans_libs::file_readers::stat_results::KruskalWallisTest_result" );

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

	#'group nr. 0 (T/T)'
	if ( $value =~ m/group nr. (\d+) \(([AGCT]\/?[ACGT])\)/ ) {
		my ( $group, $tag ) = ( $1, $2 );

		## OK we have a new group - and that is group
		Carp::confess(
"we have a group number error with group '$value' - we had expected to read group $self->{'number_of_read_groups'}\ first!\n"
		) unless ( $group eq $self->{'number_of_read_groups'} );
		@{ $self->{'sample_ids'} }[ $self->{'number_of_read_groups'} ] =
		  { 'tag' => $tag, 'samples' => [] };
		$self->{'number_of_read_groups'}++;
		$self->{'header_position'}->{$value} = $self->{'last_group'} =
		  scalar( @{ $self->{'header'} } );
		@{ $self->{'header'} }[ $self->{'last_group'} ] = $value;
		return $self->{'header_position'}->{$value};

	}
	elsif ( $value =~ m/group nr. (\d+) \(([\w+])\)/ ) {
		my ( $group, $tag ) = ( $1, $2 );

		Carp::confess(
"we have a group number error with group '$value' - we had expected to read group $self->{'number_of_read_groups'}\ first!\n"
		) unless ( $group eq $self->{'number_of_read_groups'} );
		@{ $self->{'sample_ids'} }[ $self->{'number_of_read_groups'} ] =
		  { 'tag' => $tag, 'samples' => [] };
		$self->{'number_of_read_groups'}++;
		$self->{'header_position'}->{$value} = $self->{'last_group'} =
		  scalar( @{ $self->{'header'} } );
		@{ $self->{'header'} }[ $self->{'last_group'} ] = $value;
		return $self->{'header_position'}->{$value};
	}
	elsif ( $value =~ m/group nr. (\d+) \((\w+)\)/ ) {
		my ( $group, $tag ) = ( $1, $2 );

		Carp::confess(
"we have a group number error with group '$value' - we had expected to read group $self->{'number_of_read_groups'}\ first!\n"
		) unless ( $group eq $self->{'number_of_read_groups'} );
		@{ $self->{'sample_ids'} }[ $self->{'number_of_read_groups'} ] =
		  { 'tag' => $tag, 'samples' => [] };
		$self->{'number_of_read_groups'}++;
		$self->{'header_position'}->{$value} = $self->{'last_group'} =
		  scalar( @{ $self->{'header'} } );
		@{ $self->{'header'} }[ $self->{'last_group'} ] = $value;
		return $self->{'header_position'}->{$value};
	}
	else {
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

=head2 plot ( $outpath )

I will create a list of piczures, that depict the change in expression ofver the analyzed groups.

=cut

sub plot {
	my ( $self, $outpath, $type ) = @_;
	return [] if ( scalar( $self->{'data'} ) == 0 );
	$self->define_subset( '__data_description__', ['Probe Set ID', 'Gene Symbol'] );
#	Carp::confess ( "the outpath $outpath does not exist!\n" ) unless ( -d $outpath );
	my (
		$line,     $error,             $figure, @groups,
		$dataset,  $simpleWhiskerPlot, @return, @temp,
		$geneName, $file_modifier
	);
	$type = '' unless ( defined $type );
	$error = ref($self) . ':plot($outpath) - the path does not exist!' . "\n"
	  unless ( -f $outpath );
	$figure = simpleWhiskerPlot->new();
	$figure->_createPicture();

	foreach ( @{ $self->{'sample_ids'} } ) {
		push( @groups, $_->{'tag'} );
		$self->define_subset( $_->{'tag'}, $_->{'samples'} );
	}
	@groups = sort (@groups);
	my ( @colors, @labels );

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
	Carp::confess(
"We have no initial filename or we are unable to parse that into a file modifier!\ninitial filename='$self->{'read_filename'}'\nfile_modifier='$file_modifier'"
	) unless ( $file_modifier =~ m/\w/ );
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
				  . join( "_", @$line[ $self->Header_Position ( '__data_description__') ] )
				  . ".svg" );
			next;
		}
		if ( $type eq "bars" ) {
			$simpleWhiskerPlot = simpleBarGraph->new();
		}
		else {
			$simpleWhiskerPlot = simpleWhiskerPlot->new();
		}

		$geneName = @$line[$self->Header_Position('Gene Symbol')];
		$geneName = @$line[$self->Header_Position('Probe Set ID')] unless ( $geneName =~ m/\w/ );
		$geneName =~ s/ *\/\/.*$//;
		$simpleWhiskerPlot->Title($geneName);
		$simpleWhiskerPlot->Ytitle(
			"$geneName expression [min, lower, median, upper, max]");
		$dataset->{'data'} = {};
		@labels = ();
		for ( my $i = 0 ; $i < @groups ; $i++ ) {
			print
			  "We will convert the tag $groups[$i] into the tag  $groups[$i] ("
			  . scalar( $self->Header_Position( $groups[$i] ) ) . ")\n";
			$labels[$i] =
			  $groups[$i] . " ("
			  . scalar( $self->Header_Position( $groups[$i] ) ) . ")";
			$dataset->{'data'}->{ $groups[$i] . " ("
				  . scalar( $self->Header_Position( $groups[$i] ) )
				  . ")" } = [ @$line[ $self->Header_Position( $groups[$i] ) ] ];
		}
		$dataset->{'order_array'} = \@labels;
		$dataset->{'name'}        = 'p = ' . sprintf( '%.1e', @$line[$self->Header_Position('p-value') ]);
		$dataset->{'color'}       = $colors[0] || 'black';
#		Carp::confess (  root::get_hashEntries_as_string ( {'dataset' => $dataset, 'self' => $self }  , 7 , "I have an issue here - why do I not get the right min and max for the plot here?" ,100));
		$simpleWhiskerPlot->AddDataset($dataset);
		push(
			@return,
			$simpleWhiskerPlot->plot(
				{
					'x_res'   => 400,
					'y_res'   => 400,
					'outfile' => $outpath
					  . "/$file_modifier" . "_"
					  . join( "_", @$line[ $self->Header_Position ( '__data_description__') ] ),
					'x_min' => 100,
					'x_max' => 400 - 40,
					'y_min' => 40,            # oben
					'y_max' => 400 - 40,      # unten
					'mode'  => 'landscape',
				}
			)
		);
	}
	return \@return;
}

sub Describe_Samples {
	my ( $self, $latex_section ) = @_;
	return 0 unless ( ref($latex_section) =~ m/Section$/ );
	my $str = "\\begin{description}\n";
	foreach ( @{ $self->{'sample_ids'} } ) {
		$str .= "\\item[Group $_->{'tag'}] samples: "
		  . join( ", ", @{ $_->{'samples'} } ) . "\n";
	}
	$str .= "\\end{description}\n";
	$latex_section->AddText(
'For this phenotype we did apply a Kruskal Wallis statistics implemented in R. We have used the groups '
		  . $str
		  . ".\n" );
	return 1;
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
	foreach my $index_name ( keys %{ $self->{'index'} } ) {
		$return->{'index'}->{$index_name} = {};
	}
	foreach my $index_name ( keys %{ $self->{'uniques'} } ) {
		$return->{'uniques'}->{$index_name} = {};
	}
	$return->{'subsets'} = $self->{'subsets'};
	return $return;
}

1;
