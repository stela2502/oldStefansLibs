package data_table;

#  Copyright (C) 2008 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a  of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.


## use stefans_libs::flexible_data_structures::data_table;
use strict;
use warnings;
use Carp qw(cluck);
use stefans_libs::root;
use stefans_libs::flexible_data_structures::data_table::arraySorter;
use stefans_libs::plot::simpleBarGraph;
use stefans_libs::plot::simpleWhiskerPlot;

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'                 => $debug,
		'arraySorter'           => arraySorter->new(),
		'header_position'       => {},
		'default_value'         => [],
		'header'                => [],
		'data'                  => [],
		'index'                 => {},
		'__LaTeX_column_mods__' => {},
		'__HTML_column_mods__'  => {},
		'last_warning'          => '',
		'subsets'               => {}
	};

	bless $self, $class if ( $class eq "data_table" );

	return $self;

}

=head2 plot_columns_as_whisker_plot({
	'title'
	'y_title'
	'outfile'
	'columns'
	'x_res'
	'y_res'
	'x_border'
	'y_border'
});

Here we expect you to use the column titles as data keys.
Hence all data in the respective columns has to be numeric!

=cut

sub plot_columns_as_whisker_plot {
	my ( $self, $hash ) = @_;
	my ($error);
	$error = '';
	foreach (
		'title', 'x_title', 'y_title',  'outfile', 'columns',
		'x_res', 'y_res',   'x_border', 'y_border'

	  )
	{
		$error .= "missing data for key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	unless ( ref( $hash->{'columns'} ) eq "ARRAY" ) {
		$hash->{'columns'} = [ $hash->{'columns'} ];
	}
	my ( @data_columns, $dataset, $x_position, $Graph );
	## I need to create an empty picture to create the colors!
	my $figure = simpleWhiskerPlot->new();
	$figure->_createPicture();
	my @colors;
	foreach (
		'green', 'red',    'blue',  'pink', 'tuerkies1',
		'rosa',  'orange', 'brown', 'grey'
	  )
	{
		push( @colors, $figure->{'color'}->{$_} );
	}
	$dataset = {
		'name'         => $self->{'filename'},
		'data'         => {},
		'order_array'  => $hash->{'columns'},
		'color'        => $colors[2],
		'border_color' => $colors[2]
	};
	$dataset->{'name'} = 'data' unless ( defined $dataset->{'name'} );
	foreach ( @{ $hash->{'columns'} } ) {
		$dataset->{'data'}->{$_} = $self->getAsArray($_);
	}
	$Graph = simpleWhiskerPlot->new();
	$Graph->AddDataset($dataset);
	$Graph->Ytitle( $hash->{'y_title'} );
	$Graph->Xtitle( $hash->{'x_title'} );
	return $Graph->plot(
		{
			'x_res'   => $hash->{'x_res'},
			'y_res'   => $hash->{'y_res'},
			'outfile' => $hash->{'outfile'},
			'x_min'   => $hash->{'x_border'},
			'x_max'   => $hash->{'x_res'} - $hash->{'x_border'},
			'y_min'   => $hash->{'y_border'},
			'y_max'   => $hash->{'y_res'} - $hash->{'y_border'},
			'mode'    => 'landscape',
		}
	);
}

=head2 plot_as_bar_graph

needed hash keys:
'title'
'y_title'
'outfile'
'data_names_column'
'data_values_columns'
'x_res'
'y_res'
'x_border'
'y_border'

I will use the stefans_libs::plot::simpleBarGraph for plotting

=cut

sub plot_as_bar_graph {
	my ( $self, $hash ) = @_;
	my $error  = '';
	my $figure = simpleBarGraph->new();
	$figure->_createPicture();
	foreach (
		'title',            'y_title',             'outfile',
		'data_name_column', 'data_values_columns', 'x_res',
		'y_res',            'x_border',            'y_border'
	  )
	{
		$error .= "missing data for key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	## now some more checks ...
	my ( @data_columns, $dataset, $x_position, $simpleBarGraph );
	$simpleBarGraph = simpleBarGraph->new();
	$error .=
	  "I do not know the header position for $hash->{'data_name_column'}\n"
	  unless ( defined $self->Header_Position( $hash->{'data_name_column'} ) );
	foreach ( @{ $hash->{'data_values_columns'} } ) {
		push( @data_columns, ( $self->Header_Position($_) ) );
		$error .= "I do not know the data column $_\n"
		  unless ( defined $self->Header_Position($_) );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	my @colors;
	foreach (
		'green', 'red',    'blue',  'pink', 'tuerkies1',
		'rosa',  'orange', 'brown', 'grey'
	  )
	{
		push( @colors, $figure->{'color'}->{$_} );
	}
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$dataset->{'name'} =
		  $self->get_value_4_line_and_column( $i, $hash->{'data_name_column'} );
		$dataset->{'data'}        = {};
		$dataset->{'order_array'} = [];
		foreach $x_position (@data_columns) {
			push(
				@{ $dataset->{'order_array'} },
				@{ $self->{'header'} }[$x_position]
			);
			$dataset->{'data'}->{ @{ $self->{'header'} }[$x_position] } =
			  { 'y' => @{ @{ $self->{'data'} }[$i] }[$x_position] };
		}
		$dataset->{'color'} = $colors[$i] || 'black';
		$dataset->{'border_color'} = $dataset->{'color'};
		$simpleBarGraph->AddDataset($dataset);
	}
	## OK and now we should be able to plot the figure!
	$simpleBarGraph->Ytitle( $hash->{'y_title'} );
	$simpleBarGraph->Title( $hash->{'title'} );
	if ( defined $hash->{'x_min_value'} ) {
		$simpleBarGraph->X_Min( $hash->{'x_min_value'} );
	}
	if ( defined $hash->{'x_max_value'} ) {
		$simpleBarGraph->X_Max( $hash->{'x_max_value'} );
	}
	if ( defined $hash->{'y_min_value'} ) {
		$simpleBarGraph->Y_Min( $hash->{'y_min_value'} );
	}
	if ( defined $hash->{'y_max_value'} ) {
		$simpleBarGraph->Y_Max( $hash->{'y_max_value'} );
	}
	$simpleBarGraph->plot(
		{
			'x_res'   => $hash->{'x_res'},
			'y_res'   => $hash->{'y_res'},
			'outfile' => $hash->{'outfile'},
			'x_min'   => $hash->{'x_border'},
			'x_max'   => $hash->{'x_res'} - $hash->{'x_border'},
			'y_min'   => $hash->{'y_border'},                       # oben
			'y_max'   => $hash->{'y_res'} - $hash->{'y_border'},    # unten
			'mode'    => 'landscape',
		}
	);
	return $hash->{'outfile'};
}

sub getCopy_4_values {
	my ( $self, $index, @values ) = @_;
	return $self unless ( defined $values[0] );
	unless ( defined $self->{'index'}->{$index} ) {
		return undef unless ( defined $self->Header_Position($index) );
		$self->createIndex($index);
	}
	my $dataset = data_table->new();
	my $temp;
	$dataset->{'header'} = [ @{ $self->{'header'} } ];
	while ( my ( $key, $value ) = each %{ $self->{'header_position'} } ) {
		$dataset->{'header_position'}->{$key} = $value;
	}
	foreach my $subset ( %{ $self->{'subsets'} } ) {
		$dataset->{'subsets'} = $subset;
	}
	foreach my $value (@values) {

		#warn "we try to get the value for the search $index -> $value\n";
		foreach my $i (
			$self->get_rowNumbers_4_columnName_and_Entry( $index, $value ) )
		{

	   #warn ref($self)."::we got a line for the query $index -> $value ($i)\n";

			unless (
				scalar(
					$self->get_rowNumbers_4_columnName_and_Entry(
						$index, $value
					)
				) > 0
			  )
			{
				$self->{'last_warning'} = ref($self)
				  . "::we did not find an column entry for the search '$index', '$value'\n";
			}
			else {
				$temp = {};
				foreach ( my $col = 0 ; $col < @{ $self->{'header'} } ; $col++ )
				{
					$temp->{ @{ $self->{'header'} }[$col] } =
					  @{ @{ $self->{'data'} }[$i] }[$col];
				}
				$dataset->Add_Dataset($temp);
			}

		}
	}
	return $dataset;

}

=head2 select_where ( <column name>, <sorting_function as CODE object> )

This function will select a subset of the data from a table based on the selection make
and return a new data_table object with the selected lines.

=head3 Example

the code 
{
my $data_table = data_table->new();
$data_table->Add_db_result ( ['name','gender'], [['Mikey Maus', 'male'],['Minni','female'], ['George Bush', 'male']]);
retrun $data_table->select_where ( 'gender', sub { return shift eq 'male'} );
}
will return a data_table with the lines ['Mikey Maus', 'male'] and ['George Bush', 'male'].

=cut

sub select_where {
	my ( $self, $col_name, $function_ref ) = @_;
	my $error = '';
	$error .=
	  ref($self) . ":select_where - we do not have a column named '$col_name'\n". "only '".join("'; '",@{$self->{'header'}})."'\n"
	  unless ( defined $self->Header_Position($col_name) );
	$error .=
	  ref($self)
	  . ":select_where - we need a function ref at start up - not '$function_ref'\n"
	  unless ( ref($function_ref) eq "CODE" );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my $return = $self->_copy_without_data();
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$return->AddDataset( $self->get_line_asHash($i) )
		  if (
			&$function_ref(
				$self->get_value_4_line_and_column( $i, $col_name )
			)
		  );
	}
	return $return;
}

=head2 copy_table 

For some occasions it might be interesting to just copy a table object...
	
=cut

sub copy {
	my ($self) = @_;
	my $return = $self->_copy_without_data();
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$return->AddDataset( $self->get_line_asHash($i) );
	}
	return $return;
}

=head2 pivot_table ( { 
	'grouping_column' => <col name>, 
	'Sum_data_column' => <col name>, 
	'Sum_target_columns' => [<col_name>..], 
	'Suming_function' => sub{} 
})

This function will create a key from the 'grouping_column' and will push the 'Sum_data_column's 
in one array spanning all the columns in the table datset that contain the 'Sum_data_column' key
as argument into the 'Suming_function'. The result from this function will be put into the resulting table
'Sum_target_columns'.

And now a little more detailed: I have a 3X4 table with the columns name, age and sex.
The data is A,30,m; B,40,m; C,20,w; D,21,f;
If I now want to get the mean age separated by sex, and a list of the names for each sex, 
you need to do that:

=over 3

=item 1. I need to define a subset named e.g. data that 'joins' the two columns 'name' and 'age'
	
data_table->define_subset ( 'data' ['name','age']);

=item 2. I call the pivot_table function

	my $pivot_table =data_table->pivot_table ( {
		'grouping_column' => 'sex',
		'Sum_data_column' => 'data',
		'Sum_target_columns' => [ 'mean age', 'names list'],
		'Suming_function' => sub {
			my $sum = 0;
			@list;
			for ( my $i = 0; $i < @_; $i+=2 ){ 
				##do the +=2 because we have two columns per data line 
				$sum += $_[$i];
				push ( @list, $_[$i+1]);
			}
			return $sum / scalar(@list), join(" ", @list );
		}
	})


=back

And then you are finished. The returned object will also be a data_table 
with the columns 'sex', 'mean age' and 'names list'.

=cut

sub pivot_table {
	my ( $self, $hash ) = @_;
	my $error = '';
	$error .= "I do not know the 'grouping_column'\n"
	  unless ( defined $self->Header_Position( $hash->{'grouping_column'} ) );
	$error .= "I do not know the 'Sum_data_column'\n"
	  . join( " ", @{ $self->{'header'} } ) . "\n"

	  unless ( defined $self->Header_Position( $hash->{'Sum_data_column'} ) );
	unless ( ref( $hash->{'Sum_target_columns'} ) eq "ARRAY" ) {
		$error .= "Sorry, but I need an array of 'Sum_target_columns'\n";
	}
	elsif ( scalar( @{ $hash->{'Sum_target_columns'} } ) == 0 ) {
		$error .= "I need at least one 'Sum_target_columns' column name\n";
	}
	Carp::confess(
		root::get_hashEntries_as_string( $hash, 3,
			ref($self) . "::pivot_table arguments:" )
		  . $error
	) if ( $error =~ m/\w/ );

	## get all keys
	$self->createIndex( $hash->{'grouping_column'} );
	my @keys = $self->getIndex_Keys( $hash->{'grouping_column'} );

	## create and initialize the pivot_table
	my $return_table = data_table->new();
	$return_table->Add_2_Header( $hash->{'grouping_column'} );
	foreach ( @{ $hash->{'Sum_target_columns'} } ) {
		$return_table->Add_2_Header($_);
	}

	## calculate
	my ( @temp, $row_id, $key, $data_set );
	foreach $key ( sort @keys ) {
		@temp = undef;
		foreach $row_id (
			$self->get_rowNumbers_4_columnName_and_Entry(
				$hash->{'grouping_column'}, $key
			)
		  )
		{
			push(
				@temp,
				$self->get_value_4_line_and_column(
					$row_id, $hash->{'Sum_data_column'}
				)
			);
		}
		shift(@temp) unless ( defined $temp[0] );
		@temp = &{ $hash->{'Suming_function'} }(@temp);
		$data_set->{ $hash->{'grouping_column'} } = $key;
		for (
			$row_id = 0 ;
			$row_id < @{ $hash->{'Sum_target_columns'} } ;
			$row_id++
		  )
		{
			$data_set->{ @{ $hash->{'Sum_target_columns'} }[$row_id] } =
			  $temp[$row_id];
		}
		$return_table->AddDataset($data_set);
	}

	return $return_table;

}

=head2 calculate_on_columns ( {
	'data_column' => <col name>, 
	'target_column' => <new col name>,
	'function' => sub{}
});

This function will allow you to define your own procedures to apply to the table dataset.
Keep in mind, that if you need more than one column for the calculation, 
you first need to create a subset for the needed columns and then use the subset name as data column. 

=cut

sub calculate_on_columns {
	my ( $self, $hash ) = @_;
	$hash->{'function_as_string'} = ''
	  unless ( defined $hash->{'function_as_string'} );
	my $error = '';
	foreach ( 'function', 'data_column', 'target_column' ) {
		$error .=
		  ref($self)
		  . "::calculate_on_columns - the named option '$_' is missing\n"
		  unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	$self->Add_2_Header( $hash->{'target_column'} )
	  unless ( defined $self->Header_Position( $hash->{'target_column'} ) );
	my $insert_position = $self->Header_Position( $hash->{'target_column'} );
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$! = '';
		@{ @{ $self->{'data'} }[$i] }[$insert_position] =
		  &{ $hash->{'function'} }(
			$self->get_value_4_line_and_column( $i, $hash->{'data_column'} ) );
		Carp::confess(
"An error occured while executing the variable_function on line $i with variable '"
			  . join( "','", $self->get_value_4_line_and_column( $i, $hash->{'data_column'} ))
			  . "':\nAnd the internal error = '$!'\n"
			  . "The function as string did contain '$hash->{'function_as_string'}'\n"
		  )
		  if ( $! =~ m/\w/ );
	}
	return 1;
}

sub delete_all_data {
	my ($self) = @_;
	$self->{'data'} = [];
	foreach my $key ( keys( %{ $self->{index} } ) ) {
		$self->{index}->{$key} = {};
	}
	return $self;
}

=head2 value_exists

This function checks an internal index for a value and returns 1 if it found an entry or 0 if it did not find one.

=cut

sub value_exists {
	my ( $self, $index_name, $value ) = @_;
	Carp::confess(
"Sorry, but I do not have an index called $index_name - please create it first!\n"
	) unless ( defined $self->{'index'}->{$index_name} );
	return 0 unless ( defined $value );
	return 1 if ( defined $self->{'index'}->{$index_name}->{$value} );
	return 0;
}

sub getIndex_Keys {
	my ( $self, $index_name ) = @_;
	return () unless ( ref( $self->{'index'}->{$index_name} ) eq "HASH" );
	return ( keys %{ $self->{'index'}->{$index_name} } );
}

=head3 get_column_entries

This function will return a column of the table as areference to an array of values, not including the column title.

=cut

sub getAsArray {
	my ( $self, $col_name ) = @_;
	return $self->get_column_entries($col_name);
}

sub GetAsArray {
	my ( $self, $col_name ) = @_;
	return $self->get_column_entries($col_name);
}

sub get_column_entries {
	my ( $self, $col_name ) = @_;
	my @col_ids = $self->Header_Position($col_name);
	my @return;
	foreach my $array ( @{ $self->{'data'} } ) {
		foreach ( @$array[@col_ids] ) {
			if ( defined $_ ) {
				push( @return, $_ );
			}
			else {
				push( @return, '' );
			}
		}
	}
	return \@return;
}

=head2 get_row_entries ( $row_id, $column_name )

You will get an array of values eitehr for the whole line (no column name set)
or only for the column name.
If you have specified a subset name instead of a normal column line, you will get a list of entries.

=cut

sub get_row_entries {
	my ( $self, $row_id, $column_name ) = @_;
	unless ( defined $column_name ) {
		Carp::confess( "wrong call of the function "
			  . ref($self)
			  . "::get_row_entries($row_id)\n" )
		  if ( $row_id =~ m/\w/ );
		return @{ @{ $self->{'data'} }[$row_id] };
	}
	else {
		return @{ @{ $self->{'data'} }[$row_id] }
		  [ $self->Header_Position($column_name) ];
	}
}

sub get_value_for {
	my ( $self, $index_name, $index_value, $column_name ) = @_;
	my @line_nr =
	  $self->get_rowNumbers_4_columnName_and_Entry( $index_name, $index_value );
	my @return;
	unless ( defined $line_nr[0] ) {

#warn "we ("
#  . $self->Name()
#  . ") did not have an entry for the column $index_name and the value '$index_value'\n";
		return undef;
	}
	unless ( defined $self->Header_Position($column_name) ) {
		warn
		  "we did not have an entry for the header position '$column_name'\n";
		return undef;
	}
	my $i = 0;
	my @temp;
	foreach ( @{ $self->{'data'} }[@line_nr] ) {
		@temp = @$_[ $self->Header_Position($column_name) ];
		@temp = '' unless ( defined $_ );
		push( @return, @temp );
		$i++;
	}
	return (@return);
}

=head2 print_as_gedata ( $outfile )

This function will print the adta as gedata file usable with the Qlucore omics explorer software.
In order to make this possible, we need to have a subset called 'samples'!

=cut

sub print_as_gedata {
	my ( $self, $outfile ) = @_;
	Carp::confess(
		ref($self)
		  . "->print_as_gedata( $outfile) - I do not have a subset called 'samples'!"
	) unless ( defined $self->{'subsets'}->{'samples'} );
	$outfile .= ".gedata" unless ( $outfile =~ m/\.gedata\n/ );
	open( OUT, ">$outfile" )
	  or die "Sorry, but I can not open the outfile '$outfile'\n$!\n";
	## now I need to identify the non sample columns as they have to come first
	my ( @descriptions, $sample_columns );
	foreach ( @{ $self->{'subsets'}->{'samples'} } ) {
		$sample_columns->{$_} = 1;
	}
	for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
		push( @descriptions, @{ $self->{'header'} }[$i] )
		  unless ( $sample_columns->{$i} );
	}
	$self->define_subset( 'descriptions', [@descriptions] );
	print OUT "qlucore\tgedata\tversion 1.0\n\n";
	print OUT scalar( @{ $self->{'subsets'}->{'samples'} } )
	  . "\tsamples\twith\t1\tannotations\n";
	print OUT scalar( @{ $self->{'data'} } )
	  . "\tvariables\twith\t"
	  . scalar(@descriptions)
	  . "\tannotations\n";
	for ( my $i = 1 ; $i < @descriptions ; $i++ ) {
		print OUT "\t";
	}
	print OUT "\tID\t"
	  . join( "\t",
		@{ $self->{'header'} }[ @{ $self->{'subsets'}->{'samples'} } ] )
	  . "\n";
	print OUT join( "\t", @descriptions ) . "\t\t";
	for ( my $i = 1 ; $i < @{ $self->{'subsets'}->{'samples'} } ; $i++ ) {
		print OUT "\t";
	}
	print OUT "\n";
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		print OUT join( "\t", $self->get_row_entries( $i, 'descriptions' ) )
		  . "\t\t"
		  . join( "\t", $self->get_row_entries( $i, 'samples' ) ) . "\n";
	}
	close OUT;
	print "The gedata outfile is here: '$outfile'\n";
}

=head2 red_file

you can read tables using this class.
Use 'read_file(<filename>)' to read a tab separated table file.
Afterwards you can create an index over a column using the 'createIndex(<columnName>)'.
This function will print some warnings and return 'undef' if the index creation fails.

The next cool feature gives you the possibillity to define subsets of the data (column wise).
Thereofer you need to call the 'define_subset(<>subset_name>, [ <column_names> ])' function.
These subsets can then be called for using 
'get_subset_4_columnName_and_entry(<columnName>, <entryName>, <subsetName>)'.
Please make shure, that the columnName is indexed!

And finally we have a cool print feature, that allows you to print only a subset of the 
data you have in the table_dataset!. Just use the print2file(<filename>, <subsetName>) to
print only the entries of a subset into a file. If no subset name is given, we will print the whole file.

=head2 print2file or write_file ( <outfile name>, <subset 2 print>)

This function will print the data table to a file.
If you specify the <subset 2 print> option only the named subset will be printed. 
This option should be the best to reorder the columns.

=cut

sub write_file {
	my ( $self, @array ) = @_;
	return $self->print2file(@array);
}

sub print2file {
	my ( $self, $outfile, $subset ) = @_;
	if ( defined $subset && !defined $self->{'subsets'}->{$subset} ) {
		warn "we do not print, as we do not know the subset '$subset'\n";
		return undef;
	}
	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	if ( $outfile =~ m/txt$/ ) {
		$outfile =~ s/txt$/xls/;
	}
	unless ( $outfile =~ m/xls$/ ) {
		$outfile .= ".xls";
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
	print OUT $self->AsString($subset);
	## now we need to add the keys and indexes and so on....
	unless ( defined $subset ) {
		print OUT "#subsets=";
		@temp = ();
		foreach my $key ( keys %{ $self->{'subsets'} } ) {
			print "we try to print the subset $key\n";
			next unless ( ref( $self->{'subsets'}->{$key} ) eq "ARRAY" );
			$temp[@temp] =
			  "$key;" . join( ";", @{ $self->{'subsets'}->{$key} } );
		}
		print OUT join( "\t", @temp ) . "\n";
		print OUT "#index="
		  . join( "\t", ( keys %{ $self->{'index'} } ) ) . "\n";
		print OUT "#uniques="
		  . join( "\t", ( keys %{ $self->{'uniques'} } ) ) . "\n";
		print OUT "#defaults="
		  . join( "\t", ( @{ $self->{'default_value'} } ) ) . "\n";
	}
	close(OUT);
	print "subset '$subset' written to '$outfile'\n" if ( defined $subset );
	print "all data written to '$outfile'\n";
	return 1;
}

=head2 Name

Use this function to add some description of this dataset.
This information will not be written to a file, but can be accessed using this function.
As this function is used to create the labels for the LaTEX export, I need to get rid of all underscores '_'.
I will just convert them to a space.
=cut

sub Name {
	my ( $self, $name ) = @_;
	$self->{'name'} = $name if ( defined $name );
	$self->{'name'} =~ s/_/ /g;
	return $self->{'name'};
}

=head2 Sort_by

The function expects an array of sort orders.
A sort order is an array containing the columnName and the type of the ordering of that column.
The type of the ordering can be either 'numeric', 'antiNumeric' or 'lexical'.

This function will return a new data_table object that contains all the keys and uniques of the first table, 
but the order of the table is changed.

=cut

sub Sort_by {
	my ( $self, $sortArray ) = @_;
	return $self unless ( ref($sortArray) eq "ARRAY" );
	my ( @sort_Array_new, $i );
	$i = 0;
	foreach my $def_array (@$sortArray) {
		unless ( ref($def_array) eq "ARRAY" ) {
			Carp::confess(
				ref($self)
				  . "::Sort_by -> we need an array of arrays as first argument!\n"
			);
		}
		unless ( scalar(@$def_array) == 2 ) {
			Carp::confess(
				ref($self)
				  . "::Sort_by -> we need an array of arrays containing EXACTLY two entries as first argument!\n"
			);
		}
		unless ( defined $self->Header_Position( @$def_array[0] ) ) {
			Carp::confess(
				    ref($self)
				  . "::Sort_by -> we do not know the column @$def_array[0]\n"
				  . "columns = '"
				  . join( "', '", @{ $self->{'header'} } )
				  . "'\n" );
		}
		unless ( 'lexical numeric antiNumeric' =~ m/@$def_array[1]/ ) {
			Carp::confess(
"we do not support to sort the column @$def_array[0] in mode @$def_array[1]"
			);
		}
		$sort_Array_new[ $i++ ] = {
			'position' => $self->Header_Position( @$def_array[0] ),
			'type'     => @$def_array[1]
		};
	}
	my $data = $self->_copy_without_data();
	$data->Description( $self->Description );
	$data->Add_db_result(
		$self->{header},
		[
			$data->{'arraySorter'}
			  ->sortArrayBy( \@sort_Array_new, @{ $self->{'data'} } )
		]
	);
	return $data;
}

sub Get_first_for_column {
	my ( $self, $column, $amount, $sort_type ) = @_;
	return $self unless ( defined $self->Header_Position($column) );
	return $self unless ( $amount > 0 );
	$self = $self->Sort_by( [ [ $column, $sort_type ] ] );
	my $ret = $self->_copy_without_data();
	my ( @data, $c_entry, $count, $column_nr );
	$c_entry   = '';
	$column_nr = $self->Header_Position($column);
	foreach my $array ( @{ $self->{'data'} } ) {

		unless ( $c_entry eq @$array[$column_nr] ) {
			$c_entry = @$array[$column_nr];
			$count   = 0;
		}
		$data[@data] = $array if ( $count < $amount );
		$count++;
	}
	$ret->Add_db_result( $self->{header}, \@data );
	return $ret;
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
	$return->{'description'}     = $self->{'description'};
	foreach my $index_name ( keys %{ $self->{'index'} } ) {
		$return->{'index'}->{$index_name} = {};
	}
	foreach my $index_name ( keys %{ $self->{'uniques'} } ) {
		$return->{'uniques'}->{$index_name} = {};
	}
	$return->{'subsets'} = $self->{'subsets'};
	return $return;
}

=head2 make_column_LaTeX_p_type ( 'column_name', 'size' )

If the size is given we will set the size of a column to this size.
After that the column entries will be broken if longer than this size in the LaTeX longtable.

=cut

sub make_column_LaTeX_p_type {
	my ( $self, $column_name, $size ) = @_;
	$self->{'column_p_type'} = {}
	  unless ( ref( $self->{'column_p_type'} ) eq "HASH" );
	if ( defined $size ) {
		## I will not check for logics!
		$self->{'column_p_type'}->{$column_name} = $size;
	}
	return $self->{'column_p_type'}->{$column_name};
}

=head2 LaTeX_modification_for_column (  {column_name, before, after} )

You can here specify which modification I should apply before I print a entry with AsLatexLongtable()

That might be especially useful to apply type or color changes to a whole column.

You will get the hash { 'before', 'after' } back even if you have not defined that data previously.

But I will check if I know the column_name (and die if not)!

=cut

sub LaTeX_modification_for_column {
	my ( $self, $hash ) = @_;

	#$before, $after, $column_name
	my $error = '';
	if ( ref($hash) eq "HASH" ) {
		## OK we need a 'column_name'
		unless ( defined $hash->{'column_name'} ) {
			$error .=
"Sorry, but we need a key 'column_name' in the hash that you gave me!\n";
		}
		elsif ( !defined $self->Header_Position( $hash->{'column_name'} ) ) {
			$error .=
			  "Sorry, but I do not have a column '$hash->{'column_name'}'!\n";
		}
		Carp::confess($error) if ( $error =~ m/\w/ );

		$self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} } =
		  { 'before' => '', 'after' => '' }
		  unless (
			ref( $self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} } )
			eq "HASH" );
		if ( defined $hash->{'before'} ) {
			$self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'before'} = $hash->{'before'};
		}
		if ( defined $hash->{'after'} ) {
			$self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'after'} = $hash->{'after'};
		}
	}
	elsif ( $hash =~ m/\w/ ) {
		if ( !defined $self->Header_Position($hash) ) {
			$error .= "Sorry, but I do not have a column '$hash'!\n";
		}
		Carp::confess($error) if ( $error =~ m/\w/ );
		$self->{'__LaTeX_column_mods__'}->{$hash} =
		  { 'before' => '', 'after' => '' }
		  unless ( ref( $self->{'__LaTeX_column_mods__'}->{$hash} ) eq "HASH" );
		$hash = { 'column_name' => $hash };
	}

	return $self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} };
}

=head2 HTML_modification_for_column ( 
	{
		 'column_name' => <STR>, 
		 'before' => 'HTML modification'
		 'after' => 'HTML_modifcation'
		 'td' => 'a modification of the td value'
		 'tr' => 'a modication of the tr value'
	});

=cut

sub HTML_modification_for_column {
	my ( $self, $hash ) = @_;

	#$before, $after, $column_name
	my $error = '';
	if ( ref($hash) eq "HASH" ) {
		## OK we need a 'column_name'
		unless ( defined $hash->{'column_name'} ) {
			$error .=
"Sorry, but we need a key 'column_name' in the hash that you gave me!\n";
		}
		elsif ( !defined $self->Header_Position( $hash->{'column_name'} ) ) {
			$error .=
			  "Sorry, but I do not have a column '$hash->{'column_name'}'!\n";
		}
		Carp::confess($error) if ( $error =~ m/\w/ );

		$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} } =
		  { 'before' => '', 'after' => '' }
		  unless (
			ref( $self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} } )
			eq "HASH" );
		if ( defined $hash->{'before'} ) {
			$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'before'} = $hash->{'before'};
		}
		if ( defined $hash->{'after'} ) {
			$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'after'} = $hash->{'after'};
		}
		if ( defined $hash->{'tr'} ) {
			$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'tr'} = $hash->{'tr'};
		}
		if ( defined $hash->{'td'} ) {
			$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'td'} = $hash->{'td'};
		}
	}
	elsif ( $hash =~ m/\w/ ) {
		if ( !defined $self->Header_Position($hash) ) {
			$error .= "Sorry, but I do not have a column '$hash'!\n";
		}
		Carp::confess($error) if ( $error =~ m/\w/ );
		$self->{'__HTML_column_mods__'}->{$hash} =
		  { 'before' => '', 'after' => '' }
		  unless ( ref( $self->{'__HTML_column_mods__'}->{$hash} ) eq "HASH" );
		$hash = { 'column_name' => $hash };
	}
	return $self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} };
}

=head2 AsLatexLongtable

This function will convert the table into a LaTEX lingtable string that you can use for any LaTEX document.

=cut

sub __Latex_header{
	my ( $self, @values ) = @_;
	return join( " & ",@values ) if ( defined $values[0]);
	return join( " & ",@{ $self->{'header'} } );
}
sub AsLatexLongtable {
	my ( $self, $subset, $centering_str ) = @_;
	unless ( defined $centering_str ) {
		$centering_str = 'c';
		$self->{'last_warning'} =
		  ref($self) . "::AsLatexLongtable layout set to centering\n";
	}
	unless ( "clr" =~ m/$centering_str/ ) {
		$self->{'last_warning'} =
		  ref($self) . "::AsLatexLongtable layout set to centering\n";
		$centering_str = 'c';
	}
	my ( $modifiers, $position_2_header, $temp_str );
	my $str = "\n\\begin{longtable}{|";
	if ( defined $subset ) {
		my @temp_line_array;
		my $i = 0;
		foreach my $header_str (
			@{ $self->{'header'} }[ $self->define_subset($subset) ] )
		{
			$position_2_header->{$i} = $header_str;
			$i++;
			if ( defined $self->make_column_LaTeX_p_type($header_str) ) {
				$str .=
				  "p{" . $self->make_column_LaTeX_p_type($header_str) . "}|";
			}
			else {
				$str .= "$centering_str|" if ( $header_str =~ m/\w/ );
			}
		}
		$str .= "}\n";
		$str =~ s/c/l/;
		$str .=
		  "\\hline\n"
		  . $self->__Latex_header(@{ $self->{'header'} }[ $self->define_subset($subset) ] )
		  . "\\\\\n"
		  . "\\hline\n\\hline\n\\endhead\n";
		$str =~ s/_/\\_/g;
		$str .=
"\\hline \\multicolumn{$i}{|r|}{{Continued on next page}} \\\\ \n\\hline\n\\endfoot\n";
		$str .= "\\hline \\hline\n\\endlastfoot\n";
		foreach my $data ( @{ $self->{'data'} } ) {
			@temp_line_array = @$data[ $self->define_subset($subset) ];
			for ( my $position = 0 ;
				$position < @temp_line_array ; $position++ )
			{
				$modifiers =
				  $self->LaTeX_modification_for_column(
					$position_2_header->{$position} );
				$temp_str = $temp_line_array[$position];
				$temp_str = '' unless ( defined $temp_str );
				$temp_str =~ s/#/\\#/g;
				$temp_str =~ s/&/\\&/g;
				$temp_str =~ s/_/\\_/g;
				$str .= " "
				  . $modifiers->{'before'}
				  . $temp_str
				  . $modifiers->{'after'} . " &";
			}
			chop($str);
			$str .= " \\\\\n";
		}
		$str .= "\\end{longtable}\n\n";
	}
	else {
		my (@temp_line_array);
		my $i = 0;
		foreach my $header_str ( @{ $self->{'header'} } ) {
			$position_2_header->{ $i++ } = $header_str;
			if ( defined $self->make_column_LaTeX_p_type($header_str) ) {
				$str .=
				  "p{" . $self->make_column_LaTeX_p_type($header_str) . "}|";
			}
			else {
				$str .= "$centering_str|" if ( $header_str =~ m/\w/ );
			}
		}
		$str .= "}\n";
		$str .=
		    "\\hline\n"
		  . $self->__Latex_header()
		  . "\\\\\n"
		  . "\\hline\n\\hline\n\\endhead\n";
		$str .=
		    "\\hline \\multicolumn{"
		  . scalar( @{ $self->{'header'} } )
		  . "}{|r|}{{Continued on next page}} \\\\ \n\\hline\n\\endfoot\n";
		$str =~ s/_/\\_/g;
		$str .= "\\hline \\hline\n\\endlastfoot\n";
		foreach my $data ( @{ $self->{'data'} } ) {
			@temp_line_array = @$data;
			for ( my $position = 0 ;
				$position < @temp_line_array ; $position++ )
			{
				$modifiers =
				  $self->LaTeX_modification_for_column(
					$position_2_header->{$position} );
				$temp_str = $temp_line_array[$position];
				$temp_str = '' unless ( defined $temp_str );
				$temp_str =~ s/#/\\#/g;
				$temp_str =~ s/&/\\&/g;
				$temp_str =~ s/_/\\_/g;
				$str .= " "
				  . $modifiers->{'before'}
				  . $temp_str
				  . $modifiers->{'after'} . " &";
			}
			chop($str);
			$str .= "\\\\\n";
		}
		$str .= "\\end{longtable}\n\n";
	}
	return $str;
}

sub setDefaultValue {
	my ( $self, $col_name, $default_value ) = @_;
	foreach my $col_nr ( $self->Header_Position($col_name) ) {
		@{ $self->{'default_value'} }[$col_nr] = $default_value;
	}
	return 1;
}

sub count_query_on_lines_to_column {
	my ( $self, $query_hash, $column_name, @columns ) = @_;
	my $column_id = $self->Header_Position($column_name);
	my ( $count, $val, @used_cols );

	unless ( defined $columns[0] ) {
		for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
			push( @used_cols, $i );
		}
	}
	elsif ( defined $columns[1] ) {
		## I expect you gave me a list of columns
		foreach my $col_names (@columns) {
			push( @used_cols, $self->Header_Position($col_names) )
			  if ( defined $self->Header_Position($col_names) );
		}
	}
	else {
		## I expect you wanted to do a pattern matching...
		foreach my $col_names ( @{ $self->{'header'} } ) {
			push( @used_cols, $self->Header_Position($col_names) )
			  if ( $col_names =~ m/$columns[0]/ );
		}
	}

	unless ( defined $column_id ) {
		$self->Add_2_Header($column_name);
	}
	if ( defined $query_hash->{'exact'} ) {
		foreach my $lineArray ( @{ $self->{'data'} } ) {
			$count = 0;
			foreach $val ( @$lineArray[@used_cols] ) {
				$count++ if ( $val eq $query_hash->{'exact'} );
			}
			@$lineArray[$column_id] = "$count";
		}
	}
	elsif ( defined $query_hash->{'like'} ) {
		foreach my $lineArray ( @{ $self->{'data'} } ) {
			$count = 0;
			foreach $val ( @$lineArray[@used_cols] ) {
				$count++ if ( $val =~ m/$query_hash->{'like'}/ );
			}
			@$lineArray[$column_id] = "$count";
		}
	}
	return 1;
}

sub getDefault_values {
	my ( $self, $col_name ) = @_;
	my @return;
	foreach my $col_nr ( $self->Header_Position($col_name) ) {
		@{ $self->{'default_value'} }[$col_nr] = ''
		  unless ( defined @{ $self->{'default_value'} }[$col_nr] );
		push( @return, @{ $self->{'default_value'} }[$col_nr] );
	}
	return (@return);
}

sub getAllDefault_values {
	my ($self) = @_;
	my @return;
	for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
		unless ( defined @{ $self->{'default_value'} }[$i] ) {
			push( @return, '' );
		}
		else {
			push( @return, @{ $self->{'default_value'} }[$i] );
		}
	}
	return @return;
}

sub print {
	my $self = shift;
	return $self->AsString();
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
		$str .= $self->__header_as_string(@{ $self->{'header'} }[ $self->define_subset($subset) ] );
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
		$str .= $self->__header_as_string();
		@default_values = $self->getAllDefault_values();
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

sub __header_as_string {
	my ( $self ,@values) = @_;
	unless ( defined $values[0] ){
	return  join( $self->line_separator(), @{ $self->{'header'} } ) . "\n";
	}
	else {
		return  join( $self->line_separator(), @values ) . "\n";
	}
}

=head2 Add_2_Header

If you want to create a table use this function to create the column headers first. 
The order you create the columns will be the order they show up in the outfile.

=cut

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		print "we add the column '$value'\n" if ( $self->{'debug'} );
		$self->{'header_position'}->{$value} = scalar( @{ $self->{'header'} } );
		${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] = $value;
		${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ] =
		  '';
	}
	return $self->{'header_position'}->{$value};
}

sub Header_Position {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	if ( $value eq "ALL" ) {
		return ( 0 .. scalar( @{ $self->{'header'} } ) - 1 );
	}
	unless ( defined $self->{'header_position'}->{$value} ) {
		return @{ $self->{'subsets'}->{$value} }
		  if ( ref( $self->{'subsets'}->{$value} ) eq "ARRAY" );
	}
	return $self->{'header_position'}->{$value};
}

sub rename_column {
	my ( $self, $old_name, $new_name ) = @_;
	unless ( defined $self->{'header_position'}->{$old_name} ) {
		warn ref($self)
		  . "::rename_column -> sorry - we did not have the column '$old_name'!\n";
		return undef;
	}
	return undef unless ( defined $new_name );
	${ $self->{'header'} }[ $self->{'header_position'}->{$old_name} ] =
	  $new_name;
	$self->{'header_position'}->{$new_name} =
	  $self->{'header_position'}->{$old_name};
	delete( $self->{'header_position'}->{$old_name} );
	return 1;
}

=head2 line_separator

Using this function, you can change the standars column separator "\t" to some value you would prefere.

=cut

sub line_separator {
	my ( $self, $line_separator ) = @_;
	$self->{'line_separator'} = $line_separator if ( defined $line_separator );
	$self->{'line_separator'} = "\t"
	  unless ( defined $self->{'line_separator'} );
	return $self->{'line_separator'};
}

=head2 string_separator (<separating string like ">)

This function adds a string separator to the file read process.
The column entries will not be written with this string if you write the file again.

=cut

sub string_separator {
	my ( $self, $string_separator ) = @_;
	$self->{'string_separator'} = $string_separator
	  if ( defined $string_separator );
	$self->{'string_separator'} = ''
	  unless ( defined $self->{'string_separator'} );

	#print "we have a string_separator '$self->{'string_separator'}'\n";
	return $self->{'string_separator'};
}

sub pre_process_array {
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	return 1;
}

sub _add_data_hash {
	my ( $self, $array ) = @_;
	return 1 if ( $self->Reject_Hash($array) );

	#print "we add the data ".join(";", @$array )."\n";
	push( @{ $self->{'data'} }, $array );
	return 1;
}

sub parse_from_string {
	my ( $self, $string ) = @_;
	my @data;
	my @temp;
	unless ( ref($string) eq "ARRAY" ) {
		@data = split( "\n", $string );
	}
	else {
		@data = @$string;
	}
	$self->{'description'} = [];
	my ( @line, $value, @description, $split_string, $string_separator );
	$string_separator = $self->string_separator();
	$split_string =
	    $self->string_separator()
	  . $self->line_separator()
	  . $self->string_separator();
	$self->pre_process_array( \@data );
	##print "we will try to use the string '$split_string' to split the string\n";
	foreach (@data) {
		chomp($_);
		if ( $_ =~ m/^#+(.+)/ && scalar( @{ $self->{'data'} } ) == 0 ) {
			if ( defined @{ $self->{'header'} }[0] ) {
				## that is only true for the interfaces!
				@temp = split( $split_string, $1 );
				foreach (@temp) {
					$self->Add_2_Header($_);
				}
				next if ( $temp[0] eq @{ $self->{'header'} }[0] );
			}
			push( @description, [ split( $split_string, $1 ) ] );
			next;
		}
		## but there might also be some comments on the end of the file
		elsif ( $_ =~ m/^#+(.+)/ ) {
			if ( $_ =~ m/^#subsets=(.*)/ ) {
				@line = split( "\t", $1 );
				foreach my $subset (@line) {
					@temp                         = split( ";", $subset );
					$subset                       = shift(@temp);
					$self->{'subsets'}->{$subset} = [@temp];
				}
				next;
			}
			if ( $_ =~ m/^#index=(.*)/ ) {
				@line = split( "\t", $1 );
				foreach my $subset (@line) {
					$self->{'index'}->{$subset} = {};
				}
				next;
			}
			if ( $_ =~ m/^#uniques=(.*)/ ) {
				@line = split( "\t", $1 );
				foreach my $subset (@line) {
					$self->{'uniques'}->{$subset} = {};
				}
				next;
			}
			if ( $_ =~ m/^#defaults=(.*)/ ) {
				@line = split( "\t", $1 );
				for ( my $i = 0 ; $i < @line ; $i++ ) {
					@{ $self->{'default_value'} }[$i] = $line[$i];
				}
				next;
			}
		}
		## and now we either hit the column headers, or we hit the first data line
		if ( defined $self->string_separator() ) {
			$_ =~ s/^$string_separator//;
			$_ =~ s/$string_separator$//;
		}
		@line = split( /$split_string/, $_ );
		if ( defined @{ $self->{'header'} }[0] ) {

#Carp::confess ("You have a table with only one column??\n$_\n" )unless ( defined $line[1]);
			## we have the header info - therefore we now have hit the data part!
			if ( @{ $self->{'header'} }[1] eq $line[1] ) {
				my $position;
				## Just check if the interafce got the right column header here!
				for ( my $i = 0 ; $i < @line ; $i++ ) {
					$position = $self->Add_2_Header( $line[$i] );
					Carp::confess(
"there is a file type mismatch! we have the column header $line[$i] at position $i but we "
						  . "expect it to be on position $position\n" )
					  unless ( $i == $position );
				}
				next;
			}    ## that is necessary for the new data interfaces
			push( @{ $self->{'data'} }, [@line] );
		}
		elsif (scalar(@description) > 0
			&& scalar( @{ $description[ @description - 1 ] } ) >=
			scalar(@line) )
		{
			## Most probably, the header line had a '#' in front
			@temp = @{ pop(@description) };

 #			print "we splice a string, got a line, but no header was defined.\n".
 #			"Therefore we checked if the last description line could be the header:\n".
 #			join("; ",@temp);
			foreach my $col_header (@temp) {
				$self->Add_2_Header($col_header);
			}
			push( @{ $self->{'data'} }, [@line] );
		}
		else {

			#print "we use the actual lie as a header\n";
			foreach my $col_header (@line) {
				$self->Add_2_Header($col_header);
			}
		}

	}
	for ( my $i = 0 ; $i < @description ; $i++ ) {
		$description[$i] = join( "\t", @{ $description[$i] } );
	}
	push ( @{$self->{'description'}}, @description);
	
	foreach my $columnName ( keys %{ $self->{'index'} } ) {
		$self->__update_index($columnName);
	}
	foreach my $unique ( keys %{ $self->{'uniques'} } ) {
		$self->UpdateUniqueKey($unique);
	}
	$self->After_Data_read();
	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	return 1;
}

=head2 set_HeaderName_4_position ( <new name>, <position in the header array> )

This function can be used to rename columns if you only know the position in the header array, 
but not the old column name. If you know the old column name you should use the Rename_Column function.

=cut

sub set_HeaderName_4_position {
	my ( $self, $name, $position ) = @_;
	my $error = '';
	$error .=
	  ref($self) . "::set_HeaderName_4_position -- I need the new name!\n"
	  unless ( defined $name );
	$error .=
	  ref($self)
	  . "::set_HeaderName_4_position -- you are kidding - I need to know the position you want to change!"
	  unless ( defined $position );
	Carp::confess($error) if ( $error =~ m/\w/ );
	$error .=
	  ref($self)
	  . "::set_HeaderName_4_position -- the position $position is not defined - define the column first!\n"
	  unless ( defined @{ $self->{'header'} }[$position] );
	return $self->Rename_Column( @{ $self->{'header'} }[$position], $name );
}

=head2 Rename_Column( <old name>, <new name>)

A simple function to rename columns in the data file.

=cut

sub Rename_Column {
	my ( $self, $old_name, $new_name ) = @_;
	return undef unless ( defined $old_name );
	unless ( defined $new_name ) {
		warn ref($self) . "::Rename_Column we do not know the new name!\n";
		return undef;
	}
	unless ( defined $self->Header_Position($old_name) ) {
		warn ref($self)
		  . "::Rename_Column sorry, but the column name $old_name is unknown!\n";
		return undef;
	}
	@{ $self->{'header'} }[ $self->Header_Position($old_name) ] = $new_name;
	$self->{'header_position'}->{$new_name} = $self->Header_Position($old_name);
	delete( $self->{'header_position'}->{$old_name} );
	return $self->Header_Position($new_name);
}

sub Add_2_Description {
	my ( $self, $string ) = @_;
	if ( defined $string ) {
		foreach my $description_line ( @{ $self->{'description'} } ) {
			return 1 if ( $string eq $description_line );
		}
		push( @{ $self->{'description'} }, $string );
		return 1;
	}
	return 0;
}

sub Description {
	my ( $self, $description_array ) = @_;
	if ( ref($description_array) eq "ARRAY" ) {
		## OH - probably we copy ourselve right now?
		$self->{'description'} = $description_array;
	}
	elsif ( ! defined $description_array) {
		## OK that is only used to circumvent a stupid error message.
	}
	elsif ( $description_array =~m/\w/ ){
		## OH probably you search for a specific line?
		my @return;
		foreach ( @{$self->{'description'}} ) {
			push ( @return,$_ ) if ( $_ =~m/$description_array/ );
		}
		return \@return;
	}
	return $self->{'description'};
}

=head2 read_file(<filename>, <amount of lines to read>)

This function will read a tab separated table file. The separator can be set usiong the line_separator function.

=cut

sub read_file {
	my ( $self, $filename, $lines ) = @_;
	return undef unless ( -f $filename );
	$self->{'read_filename'}   = $filename;
	$self->{'header_position'} = {} if ( ref($self) eq "data_table" );
	$self->{'header'}          = [] if ( ref($self) eq "data_table" );
	$self->{'data'}            = [];
	my ( @line, $value );
	open( IN, "<$filename" )
	  or die ref($self)
	  . "::read_file -> could not open file '$filename'\n$!\n";

	if ( defined $lines ) {
		my $i = 0;
		foreach (<IN>) {
			push( @line, $_ );
			$i++;
			last if ( $i >= $lines );
		}
		$self->parse_from_string( \@line );
	}
	else {
		$self->parse_from_string( [<IN>] );
	}
	return $self;
}

sub Add_header_Array {
	my ( $self, $header_array ) = @_;
	foreach my $value (@$header_array) {
		unless ( defined $self->Header_Position($value) ) {
			$self->Add_2_Header($value);
		}
	}
	return 1;
}

sub Add_db_result {
	my ( $self, $header, $db_result ) = @_;
	Carp::confess(
		"the header information has to be an array of column titles!\n")
	  unless ( ref($header) eq "ARRAY" );
	$self->Add_header_Array($header);
	$self->{'data'} = $db_result;
	foreach my $columnName ( keys %{ $self->{'index'} } ) {
		$self->__update_index($columnName);
	}
	return 1;
}

sub get_lable_for_row_and_column {
	my ( $self, $row_id, $columnName ) = @_;
	#my @temp = $self->get_row_entries( $row_id, $columnName );
	#foreach ( @temp ){
	#	unless ( defined $_ ){
	#		my $str = "'".join("' '", @temp )."'";
	#	die "I found an undefined entry in the result for column '$columnName' and row $row_id\n$str\n" ;
	#	}
	#}
	return join( ' ', ( $self->get_row_entries( $row_id, $columnName ) ) );
}

sub __update_index {
	my ( $self, $columnName ) = @_;
	return undef unless ( defined $self->{'index'}->{$columnName} );
	my ( @col_id, $lable );
	@col_id = $self->Header_Position($columnName);
	unless ( defined $col_id[0] ) {
		Carp::confess(
			root::get_hashEntries_as_string(
				$self->{'header'},
				3,
				"we ($self) have no column that is named '$columnName'\n"
				  . "and we have opened the file $self->{'read_filename'}\n"
			)
		);
		delete( $self->{'index'}->{$columnName} );
		return undef;
	}
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$lable = $self->get_lable_for_row_and_column( $i, $columnName );
		next unless ( $lable =~ m/\w/ );

		$self->{'index'}->{$columnName}->{$lable} = []
		  unless ( defined $self->{'index'}->{$columnName}->{$lable} );
		next
		  if (
			join( " ", @{ $self->{'index'}->{$columnName}->{$lable} } ) =~
			m/$i/ );
		@{ $self->{'index'}->{$columnName}->{$lable} }
		  [ scalar( @{ $self->{'index'}->{$columnName}->{$lable} } ) ] = $i;
	}
	return $self->{'index'}->{$columnName};
}

sub createIndex {
	my ( $self, $columnName ) = @_;
	return $self->{'index'}->{$columnName} if ( defined $self->{'index'}->{$columnName} );
	$self->{'index'}->{$columnName} = {};
	return $self->__update_index($columnName);
}

sub drop_all_indecies {
	my ($self) = @_;
	$self->{'index'} = {};
}

sub get_rowNumbers_4_columnName_and_Entry {
	my ( $self, $column, $entry ) = @_;
	unless ( defined $self->Header_Position($column) ) {
		Carp::confess("we do not have a column named '$column'\n");
		return [];
	}
	if ( ref($entry) eq "ARRAY" ) {
		$entry = "@$entry";
	}
	unless ( defined $self->{'index'}->{$column} ) {
		warn "we need to create an index for this column!\n";
		$self->createIndex($column);
		warn root::get_hashEntries_as_string( $self->{'index'}->{$column},
			3, "we have cretated this index: " )
		  if ( $self->{'debug'} );
	}
	unless ( defined $self->{'index'}->{$column}->{$entry} ) {
		return ();
	}
	return @{ $self->{'index'}->{$column}->{$entry} };
}

sub getLines_4_columnName_and_Entry {
	my ( $self, $column, $entry ) = @_;
	my @row = $self->get_rowNumbers_4_columnName_and_Entry( $column, $entry );
	unless ( defined $row[0] ) {
		$self->{'last_warning'} = "sorry - no data present!\n";
		return ();
	}
	return @{ $self->{'data'} }[@row];
}

sub merge_with_data_table {
	my ( $self, $other_data_table, $not_add_first_only_lines ) = @_;
	Carp::confess(
		    ref($self)
		  . "::merge_with_data_table - the object $other_data_table is not a "
		  . ref($self)
		  . " and therefore can not be used!" )
	  if ( !ref($other_data_table) eq ref($self)
		|| !ref($other_data_table) eq "data_table" );
	my $keys = {};
	foreach my $column_name ( @{ $self->{'header'} } ) {
		if ( defined $other_data_table->Header_Position($column_name) ) {
			$keys->{$column_name} =
			  $other_data_table->Header_Position($column_name);
			#print "we found the column $column_name in the other file!\n";
		}
	}
	Carp::confess(
		    ref($self)
		  . "::merge_with_data_table - we have no overlapp in the column headers and therefore can not join the tables!\n"
		  . "me: '"
		  . join( "', '", @{ $self->{'header'} } )
		  . "'\nthe other: '"
		  . join( "', '", @{ $other_data_table->{'header'} } )
		  . "'\n" )
	  unless ( scalar( keys %$keys ) > 0 );
	my $hash   = $other_data_table->get_line_asHash(0);
	my $return = $self->_copy_without_data();
	$return->Description( $self->Description() );
	if ( ref( $other_data_table->Description() ) eq "ARRAY" ) {
		foreach ( @{ $other_data_table->Description() } ) {
			$return->Add_2_Description($_);
		}
	}
	foreach my $other_column ( @{ $other_data_table->{'header'} } ) {
		unless ( defined $return->Header_Position($other_column) ) {
			$return->Add_2_Header($other_column);
		}
	}
	#print "we define the overlapp key to contain the columns '"
	#  . join( "';'", keys %$keys ) . "'\n";
	$other_data_table->define_subset( '___DATA___', [ sort keys %$keys ] );
	$self->define_subset( '___DATA___',             [ sort keys %$keys ] );
	my $keys_other_table = $other_data_table-> createIndex ('___DATA___' );
	my $keys_this_table = $self->  createIndex ('___DATA___' );
	my ( $my_hash, $other_hash);
	foreach my $my_key ( keys %$keys_this_table ){
		if ( defined $keys_other_table->{$my_key}){
			## OK all columns that do overlapp are in the KEY - hence I need to merge the columns - ALL!
			Carp::confess ( "Sorry I do not know how to merge multiple lines!")if ( scalar ( @{$keys_other_table->{$my_key}}) > 1 );
			$other_hash = $other_data_table->get_line_asHash ( @{$keys_other_table->{$my_key}}[0] );
			foreach my $line ( @{$keys_this_table->{$my_key}}) {
				## in jede Zeile muss die Info übertragen werden!
				$my_hash = $self->get_line_asHash ( $line );
				foreach ( keys %$other_hash ){
					#print "I have NOT yet updated my data array at position $line:".$self->Header_Position($_)." ($_) with value '$other_hash->{$_}'\n";
					unless ( $my_hash->{$_} =~m/.+/){
						@{@{$self->{'data'}}[$line]}[ $self->Header_Position($_) ] = $other_hash->{$_};
						#print "I have updated my data array at position $line:".$self->Header_Position($_)." with value '$other_hash->{$_}'\n";
					}
					
				}
				#print  root::get_hashEntries_as_string ({'new' => $self->get_line_asHash ( $line ), 'old' => $my_hash }, 3, "I have updated my line  $line", 100);
			}
		}
	}
	foreach my $other_key ( keys %$keys_other_table ){
		unless ( defined $keys_this_table->{$other_key}){
			$other_hash = $other_data_table->get_line_asHash ( @{$keys_other_table->{$other_key}}[0] );
			$self-> AddDataset ( $other_hash );
		}
	}
#	foreach ( @{$self->{'header'}} ){
#		$self->setDefaultValue ( $_ , 0 );
#	}
	return $self;
}

sub get_subset_4_columnName_and_entry {
	my ( $self, $column, $entry, $subsetName ) = @_;
	Carp::confess(
		ref($self)
		  . "::get_subset_4_columnName_and_entry -> you have to define the subset $subsetName before you can get data for it!!\n"
	) unless ( defined $self->{'subsets'}->{$subsetName} );
	my @return;
	foreach
	  my $data ( $self->getLines_4_columnName_and_Entry( $column, $entry ) )
	{
		$return[@return] = [ @$data[ @{ $self->{'subsets'}->{$subsetName} } ] ];
	}
	return \@return;
}

sub define_subset {
	my ( $self, $subset_name, $column_names ) = @_;
	if ( defined $self->{'subsets'}->{$subset_name} ) {
		return @{ $self->{'subsets'}->{$subset_name} };
	}
	my @columns;
	foreach my $colName (@$column_names) {
		if ( defined $self->Header_Position($colName) ) {
			push( @columns, $self->Header_Position($colName) );
		}
		else {
			$self->Add_2_Header($colName);
			push( @columns, $self->Header_Position($colName) );
			$self->{'last_warning'} =
			    ref($self)
			  . "::define_subset -> sorry - we do not know a column called '$colName'\n"
			  . "but we have created that column for you!";

			#warn $self->{'last_warning'};
		}

	}
	foreach my $position (@columns) {
		Carp::cluck(
			ref($self)
			  . "::define_subset -> we coud not identfy all columns in our table @$column_names!!\n"
		) unless ( defined $position );
	}
	$self->{'subsets'}->{$subset_name} = \@columns;
	return @{ $self->{'subsets'}->{$subset_name} };
}

sub drop_subset {
	my  ( $self, $subset_name ) = @_;
	return 0 unless ( defined $self->{'subsets'}->{$subset_name});
	delete $self->{'subsets'}->{$subset_name};
	delete $self->{'index'}->{$subset_name} if ( defined  $self->{'index'}->{$subset_name});
 
	return 1;
} 


sub AddDataset {
	my $self = shift;
	return $self->Add_Dataset(@_);
}

sub Columns{
	my ( $self ) = @_;
	return scalar(@{$self->{'header'}});
}

sub Reject_Hash {
	my ( $self, $array ) = @_;
	return 0;
}

sub Add_Dataset {
	my ( $self, $dataset ) = @_;
	my ( @data, @lines, $index_col_id, $line_id, $mismatch, $inserted );
	## if we already have such a dataset - see if
	## 1 the columns are already poulated like that
	##   or in other words if we want to add a duplicate entry - skip the process
	## 2 the columns that would be added would add to the dataset ( the columns have been empty )
	## 3 there is the need of a new dataset line with the new results
	Carp::confess("Hey - I need a hash of valuies, not $dataset !\n")
	  unless ( ref($dataset) eq "HASH" );
	foreach my $colName ( keys %$dataset ) {
		unless ( defined $self->Header_Position($colName) ) {
			Carp::confess(
"we do not have a column called '$colName' - I do not know where to add this data!\n"
				  . "I have the header: "
				  . join( "; ", @{ $self->{'header'} } )
				  . "\n" );
			next;
		}
		if ( defined $dataset->{$colName} ) {
			$data[ $self->Header_Position($colName) ] = $dataset->{$colName};
		}
		else {
			$data[ $self->Header_Position($colName) ] = '';
		}

	}
	## see if we already have that dataset - will only work if we have an index!!
	my $check_lines = {};
	## see if we have some columns where we could add the dataset
	foreach my $indexColumns ( keys %{ $self->{'index'} } ) {

		#warn "does the dataset contain the column $indexColumns?\n";
		if ( defined $dataset->{$indexColumns} ) {

			#print "YES!\n";
			## do we have some lines we need to check?
			$check_lines->{$indexColumns} = [
				$self->get_rowNumbers_4_columnName_and_Entry(
					$indexColumns, $dataset->{$indexColumns}
				)
			];
			foreach my $col_id ( $self->Header_Position($indexColumns) ) {
				$index_col_id->{$col_id} = 1;
			}
			foreach my $row_id ( @{ $check_lines->{$indexColumns} } ) {
				$check_lines->{'final'}->{$row_id} = 0
				  unless ( defined $check_lines->{'final'}->{$row_id} );
				$check_lines->{'final'}->{$row_id}++;
			}
		}
	}

#warn "we checked the lines ".join(", ",(keys %$check_lines))."\n".
#root::get_hashEntries_as_string ($check_lines, 3, "and here comes the temporary check_lines dataset ");;

	## check if these columns do match ALL the keys the dataset has
	if ( scalar( keys %$check_lines ) > 1 ) {

		#warn "now we check the single columns...\n";
		my $final = scalar( keys %$check_lines ) - 1;

#warn "all columns we would want to use have to have $final matches to the dataset!\n";
		foreach my $row_id ( keys %{ $check_lines->{'final'} } ) {
			unless ( $check_lines->{'final'}->{$row_id} == $final ) {
				delete( $check_lines->{'final'}->{$row_id} );

				#  	warn "oops - we must no add to row $row_id\n";
			}

			#	else {
			#		warn "and the row $row_id passed the test!\n";
			#}
		}
		@lines = ( keys %{ $check_lines->{'final'} } );
	}
	## add the dataset to all the columns if the column would not delete a already present value
	$inserted = 0;
	foreach $line_id (@lines) {
		$mismatch = 0;
		## I need to consider the 'good' matches!

		for ( my $i = 0 ; $i < @data ; $i++ ) {
			next unless ( defined $data[$i] );
			next if ( $index_col_id->{$i} );
			next
			  unless ( defined @{ @{ $self->{'data'} }[$line_id] }[$i] );
			next if ( @{ @{ $self->{'data'} }[$line_id] }[$i] eq "" );
			unless ( @{ @{ $self->{'data'} }[$line_id] }[$i] eq $data[$i] ) {
				$mismatch++;

#warn "we have a mismatch for column value ".@{ @{ $self->{'data'} }[$line_id] }[$i]." and $data[$i]\n";
			}
		}

#warn "we have checked for mismatches between our two dataset - and we have found $mismatch mismatched for line $line_id\n";
		if ( $mismatch == 0 ) {
			## OK we do not have a problem in this line  - just paste over this line!
			for ( my $i = 0 ; $i < @data ; $i++ ) {
				@{ @{ $self->{'data'} }[$line_id] }[$i] = $data[$i]
				  if ( defined $data[$i] );
			}
			$inserted = 1;

			#print "we merged two lines!\n";
		}
	}

	if ($inserted) {

		#print "we do not need to update the index!\n\t".join("; ",@data)."\n";
		return -1;
	}

	## OK this is a novel dataset - add a new line
	#print "we added a line\n\t" . join( "; ", @data ) . "\n";
	@{ $self->{'data'} }[ scalar( @{ $self->{'data'} } ) ] = \@data;

	#print "we are done with " . ref($self) . "->Add_Dataset\n";
	$self->UpdateIndex( @{ $self->{'data'} } - 1 );
	return scalar( @{ $self->{'data'} } );
}

sub is_empty {
	my ($self) = @_;
	return 1 if ( scalar( @{ $self->{'data'} } == 0 ) );
	return 0;
}

sub Lines {
	my ( $self ) = @_;
	return scalar ( @{$self->{'data'}} );
}

sub UpdateIndex {
	my ( $self, $data_line ) = @_;
	return undef unless ( defined $data_line );
	return undef unless ( defined @{ $self->{'data'} }[$data_line] );
	my @col_id;
	foreach my $columnName ( keys %{ $self->{'index'} } ) {
		@col_id = $self->Header_Position($columnName);

		unless (
			defined $self->{'index'}->{$columnName}
			->{"@{@{ $self->{'data'}}[$data_line]}[@col_id]"} )
		{
			$self->{'index'}->{$columnName}
			  ->{"@{@{ $self->{'data'}}[$data_line]}[@col_id]"} = [];
		}
		elsif (
			join(
				" ",
				@{
					$self->{'index'}->{$columnName}
					  ->{"@{@{ $self->{'data'}}[$data_line]}[@col_id]"}
				  }
			) =~ m/$data_line/
		  )
		{
			next;
		}

		#		push (@{ $self->{'index'}->{$columnName}
		#			  ->{"@{@{ $self->{'data'}}[$data_line]}[@col_id]"} }, $data_line );
		@{ $self->{'index'}->{$columnName}
			  ->{"@{@{ $self->{'data'}}[$data_line]}[@col_id]"} }[
		  scalar(
			  @{
				  $self->{'index'}->{$columnName}
					->{"@{@{ $self->{'data'}}[$data_line]}[@col_id]"}
				}
		  )
			  ]
		  = $data_line;
	}
	foreach my $unique ( keys %{ $self->{'uniques'} } ) {
		my @columns = $self->Header_Position($unique);
		my $key     = "@{@{$self->{'data'}}[$data_line]}[@columns]";

		#print "we add a unique key $key\n";
		Carp::confess(
			"the Unique key $unique has a duplicate on line $data_line ($key)")
		  if ( defined $self->{'uniques'}->{$unique}->{$key}
			&& $self->{'uniques'}->{$unique}->{$key} != $data_line );
		$self->{'uniques'}->{$unique}->{$key} = $data_line;
	}
	return 1;
}

sub Add_unique_key {
	my ( $self, $key_name, $columnName ) = @_;
	return 1 if ( defined $self->{'uniques'}->{$key_name} );
	$self->{'uniques'}->{$key_name} = {};
	my @columns;
	unless ( ref($columnName) eq "ARRAY" ) {
		$columnName = [$columnName];
	}
	foreach my $colName (@$columnName) {
		push( @columns, $self->Header_Position($colName) );
		warn "column name '$colName' is unknown!"
		  unless ( defined $columns[ @columns - 1 ] );
	}
	foreach my $position (@columns) {
		Carp::cluck(
			ref($self)
			  . "::define_subset -> we coud not identfy all columns in our table @$columnName!!\n"
		) unless ( defined $position );
	}
	$self->{'subsets'}->{$key_name} = \@columns;
	$self->UpdateUniqueKey($key_name);
	return @{ $self->{'subsets'}->{$key_name} };
}

sub UpdateUniqueKey {
	my ( $self, $columnName ) = @_;
	my @columns = $self->Header_Position($columnName);
	my ( $key, $i );
	$i = 0;
	foreach my $data ( @{ $self->{'data'} } ) {
		$key = "@$data[@columns]";

		#print "we add a unique key $key\n";
		Carp::confess(
			"the Unique key $columnName has a duplicate on line $i ($key)")
		  if ( defined $self->{'uniques'}->{$columnName}->{$key}
			&& $self->{'uniques'}->{$columnName}->{$key} != $i );
		$self->{'uniques'}->{$columnName}->{$key} = $i;
		$i++;
	}
	return 1;
}

sub getLine_4_unique_key {
	my ( $self, $key_name, $data ) = @_;
	unless ( defined $self->{'uniques'}->{$key_name} ) {
		warn ref($self)
		  . "::getLine_4_unique_key -> we do not have an unique key named '$key_name'\n";
	}
	if ( ref($data) eq "ARRAY" ) {
		$data = "@$data";
	}
	return $self->{'uniques'}->{$key_name}->{$data};
}

sub Add_dataset_for_entry_at_index {
	my ( $self, $dataset, $entry, $index ) = @_;
	my @rows = $self->get_rowNumbers_4_columnName_and_Entry( $index, $entry );
	foreach my $colName ( keys %$dataset ) {
		Carp::confess(
"we do not have a column called '$colName' - I do not know where to add this data!\n"
		) unless ( $self->Header_Position($colName) );
	}
	my ( $temp, $row, @uniques, $actual );
	foreach my $colName ( keys %$dataset ) {
		my ($unique_column) = ( keys %{ $self->{'uniques'} } );
		if ( defined $unique_column ) {
			@uniques = $self->Header_Position($unique_column);
			Carp::confess(
"you can not add a such complex dataset if you do not have a unique key!\n"
			) unless ( defined $uniques[0] );
		}
		if ( ref( $dataset->{$colName} ) eq "ARRAY" ) {
			## oops - we want to add new data lines!
			## WE will add the value I got to all the lines there are
			## therefore I have to admitt, that you want to take each and every line as an template!!!
			## OK another possibillity is, that you have added an unique key...
			$temp = undef;
			## we need to check if the dat is already present in the dataset!
			foreach $row (@rows) {
				$temp->{"@{@{$self->{data}}[$row]}[@uniques]"} = $row;
				print
				  "unique key @{@{$self->{data}}[$row]}[@uniques] at row $row\n"
				  if ( $self->{'debug'} );
			}

			foreach $unique_column ( keys %$temp ) {
				$actual =
				  @{ @{ $self->{data} }[ $temp->{$unique_column} ] }
				  [ $self->Header_Position($colName) ];
				foreach my $value ( @{ $dataset->{$colName} } ) {
					unless ( $actual =~ m/$value/ ) {
						## we need to add that dataset!
						$row =
						  $self->create_dataset_for_line(
							$temp->{$unique_column} );
						$row->{$colName} = $value;
						print root::get_hashEntries_as_string ( $row, 3,
							"we are going to add this dataset " )
						  if ( $self->{'debug'} );
						$self->Add_Dataset($row);
						$actual .= " " . $value;
					}
				}
				Carp::confess(
"SORRY, but you can not add multiple datasets in the add mode, as that will mess up the data structure!"
				) if ( scalar( ( keys %$dataset ) ) > 1 );
			}
		}
		else {
			foreach my $row (@rows) {
				@{ @{ $self->{data} }[$row] }
				  [ $self->Header_Position($colName) ] = $dataset->{$colName};
				$self->UpdateIndex($row);
			}
		}

	}
	return 1;
}

sub get_value_4_line_and_column {
	my ( $self, $line, $column ) = @_;
	Carp::confess("Sorry, but I do not know the column $column\n")
	  unless ( defined $self->Header_Position($column) );
	Carp::confess("Sorry, but I do not have a line with the number $line\n")
	  unless ( ref( @{ $self->{'data'} }[$line] ) eq "ARRAY" );
	return @{ @{ $self->{'data'} }[$line] }[ $self->Header_Position($column) ];
}

=head2 get_line_asHash (<line_id>, <subset name>)

You will get either the whiole line or the columns defined ias subset as hash.

=cut

sub get_line_asHash {
	my ( $self, $line_id, $subset_name ) = @_;
	return undef unless ( defined $line_id );
	return undef unless ( ref( @{ $self->{'data'} }[$line_id] ) eq "ARRAY" );
	my ( $hash, @temp );
	$subset_name = "ALL" unless ( defined $subset_name );
	foreach my $col_id ( $self->Header_Position($subset_name) ) {
		Carp::confess ( "get_line_asHash(  $line_id, $subset_name) - @{ $self->{'data'} }[$line_id] } is undefined!" ) unless ( defined $line_id  );
		@{ @{ $self->{'data'} }[$line_id] }[$col_id] = '' unless ( defined @{ @{ $self->{'data'} }[$line_id] }[$col_id]);
		$hash->{ @{ $self->{'header'} }[$col_id] } =
		  @{ @{ $self->{'data'} }[$line_id] }[$col_id];
		unless ( defined $hash->{ @{ $self->{'header'} }[$col_id] } ) {
			@temp = $self->getDefault_values( @{ $self->{'header'} }[$col_id] );
			$hash->{ @{ $self->{'header'} }[$col_id] } = $temp[0];
		}
	}
	return $hash;
}

=head2 GetAll_AsHashArrayRef  ()

return all values in the dataset as array of hases.

=cut

sub GetAll_AsHashArrayRef {
	my ($self) = @_;
	my @return;
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		push( @return, $self->get_line_asHash($i) );
	}
	return \@return;
}

=head2 getAsHash

This function will return two columns ( $ARHV[0], $ARGV[1]) as hash
{ <$ARGV[0]> => <$ARGV[1]> } for the whole table.

=cut

sub getAsHash {
	my ( $self, $key_name, $value_name ) = @_;
	my ( $hash, $line, @key_id, @value_id );
	@key_id   = $self->Header_Position($key_name);
	@value_id = $self->Header_Position($value_name);

#Carp::confess ( root::get_hashEntries_as_string ({$key_name => @key_id, $value_name => @value_id}, 3, "The important places "));
	Carp::confess(
"Sorry, but we do not have a column named '$value_name' - only the columns "
		  . join( ", ", @{ $self->{'header'} } )
		  . "\n" )
	  unless ( defined $value_id[0] );
	foreach $line ( @{ $self->{'data'} } ) {
		@$line[@value_id] = '' unless ( defined @$line[@value_id] );
		$key_name   = join( " ", @$line[@key_id] );
		$value_name = join( " ", @$line[@value_id] );
		$hash->{"$key_name"} = "$value_name";
	}

#Carp::confess( "sorry, but we had a problem!". root::get_hashEntries_as_string ($hash, 3, " "));
	return $hash;
}

=head2 GetAsObject ( <subset name> )

This function can be used to reformat the table according to a subset name.

=cut

sub GetAsObject {
	my ( $self, $subset ) = @_;
	return $self unless ( defined $subset );
	unless ( defined $self->{'subsets'}->{$subset} ) {
		warn "we do not know the subset $subset\n";
		return undef;
	}
	my $return = ref($self)->new();
	my @data;
	foreach my $array ( @{ $self->{'data'} } ) {
		push( @data, [ @$array[ @{ $self->{'subsets'}->{$subset} } ] ] );
	}
	$return->Add_db_result(
		[ @{ $self->{'header'} }[ @{ $self->{'subsets'}->{$subset} } ] ],
		\@data );
	$return->Description( $self->Description() );
	return $return;
}

sub create_dataset_for_line {
	my ( $self, $line_id ) = @_;
	my $dataset = {};
	return $dataset unless ( defined $line_id );
	return $dataset
	  unless ( ref( @{ $self->{data} }[$line_id] ) eq "ARRAY" );
	for ( my $i = 0 ; $i < @{ $self->{header} } ; $i++ ) {
		$dataset->{ @{ $self->{header} }[$i] } =
		  @{ @{ $self->{data} }[$line_id] }[$i];
	}
	print root::get_hashEntries_as_string ( $dataset, 3,
		"we have created the dataset " )
	  if ( $self->{'debug'} );
	return $dataset;
}

sub AsHTML {
	my $self = shift;
	return $self->GetAsHTML();
}

sub GetAsHTML {
	my ($self) = @_;
	my $str = "<table border=\"1\">\n";
	$str .= $self->__array_2_HTML_table_line( $self->{'header'} );
	foreach my $array ( @{ $self->{'data'} } ) {
		$str .= $self->__array_2_HTML_table_line($array);
	}
	$str .= "</table>\n";
	return $str;
}

sub __array_2_HTML_table_line {
	my ( $self, $array ) = @_;
	my $str = "\t<tr>";
	my ( $modifications, $temp );
	for ( my $i = 0 ; $i < @$array ; $i++ ) {
		$modifications =
		  $self->HTML_modification_for_column( @{ $self->{'header'} }[$i] );
		$temp =
"<td>$modifications->{'before'}@$array[$i]$modifications->{'after'}</td>";
		if ( $modifications->{'td'} ) {
			$temp =~ s/<td>/<td $modifications->{'td'}>/;
		}
		$str .= $temp;
		if ( $modifications->{'tr'} ) {
			$str =~ s/<tr>/<tr $modifications->{'tr'}>/;
		}
	}
	$str .= "</tr>\n";
	return $str;
}

1;
