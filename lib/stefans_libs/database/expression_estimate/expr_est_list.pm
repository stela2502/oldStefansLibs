package expr_est_list;

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

use stefans_libs::database::lists::basic_list;
use stefans_libs::database::expression_estimate;
use base ('basic_list');

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A linkage table that links a list of chemicals to a protocol.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class materialList.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh)
	  unless ( ref($dbh) eq "DBI::db" );

	my ($self);

	$self = {
		debug           => $debug,
		dbh             => $dbh,
		'my_table_name' => "expr_est_list"
	};

	bless $self, $class if ( $class eq "expr_est_list" );

	$self->init_tableStructure();
	$self->{'data_handler'}->{'otherTable'} =
	  expression_estimate->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'__actualID'} = $self->readLatestID();

	return $self;

}

sub GetExpressionInterface_4_ListID {
	my ( $self, $my_id ) = @_;
	unless ( defined $my_id ) {
		return [];
	}
	return $self->{'data_handler'}->{'otherTable'}->GetInterface(
		[
			[
				ref( $self->{'data_handler'}->{'otherTable'} ) . '.id', '=',
				'my_value'
			]
		],
		$self->Get_IDs_for_ListID($my_id)
	);
}

1;
