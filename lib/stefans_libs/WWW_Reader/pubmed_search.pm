package pubmed_search;
#  Copyright (C) 2010-08-20 Stefan Lang

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

::home::stefan_l::workspace::Stefans_Libraries::lib::::home::stefan_l::Link_2_My_Libs::lib::WWW_Reader::pubmed_search.pm

=head1 DESCRIPTION

A tool to estimate the importance of a pubmed search result for a gene in connection with T2D.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class pubmed_search.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "pubmed_search" );

  	return $self;

}


1;
