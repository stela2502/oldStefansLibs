package Affymetrix_SNP_array;
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
use stefans_libs::database::array_dataset::Affy_SNP_array::affy_cell_flatfile;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die $class, ":new -> we need a DBI object at startup!(not $dbh)\n$!"
	  unless ( defined $dbh && $dbh =~ m/DBI::db/ );

	my ($self);

	$self = {
		dbh   => $dbh,
		debug => $debug
	};

  	bless $self, $class  if ( $class eq "Affymetrix_SNP_array" );

  	return $self;

}


sub expected_dbh_type {
	return "not a primary table handler";
}

sub AddDataset{
	my ( $self, $dataset ) = @_;
	## here we are a SIMPLE wrapper around affy_cell_flatfile
	
}
1;
