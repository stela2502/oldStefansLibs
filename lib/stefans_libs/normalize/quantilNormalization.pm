package quantilNormalization;

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
use stefans_libs::root;

sub new {

	my ( $class, $log2, $debug ) = @_;

	my ($self);

	$self = { log2_data => $log2, debug => $debug };

	bless $self, $class if ( $class eq "quantilNormalization" );

	return $self;

}

sub quantilNormalize {
	my ( $self, @hashes ) = @_;

	return $self->_quantilNormalize_hash(@hashes)
	  if ( ref( $hashes[0] ) eq "HASH" );
	die "quantilNormalize got no usable data ( @hashes )\n"
	  unless ( ref( $hashes[0] ) eq "ARRAY" );

	my ( $array, $hash, $hashes_from_arrays );

	## we have to place the new values into the array!
	$hashes_from_arrays = $self->_createHashfromArray(@hashes);
	$self->_quantilNormalize_hash(@$hashes_from_arrays);

	for ( my $i = 0 ; $i < @$hashes_from_arrays ; $i++ ) {
		$hash  = @$hashes_from_arrays[$i];
		$array = $hashes[$i];
		foreach my $key ( keys %$hash ) {
			@$array[$key] = $hash->{$key};
		}
	}

	return 1;
}

sub _createHashfromArray {
	my ( $self, @arrays ) = @_;

	my ( $matrix, @hashes, $array );

	for ( my $i = 0 ; $i < @arrays ; $i++ ) {
		$array = $arrays[$i];
		my $hash;
		for ( my $position = 0 ; $position < @$array ; $position++ ) {
			$hash->{$position} = @$array[$position];
		}
		push( @hashes, $hash );
	}
	return \@hashes;
}

sub _quantilNormalize_hash {
	my ( $self, @hashes ) = @_;

	my ( $matrix, $hash );

	$matrix = $self->_create_quantil_matrix(@hashes);

	$matrix = $self->_setLineValuesTo_mean($matrix);

	my $dataPosition;
	for ( my $i = 0 ; $i < ( @hashes * 2 ) ; $i += 2 ) {
		$hash = $hashes[ $i / 2 ];

		foreach my $lineArray (@$matrix) {
			$hash->{ @$lineArray[$i] } = @$lineArray[ $i + 1 ];
		}
	}
	return 1;
}

sub _setLineValuesTo_mean {
	my ( $self, $matrix ) = @_;

	my ( @values, $mean, $anzahl );
	unless ( $self->{log2_data} ) {
		foreach my $lineArray (@$matrix) {
			@values = ();
			for ( my $i = 1 ; $i < @$lineArray ; $i += 2 ) {
				push( @values, @$lineArray[$i] );
			}
			( $mean, $anzahl ) = root::mittelwert( 'root', \@values );
			for ( my $i = 1 ; $i < @$lineArray ; $i += 2 ) {
				@$lineArray[$i] = $mean;
			}
		}
	}
	else {
		foreach my $lineArray (@$matrix) {
			@values = ();
			for ( my $i = 1 ; $i < @$lineArray ; $i += 2 ) {
				push( @values, 2**@$lineArray[$i] );
			}
			( $mean, $anzahl ) = root::mittelwert( 'root', \@values );
			for ( my $i = 1 ; $i < @$lineArray ; $i += 2 ) {
				@$lineArray[$i] = log2($mean);
			}
		}
	}
	return $matrix;
}

sub log2 {
	my ($value) = @_;
	return log($value) / log(2);
}

sub _create_quantil_matrix {
	my ( $self, @hashes ) = @_;
	my ( @temp, @matrix, $hash, @keys );

	$hash = $hashes[0];
	@keys = ( keys %$hash );
	for ( my $i = 0 ; $i < @keys ; $i++ ) {
		$matrix[$i] = [];
	}

	for ( my $array_id = 0 ; $array_id < @hashes ; $array_id++ ) {
		$hash = $hashes[$array_id];
		foreach (@temp) {
			@$_ = undef;
		}
		@temp = ();
		while ( my ( $id, $value ) = each %$hash ) {
			push( @temp, [ $id, $value ] );
		}
		@temp = ( sort { @$a[1] <=> @$b[1] } @temp );
		for ( my $i = 0 ; $i < @keys ; $i++ ) {
			push( @{ $matrix[$i] }, ( @{ $temp[$i] } ) );
		}
	}
	return ( \@matrix );
}

1;

