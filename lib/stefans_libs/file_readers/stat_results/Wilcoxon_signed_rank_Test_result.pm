package stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result;

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

You can open and plot Wilcoxon_signed_rank_Test results using this module.

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
			'w'            => 3,
			'fold change'  => 4
		},
		'default_value' => [],
		'header' =>
		  [ 'Probe Set ID', 'Gene Symbol', 'p value', 'w', 'fold change' ],
		'data'         => [],
		'index'        => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class
	  if ( $class eq
"stefans_libs::file_readers::stat_results::Wilcoxon_signed_rank_Test_result"
	  );

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
	if ( $value =~ m/group(\d)->/ ) {
		my ($group) = ($1);

		## OK we have a new group - and that is group
		Carp::confess(
"we have a group number error with group '$value' - we had expected to read group $self->{'number_of_read_groups'}\ first!\n"
		) unless ( $group eq $self->{'number_of_read_groups'} + 1 );
		@{ $self->{'sample_ids'} }[ $self->{'number_of_read_groups'} ] =
		  { 'tag' => $group, 'samples' => [] };
		$self->{'number_of_read_groups'}++;
		$self->{'header_position'}->{$value} = $self->{'last_group'} =
		  scalar( @{ $self->{'header'} } );
		@{ $self->{'header'} }[ $self->{'last_group'} ] = $value;
		return $self->{'header_position'}->{$value};

	}
	else {
		## As it is no group definition it has to be a sample id
#print "we stuff the sample $value into the sample group ".($self->{'number_of_read_groups'}-1)."\n";
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

sub After_Data_read {
	my ($self) = @_;
	$self->Rename_Column( 'p value', 'p-value' );
}

=head2 plot ( $outpath )

I will create a list of piczures, that depict the change in expression ofver the analyzed groups.

=cut

sub plot {
	my ( $self, $outpath, $type, $exclude_00 ) = @_;
	return [] if ( scalar( $self->{'data'} ) == 0 );
	$self->define_subset( '__data_description__', ['Probe Set ID', 'Gene Symbol'] );
#	Carp::confess ( "the outpath $outpath does not exist!\n" ) unless ( -d $outpath );
	my ( $line, $error, $figure, @groups, $dataset, $simpleWhiskerPlot, @return,
		@temp, $file_modifier, $geneName );
	$type = '' unless ( defined $type );
	print
"we are at the file $self->{'read_filename'} and should plot to '$outpath'\n";
	## I first need to change the tag info - thatis unfortunately in the data lines!!
	@{ $self->{'sample_ids'} }[0]->{'tag'} =
	  @{ @{ $self->{'data'} }[0] }[ $self->Header_Position('group1->') ] unless ( defined @{ $self->{'sample_ids'} }[0]->{'tag'});
	@{ $self->{'sample_ids'} }[1]->{'tag'} =
	  @{ @{ $self->{'data'} }[0] }[ $self->Header_Position('group2->') ] unless ( defined @{ $self->{'sample_ids'} }[1]->{'tag'});
	print "I think we got the group names right - or? "
	  . @{ $self->{'sample_ids'} }[0]->{'tag'} . " and "
	  . @{ $self->{'sample_ids'} }[1]->{'tag'} . "\n";
	$error = ref($self) . ':plot($outpath) - the path does not exist!' . "\n"
	  unless ( -d $outpath );
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
	die
"We have no initial filename or we are unable to parse that into a file modifier!\n'$self->{'read_filename'}'\n'$file_modifier'"
	  unless ( $file_modifier =~ m/\w/ );
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$line = @{ $self->{'data'} }[$i];
		if (  -f $outpath
			. "/$file_modifier" . "_"
			. join( "_", @$line[  $self->Header_Position ( '__data_description__')  ] )
			. ".svg" )
		{
			push( @return,
				    $outpath
				  . "/$file_modifier" . "_"
				  . join( "_", @$line[  $self->Header_Position ( '__data_description__')  ] )
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
		## And now I need to remove the 00 values
		if ($exclude_00) {
			my ( @data, $i );
			my @temp = ( keys %{ $dataset->{'data'} } );
			foreach my $group (@temp) {
				@data = undef;
				$i    = 0;
				foreach ( @{ $dataset->{'data'}->{$group} } ) {
					$data[ $i++ ] = $_;
				}
				$dataset->{'data'}->{$group} = [@data];
				Carp::confess(
					"We have a problem here - there -No data for group $group!"
				);
			}

		}
		$dataset->{'order_array'} = \@labels;
		$dataset->{'name'}        = 'p = ' . sprintf( '%.1e', @$line[$self->Header_Position('p-value')] );
		$dataset->{'color'}       = $colors[0] || 'black';
		$simpleWhiskerPlot->AddDataset($dataset);
		push(
			@return,
			$simpleWhiskerPlot->plot(
				{
					'x_res'   => 400,
					'y_res'   => 400,
					'outfile' => $outpath . "/" 
					  . $file_modifier . "_"
					  . join( "_",
						split( /[\s<>]/, join( "_", @$line[ $self->Header_Position ( '__data_description__') ] ) ) ),
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
'For this phenotype we did apply a Wilcoxon signed rank statistics implemented in R. We have used the groups '
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
