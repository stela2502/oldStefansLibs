package alleleFreq;
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

sub new{

	my ( $class, $string ) = @_;

	my ( $self, $data, @allelFreq );

	$self = {
		populations => $data
  	};

  	bless $self, $class  if ( $class eq "alleleFreq" );

  	return $self;

}

sub parse_affy_String{
	my ( $self, $string ) = @_;
	my ( @values, $A, $B, $popID );
	@values = split ( "//", $string );
	foreach (@values){
		unless ( defined $A ){
			$_ =~ m/(0\.\d+)/;
			$A = $1;
			next;
		}
		unless ( defined $B ){
			$_ =~ m/(0\.\d+)/;
			$B = $1;
			next;
		}
		$_ =~ m/(\w+)/;
		$self->{populations}->{$1} = {major => $A, minor => $B};
		$A = $B = undef;
	}
	return 1;
}

sub getMinorFreq_4_popID{
	my ( $self, $popID) = @_;
	unless ( defined  $self->{populations}->{$popID}->{minor} ){
		$self->{populations}->{$popID}->{minor} =  1- $self->{populations}->{$popID}->{major};
	}
	return $self->{populations}->{$popID}->{minor};
}

sub getMajorFreq_4_popID{
	my ( $self, $popID) = @_;
	return $self->{populations}->{$popID}->{major};
}

sub getHeterozygousFreq_4_popID{
	my ( $self, $popID) = @_;
	return ($self->{populations}->{$popID}->{major} * $self->{populations}->{$popID}->{minor} * 2 );
}

1;
