package stefans_libs::file_readers::CoExpressionDescription::KEGG_results;

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
use base 'data_table';

=head1 General description

This package should be used if you work with KEGG pathway results. If you use it already at the creation state, you will be able to save a lot time during the analysis.

=cut

sub new {

	my ( $class, $debug ) = @_;
	my ($self);
	$self = {
		'debug'           => $debug,
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'kegg_pathway.id'        => 0,
			'matched genes'          => 1,
			'pathway_name'           => 2,
			'Gene Symbols'           => 3,
			'max_count'              => 4,
			'bad_entries'            => 5,
			'hypergeometric p value' => 6,
		},
		'default_value' => [],
		'header'        => [
			'kegg_pathway.id', 'matched genes',
			'pathway_name',    'Gene Symbols',
			'max_count',       'bad_entries',
			'hypergeometric p value',
		],
		'data'         => [],
		'index'        => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class
	  if ( $class eq
		"stefans_libs::file_readers::CoExpressionDescription::KEGG_results" );

	return $self;
}

sub Add_2_Header {
	my ( $self, $value ) = @_;
	return undef unless ( defined $value );
	unless ( defined $self->{'header_position'}->{$value} ) {
		Carp::confess(
			    "You try to change the table structure - That is not allowed!\n"
			  . "If you really want to add the column '$value' use "
			  . "the original data_table class to modify the table structure!\n"
		);
	}
	return $self->{'header_position'}->{$value};
}

=head2 get_significant_pathway_names

If this object does know a alternative p_value cut off, that has to be part of the 'description'
information of this object (onle line like 0.05=([\d\.E\-]+) ), This object will return a list
of pathway names, that were found to be significantly correlated in this KEGG file.

If no corrected p_value if found, the object will asume 0.05 as being the correct p_value!

=cut

sub get_significant_pathway_names {
	my ($self) = @_;
	## First I need to get the necessary signifcance niveau
	my $cut_off;
	$cut_off = $1
	  if ( join( "!-!", @{$self->{'description'}} ) =~ m/!-!0.05=([\d\.E\-]+)!-!/ );
	$cut_off = 0.05 unless ( defined $cut_off );
	warn "we have the p_value cutoff $cut_off\n";
	print $self->select_where( 'hypergeometric p value',
		sub { return 1 if ( $_[0] <= $cut_off ); return 0; } ) ->AsString();
	return ($self->select_where( 'hypergeometric p value',
		sub { return 1 if ( $_[0] <= $cut_off ); return 0; } )
	  ->getAsArray('pathway_name')) ;
}


1;
