package new_histogram;

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
use stefans_libs::root;
use GD::SVG;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use stefans_libs::plot::axis;

sub new {

	my ( $class, $title, $data ) = @_;

	my ( $self, $root, $hash );

	$self = {
		debug          => 0,
		title          => $title,
		root           => root->new(),
		logged         => 0,
		scale21        => 0,
		category_steps => 10,
		minAmount      => undef,
		maxAmount      => undef,
		scale21        => 0,
		noNull         => 0
	};

	bless $self, $class if ( $class eq "new_histogram" );
	if ( defined $data ) {
		$self->loadFromArray($data);
	}
	return $self;

}

sub export {
	my ($self) = @_;

	my @werte =
	  qw( title logged min max category_steps minAmount maxAmount scale21 stepSize noNull);
	my $string = "";
	foreach my $v (@werte) {
		$string .= "$v\t" . $self->{$v} . "\n" if ( defined $self->{$v} );
	}

	$string .= "data\n";
	my ( $data, $values );
	$data   = $self->{bins};
	$values = $self->{data};
	foreach my $hash ( sort { $a->{min} <=> $b->{min} } @$data ) {
		$string .= join(
			"\t",
			(
				$hash->{min},      $hash->{max},
				$hash->{category}, $values->{ $hash->{category} }
			)
		) . "\n";
	}
	return $string;
}

sub import_from_file {
	my ( $self, $file ) = @_;
	open( IN, "<$file" ) or die "could not open file $file \n$!\n";
	my @lines = (<IN>);
	close(IN);
	return $self->import_from_line_array( \@lines );
}

sub import_from_line_array {
	my ( $self, $array ) = @_;
	my ( $data, $values, @data, @line );

	$data = 0;

	foreach (@$array) {
		chomp $_;
		@line = split( "\t", $_ );
		if ($data) {
			push( @data,
				{ min => $line[0], max => $line[1], category => $line[2] } );
			$values->{ $line[2] } = $line[3];
			next;
		}
		if ( $_ eq "data" ) {
			$data = 1;
			next;
		}
		$self->{ $line[0] } = $line[1];
	}
	$self->{data} = $values;
	$self->{bins} = \@data;
	return $self;
}

sub loadFromArray {
	my ( $self, $array ) = @_;
	my ( $info, $tag );

	( $info, $tag ) = split( "\t", @$array[0] );
	die "max value is not at its place!\n"
	  unless ( $info eq "max" );
	$self->Max($tag);

	( $info, $tag ) = split( "\t", @$array[1] );
	die "min value is not at its place!\n"
	  unless ( $info eq "min" );
	$self->Min($tag);

	( $info, $tag ) = split( "\t", @$array[2] );
	die "category_steps value is not at its place!\n"
	  unless ( $info eq "category_steps" );
	$self->Category_steps($tag);

	( $info, $tag ) = split( "\t", @$array[3] );
	die "log_ed value is not at its place!\n"
	  unless ( $info eq "log_ed" );
	$self->{log_ed} = $tag;

	$self->initialize();

	for ( my $i = 4 ; $i < @$array ; $i++ ) {
		( $info, $tag ) = split( "\t", @$array[$i] );
		die "error during the import of line '@$array[$i]'\n"
		  unless ( defined $self->{data}->{$info} );
		$self->{data}->{$info} = $tag;
	}
	return $self;
}

sub getAsString {
	my ($self) = @_;
	my ( @string, $temp );
	push( @string, "log_ed\t$self->{log_ed}" );
	$temp = $self->Max();
	push( @string, "max\t$temp" );
	$temp = $self->Min();
	push( @string, "min\t$temp" );
	$temp = $self->Category_steps();
	push( @string, "category_steps\t$temp" );
	$temp = $self->{log_ed};
	push( @string, "log_ed\t$temp" );
	$temp = $self->{data};

	foreach my $key ( sort { $a <=> $b } keys %$temp ) {
		push( @string, "$key\t$temp->{$key}" );
	}
	push( @string, "//\n" );
	return join( "\n", @string );
}

sub _sum {
	## I suspect we get a hash of data_values that is not in log scale!!
	my ( $self, $hash ) = @_;
	my $i = 0;
	while ( my ( $key, $value ) = each %$hash ) {

		#print "$self _sum got the value $value\n";
		$i += $value unless ( $key =~ m/ARRAY/ );
	}
	return $i;    #unless ( $self->{logged} );
	return log($i);
}

sub ScaleSumToOne {
	my ($self) = @_;

	return 1 if ( $self->{scale21} == 1 );

	my ( $i, $data, $logNature );
	$logNature = $self->{logged};

	$self->RemoveLogNature() if ($logNature);

	$data = $self->{data};
	die "$self->ScaleSumToOne no data present!" unless ( defined $data );
	$self->{scale21} = 1;

	$i = $self->_sum($data);

	foreach my $value ( values %$data ) {
		$value = $value / $i;
	}
	$i = 0;
	while ( my ( $key, $value ) = each %$data ) {
		$i += $value unless ( $key =~ m/ARRAY/ );
	}
	unless ( $i > 0.99999 && $i < 1.000001 ) {
		$self->{scale21} = 0;
		$i = $self->ScaleSumToOne();
	}

	$self->LogTheHash() if ($logNature);

	return $i;
}

sub printHistogram2file_simple {
	my ( $self, $filename ) = @_;
	die
"new_histogram printHistogram2file_simple absolutely needs to know the filename!\n"
	  unless ( defined $filename );
	my $data = $self->{data};
	open( OUT, ">$filename" )
	  or die "$self printHistogram2file could not open $filename\n";

	unless ( defined $self->{log_ed} ) {
		foreach my $x ( sort numeric keys %$data ) {
			unless ( $x =~ m/ARRAY/ ) {
				print OUT "$x\t$data->{$x}\n";
			}
			else {
				warn
"$self: $self->{title} printHistogram2file had a strange value: $x -> $data->{$x}\n";
			}
		}
	}
	else {
		foreach my $x ( sort numeric keys %$data ) {
			unless ( $x =~ m/ARRAY/ ) {
				print OUT "$x\t", exp( $data->{$x} ), "\n";
			}
			else {
				warn
"$self: $self->{title} printHistogram2file had a strange value: $x -> $data->{$x}\n";
			}
		}
	}
	close(OUT);
	print "$self data was written to $filename\n";
	return 1;
}

sub printHistogram2file {
	my ( $self, $filename ) = @_;
	return undef unless ( defined $filename );
	my $data = $self->{data};

	my @array = qw( logged  noNull scale21);
	foreach my $cmd (@array) {
		if ( $self->{$cmd} == 1 ) {
			my ( $a, $b ) = split( /\./, $filename );
			$a = "$a-$cmd";
			$filename = join( "\.", ( $a, $b ) );
		}
	}

	unless ( defined %$data ) {
		warn "$self printHistogram2file no data present!\n";
		return undef;
	}
	open( OUT, ">$filename" )
	  or die "$self printHistogram2file could not open $filename\n";
	unless ( defined $self->{log_ed} ) {
		foreach my $x ( sort numeric keys %$data ) {
			unless ( $x =~ m/ARRAY/ ) {
				print OUT "$x\t$data->{$x}\n";
			}
			else {
				warn
"$self: $self->{title} printHistogram2file had a strange value: $x -> $data->{$x}\n";
			}
		}
	}
	else {
		foreach my $x ( sort numeric keys %$data ) {
			unless ( $x =~ m/ARRAY/ ) {
				print OUT "$x\t", exp( $data->{$x} ), "\n";
			}
			else {
				warn
"$self: $self->{title} printHistogram2file had a strange value: $x -> $data->{$x}\n";
			}
		}
	}
	close(OUT);
	print "$self data was written to $filename\n";
	return 1;
}

sub getOrderedYvalues {
	my $self = shift;
	my $data = $self->{data};
	my @return;
	foreach my $key ( sort numeric keys %$data ) {
		push( @return, $data->{$key} );
	}
	return \@return;
}

sub getOrderedXvalues {
	my $self = shift;
	my $data = $self->{data};
	my @return;
	foreach my $key ( sort numeric keys %$data ) {
		push( @return, $key );
	}
	return \@return;
}

sub GetDataAsHash {
	my ($self) = @_;
	return $self->{data};
}

sub Category_steps {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
#		die "$self category_steps has to be of type int! ($value)\n"
#		  if ( $value != int($value) );
		$value = 4 if ( $value < 4 );
		$self->{category_steps} = $value;
	}
	$self->{category_steps} = 10 unless ( defined $self->{category_steps} );
	return $self->{category_steps};
}

sub AddValue {
	my ( $self, $value ) = @_;

	die "do not use this method use CreateHistogram!\n"
	  if ( ref($value) eq "ARRAY" );

	my $category = $self->getCategoryOfTi($value);

#print "Creation of the probability array value $value is converted into category $category!\n";
	$self->{data}->{$category} = 0
	  unless ( defined $self->{data}->{$category} );
	$self->{data}->{$category}++;
	$self->Min($value);
	$self->Max($value);
	return 1;
}

sub Min {
	my ( $self, $value ) = @_;
	return $self->{min} unless ( defined $value );
	$self->{min} = +10E+30 if ( !defined $self->{min} );
	$self->{min} = $value  if ( $self->{min} > $value );
	print "in package ", ref($self),
	  " we try if $value is smaler than the min value = $self->{min}\n"
	  if ( $self->{debug} );
	return $self->{min};
}

sub Max {
	my ( $self, $value ) = @_;
	return $self->{max} unless ( defined $value );
	$self->{max} = -10E+30 unless ( defined $self->{max} );
	$self->{max} = $value if ( $self->{max} < $value );
	print "in package ", ref($self),
	  " we try if $value is larger than the max value = $self->{max}\n"
	  if ( $self->{debug} );
	return $self->{max};
}

sub getStart_End_4_DatBinID {
	my ( $self, $id ) = @_;
	return $self->{bins}[$id]->{min}, $self->{bins}[$id]->{max};
}

sub CreateHistogram {

	my ( $self, $array, $hashEntryX, $steps ) = @_;
	my ( $hash, $category, @arrayOfYvalues, @newArray, @Xvalues );

	unless ( defined $hashEntryX ) {
		if ( ref($array) eq "ARRAY" ) {
			if ( ref( @$array[0] ) eq "ARRAY" ) {
				foreach ( @$array[0] ) {
					push( @Xvalues, @$_ );
				}
			}
			else {
				@Xvalues = @$array;
			}
		}
		elsif ( ref($array) eq "HASH" ) {
			die
			  "Oh we analyze a hash, but we did not get a possible hash key!\n";
		}
	}
	elsif ( ref($array) eq "ARRAY" ) {

		my ($newX);
		if ( @$array[0] =~ m/ARRAY/ ) {
			foreach my $arrayRef (@$array) {
				push( @Xvalues, @$arrayRef[$hashEntryX] );
			}
		}
		elsif ( @$array[0] =~ m/HASH/ ) {
			foreach my $newHash (@$array) {
				push( @Xvalues, $newHash->{$hashEntryX} );
			}
		}
		else {
			die
"if a hash entry ($hashEntryX) is given to CreateHistogram, we exprect ",
"\neither a array of arrays or an array of hashes to select the values from!\nNOT @$array[0]";
		}
	}
	elsif ( ref($array) eq "HASH" ) {
		foreach my $newHash ( values %$array ) {
			push( @Xvalues, $newHash->{$hashEntryX} );
		}
	}

	foreach (@Xvalues) {
		$self->Max($_);
		$self->Min($_);
	}

	#$steps = 10 unless ( defined $steps );
	$self->Category_steps($steps) if ( defined $steps );
	$self->initialize();

	$hash = $self->{data};
	print "package ", ref($self), "got the values:\n", join( "; ", @Xvalues ),
	  "\n"
	  if ( $self->{debug} );

	foreach my $value (@Xvalues) {
		next if ( $value =~ m/ARRAY/ );
		$category = $self->getCategoryOfTi($value);

#print
#"Creation of the probability array value $value is converted into category $category!\n";
		$hash->{$category} = 0 unless ( defined $hash->{$category} );
		$hash->{$category}++;
	}

   #root::print_hashEntries($self->{data}, 2, "the newly created data hash:\n");
	return $hash;
}

sub removeNullstellen {
	my ($self) = @_;
	my $total  = 100;
	my $data   = $self->{data};
	die
	  "$self: removenullstellen darf nicht nach LogTheHash ausgefuehrt werden!"
	  if ( $self->{logged} == 1 );
	$self->{noNull} = 1;

	foreach my $value ( values %$data ) {
		if ( $value == 0 || !defined $value ) {
			$value = 0.00000000001;
			print
"DEBUG $self->removeNullstellen added the value $value to $data\n";
		}

	}
	return 1;
}

sub getHistoValue {
	my ( $self, $searchValue ) = @_;
	return $self->{data}->{ $self->getCategoryOfTi($searchValue) };
}

sub LogTheHash {
	my ($self) = @_;
	my $data = $self->{data};

	if ( $self->{logged} == 1 ) {
		return 0 unless ( $self->{duringReestimation} == 1 );
		$self->{duringReestimation} = 0;
		$self->{logged}             = 0;
	}
	$self->removeNullstellen();
	foreach my $key ( keys %{ $self->{data} } ) {
		$self->{data}->{$key} = log( $self->{data}->{$key} );
	}
	$self->{logged} = 1;
	return 1;
}

sub RemoveLogNature {
	my ($self) = @_;
	if ( $self->{logged} == 0 ) {
		warn "the histogram was not in log state!\n";
		return 0;
	}
	foreach my $key ( keys %{ $self->{data} } ) {
		$self->{data}->{$key} = exp( $self->{data}->{$key} );
	}
	$self->{logged} = 0;
	return 1;
}

=head 2 getAsDataTable

this function will return the actual data as data_table object containing the columns
'start', 'end' and 'value'.

=cut

sub getAsDataTable {
	my ($self) = @_;
	my $data_table = data_table->new();
	foreach (qw/start end value/) {
		$data_table->Add_2_Header($_);
	}
	foreach my $hash ( sort { $a->{min} <=> $b->{min} } @{ $self->{bins} } ) {
		$data_table->AddDataset( {
			'start' => $hash->{'min'},
			'end'   => $hash->{'max'},
			'value' => $self->{'data'}->{ $hash->{'category'} }
		}
		);
	}
	return $data_table;
}

sub getAsDataMatrix {
	my ($self) = @_;
	my ( $data, @return, $values );
	$data   = $self->{bins};
	$values = $self->{data};
	foreach my $hash ( sort { $a->{min} <=> $b->{min} } @$data ) {
		push( @return,
			[ $hash->{min}, $hash->{max}, $values->{ $hash->{category} } ] );
	}
	return \@return;
}

sub get_as_table{
	my ( $self ) = @_;
	my $data_table = data_table->new();
	foreach ( 'x', 'y' ){
		$data_table ->Add_2_Header( $_ );
	}
	foreach my $key ( sort { $a <=> $b } keys %{ $self->{data} } ) {
		$data_table -> AddDataset ( { 'x' => $key, 'y' => $self->{data}->{$key} })
	}
	return $data_table;
}

sub getAs_XY_plottable {
	my ($self) = @_;
	my @return;
	my $i = 0;
	foreach my $key ( sort { $a <=> $b } keys %{ $self->{data} } ) {
		if ( $self->{logged} ){
		 $return[$i++] = { 'x' => $key, 'y' => exp( $self->{data}->{$key} ) } ;
		}
		else {
			$return[$i++] = { 'x' => $key, 'y' =>  $self->{data}->{$key} }  ;
		}

	}
	return \@return;
}

sub _getXrange {
	my ($self) = @_;
	my $data = $self->getAsDataMatrix();
	## the min x_value = @$data[0][1]
	## the max x_value = @$data[ @$data - 1 ][1]
	#print "we get the xrange @$data[0]->[0] -> @$data[@$data-1]->[1]\n";
	return ( $self->Min, $self->Max );
}

sub _plotAxies {
	my ( $self, $im, $color, $xTitle, $yTitle ) = @_;
	die "you have to define the axies first!\n"
	  unless ( defined $self->{xaxis} );
	$self->{xaxis}
	  ->plot( $im, $self->{yaxis}->resolveValue( $self->{yaxis}->min_value ),
		$color, $xTitle );
	$self->{yaxis}
	  ->plot( $im, $self->{xaxis}->resolveValue( $self->{xaxis}->min_value ),
		$color, $yTitle );
	return 1;
}

sub maxAmount {
	my ( $self, $max ) = @_;
	if ( defined $max ) {
		$self->{maxAmount} = $max unless ( defined $self->{maxAmount} );
		$self->{maxAmount} = $max if ( $self->{maxAmount} < $max );
	}
	return $self->{maxAmount} if ( defined $self->{maxAmount} );
	my $data = $self->{data};
	$max = -10E+30;
	foreach ( values %$data ) {
		$max = $_ if ( $_ > $max );
	}
	$self->{maxAmount} = $max;

	print "$self max amount = $max\n" if ( $self->{debug} );
	return $max;
}

sub minAmount {
	my ( $self, $min ) = @_;
	if ( defined $min ) {
		$self->{minAmount} = $min unless ( defined $self->{minAmount} );
		$self->{minAmount} = $min if ( $self->{minAmount} > $min );
	}
	return $self->{minAmount} if ( defined $self->{minAmount} );
	my $data = $self->{data};
	$min = $self->maxAmount();
	foreach ( values %$data ) {
		$min = $_ if ( $_ < $min );
	}
	$self->{minAmount} = $min;
	print "$self min amount = $min\n" if ( $self->{debug} );
	return $min;
}

=head2 plot_2_image

this function will add the values in the histogram to an existing image object.

Named options:

=over

=item x_min, x_max, y_min, y_max

define the region on the image to plot the histogram

=item color, fillColor

a integer color value that you can get from a stefans_libs::plot::color object

=item x_title, y_title

the string titles for the x and y axis

=item portrait

defined: we plot it with an horizontal x axis and an vertical y axis

undefined: we plot it with an horizontal y axis and an vertical x axis

=item fixed_axis

any object implementing stefans_libs::plot::axis. This object will be used as axis and no internal axis will be created

=item fixed_axis_is

'X' the fixed axis object will be used as x axis

'Y' the fixed axis will be used as y axis

=back

=cut

sub plot_axies {
	my ( $self, $portrait, $im, $color, $xTitle, $yTitle ) = @_;

	unless ( $self->plotSingle() ) {
		unless ($portrait) {
			$self->{xaxis}->plot_without_digits( $im,
				$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
				$color, "", 3 );
		}
		##_without_digits
		else {
			$self->{yaxis}->plot_without_digits( $im,
				$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
				$color, "", 3 );
		}
	}
	else {
		## we want to have real axies!
		unless ($portrait) {
			$self->{xaxis}->plot( $im,
				$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
				$color, $xTitle );
			$self->{yaxis}->plot( $im,
				$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
				$color, $yTitle );
		}
		else {
			$self->{yaxis}->plot( $im,
				$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
				$color, $xTitle );
			$self->{xaxis}->plot( $im,
				$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
				$color, $yTitle );
		}
	}
}

sub plot_2_image {
	my ( $self, $hash ) = @_;
	my @keys =
	  qw(im x_min x_max y_min y_max color fillColor x_title y_title portrait fixed_axis fixed_axis_is );
	Carp::confess(
		    ref($self)
		  . ".plot_2_image - the syntax has changed - I now need an hash containing the keys: "
		  . join( ", ", @keys ) )
	  unless ( ref($hash) eq "HASH" );
	my (
		$im,        $x_start, $y_start, $x_end,    $y_end,     $color,
		$fillColor, $xTitle,  $yTitle,  $portrait, $fixedAxis, $which
	);

	$im        = $hash->{'im'};
	$x_start   = $hash->{'x_min'};
	$x_end     = $hash->{'x_max'};
	$y_start   = $hash->{'y_min'};
	$y_end     = $hash->{'y_max'};
	$color     = $hash->{'color'};
	$fillColor = $hash->{'fillColor'};
	$xTitle    = $hash->{'x_title'};
	$yTitle    = $hash->{'y_title'};
	$portrait  = $hash->{'portrait'};
	$fixedAxis = $hash->{'fixed_axis'};
	$which     = $hash->{'fixed_axis_is'};

	if ( defined $hash->{'x_axis'} ) {
		$self->{xaxis} = $hash->{'x_axis'};
	}
	if ( defined $hash->{'y_axis'} ) {
		$self->{yaxis} = $hash->{'y_axis'};
	}
	unless ( defined $self->{xaxis} && defined $self->{yaxis} ) {
		$self->createAxies( $x_start, $y_start, $x_end, $y_end, $portrait );
		$which |= "";
		if ( $which eq "X" ) {
			$self->{xaxis} = $fixedAxis;
		}
		if ( $which eq "Y" ) {
			$self->{yaxis} = $fixedAxis;
		}
	}

#Carp::confess ( root::get_hashEntries_as_string ({'xaxis' => $self->{xaxis}, 'yaxis' =>$self->{yaxis}}, 3, "There has to be some missing values here - please find them! "), 200);
	my $data = $self->getAsDataMatrix();

  #root::print_hashEntries( $self, 5, "what is the problem in the histogram??");
  #root::print_hashEntries( $data, 3, "$self wq got the data!");

#$self->{xaxis}->plot($im, $self->{yaxis}->resolveValue($self->{yaxis}->min_value()), $color, "This is only a test! (x_axis)");
#$self->{yaxis}->plot($im, $self->{xaxis}->resolveValue($self->{xaxis}->min_value()), $color, "This is only a test! (y_axis)");

	$self->_barGraph2im( $im, $data, $color, $fillColor, $portrait );
	$self->plot_axies( $portrait, $im, $color, $xTitle, $yTitle );
	if ( $self->Title() ) {

#$self->{font}->plotStringCenteredAtXY( $im, $self->Title(), ($x_start + $x_end ) / 2 , 20 , $color, 'large', 0  );
	}

	#print "and now we try to craete a bargraph\n";
	#$self->_plotAxies($im, $color, $xTitle, $yTitle);
	#print "and now we are ready!\n";
	return 1;
}

sub Title {
	my ( $self, $title ) = @_;
	return $self->{'title'} unless ( defined $title );
	return $self->{'title'} = $title;
}

sub _check_plot_hash {
	my ( $self, $hash ) = @_;
	$self->{error} = $self->{warning} = '';
	unless ( defined $hash->{'x_resolution'} ) {
		$self->{warning} .= ref($self)
		  . ":_check_plot_hash -> x_resolution was not set (set to 800)\n";
		$hash->{'x_resolution'} = 800;
	}
	unless ( defined $hash->{'y_resolution'} ) {
		$self->{warning} .= ref($self)
		  . ":_check_plot_hash -> y_resolution was not set (set to 600)\n";
		$hash->{'y_resolution'} = 600;
	}
	unless ( defined $hash->{'outfile'} ) {
		$self->{error} .= ref($self)
		  . ":_check_plot_hash -> we got no outfile - critical error\n";
	}

}

sub Mark_position {
	my ( $self, $value, $color ) = @_;
	$color = 'red' unless ( defined $color );
	if ( defined $self->{'marks'}->{$value} ) {
		warn "we will already set a makr at x position $value!\n";
		return 0;
	}
	$self->{'marks'}->{$value} = $color;
	return 1;
}

=head2 plot ( {
	'x_title' (defualt = 'data values'),
	'y_title' (defualt = 'amount of data points'),
	'x_resolution',
	'y_resolution',
	'outfile'
})

# 'x_title', 'y_title', 'x_resolution','y_resolution','outfile'

=cut

sub plot {
	my ( $self, $hash ) = @_;

	$self->_check_plot_hash($hash);
	Carp::confess( "the plot hash did not contain all necessary information:\n"
		  . $self->{'error'}
		  . "and the warnings\n"
		  . $self->{'warning'} )
	  if ( $self->{'error'} =~ m/\w/ );
	$self->plotSingle(1);

	#warn $self->{warning} if ( $self->{warning} =~ m/\w/);

	$hash->{'x_title'} = "data values" unless ( defined $hash->{'x_title'} );
	$hash->{'y_title'} = "amount of data points"
	  unless ( defined $hash->{'y_title'} );

	my $im =
	  GD::SVG::Image->new( $hash->{'x_resolution'}, $hash->{'y_resolution'} );
	my $color = $self->{'color'} = color->new($im);
	$self->plot_2_image(
		{
			'im'        => $im,
			'x_min'     => $hash->{'x_resolution'} * 0.1,
			'x_max'     => $hash->{'x_resolution'} * 0.9,
			'y_min'     => $hash->{'y_resolution'} * 0.1,
			'y_max'     => $hash->{'y_resolution'} * 0.89,
			'color'     => $color->{black},
			'fillColor' => $color->{gray},
			'x_title'   => $hash->{'x_title'},
			'y_title'   => $hash->{'y_title'}
		}
	);
	&writePicture( $im, $hash->{'outfile'} );
}

sub writePicture {
	my ( $im, $pictureFileName ) = @_;

	# Das Bild speichern
	print "bild unter $pictureFileName speichern:\n";
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );

	#print "We print to path $path\n";
	mkdir($path) unless ( -d $path );
	$pictureFileName = "$pictureFileName.svg"
	  unless ( $pictureFileName =~ m/\.svg$/ );
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n$!\n";

	binmode PICTURE;
	my $RETURN = $im->svg;
	print PICTURE $RETURN;
	close PICTURE;
	print "Bild als $pictureFileName gespeichert\n";
	$im = undef;
	return $pictureFileName;
}

sub plotSingle {
	my ( $self, $plotSingle ) = @_;
	if ( defined $plotSingle ) {
		$self->{_write_axis_numbers} = 1;
	}
	return $self->{_write_axis_numbers};
}

sub __checkArray {
	my ( $self, $array ) =@_;
	return 0 unless ( ref($array) eq "ARRAY");
	foreach ( @$array ) {
		return 0 unless ( defined $_);
	}
	return 1;
}
sub _barGraph2im {
	my ( $self, $im, $dataset, $color, $fillColor, $potrait ) = @_;

	$fillColor = $color unless ( defined $fillColor );
	unless ($potrait) {
		my $minValue = $self->{yaxis}->resolveValue(  $self->{yaxis}->min_value() );
		foreach my $dataArray (@$dataset) {
			next unless ( $self->__checkArray($dataArray));
			$im->filledRectangle(
				$self->{xaxis}->resolveValue( @$dataArray[0] ),
				$minValue,
				$self->{xaxis}->resolveValue( @$dataArray[1] ),
				$self->{yaxis}->resolveValue( @$dataArray[2] ),
				$fillColor
			);
			$im->rectangle(
				$self->{xaxis}->resolveValue( @$dataArray[0] ),
				$minValue,
				$self->{xaxis}->resolveValue( @$dataArray[1] ),
				$self->{yaxis}->resolveValue( @$dataArray[2] ),
				$color
			);
		}
	}
	else {
		## now the y_values come from the x_axis and the x_values come from the y_axis
		my $minValue = $self->{xaxis}->resolveValue( $self->{yaxis}->min_value() );
		foreach my $dataArray (@$dataset) {
			next unless ( $self->__checkArray($dataArray));
			$im->filledRectangle(
				$minValue,
				$self->{yaxis}->resolveValue( @$dataArray[1] ),
				$self->{xaxis}->resolveValue( @$dataArray[2] ),
				$self->{yaxis}->resolveValue( @$dataArray[0] ),
				$fillColor
			);
			$im->rectangle(
				$minValue,
				$self->{yaxis}->resolveValue( @$dataArray[1] ),
				$self->{xaxis}->resolveValue( @$dataArray[2] ),
				$self->{yaxis}->resolveValue( @$dataArray[0] ),
				$color
			);
		}
	}

	if ( defined $self->{'marks'} ) {
		my $group_title = 'Marks' . rand();
		$im->newGroup($group_title);
		foreach my $x_value ( keys %{ $self->{'marks'} } ) {
			print "we mark the value $x_value\n" if ( $self->{'debug'} );
			$im->line(
				$self->{xaxis}->resolveValue($x_value),
				$self->{yaxis}->resolveValue( $self->{yaxis}->min_value ),
				$self->{xaxis}->resolveValue($x_value),
				$self->{yaxis}->resolveValue( $self->{yaxis}->max_value ),
				$self->{color}->{ $self->{'marks'}->{$x_value} }
			);
		}
		$im->endGroup($group_title);
	}

	return $im;
}

sub createAxies {
	my ( $self, $x_start, $y_start, $x_end, $y_end, $portrait ) = @_;

	my ( $data, @xrange, $x_axis, $y_axis );

	@xrange = $self->_getXrange();

	unless ($portrait) {
		## we plot it with an horizontal x axis and an vertical y axis
		print
"$self - we plot it with an horizontal x axis and an vertical y axis\n"
		  if ( $self->{debug} );
		$self->{xaxis} = axis->new( "x", $x_start, $x_end, "title", "min" );
		$self->{yaxis} = axis->new( "y", $y_start, $y_end, "title", "min" );
		$self->{yaxis}->max_value( $self->maxAmount() );
		$self->{yaxis}->min_value( $self->minAmount() );
		$self->{xaxis}->max_value( $xrange[1] );
		$self->{xaxis}->min_value( $xrange[0] );
	}
	else {
		## we plot it with an vertical x axis and an horizontal y axis
		print "we plot it with an vertical x axis and an horizontal y axis\n"
		  if ( $self->{debug} );
		$self->{xaxis} = axis->new( "x", $x_start, $x_end, "title", "min" );
		$self->{yaxis} = axis->new( "y", $y_start, $y_end, "title", "min" );
		$self->{yaxis}->max_value( $xrange[1] );
		$self->{yaxis}->min_value( $xrange[0] );
		$self->{xaxis}->max_value( $self->maxAmount() );
		$self->{xaxis}->min_value( $self->minAmount() );
	}

	print "hopefully the thing will work!\nINITIALIZATION of the axies:\n"
	  if ( $self->{debug} );
	$self->{xaxis}->resolveValue(0);
	print "x_axis OK\n" if ( $self->{debug} );
	$self->{yaxis}->resolveValue(0);
	print "y_axis OK!\n\tworked!\n" if ( $self->{debug} );
	print "initAxis in package ", ref($self), "\nxaxis min value =",
	  $self->{xaxis}->min_value, "; max value =", $self->{xaxis}->max_value,
	  "\n", "x coordinate for min value =",
	  $self->{xaxis}->resolveValue( $self->{xaxis}->min_value ), "; max value=",
	  $self->{xaxis}->resolveValue( $self->{xaxis}->max_value ), "\n",
	  "yaxis min value =", $self->{yaxis}->min_value, "; may value =",
	  $self->{yaxis}->max_value, "\n", "y coordinate for min value =",
	  $self->{yaxis}->resolveValue( $self->{yaxis}->min_value ), "; may value=",
	  $self->{yaxis}->resolveValue( $self->{yaxis}->max_value ), "\n"
	  if ( $self->{debug} );

	#	$self->writePicture($filename);
}

sub copyLayout {
	my ( $self, $other ) = @_;
	warn "$self->copyLayout got no example\n"
	  unless ( $other->isa('new_histogram') );
	$self->{bins} = $other->{bins};
	my $bins = $self->{bins};
	foreach my $binEntry (@$bins) {
		$self->{data}->{ $binEntry->{category} } = 0;
	}
	$self->Max( $other->Max );
	$self->Min( $other->Min );
	$self->Category_steps( $other->Category_steps() );
	return 1;
}

sub getCategoryOfTi {
	my ( $self, $Ti ) = @_;

	unless ( defined $self->{bins} ) {
		die
"$self->getCategoryOfTi Max and Min Values of the X-values is not defined!\n"
		  unless ( defined $self->Max && defined $self->Min );

		$self->initialize();
	}
	my $categoryList = $self->{bins};
	die "$self->getCategoryOfTi no histo definition!\n"
	  unless ( defined $categoryList );
	foreach my $hash (@$categoryList) {
		return $hash->{category} if ( $hash->{category} eq $Ti );
		return $hash->{category}
		  if ( $Ti > $hash->{min} && $Ti <= $hash->{max} );
	}
	if ( $Ti == $self->Min ) {
		Carp::confess("Hey! the cotegoryList was not initialized!")
		  unless ( defined @$categoryList[0] );
		return @$categoryList[0]->{category};
	}

#	if ( $Ti == $self->Max ) {
#		return @$categoryList[ @$categoryList - 1 ]->{category};
#	}
	print root::get_hashEntries_as_string ( $self->{bins}, 3, "the bins:", 100 );
	Carp::confess(
"$self -> getCategoryOfTi :Value $Ti is not in the range of $self->{min} to $self->{max} and can therefore not be evaluated!\n"
	);
}

sub get_relPosition {
	my ( $self, $Ti ) = @_;

	unless ( defined $self->{bins} ) {
		die
"$self->getCategoryOfTi Max and Min Values of the X-values is not defined!\n"
		  unless ( defined $self->Max && defined $self->Min );

		$self->initialize();
	}
	return 0 if ( $Ti == $self->Min );
	my $categoryList = $self->{bins};
	die "$self->getCategoryOfTi no histo definition!\n"
	  unless ( defined $categoryList );
	for ( my $i = 0 ; $i < @$categoryList ; $i++ ) {
		return $i
		  if ( $Ti > @$categoryList[$i]->{min}
			&& $Ti <= @$categoryList[$i]->{max} );
	}
	root::print_hashEntries( $self->{bins}, 2 );
	die
"Value $Ti is not in the range of $self->{min} to $self->{max} and can therefore not be evaluated!\n";
}

sub numeric {
	return $a <=> $b;
}

sub initialize {
	my $self = shift;
	if ( ref( $self->{bins} ) eq "ARRAY" ) {

		# OK - only reinitialize - no complete breakdown!
		$self->{data} = {};
		foreach ( @{ $self->{bins} } ) {
			$self->{data}->{ $_->{'category'} } = 0;
		}
		return $self->{data}, $self->{bins};

	}
	$self->{data} = $self->{bins} = undef;

#print "Initialize max = ",$self->Max()," min = ",$self->Min()," and the data is separated in ", $self->Category_steps," Steps\n";
	$self->{stepSize} =
	  ( ( $self->Max() - $self->Min() ) / $self->Category_steps );
	my ( @array, $hash );
	$self->{data} = $hash;
	$self->{bins} = \@array;
	for ( my $i = $self->Min() ; $i < $self->Max() ; $i += $self->{stepSize} ) {
		push(
			@array,
			{
				category => $i + $self->{stepSize} / 2,
				max      => $i + $self->{stepSize},
				min      => $i
			}
		);
		$self->{data}->{ $i + $self->{stepSize} / 2 } = 0;
	}
	return $self->{data}, $self->{bins};
}

1;

