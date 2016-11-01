package stefans_libs::SNP_2_Gene_Expression;
#  Copyright (C) 2010-09-03 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::SNP_2_Gene_Expression.pm

=head1 DESCRIPTION

A class to hold all information for a SNP_2_Gene_Expression analysis at one place including all file, database, statistics and plot information in one place.

=head2 Contains

All included classes need to support the functions

get_4_sample_name [returns a value_object]

type [give me the type of the returned object??]

correct_4 (list of  {<sample> => <float>} hashes)

=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::SNP_2_Gene_Expression.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "stefans_libs::SNP_2_Gene_Expression" );

  	return $self;

}



1;
