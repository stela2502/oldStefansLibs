package gnuplotParser;
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

use stefans_libs::root;
use strict;

sub new{

  my ( $class ) = @_;

  my ( $self );

  $self = {
  };

  bless $self, $class  if ( $class eq "gnuplotParser" );

  return $self;

}

sub parseProbobilityFunctionFilename{

  my ( $self, $filename ) = @_;

  my ( $fileHash );

  $fileHash = root->getPureSequenceName($filename);
  $fileHash->{origName} = $filename;

  if ( $fileHash->{filename} =~ m/(F[01])_([\w\d]+)\.([\w\d]+)\.([\w\d]+)_(\d+)-design(\d\d\d\d-\d\d-\d\d_RZPD\d\d\d\d_MM\d_ChIP)/){
      ($fileHash->{'probability_Function_Type'}, $fileHash->{'antibody'}, $fileHash->{'celltype'}, $fileHash->{'organism'}, $fileHash->{'iteration'}, $fileHash->{'designID'}) =
       ($1,$2,$3,$4,$5,$6);
  }
  else {
     die "$fileHash->{filename} ist kein HMM Ergenbins Datei Name!\n";
  }
  return $fileHash;
}


1;
