package gbFile_X_axis;
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


sub new{

  my ( $class, $start, $end ) = @_;

  my ( $self );

  $self = {
     features => undef,
     min => $start,
     max => $end
  };

  bless $self, $class  if ( $class eq "gbFile_X_axis" );

  return $self;

}

sub Add_gbFeatures {
  my ( $self, $features, $start, $end) = @_;
  $self->{start} = $start;
  $self->{end}   = $end;
  die "gbFile_X_axis -> Add_gbFeatures muss ein array von gbFeatures übergeben werden!\n" unless ( @$features[0] =~ m/gbFeature/);
  $self->{features} = $features;
  return 1;
}

sub getAsPlottable {
  my ( $self ) = @_;

  my ($features, @return, $i);

  $features = $self->{features};
  $i = 0;
  foreach my $feature (@$features){
     $return[$i++] = $feature->getAsPlottable();
  }
  return \@return;
}

1;
