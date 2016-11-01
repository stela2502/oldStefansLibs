package creaturesTable;
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
use stefans_libs::database::organismDB;
use stefans_libs::database::variable_table;
use base "variable_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store information on a creature that was used for a experiment.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class creaturesTable.

=cut

sub new{

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!" unless (defined $dbh);
	
	my ( $self );

	$self = {
		dbh => $dbh,
		debug => $debug,
		downstream_Tables => [ 'organism' ]
	};
	
  	bless $self, $class  if ( $class eq "creaturesTable" );

	$self->{'organism'} = organismDB->new( $self->{dbh}, $self->{debug});
	
  	return $self;

}

sub create {
	my ($self) = @_;

	$self->{dbh}->do( "DROP table if exists creatures;" );

	my $craeteString = "
CREATE TABLE creatures (
	id  INTEGER UNSIGNED auto_increment,
	family_id INTEGER UNSIGNED default 0,
	identifier varchar ( 20 ) default '',
	organism_id INTEGER UNSIGNED NOT NULL,
	state varchar ( 20 ) default '',
	KEY ID ( id),
	UNIQUE unique ( identifier )
); ";

	if ( $self->{debug} ) {
		print ref($self), ":create -> we would run $craeteString\n" ;
		foreach my $downstreamTable ( @{ $self->{'downstream_Tables'} } ) {
            print ref($self),":create -> we create a downstream table for class ",ref($self->{$downstreamTable})," for table name $downstreamTable\n";
			unless ( $self->tableExists($downstreamTable) ) {
				$self->{$downstreamTable}->create();
			}
		}
	}
	else {
		$self->{dbh}->do( $craeteString ) or die $self->{dbh}->{errstr};
		foreach my $downstreamTable ( @{ $self->{'downstream_Tables'} } ) {
            print ref($self),":create -> we create a downstream table for class ",ref($self->{$downstreamTable})," for table name $downstreamTable\n";
			unless ( $self->tableExists($downstreamTable) ) {
				$self->{$downstreamTable}->create();
			}
		}
		$self->{__tableNames} = undef;
	}
	return 1;
}

1;
