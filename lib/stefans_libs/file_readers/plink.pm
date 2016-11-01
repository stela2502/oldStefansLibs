package plink;
#  Copyright (C) 2010-09-07 Stefan Lang

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
use stefans_libs::file_readers::plink::ped_file;
use stefans_libs::file_readers::plink::bim_file;


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::file_readers::plink

=head1 DESCRIPTION

A lib to read the plink text files. This lib was developed to read from the huge data files
and process them line by line to transfere the whole dataset into a database.
Therefore you should not use this interface to read directly from the files, 
as this module is SLOW and might use horrible amounts of memory!

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class plink.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
  	};

  	bless $self, $class  if ( $class eq "plink" );

  	return $self;

}


1;
